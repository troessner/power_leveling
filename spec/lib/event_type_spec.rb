require 'spec_helper'

module PowerLeveling
  describe 'EventType' do
    it 'should validate via Factory' do
      Factory(:event_type).should be_valid
    end

    context 'should not validate' do
      before(:all) do
        @existing_event_type = Factory(:event_type, :tenant_name => $app_config[:cassandra][:spec_keyspace])
        @existing_event_type.save
      end

      it 'with invalid constraints ("type" value is not a hash)' do
        @event_type = Factory(:event_type)
        @event_type.constraints = { 'type' => %w(int float) }
        @event_type.valid?.should be_false
        @event_type.errors[:constraints].to_s.should == Messages::ERRORS[:invalid_constraints]
      end

      it 'with invalid override' do
        @event_type = Factory(:event_type, :tenant_name => @existing_event_type.tenant_name, :override => true, :redis_key => 'unknown')
        @event_type.valid?.should be_false
        @event_type.errors[:override].to_s.should == Messages::ERRORS[:invalid_override]
      end
    end

    context 'constraints_valid?' do
      before(:all) do
        @event_type = Factory(:event_type)
      end

      it 'should return false on invalid constraints: Not allowed validation key' do
        @event_type.constraints = { 'unique' => %w(order_number order_id) }
        @event_type.constraints_valid?.should_not be_true
      end

      it 'should return false on invalid constraints: "required" value is not an array' do
        @event_type.constraints = { 'required' => {'order_number' => 'unique'} }
        @event_type.constraints_valid?.should_not be_true
      end

      it 'should return false on invalid constraints: "type" value is not a hash' do
        @event_type.constraints = { 'type' => %w(int float) }
        @event_type.constraints_valid?.should_not be_true
      end

      it 'should return false on invalid constraints: validation type is unknown' do
        @event_type.constraints = { 'required' => %w(price order_id), 'type' => {'price' => 'unknown', 'order_id' => 'typo'} }
        @event_type.constraints_valid?.should_not be_true
      end

      it 'should return true on valid constraints' do
        @event_type.constraints = { 'required' => %w(price order_id), 'type' => {'price' => 'float', 'order_id' => 'integer'} }
        @event_type.constraints_valid?.should be_true
      end
    end

    context 'invalid_override?' do
      before(:all) do
        @existing_event_type = Factory(:event_type, :tenant_name => $app_config[:cassandra][:spec_keyspace])
        @existing_event_type.save
      end

      it 'should return true if we try to override an existing event type and pass in a non existent redis key' do
        @event_type = Factory(:event_type, :tenant_name => @existing_event_type.tenant_name, :override => true, :redis_key => 'unknown')
        @event_type.invalid_override?.should be_true
      end

      it 'should return true if we try to override an existing event type and do not pass the override flag' do
        @event_type = Factory(:event_type, :tenant_name => @existing_event_type.tenant_name)
        # We need to set a wrong redis_key explicitly here (and not in the FG call above)
        # because a standard call to a FG sets the redis key "after build" thus overriding
        # anything we pass into the FG call itself
        @event_type.redis_key = @existing_event_type.redis_key
        @event_type.invalid_override?.should be_true
      end

      it 'should return false if we try to override an existing event type and pass in the override switch' do
        @event_type = Factory(:event_type, :override    => true,
                                           :tenant_name => @existing_event_type.tenant_name,
                                           :app_id      => @existing_event_type.app_id,
                                           :event_id    => @existing_event_type.event_id)
        @event_type.invalid_override?.should be_false
      end
    end

    context 'exists?' do
      before(:all) do
        @existing_event_type = Factory(:event_type, :tenant_name => $app_config[:cassandra][:spec_keyspace])
        @existing_event_type.save
      end

      it 'should return true if we can find the event_type using its redis key' do
        @existing_event_type.exists?.should be_true
      end

      it 'should return true if we try to override an existing event type and pass in a non existent redis key' do
        Factory.build(:event_type).exists?.should be_false
      end
    end

    context 'constraints_to_hash' do
      it 'should return an empty hash if we pass in blank arguments' do
        EventType.constraints_to_hash(nil, nil).should == {}
      end

      it 'should return an approprate hash if we pass required fields and types as string' do
        EventType.constraints_to_hash('item_id, checkout_type', 'item_id:Integer, checkout_type:String').should == {
          'required' => %w!item_id checkout_type!,
          'type'     => {
            'item_id'       => 'Integer',
            'checkout_type' => 'String'
          }
        }
      end
    end
  end
end
