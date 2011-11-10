module PowerLeveling
  module Verifier
    def self.redis_available?
      begin
        PowerLeveling::Redis.client.randomkey
      rescue => e
        raise "Getting a random key from Redis failed. Are you sure Redis is up and running? Exception is #{e}"
      end
    end

    def self.cassandra_available?(client)
      begin
        client.keyspaces
      rescue => e
        raise "Can\'t get a list of keyspaces for Cassandra. Are you sure Cassandra is up and running? Exception is #{e}"
      end
    end

    def self.config_present?(path)
      raise "Could not find #{path} - Exiting." unless File.exists? path
    end
  end
end

