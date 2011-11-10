module PowerLeveling
  class CassandraConnectionNotInitializedError < StandardError
    def initialize(msg =  'You need to call `PowerLeveling::Cassandra.establish(host, port)` in your application before using PowerLeveling.')
      super(msg)
    end
  end

  class Cassandra
    @@host = nil
    @@port = nil

    def self.establish(host, port)
      @@host = host
      @@port = port
    end

    def self.host
      raise CassandraConnectionNotInitializedError unless @@host.present?
      @@host
    end

    def self.port
      raise CassandraConnectionNotInitializedError unless @@port.present?
      @@port
    end
  end
end
