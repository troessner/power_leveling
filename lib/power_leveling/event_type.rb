module PowerLeveling
  class EventType < BasicEvent
    REDIS_KEY_INFIX  = 'event_type'
    REDIS_KEY_FORMAT = "#{REDIS_KEY_INFIX}_#{APP_ID_FORMAT}_#{EVENT_ID_FORMAT}"
    AVAILABLE_VALIDATION_TYPES = %w!float integer string!

    validate :invalid_override
    validate :invalid_constraints

    attr_accessor :constraints, :redis_key, :override
    # We need the accessors below for the management-app (EventTypes-Ctrl)
    attr_accessor :required_fields, :required_types

    def initialize(options = {})
      @redis_key    = self.class.build_redis_key(options[:app_id], options[:event_id])
      @constraints  = options[:constraints_as_hash] || (options[:constraints_as_serialized_json].present? ? JSON.load(options[:constraints_as_serialized_json]) : {})
      @override     = options[:override]
      super(options)
    end

    def self.create(options)
      event_type = EventType.new options
      if event_type.valid?
        event_type.save
        [true, Messages::INFO[:record_created]]
      else
        [false, event_type.errors.values.flatten.first]
      end
    end

    def constraints_valid?
      constraint_keys_valid? &&
      (@constraints['required'].present? ? required_constraints_valid? : true) &&
      (@constraints['type'].present? ? type_constraints_valid? : true)
    end

    def save
      PowerLeveling::Redis.client.hset @tenant_name, @redis_key, JSON.dump(@constraints)
      create_column_family
    end

    def create_column_family
      PowerLeveling::CassandraHelper.create_column_family PowerLeveling::Cassandra.host, PowerLeveling::Cassandra.port, @tenant_name, column_family_name
    end

    def column_family_name
      "#{@app_id}_#{@event_id}"
    end

    def self.build_redis_key(app_id, event_id)
      "#{REDIS_KEY_INFIX}_#{app_id}_#{event_id}"
    end

    def self.find(tenant_name, key)
      serialized_constraints = PowerLeveling::Redis.client.hget tenant_name, key
      app_id, event_id = key.gsub("#{REDIS_KEY_INFIX}_", '').split '_'
      event_type = EventType.new(:constraints_as_serialized_json => serialized_constraints,
                                 :tenant_name                    => tenant_name,
                                 :app_id                         => app_id,
                                 :event_id                       => event_id)
      event_type.exists? ? event_type : nil
    end

    def invalid_override?
      (@override.present? && !exists?) || (@override.blank? && exists?)
    end

    def exists?
      PowerLeveling::Redis.client.hexists @tenant_name, @redis_key
    end

    def destroy
      PowerLeveling::Redis.client.hdel @tenant_name, @redis_key
    end

    def self.constraints_to_hash(required_fields_as_string, required_types_as_string)
      hash = {}
      return hash if required_fields_as_string.blank? && required_types_as_string.blank?
      hash['required'] = required_fields_as_string.gsub(' ', '').split(',')
      hash['type']     = required_types_as_string .gsub(' ', '').split(',').inject({}) do |result, pair|
        k,v = pair.split(':')
        result[k] = v
        result
      end
      hash
    end

    private

    def invalid_override
      errors.add(:override, Messages::ERRORS[:invalid_override]) if invalid_override?
    end

    def invalid_constraints
      errors.add(:constraints, Messages::ERRORS[:invalid_constraints]) unless constraints_valid?
    end

    def constraint_keys_valid?
      !@constraints.keys.any? {|key| ![:required, :type].include?(key.to_sym)}
    end

    def required_constraints_valid?
      @constraints['required'].is_a?(Array)
    end

    def type_constraints_valid?
      @constraints['type'].is_a?(Hash) && validation_types_known?(@constraints['type'].values.each(&:to_s))
    end

    def validation_types_known?(types)
      types_sorted = types.uniq.sort
      AVAILABLE_VALIDATION_TYPES & types_sorted == types_sorted
    end
  end
end
