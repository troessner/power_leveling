require 'spec_helper'

module PowerLeveling
  describe 'BasicEvent' do
    context 'should not validate' do
      it 'without a tenant_name' do
        Factory(:basic_event, :tenant_name => nil).should_not be_valid
      end

      it 'without an event id' do
        Factory(:basic_event, :event_id => nil).should_not be_valid
      end

      it 'without an app id' do
        Factory(:basic_event, :app_id => nil).should_not be_valid
      end

      it 'with an invalid tenant_name (< 4 chars)' do
        Factory(:basic_event, :tenant_name => 'xxx').should_not be_valid
      end

      it 'with an invalid tenant_name (> 10 chars)' do
        Factory(:basic_event, :tenant_name => 'x' * 11).should_not be_valid
      end

      it 'with an invalid tenant_name (alphanumeric chars)' do
        Factory(:basic_event, :tenant_name => 'xxx123xxx').should_not be_valid
      end

      it 'with an invalid event id (> 24 chars)' do
        Factory(:basic_event, :event_id => 'x' * 25).should_not be_valid
      end

      it 'with an invalid event id (special chars)' do
        Factory(:basic_event, :event_id => '%' * 24).should_not be_valid
      end

      it 'with an invalid app id (special chars)' do
        Factory(:basic_event, :app_id => '_' * 25).should_not be_valid
      end
    end
  end
end
