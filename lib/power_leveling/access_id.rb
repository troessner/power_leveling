module PowerLeveling
  class AccessId
    REDIS_KEY_INFIX = 'access_id'
    ID_FORMAT       = '[a-zA-Z0-9]{1,24}'

    include ActiveModel::Validations

    validates_presence_of :value, :api_key_value
    validates_format_of   :value, :with => /\A#{ID_FORMAT}\z/, :message => Messages::ERRORS[:access_id_invalid]
    validate :authorized

    attr_accessor :tenant_name, :api_key_value, :value, :redis_key

    def initialize(options = {})
      @value          = options[:value]
      @tenant_name    = options[:tenant_name]
      @redis_key      = build_redis_key
      @api_key_value  = options[:api_key_value]
    end

    def self.fetch_for(user)
      tenant_name = user.tenant.name

      redis_keys = PowerLeveling::Redis.client.hgetall(tenant_name).keys.grep(/\A#{REDIS_KEY_INFIX}_#{ID_FORMAT}\z/)
      access_id_values = values redis_keys
      access_ids = []
      access_id_values.each do |value|
        api_key_value = PowerLeveling::Redis.client.hget tenant_name, "#{REDIS_KEY_INFIX}_#{value}"
        access_id = AccessId.new :value => value, :tenant_name => user.tenant.name, :api_key_value => api_key_value
        access_ids << access_id if access_id.valid?
      end
      access_ids
    end

    def exists?
      PowerLeveling::Redis.client.hget @tenant_name, @redis_key
    end

    def save
      PowerLeveling::Redis.client.hset @tenant_name, @redis_key, @api_key_value
    end

    def destroy
      PowerLeveling::Redis.client.hdel @tenant_name, @redis_key
    end

    def self.find(value, tenant_name)
      access_id = new :value => value, :tenant_name => tenant_name
      return nil unless access_id.exists?
      access_id.api_key_value = PowerLeveling::Redis.client.hget access_id.tenant_name, access_id.redis_key
      access_id
    end

    def ==(other)
      @redis_key == other.redis_key && @api_key_value == other.api_key_value
    end

    private

    def authorized
      errors.add(:value, Messages::ERRORS[:access_id_unauthorized]) unless ApiKey.authenticated? @tenant_name, @api_key_value
    end

    def build_redis_key
      "#{REDIS_KEY_INFIX}_#{@value}"
    end

    def self.values(redis_keys)
      start_index = REDIS_KEY_INFIX.size + 1 # +1 for the '_'
      redis_keys.map{|k| k[start_index..-1]}
    end
  end
end
