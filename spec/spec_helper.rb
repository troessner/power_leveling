# TODO Let Bundler handle all of the necessary requirements.
dir = File.dirname(__FILE__)

require File.join(dir, '..', 'lib', 'power_leveling')
require 'random_data'
require 'rspec'

# Config
PATH_TO_CONFIG = 'spec/app_config.yml'
PowerLeveling::Verifier.config_present? PATH_TO_CONFIG
$app_config = YAML.load_file PATH_TO_CONFIG

# Redis
PowerLeveling::Redis.establish(Redis.new(:host => $app_config[:redis][:host], :port => $app_config[:redis][:port], :password => $app_config[:redis][:password]))
PowerLeveling::Verifier.redis_available?

# Cassandra
cassandra_endpoint = "#{$app_config[:cassandra][:host]}:#{$app_config[:cassandra][:port]}"
client = ::Cassandra.new $app_config[:cassandra][:default_keyspace], cassandra_endpoint
PowerLeveling::Verifier.cassandra_available? client

# Clean up before running the specs.
PowerLeveling::CassandraHelper.drop_keyspace   $app_config[:cassandra][:host], $app_config[:cassandra][:port], $app_config[:cassandra][:spec_keyspace]
PowerLeveling::CassandraHelper.create_keyspace $app_config[:cassandra][:host], $app_config[:cassandra][:port], $app_config[:cassandra][:spec_keyspace]
PowerLeveling::CassandraHelper.create_column_family $app_config[:cassandra][:host], $app_config[:cassandra][:port], $app_config[:cassandra][:spec_keyspace], "#{$app_config[:cassandra][:app_id]}_#{$app_config[:cassandra][:event_id]}"

$cass_spec_client = ::Cassandra.new $app_config[:cassandra][:spec_keyspace], cassandra_endpoint

PowerLeveling::Cassandra.establish $app_config[:cassandra][:host], $app_config[:cassandra][:port]
