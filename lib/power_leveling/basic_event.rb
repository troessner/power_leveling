module PowerLeveling
  class BasicEvent
    TENANT_NAME_FORMAT = '[a-zA-Z]{4,10}'
    EVENT_ID_FORMAT    = '[a-zA-Z0-9]{1,24}'
    APP_ID_FORMAT      = '[a-zA-Z0-9]+'

    include ActiveModel::Validations

    validates_presence_of :tenant_name, :event_id, :app_id
    validates_format_of   :tenant_name, :with => /\A#{TENANT_NAME_FORMAT}\z/, :message => Messages::ERRORS[:tenant_name_invalid]
    validates_format_of   :event_id,    :with => /\A#{EVENT_ID_FORMAT}\z/,    :message => Messages::ERRORS[:event_id_invalid]
    validates_format_of   :app_id,      :with => /\A#{APP_ID_FORMAT}\z/,      :message => Messages::ERRORS[:app_id_invalid]

    attr_accessor :tenant_name, :event_id, :app_id

    def initialize(attr = {})
      @tenant_name   = attr[:tenant_name]
      @event_id      = attr[:event_id]
      @app_id        = attr[:app_id]
    end
  end
end
