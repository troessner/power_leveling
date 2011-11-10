require 'date'

module PowerLeveling
  class Event < BasicEvent
    include ActiveModel::Validations
    attr_accessor :event_type, :attributes

    validate :custom

    def initialize(options = {})
      redis_key_for_event_type = EventType.build_redis_key(options[:app_id], options[:event_id])
      @event_type = EventType.find options[:tenant_name], redis_key_for_event_type
      @attributes = options[:attributes_as_serialized_json].present? ? JSON.load(options[:attributes_as_serialized_json]) : {}
      super(options)
    end

    def self.create(options)
      event = Event.new options
      if event.valid?
        event.save
      else
        [false, event.errors.values.flatten.first]
      end
    end

    def save
      client = ::Cassandra.new @tenant_name, "#{$app_config[:cassandra][:host]}:#{$app_config[:cassandra][:port]}"
      @attributes.each {|k,v| @attributes[k] = v.to_s}
      client.insert column_family, self.class.time_uuid, @attributes.merge('timestamp' => DateTime.now.to_s)
      [true, Messages::INFO[:record_created]]
    end

    def has_event_type?
      @event_type.present?
    end

    def column_family
      "#{@app_id}_#{@event_id}"
    end

    def self.time_uuid
      SimpleUUID::UUID.new.to_guid
    end

    private

    def has_attribute?(key)
      @attributes.keys.include?(key) && @attributes[key].present?
    end

    def attribute_has_type?(attr_name, type)
      if @attributes[attr_name].present?
        method(type.camelcase).call(@attributes[attr_name]) rescue false
      end
    end

    def attributes_must_be_a_hash
      errors.add(:attributes, Messages::ERRORS[:not_a_hash]) unless @attributes.is_a? Hash
    end

    def event_type_does_exist
      errors.add(:event_type, Messages::ERRORS[:event_type_does_not_exist]) unless has_event_type?
    end

    def required_constraints
      if @event_type.constraints['required'].present?
        @event_type.constraints['required'].each do |required_attribute|
          errors.add(:event_type, "'Required' validation failed for attribute #{required_attribute}.") && return unless has_attribute?(required_attribute)
        end
      end
    end

    def type_constraints
      if @event_type.constraints['type'].present?
        @event_type.constraints['type'].each do |attr, type|
          errors.add(:event_type, "'Type' validation failed for attribute #{attr}.") && return unless attribute_has_type?(attr, type)
        end
      end
    end

    def custom
      # We need to ensure that validations are called in the exact order below, hence
      # the clumsy construct below. Apparently ActiveModel doesn't offer anything to solve
      # this issue in a better way.
      attributes_must_be_a_hash; return if errors.present?
      event_type_does_exist(); return if errors.present?
      required_constraints; return if errors.present?
      type_constraints; return if errors.present?
    end
  end
end
