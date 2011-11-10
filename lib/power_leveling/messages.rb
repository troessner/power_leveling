module PowerLeveling
  module Messages
    ERRORS = {
      :bad_format                 => 'Bad Format.',
      :authentication_failed      => 'Authentication failed.',
      :bad_action                 => 'Bad Action.',
      :invalid_override           => 'Invalid Override.',
      :invalid_constraints        => 'Invalid Constraints.',
      :not_a_hash                 => 'Bad attribute format (not a hash).',
      :event_type_does_not_exist  => 'Event type does not exist.',
      :no_app_id_given            => 'No App ID given',
      :tenant_name_invalid        => 'Only 4 - 10 letters allowed.',
      :event_id_invalid           => 'Min. 1, max. 24 letters and / or digits.',
      :app_id_invalid             => 'Only letters and digits allowed.',
      :access_id_invalid          => 'Min. 1, max. 24 letters and / or digits. No underscores or special chars are allowed.',
      :access_id_unauthorized     => "Can't find a tenant / api key mapping for this access id.",
      :api_key_invalid            => 'Min. 1, max. 24 letters and / or digits. No underscores or special chars are allowed.',
      :access_id_unknown          => 'Access ID unknown.'
      }

    INFO = {
      :record_created => 'Record created.',
      :event_type_exists => 'EventType exists.',
      :event_type_does_not_exist => 'EventType does not exist.'
    }
  end
end
