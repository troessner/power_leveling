module PowerLeveling
  class ApiKey
    REDIS_KEY_INFIX = 'api_key'
    VALUE_FORMAT = '[a-zA-Z0-9]{1,24}'

    include ActiveModel::Validations

    validates_presence_of :value, :tenant_name
    validates_format_of   :value, :with => /\A#{VALUE_FORMAT}\z/, :message => Messages::ERRORS[:api_key_invalid]

    attr_accessor :redis_key, :value, :tenant_name

    # TODO fetch_for should return full-fledged ApiKey objects, not just the values.
    def self.fetch_for(user)
      redis_keys = PowerLeveling::Redis.client.hgetall(user.tenant.name).keys.grep(/\A#{REDIS_KEY_INFIX}_#{VALUE_FORMAT}\z/)
      values redis_keys
    end

    def initialize(options = {})
      @tenant_name = options[:tenant_name]
      @value       = options[:value]
      @redis_key   = self.class.build_redis_key(@value)
    end

    def save
      PowerLeveling::Redis.client.hset @tenant_name, @redis_key, nil
    end

    def exists?
      PowerLeveling::Redis.client.hexists @tenant_name, @redis_key
    end

    def destroy
      PowerLeveling::Redis.client.hdel @tenant_name, @redis_key
    end

    def self.find(value, tenant_name)
      api_key = new :value => value, :tenant_name => tenant_name
      api_key.exists? ? api_key : nil
    end

    def ==(other)
      @redis_key == other.redis_key && @tenant_name == other.tenant_name
    end

    def self.authenticated?(tenant_name, api_key_value)
      ApiKey.new(:tenant_name => tenant_name, :value => api_key_value).exists?
    end

    def self.build_redis_key(value)
      "#{REDIS_KEY_INFIX}_#{value}"
    end

    private

    def self.values(redis_keys)
      start_index = REDIS_KEY_INFIX.size+1
      redis_keys.map{|k| k[start_index..-1]}
    end
  end
end
