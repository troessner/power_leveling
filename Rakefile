require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "power_leveling"
  gem.homepage = "http://github.com/troessner/power_leveling"
  gem.license = "TBA"
  gem.summary = %Q{A common library for everyting related to power_leveling.}
  gem.description = %Q{A common library for everyting related to power_leveling (CE_management and CE_middleware).}
  gem.email = "timo.roessner@googlemail.com"
  gem.authors = ["Timo Rößner"]
  gem.files = ['power_leveling.gemspec',
               'Gemfile',
               'lib/power_leveling/access_id.rb',
               'lib/power_leveling/api_key.rb',
               'lib/power_leveling/basic_event.rb',
               'lib/power_leveling/cassandra.rb',
               'lib/power_leveling/cassandra_helper.rb',
               'lib/power_leveling/dependencies.rb',
               'lib/power_leveling/event_type.rb',
               'lib/power_leveling/event.rb',
               'lib/power_leveling/messages.rb',
               'lib/power_leveling/redis.rb',
               'lib/power_leveling/verifier.rb',
               'LICENSE.txt',
               'Rakefile',
               'README.rdoc',
               'spec/app_config.yaml.sample',
               'spec/factories.rb',
               'spec/lib/api_key_spec.rb',
               'spec/lib/basic_event_spec.rb',
               'spec/lib/event_spec.rb',
               'spec/lib/event_type_spec.rb',
               'spec/spec_helper.rb',
               'VERSION']
  gem.add_dependency 'activemodel', '=3.0.3'
  gem.add_dependency 'cassandra', '=0.9.0'
  gem.add_dependency 'redis', '=2.0.1'
  gem.add_dependency 'yajl-ruby', '=0.7.8'
  gem.rubyforge_project = "nowarning"
end
Jeweler::RubygemsDotOrgTasks.new

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "power_leveling #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
