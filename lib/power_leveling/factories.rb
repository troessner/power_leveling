def random_tenant_name
  iterations = Random.number(4..10)
  tenant_name = ''
  iterations.times do
    tenant_name << ('a'..'z').to_a[rand(25)]
  end
  tenant_name
end

Factory.define :access_id, :class => PowerLeveling::AccessId, :default_strategy => :build do |ai|
  ai.tenant_name    { random_tenant_name }
  ai.api_key_value  { Random.alphanumeric(24) }
  ai.value          { Random.alphanumeric(24) }
  ai.after_build do |access_id|
    PowerLeveling::ApiKey.new(:tenant_name => access_id.tenant_name, :value => access_id.api_key_value).save
    access_id.redis_key = access_id.send :build_redis_key
  end
end

Factory.define :api_key, :class => PowerLeveling::ApiKey, :default_strategy => :build do |ak|
  ak.tenant_name    { random_tenant_name }
  ak.value          { Random.alphanumeric(24) }
  ak.after_build do |api_key|
    api_key.redis_key  =  PowerLeveling::ApiKey.build_redis_key api_key.value
  end
end

Factory.define :basic_event, :class => PowerLeveling::BasicEvent, :default_strategy => :build do |be|
  be.tenant_name  { random_tenant_name }
  be.event_id     { Random.alphanumeric(24) }
  be.app_id       { Random.alphanumeric(24) }
end

Factory.define :event, :class => PowerLeveling::Event, :parent => :basic_event, :default_strategy => :build do |e|
  e.after_build do |event|
    et = Factory(:event_type, :tenant_name => event.tenant_name, :event_id => event.event_id)
    et.save
    event.event_type = et
  end
end

Factory.define :event_type, :class => PowerLeveling::EventType, :parent => :basic_event, :default_strategy => :build do |et|
  et.constraints    {{ 'required' => %w(price), 'type' => { 'price' => 'float' }}}
  # FIXME Setting "override" here causes specs to fail.
  # et.override       false
  # We need to build the redis key explicitly here as there is no way to pass an options hash
  # to our EventType constructor via FactoryGirl (so the redis key can not be build properly)
  et.after_build do |event_type|
    event_type.redis_key = PowerLeveling::EventType.build_redis_key event_type.app_id, event_type.event_id
  end
end
