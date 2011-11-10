module PowerLeveling
  class RedisConnectionNotInitializedError < StandardError
    def initialize(msg =  'You need to call `PowerLeveling::Redis.establish(client)` in your application before using PowerLeveling.')
      super(msg)
    end
  end

  class Redis
    @@client = nil

    def self.establish(client)
      @@client = client
    end

    def self.client
      raise RedisConnectionNotInitializedError unless @@client.present?
      @@client
    end
  end
end
