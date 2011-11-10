require 'spec_helper'

module PowerLeveling
  describe 'ApiKey' do
    context 'validation' do
      it 'should be ok on correct parameters' do
        Factory(:api_key).should be_valid
      end

      it 'should fail without a value' do
        Factory(:api_key, :value => nil).should_not be_valid
      end

      it 'should fail without a tenant name' do
        Factory(:api_key, :tenant_name => nil).should_not be_valid
      end

      it 'should fail on invalid value formats' do
        api_key = Factory(:api_key, :value => '_invalid_underscores_')
        api_key.should_not be_valid
        api_key.errors.first.should == [:value, Messages::ERRORS[:api_key_invalid]]
      end
    end

    context 'fetch_for' do
      before(:each) do
        @tenant = mock 'Tenant'
        @tenant.stub!(:name).and_return(random_tenant_name)
        @user = mock 'User'
        @user.stub!(:tenant).and_return(@tenant)
      end

      it 'should return an api_key collection' do
        key1, key2 = [Random.alphanumeric(24), Random.alphanumeric(24)].sort
        [key1, key2].each do |key|
          api_key = Factory(:api_key, :tenant_name => @tenant.name, :value => key)
          api_key.save
        end
        ApiKey.fetch_for(@user).sort.should == [key1, key2]
      end
    end

    context 'exists?' do
      it 'should return false if record has not been persisted' do
        api_key = Factory :api_key
        api_key.exists?.should be_false
      end

      it 'should return true if record has been persisted' do
        api_key = Factory :api_key
        api_key.save
        api_key.exists?.should be_true
      end
    end

    context 'save' do
      it 'should persist a record' do
        api_key = Factory :api_key
        api_key.save
        api_key.exists?.should be_true
      end
    end

    describe 'destroy' do
      it 'should destroy a record' do
        api_key = Factory :api_key
        api_key.save
        api_key.exists?.should be_true
        api_key.destroy
        api_key.exists?.should be_false
      end
    end

    context 'find' do
      it 'should return nil if there is no record' do
        ApiKey.find(Random.alphanumeric(24), random_tenant_name).should == nil
      end

      it 'should return a valid api_key object' do
        api_key = Factory :api_key
        api_key.save
        ApiKey.find(api_key.value, api_key.tenant_name).should == api_key
      end
    end

    context 'values' do
      it 'should return a collection of values' do
        redis_keys  = ["#{ApiKey::REDIS_KEY_INFIX}_#{'x'*24}"]
        ApiKey.values(redis_keys).should == ['x'*24]
      end
    end
  end
end
