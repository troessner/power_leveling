require 'spec_helper'

module PowerLeveling
  describe 'AccessId' do
    context 'validation' do
      it 'should be ok on correct parameters' do
        Factory(:access_id).should be_valid
      end

      it 'should fail without a value' do
        Factory(:access_id, :value => nil).should_not be_valid
      end

      it 'should fail on invalid value formats' do
        access_id = Factory(:access_id, :value => '_invalid_underscores_')
        access_id.should_not be_valid
        access_id.errors.first.should == [:value, Messages::ERRORS[:access_id_invalid]]
      end

      it 'should fail if there is not corresponding tenant_name / api_key mapping' do
        access_id = Factory :access_id, :value => Random.alphanumeric(24), :tenant_name => random_tenant_name
        access_id.api_key_value = Random.alphanumeric(24)
        access_id.should_not be_valid
        access_id.errors.first.should == [:value, Messages::ERRORS[:access_id_unauthorized]]
      end
    end

    context 'exists?' do
      it 'should be true for existant records' do
        access_id = Factory(:access_id)
        access_id.save
        access_id.exists?.should be_true
      end

      it 'should be false for non existant records' do
        Factory(:access_id).exists?.should be_false
      end
    end

    context 'save' do
      it 'should create a redis record' do
        access_id = Factory(:access_id)
        access_id.save
        Redis.client.hget(access_id.tenant_name, access_id.redis_key).should == access_id.api_key_value
      end
    end

    context 'destroy' do
      it 'should destroy an existing redis record' do
        access_id = Factory(:access_id)
        access_id.save
        access_id.exists?.should be_true
        access_id.destroy
        access_id.exists?.should be_false
      end
    end

    context 'find' do
      it 'should return nil if there is no record' do
        AccessId.find(Random.alphanumeric(24), random_tenant_name).should == nil
      end

      it 'should return a valid access_id object' do
        access_id = Factory :access_id
        access_id.save
        AccessId.find(access_id.value, access_id.tenant_name).should == access_id
      end
    end

    context 'fetch_for' do
      it 'should return the right access_id collection' do
        my_tenant = mock 'Tenant'
        my_tenant.stub!(:name).and_return(random_tenant_name)
        my_user = mock 'User'
        my_user.stub!(:tenant).and_return(my_tenant)

        other_tenant = mock 'Tenant'
        other_tenant.stub!(:name).and_return(random_tenant_name)
        other_user = mock 'User'
        other_user.stub!(:tenant).and_return(other_tenant)

        my_access_id_1    = Factory(:access_id, :tenant_name => my_tenant.name)
        my_access_id_2    = Factory(:access_id, :tenant_name => my_tenant.name)
        my_access_id_1.save; my_access_id_2.save

        other_access_id_1 = Factory(:access_id)
        other_access_id_2 = Factory(:access_id)
        other_access_id_1.save; other_access_id_2.save

        AccessId.fetch_for(my_user).map{|ai| ai.redis_key}.sort.should == [my_access_id_1.redis_key, my_access_id_2.redis_key].sort
      end
    end

    context 'values' do
      it 'should return a collection of values' do
        redis_keys  = ["#{AccessId::REDIS_KEY_INFIX}_#{'x'*24}"]
        AccessId.send(:values, redis_keys).should == ['x'*24]
      end
    end
  end
end
