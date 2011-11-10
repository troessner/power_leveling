# NOTE: We need to use the scope operator :: below, because otherwise rails (but none of the other
#       apps) thinks that Cassandra::Keyspace belongs to PowerLeveling.
module PowerLeveling
  module CassandraHelper
    def self.drop_keyspace(host, port, name)
      c = client(host, port)
      c.drop_keyspace name if c.keyspaces.include? name
    end

    def self.create_keyspace(host, port, name)
      ks = ::Cassandra::Keyspace.new :name => name, :strategy_class => 'org.apache.cassandra.locator.SimpleStrategy', :replication_factor => 1, :cf_defs => []
      client(host, port).add_keyspace ks
    end

    def self.create_column_family(host, port, keyspace, column_family_name)
      # FIXME This is a workaround - apparently there is no column_family_exists? method in the cassandra
      #       gem so we need to catch the exceptions thrown when doing a drop_column_family on a non
      #       existent CF.
      begin
        client(host, port, keyspace).drop_column_family column_family_name
      rescue
      end
      cf = ::Cassandra::ColumnFamily.new :name => column_family_name, :keyspace => keyspace, :comparator_type => 'UTF8Type'
      client(host, port, keyspace).add_column_family cf
    end

    def self.keyspace_exists?(host, port, name)
      client(host, port).keyspaces.include? name
    end

    def self.client(host, port, keyspace = 'system')
      ::Cassandra.new keyspace, "#{host}:#{port}"
    end
  end
end
