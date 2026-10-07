-- Initial Local/Pilot schema for Personal Safety App.
-- Existing migrations must remain immutable after they have run in Pilot.

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE user_account (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name text NOT NULL,
    account_status text NOT NULL DEFAULT 'ACTIVE'
        CHECK (account_status IN ('ACTIVE', 'SUSPENDED', 'DELETION_PENDING', 'DELETED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz,
    CHECK ((account_status = 'DELETED') = (deleted_at IS NOT NULL))
);

CREATE TABLE user_identifier (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    identifier_type text NOT NULL CHECK (identifier_type IN ('PHONE', 'EMAIL')),
    normalized_value text NOT NULL,
    verified_at timestamptz,
    is_primary boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX uq_user_identifier_verified
    ON user_identifier(identifier_type, normalized_value) WHERE verified_at IS NOT NULL;
CREATE UNIQUE INDEX uq_user_identifier_primary
    ON user_identifier(user_id, identifier_type) WHERE is_primary;
CREATE INDEX ix_user_identifier_user ON user_identifier(user_id);

CREATE TABLE device_session (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    token_hash text NOT NULL UNIQUE,
    issued_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL,
    revoked_at timestamptz,
    CHECK (expires_at > issued_at)
);
CREATE INDEX ix_device_session_user_active ON device_session(user_id, expires_at) WHERE revoked_at IS NULL;

CREATE TABLE registered_device (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    platform text NOT NULL CHECK (platform IN ('ANDROID', 'IOS')),
    device_label text,
    push_token_ciphertext text,
    last_seen_at timestamptz,
    revoked_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_registered_device_user ON registered_device(user_id) WHERE revoked_at IS NULL;

CREATE TABLE consent_record (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    consent_type text NOT NULL,
    policy_version text NOT NULL,
    decision text NOT NULL CHECK (decision IN ('GRANTED', 'REVOKED', 'DECLINED')),
    recorded_at timestamptz NOT NULL DEFAULT now(),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX ix_consent_record_user_time ON consent_record(user_id, recorded_at DESC);

CREATE TABLE user_safety_settings (
    user_id uuid PRIMARY KEY REFERENCES user_account(id) ON DELETE RESTRICT,
    continuous_monitoring_enabled boolean NOT NULL DEFAULT false,
    location_mode text NOT NULL DEFAULT 'SOS_ONLY'
        CHECK (location_mode IN ('SOS_ONLY', 'PERIODIC', 'ALWAYS')),
    requested_interval_seconds integer CHECK (requested_interval_seconds IS NULL OR requested_interval_seconds > 0),
    sos_audio_enabled boolean NOT NULL DEFAULT false,
    low_battery_prompt_dismissed_at timestamptz,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE location_sharing_policy (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    policy_version integer NOT NULL CHECK (policy_version > 0),
    location_mode text NOT NULL CHECK (location_mode IN ('SOS_ONLY', 'PERIODIC', 'ALWAYS')),
    requested_interval_seconds integer CHECK (requested_interval_seconds IS NULL OR requested_interval_seconds > 0),
    effective_from timestamptz NOT NULL,
    effective_until timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, policy_version),
    CHECK (effective_until IS NULL OR effective_until > effective_from)
);
CREATE UNIQUE INDEX uq_location_policy_current ON location_sharing_policy(user_id) WHERE effective_until IS NULL;

CREATE TABLE sharing_recipient (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    recipient_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    sharing_purpose text NOT NULL CHECK (sharing_purpose IN ('PERIODIC_LOCATION', 'ON_DEMAND_LOCATION')),
    granted_at timestamptz NOT NULL DEFAULT now(),
    revoked_at timestamptz,
    CHECK (owner_user_id <> recipient_user_id),
    CHECK (revoked_at IS NULL OR revoked_at >= granted_at)
);
CREATE UNIQUE INDEX uq_sharing_recipient_active
    ON sharing_recipient(owner_user_id, recipient_user_id, sharing_purpose) WHERE revoked_at IS NULL;

CREATE TABLE trusted_circle (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id uuid NOT NULL UNIQUE REFERENCES user_account(id) ON DELETE RESTRICT,
    display_name text NOT NULL DEFAULT 'Trusted circle',
    created_at timestamptz NOT NULL DEFAULT now(),
    deactivated_at timestamptz
);

CREATE TABLE trusted_circle_member (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    trusted_circle_id uuid NOT NULL REFERENCES trusted_circle(id) ON DELETE RESTRICT,
    linked_user_id uuid REFERENCES user_account(id) ON DELETE RESTRICT,
    display_name text NOT NULL,
    phone_e164 text,
    email_normalized text,
    sos_alert_enabled boolean NOT NULL DEFAULT true,
    member_status text NOT NULL DEFAULT 'ACTIVE' CHECK (member_status IN ('ACTIVE', 'REVOKED')),
    added_at timestamptz NOT NULL DEFAULT now(),
    revoked_at timestamptz,
    CHECK (linked_user_id IS NOT NULL OR phone_e164 IS NOT NULL),
    CHECK ((member_status = 'REVOKED') = (revoked_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_trusted_circle_member_user
    ON trusted_circle_member(trusted_circle_id, linked_user_id)
    WHERE linked_user_id IS NOT NULL AND revoked_at IS NULL;
CREATE UNIQUE INDEX uq_trusted_circle_member_phone
    ON trusted_circle_member(trusted_circle_id, phone_e164)
    WHERE phone_e164 IS NOT NULL AND revoked_at IS NULL;

CREATE TABLE contact_join_link (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    trusted_circle_member_id uuid NOT NULL REFERENCES trusted_circle_member(id) ON DELETE RESTRICT,
    token_hash text NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    revoked_at timestamptz,
    linked_user_id uuid REFERENCES user_account(id) ON DELETE RESTRICT,
    consumed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (consumed_at IS NULL OR consumed_at <= expires_at)
);

CREATE TABLE contact_notification_delivery (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    trusted_circle_member_id uuid NOT NULL REFERENCES trusted_circle_member(id) ON DELETE RESTRICT,
    channel text NOT NULL CHECK (channel IN ('SMS', 'EMAIL')),
    purpose text NOT NULL CHECK (purpose IN ('ADDED_NOTICE')),
    destination_snapshot text NOT NULL,
    delivery_status text NOT NULL DEFAULT 'PENDING'
        CHECK (delivery_status IN ('PENDING', 'PROVIDER_ACCEPTED', 'DELIVERED', 'FAILED', 'UNKNOWN')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE family (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    head_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    family_name text NOT NULL,
    family_status text NOT NULL DEFAULT 'ACTIVE' CHECK (family_status IN ('ACTIVE', 'DISSOLVED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    dissolved_at timestamptz,
    CHECK ((family_status = 'DISSOLVED') = (dissolved_at IS NOT NULL))
);
CREATE INDEX ix_family_head ON family(head_user_id, family_status);

CREATE TABLE family_membership (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id uuid NOT NULL REFERENCES family(id) ON DELETE RESTRICT,
    user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    membership_role text NOT NULL DEFAULT 'MEMBER' CHECK (membership_role IN ('HEAD', 'MEMBER')),
    membership_status text NOT NULL CHECK (membership_status IN ('INVITED', 'ACTIVE', 'DECLINED', 'LEFT', 'REMOVED')),
    joined_at timestamptz,
    ended_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK ((membership_status = 'ACTIVE' AND ended_at IS NULL) OR membership_status <> 'ACTIVE')
);
CREATE UNIQUE INDEX uq_family_membership_active ON family_membership(family_id, user_id) WHERE ended_at IS NULL;
CREATE INDEX ix_family_membership_user ON family_membership(user_id, membership_status);

CREATE TABLE family_invitation (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id uuid NOT NULL REFERENCES family(id) ON DELETE RESTRICT,
    invited_by_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    target_phone_e164 text,
    target_email_normalized text,
    token_hash text NOT NULL UNIQUE,
    invitation_status text NOT NULL DEFAULT 'PENDING'
        CHECK (invitation_status IN ('PENDING', 'ACCEPTED', 'DECLINED', 'EXPIRED', 'REVOKED')),
    expires_at timestamptz NOT NULL,
    responded_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (target_phone_e164 IS NOT NULL OR target_email_normalized IS NOT NULL)
);
CREATE INDEX ix_family_invitation_pending ON family_invitation(family_id, expires_at) WHERE invitation_status = 'PENDING';

CREATE TABLE family_location_permission (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    family_membership_id uuid NOT NULL REFERENCES family_membership(id) ON DELETE RESTRICT,
    consent_record_id uuid NOT NULL REFERENCES consent_record(id) ON DELETE RESTRICT,
    granted_at timestamptz NOT NULL,
    revoked_at timestamptz,
    permission_version integer NOT NULL CHECK (permission_version > 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (revoked_at IS NULL OR revoked_at >= granted_at)
);
CREATE UNIQUE INDEX uq_family_permission_active ON family_location_permission(family_membership_id) WHERE revoked_at IS NULL;

CREATE TABLE family_member_tracking (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    family_membership_id uuid NOT NULL REFERENCES family_membership(id) ON DELETE RESTRICT,
    selected_by_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    started_at timestamptz NOT NULL DEFAULT now(),
    stopped_at timestamptz,
    stop_reason text,
    CHECK (stopped_at IS NULL OR stopped_at >= started_at)
);
CREATE UNIQUE INDEX uq_family_tracking_active ON family_member_tracking(family_membership_id) WHERE stopped_at IS NULL;

CREATE TABLE family_location_access_event (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    family_membership_id uuid NOT NULL REFERENCES family_membership(id) ON DELETE RESTRICT,
    requested_by_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    access_type text NOT NULL CHECK (access_type IN ('VIEW', 'REFRESH', 'START_TRACKING', 'STOP_TRACKING')),
    result_status text NOT NULL CHECK (result_status IN ('RETURNED', 'UNAVAILABLE', 'DENIED', 'FAILED')),
    location_sample_id uuid,
    occurred_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_family_access_membership_time ON family_location_access_event(family_membership_id, occurred_at DESC);

CREATE TABLE trip (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    trip_status text NOT NULL DEFAULT 'ACTIVE' CHECK (trip_status IN ('ACTIVE', 'COMPLETED', 'CANCELLED', 'SOS')),
    destination text,
    expected_arrival_at timestamptz,
    timezone_name text NOT NULL,
    started_at timestamptz NOT NULL DEFAULT now(),
    ended_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (ended_at IS NULL OR ended_at >= started_at)
);
CREATE INDEX ix_trip_user_active ON trip(user_id, started_at DESC) WHERE ended_at IS NULL;

CREATE TABLE checkin_policy_snapshot (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_version text NOT NULL,
    reminder_minutes integer NOT NULL CHECK (reminder_minutes >= 0),
    grace_minutes integer NOT NULL CHECK (grace_minutes >= 0),
    captured_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE trip_checkin (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id uuid NOT NULL REFERENCES trip(id) ON DELETE RESTRICT,
    policy_snapshot_id uuid NOT NULL REFERENCES checkin_policy_snapshot(id) ON DELETE RESTRICT,
    sequence_number integer NOT NULL CHECK (sequence_number > 0),
    due_at_utc timestamptz NOT NULL,
    original_timezone text NOT NULL,
    original_local_time timestamp NOT NULL,
    grace_deadline_at timestamptz NOT NULL,
    checkin_status text NOT NULL DEFAULT 'SCHEDULED'
        CHECK (checkin_status IN ('SCHEDULED', 'CONFIRMED', 'EXTENDED', 'MISSED', 'CANCELLED', 'SOS_CREATED')),
    confirmed_at timestamptz,
    UNIQUE (trip_id, sequence_number),
    CHECK (grace_deadline_at >= due_at_utc)
);
CREATE INDEX ix_trip_checkin_due_pending ON trip_checkin(due_at_utc) WHERE checkin_status IN ('SCHEDULED', 'EXTENDED');

CREATE TABLE fake_call_schedule (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    scheduled_for timestamptz NOT NULL,
    timezone_name text NOT NULL,
    caller_name text NOT NULL,
    call_status text NOT NULL DEFAULT 'SCHEDULED'
        CHECK (call_status IN ('SCHEDULED', 'EXECUTED', 'CANCELLED', 'FAILED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    completed_at timestamptz
);
CREATE INDEX ix_fake_call_due ON fake_call_schedule(scheduled_for) WHERE call_status = 'SCHEDULED';

CREATE TABLE incident (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    trip_id uuid REFERENCES trip(id) ON DELETE RESTRICT,
    trigger_source text NOT NULL CHECK (trigger_source IN ('MANUAL', 'MISSED_CHECKIN', 'PARTNER', 'USSD', 'OTHER')),
    incident_mode text NOT NULL CHECK (incident_mode IN ('PRACTICE', 'LIVE')),
    severity text NOT NULL DEFAULT 'UNCLASSIFIED' CHECK (severity IN ('UNCLASSIFIED', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    incident_status text NOT NULL DEFAULT 'ACTIVE'
        CHECK (incident_status IN ('ACTIVE', 'ACKNOWLEDGED', 'ESCALATED', 'RESOLVED', 'CANCELLED', 'CLOSED')),
    state_version bigint NOT NULL DEFAULT 1 CHECK (state_version > 0),
    triggered_at timestamptz NOT NULL,
    resolved_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_incident_queue ON incident(incident_mode, incident_status, severity, created_at DESC);
CREATE INDEX ix_incident_user_time ON incident(user_id, triggered_at DESC);

CREATE TABLE incident_event (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id uuid NOT NULL REFERENCES incident(id) ON DELETE RESTRICT,
    event_type text NOT NULL,
    actor_user_id uuid REFERENCES user_account(id) ON DELETE RESTRICT,
    previous_status text,
    new_status text,
    event_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    occurred_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_incident_event_time ON incident_event(incident_id, occurred_at);

CREATE TABLE incident_assignment (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id uuid NOT NULL REFERENCES incident(id) ON DELETE RESTRICT,
    operator_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    assigned_by_user_id uuid REFERENCES user_account(id) ON DELETE RESTRICT,
    assigned_at timestamptz NOT NULL DEFAULT now(),
    unassigned_at timestamptz
);
CREATE UNIQUE INDEX uq_incident_assignment_current ON incident_assignment(incident_id) WHERE unassigned_at IS NULL;

CREATE TABLE incident_note (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id uuid NOT NULL REFERENCES incident(id) ON DELETE RESTRICT,
    author_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    note_text text NOT NULL CHECK (length(trim(note_text)) > 0),
    corrects_note_id uuid REFERENCES incident_note(id) ON DELETE RESTRICT,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_incident_note_time ON incident_note(incident_id, created_at);

CREATE TABLE incident_contact_attempt (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id uuid NOT NULL REFERENCES incident(id) ON DELETE RESTRICT,
    operator_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    contact_method text NOT NULL CHECK (contact_method IN ('SMS', 'PHONE_CALL', 'EMAIL', 'OTHER')),
    outcome text NOT NULL,
    notes text,
    attempted_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE location_sample (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    incident_id uuid REFERENCES incident(id) ON DELETE RESTRICT,
    trip_id uuid REFERENCES trip(id) ON DELETE RESTRICT,
    position geography(Point, 4326) NOT NULL,
    source text NOT NULL CHECK (source IN ('GNSS', 'NETWORK', 'FUSED', 'CACHED', 'ESTIMATED', 'OTHER')),
    captured_at timestamptz NOT NULL,
    received_at timestamptz NOT NULL DEFAULT now(),
    accuracy_meters double precision CHECK (accuracy_meters IS NULL OR accuracy_meters >= 0),
    device_time_trusted boolean NOT NULL DEFAULT false,
    retain_until timestamptz
);
CREATE INDEX ix_location_user_captured ON location_sample(user_id, captured_at DESC);
CREATE INDEX ix_location_position_gist ON location_sample USING gist(position);
CREATE INDEX ix_location_retention ON location_sample(retain_until) WHERE retain_until IS NOT NULL;

ALTER TABLE family_location_access_event
    ADD CONSTRAINT fk_family_access_location_sample
    FOREIGN KEY (location_sample_id) REFERENCES location_sample(id) ON DELETE RESTRICT;

CREATE TABLE user_location_current (
    user_id uuid PRIMARY KEY REFERENCES user_account(id) ON DELETE RESTRICT,
    location_sample_id uuid NOT NULL REFERENCES location_sample(id) ON DELETE RESTRICT,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE incident_recipient (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id uuid NOT NULL REFERENCES incident(id) ON DELETE RESTRICT,
    recipient_key text NOT NULL,
    recipient_user_id uuid REFERENCES user_account(id) ON DELETE RESTRICT,
    phone_e164_snapshot text,
    display_name_snapshot text NOT NULL,
    signup_link_included boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (incident_id, recipient_key),
    CHECK (recipient_user_id IS NOT NULL OR phone_e164_snapshot IS NOT NULL)
);

CREATE TABLE incident_recipient_reason (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_recipient_id uuid NOT NULL REFERENCES incident_recipient(id) ON DELETE RESTRICT,
    relationship_type text NOT NULL CHECK (relationship_type IN ('FAMILY', 'TRUSTED_CIRCLE')),
    family_id uuid REFERENCES family(id) ON DELETE RESTRICT,
    trusted_circle_member_id uuid REFERENCES trusted_circle_member(id) ON DELETE RESTRICT,
    CHECK ((relationship_type = 'FAMILY' AND family_id IS NOT NULL AND trusted_circle_member_id IS NULL)
        OR (relationship_type = 'TRUSTED_CIRCLE' AND trusted_circle_member_id IS NOT NULL AND family_id IS NULL))
);
CREATE UNIQUE INDEX uq_incident_recipient_reason
    ON incident_recipient_reason(incident_recipient_id, relationship_type, COALESCE(family_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(trusted_circle_member_id, '00000000-0000-0000-0000-000000000000'::uuid));

CREATE TABLE notification_delivery (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_recipient_id uuid NOT NULL REFERENCES incident_recipient(id) ON DELETE RESTRICT,
    channel text NOT NULL CHECK (channel IN ('SMS', 'PUSH', 'EMAIL')),
    purpose text NOT NULL CHECK (purpose IN ('SOS_ALERT', 'INCIDENT_UPDATE')),
    delivery_status text NOT NULL DEFAULT 'PENDING'
        CHECK (delivery_status IN ('PENDING', 'PROVIDER_ACCEPTED', 'DELIVERED', 'ACKNOWLEDGED', 'FAILED', 'UNKNOWN')),
    provider_message_id text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (incident_recipient_id, channel, purpose)
);
CREATE INDEX ix_notification_delivery_status ON notification_delivery(delivery_status, created_at);

CREATE TABLE notification_attempt (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_delivery_id uuid NOT NULL REFERENCES notification_delivery(id) ON DELETE RESTRICT,
    attempt_number integer NOT NULL CHECK (attempt_number > 0),
    provider_name text NOT NULL,
    outcome text NOT NULL CHECK (outcome IN ('ACCEPTED', 'DELIVERED', 'FAILED', 'TIMEOUT', 'UNKNOWN')),
    attempted_at timestamptz NOT NULL DEFAULT now(),
    provider_response_code text,
    UNIQUE (notification_delivery_id, attempt_number)
);

CREATE TABLE provider_callback (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_name text NOT NULL,
    provider_event_id text NOT NULL,
    callback_type text NOT NULL,
    signature_verified boolean NOT NULL DEFAULT false,
    received_at timestamptz NOT NULL DEFAULT now(),
    payload_redacted jsonb NOT NULL DEFAULT '{}'::jsonb,
    UNIQUE (provider_name, provider_event_id)
);

CREATE TABLE outbox_event (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type text NOT NULL,
    aggregate_id uuid NOT NULL,
    event_type text NOT NULL,
    payload jsonb NOT NULL,
    available_at timestamptz NOT NULL DEFAULT now(),
    lease_owner text,
    lease_expires_at timestamptz,
    attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    completed_at timestamptz,
    terminal_error_code text,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_outbox_available ON outbox_event(available_at) WHERE completed_at IS NULL AND terminal_error_code IS NULL;

CREATE TABLE idempotency_record (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    principal_key text NOT NULL,
    operation_name text NOT NULL,
    idempotency_key text NOT NULL,
    request_hash text NOT NULL,
    response_reference uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz,
    UNIQUE (principal_key, operation_name, idempotency_key)
);

CREATE TABLE incident_evidence (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id uuid NOT NULL REFERENCES incident(id) ON DELETE RESTRICT,
    evidence_type text NOT NULL CHECK (evidence_type IN ('AUDIO', 'IMAGE', 'DOCUMENT', 'OTHER')),
    object_key text NOT NULL UNIQUE,
    media_type text NOT NULL,
    byte_size bigint CHECK (byte_size IS NULL OR byte_size >= 0),
    content_hash text,
    evidence_status text NOT NULL CHECK (evidence_status IN ('CAPTURING', 'QUEUED', 'UPLOADED', 'FAILED', 'DELETED')),
    captured_at timestamptz,
    uploaded_at timestamptz,
    retain_until timestamptz,
    deleted_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_evidence_retention ON incident_evidence(retain_until) WHERE deleted_at IS NULL;

CREATE TABLE operator_profile (
    user_id uuid PRIMARY KEY REFERENCES user_account(id) ON DELETE RESTRICT,
    operator_status text NOT NULL CHECK (operator_status IN ('ACTIVE', 'SUSPENDED')),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE admin_profile (
    user_id uuid PRIMARY KEY REFERENCES user_account(id) ON DELETE RESTRICT,
    admin_role text NOT NULL CHECK (admin_role IN ('ADMIN', 'SUPERVISOR')),
    admin_status text NOT NULL CHECK (admin_status IN ('ACTIVE', 'SUSPENDED')),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE incident_audit_event (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id uuid NOT NULL REFERENCES incident(id) ON DELETE RESTRICT,
    actor_user_id uuid REFERENCES user_account(id) ON DELETE RESTRICT,
    action text NOT NULL,
    details_redacted jsonb NOT NULL DEFAULT '{}'::jsonb,
    occurred_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_incident_audit_time ON incident_audit_event(incident_id, occurred_at);

CREATE TABLE system_audit_event (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id uuid REFERENCES user_account(id) ON DELETE RESTRICT,
    action text NOT NULL,
    target_type text NOT NULL,
    target_id uuid,
    details_redacted jsonb NOT NULL DEFAULT '{}'::jsonb,
    occurred_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ix_system_audit_target_time ON system_audit_event(target_type, target_id, occurred_at DESC);

CREATE TABLE configuration_version (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    configuration_key text NOT NULL,
    version_number integer NOT NULL CHECK (version_number > 0),
    configuration_value jsonb NOT NULL,
    changed_by_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    effective_from timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (configuration_key, version_number)
);
CREATE INDEX ix_configuration_effective ON configuration_version(configuration_key, effective_from DESC);

CREATE TABLE retention_policy_version (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    record_class text NOT NULL,
    version_number integer NOT NULL CHECK (version_number > 0),
    retention_days integer NOT NULL CHECK (retention_days > 0),
    changed_by_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    legal_basis_reference text,
    effective_from timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (record_class, version_number)
);
CREATE INDEX ix_retention_policy_effective ON retention_policy_version(record_class, effective_from DESC);

CREATE TABLE account_deletion_event (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    requested_at timestamptz NOT NULL DEFAULT now(),
    completed_at timestamptz,
    deletion_status text NOT NULL CHECK (deletion_status IN ('REQUESTED', 'PROCESSING', 'COMPLETED', 'BLOCKED_BY_HOLD', 'FAILED')),
    dissolved_family_id uuid REFERENCES family(id) ON DELETE RESTRICT,
    retention_policy_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
    outcome_redacted jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE account_deletion_notification (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    deletion_event_id uuid NOT NULL REFERENCES account_deletion_event(id) ON DELETE RESTRICT,
    family_id uuid NOT NULL REFERENCES family(id) ON DELETE RESTRICT,
    recipient_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    channel text NOT NULL CHECK (channel IN ('SMS', 'EMAIL')),
    destination_snapshot text NOT NULL,
    delivery_status text NOT NULL DEFAULT 'PENDING'
        CHECK (delivery_status IN ('PENDING', 'PROVIDER_ACCEPTED', 'DELIVERED', 'FAILED', 'UNKNOWN')),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (deletion_event_id, recipient_user_id, channel)
);

CREATE TABLE legal_hold (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    record_type text NOT NULL,
    record_id uuid NOT NULL,
    hold_reason text NOT NULL,
    created_by_user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    created_at timestamptz NOT NULL DEFAULT now(),
    released_by_user_id uuid REFERENCES user_account(id) ON DELETE RESTRICT,
    released_at timestamptz,
    CHECK ((released_at IS NULL) = (released_by_user_id IS NULL))
);
CREATE INDEX ix_legal_hold_record ON legal_hold(record_type, record_id) WHERE released_at IS NULL;

CREATE TABLE subscription_package (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    package_key text NOT NULL UNIQUE,
    package_status text NOT NULL CHECK (package_status IN ('DRAFT', 'ACTIVE', 'RETIRED')),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE package_version (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_package_id uuid NOT NULL REFERENCES subscription_package(id) ON DELETE RESTRICT,
    version_number integer NOT NULL CHECK (version_number > 0),
    display_name text NOT NULL,
    price_minor_units bigint CHECK (price_minor_units IS NULL OR price_minor_units >= 0),
    currency_code char(3),
    billing_period text CHECK (billing_period IN ('NONE', 'MONTHLY', 'YEARLY', 'CUSTOM')),
    trial_days integer CHECK (trial_days IS NULL OR trial_days >= 0),
    effective_from timestamptz NOT NULL,
    effective_until timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (subscription_package_id, version_number),
    CHECK (effective_until IS NULL OR effective_until > effective_from)
);

CREATE TABLE package_entitlement (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    package_version_id uuid NOT NULL REFERENCES package_version(id) ON DELETE RESTRICT,
    feature_key text NOT NULL,
    enabled boolean NOT NULL,
    usage_limit integer CHECK (usage_limit IS NULL OR usage_limit >= 0),
    family_limit integer CHECK (family_limit IS NULL OR family_limit >= 0),
    UNIQUE (package_version_id, feature_key)
);

CREATE TABLE user_subscription (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES user_account(id) ON DELETE RESTRICT,
    package_version_id uuid NOT NULL REFERENCES package_version(id) ON DELETE RESTRICT,
    subscription_status text NOT NULL CHECK (subscription_status IN ('TRIAL', 'ACTIVE', 'PAST_DUE', 'CANCELLED', 'EXPIRED')),
    started_at timestamptz NOT NULL,
    ends_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    CHECK (ends_at IS NULL OR ends_at >= started_at)
);
CREATE INDEX ix_user_subscription_current ON user_subscription(user_id, subscription_status);
