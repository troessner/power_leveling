require 'spec_helper'

# NOTE: Don't use symbols in hashes for events. We get strings in params, we serialize
# strings and we deserialize strings.

module PowerLeveling
  describe 'Event' do
    context 'validate' do
      let(:event) do
        event = Factory(:event, :tenant_name => $app_config[:cassandra][:spec_keyspace])
        event.event_type.constraints = { 'required' => %w(order_id price), 'type' => { 'price' => 'float' }}
        event
      end

      it 'should return false on failed validation: "required" field is not set' do
        event.attributes = { 'price' => '6.66' }
        event.valid?.should == false
        event.errors.should == {:event_type=> ["'Required' validation failed for attribute order_id."]}
      end

      it 'should return false on failed validation: "wrong type"' do
        event.attributes = { 'order_id' => Random.alphanumeric(15), 'price' => 'xxx' }
        event.valid?.should == false
        event.errors.should == {:event_type => ["'Type' validation failed for attribute price."]}
      end

      it 'should return true on successful validation' do
        event.attributes = { 'order_id' => Random.alphanumeric(15), 'price' => '6.66' }
        event.valid?.should == true
      end
    end

    context 'attribute_has_type?' do
      before(:all) do
        @event = Factory(:event, :tenant_name => $app_config[:cassandra][:spec_keyspace])
      end

      it 'should return false if we submit an alpanumeric string but want a float' do
        @event.attributes = { 'price' => 'xyz' }
        @event.send(:attribute_has_type?, 'price', 'float').should be_false
      end

      it 'should return false if we submit an alpanumeric string but want a integer' do
        @event.attributes = { 'order_id' => 'xyz' }
        @event.send(:attribute_has_type?, 'order_id', 'integer').should be_false
      end

      it 'should return true if we submit a float as string and want a float' do
        @event.attributes = { 'price' => '6.66' }
        @event.send(:attribute_has_type?, 'price', 'float').should be_true
      end
    end

    context 'create' do
      before(:all) do
        @event_type = Factory(:event_type, :tenant_name  => $app_config[:cassandra][:spec_keyspace],
                                           :event_id     => $app_config[:cassandra][:event_id],
                                           :app_id       => $app_config[:cassandra][:app_id])
        @event_type.constraints = { 'required' => %w(price), 'type' => { 'price' => 'float' }}
        @event_type.save
        @args = { :tenant_name                    => @event_type.tenant_name,
                  :event_id                       => @event_type.event_id,
                  :app_id                         => @event_type.app_id,
                  :attributes_as_serialized_json  => JSON.dump('order_id' => 'xxx', 'price' => '6.66')}
      end

      it 'should return an array with false and an appropriate error message if event attributes are not a hash' do
        attributes_as_array = %w!order_id price!
        status = Event.create(@args.merge(:attributes_as_serialized_json => JSON.dump(attributes_as_array)))
        status.should == [false, Messages::ERRORS[:not_a_hash]]
      end

      it 'should return an array with false and an appropriate error message if event has no event_type' do
        status = Event.create(@args.merge(:event_id => 'unknown'))
        status.should == [false, Messages::ERRORS[:event_type_does_not_exist]]
      end

      it 'should return an array with false and an appropriate error message if event did not pass type validation' do
        invalid_attributes = JSON.dump('price' => 'xxx')
        status = Event.create(@args.merge(:attributes_as_serialized_json => invalid_attributes))
        status.should == [false, "'Type' validation failed for attribute price."]
      end

      it 'should return an array with true and an appropriate info message if validation and storage were successful' do
        Event.create(@args).should == [true, Messages::INFO[:record_created]]
      end
    end

    context 'save' do
      it 'should create a record in cassandra' do
        @event = Factory(:event, :tenant_name   => $app_config[:cassandra][:spec_keyspace],
                                 :event_id      => $app_config[:cassandra][:event_id],
                                 :app_id        => $app_config[:cassandra][:app_id])
        @event.attributes = { 'price' => '6.66' }
        @event.event_type.constraints = { 'required' => %w(price), 'type' => { 'price' => 'float' }}
        row_key = Random.alphanumeric(12)
        Event.stub!(:time_uuid).and_return(row_key)

        @event.save.should == [true, Messages::INFO[:record_created]]
        record = $cass_spec_client.get(@event.column_family, row_key)
        record.delete('timestamp')
        record.should == { 'price' => '6.66' }
      end
    end
  end
end
