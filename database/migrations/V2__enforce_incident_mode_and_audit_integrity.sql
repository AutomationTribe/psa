-- Enforces Stage 8 safety-critical constraints 4, 12 and 13 in the database:
--   * incident.incident_mode is immutable after creation (practice/live isolation).
--   * incident_audit_event and system_audit_event are append-only for every ordinary role:
--     UPDATE and TRUNCATE are always rejected.
--   * The only DELETE path is the controlled retention role psa_audit_retention, and only for rows
--     whose server-computed retain_until has passed and that are not under an active legal hold.
--     The trigger re-checks this for every deleted row, so the role cannot delete unexpired or held
--     rows or edit any row, even with direct table access.
--
-- Triggers are defense in depth. A table owner or superuser can still disable them, so API/worker
-- roles must not own these tables or hold DDL/TRIGGER privileges (runtime roles are a later migration).
--
-- Conventions that the admin dashboard/backend must follow:
--   * Retention policy record_class values: 'INCIDENT_AUDIT_EVENT' and 'SYSTEM_AUDIT_EVENT'.
--     Without an effective policy, retain_until stays NULL and the row is kept indefinitely (fail safe).
--   * Legal holds on audit data use legal_hold.record_type 'INCIDENT_AUDIT_EVENT' / 'SYSTEM_AUDIT_EVENT'
--     with the event id, or record_type 'INCIDENT' with the incident id to hold all of its audit events.
--     A hold is active while released_at IS NULL.
--
-- Concurrency between legal holds and purging: every purge/delete calls lock_legal_holds_for_purge()
-- (LOCK TABLE legal_hold IN SHARE MODE) before it evaluates eligibility. SHARE conflicts with the
-- ROW EXCLUSIVE lock that any INSERT, UPDATE or DELETE on legal_hold holds until its transaction ends. Therefore (1) a hold being written
-- but not yet committed makes the purge wait, and the purge then sees the committed hold; and
-- (2) while a purge transaction is open, hold writes wait until it commits or rolls back. A row is
-- thus never deleted by a purge that committed after a covering hold committed. If the purge commits
-- first, the later hold simply finds the event already removed. The SHARE lock does not make purges wait
-- for each other (purges that select the same rows still wait on each other's row locks).
-- The deletion guard re-reads legal_hold after taking the lock, so it uses a fresh snapshot even for
-- a direct DELETE whose statement snapshot predates the hold's commit.
--
-- Isolation level: this protocol is only safe under READ COMMITTED, where every statement inside the
-- purge function and the trigger gets a fresh snapshot after the lock wait. Under REPEATABLE READ or
-- SERIALIZABLE the transaction snapshot is taken before the wait, so a hold that committed during the
-- wait would be invisible and a covered row could be deleted. The retention path therefore REFUSES to
-- run outside READ COMMITTED (see lock_legal_holds_for_purge), and the retention job must use the
-- default level. Hold writers touching audit events are held to the same rule (see below).
--
-- Orphan holds: a hold on an audit event that was already purged is rejected. Hold writes wait for an
-- open purge (lock above), then re-check that the target still exists with a fresh READ COMMITTED
-- snapshot, so a hold cannot commit against an event deleted by a purge that committed first.

-- ---------------------------------------------------------------- incident mode

CREATE FUNCTION reject_incident_mode_change() RETURNS trigger
    LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'incident.incident_mode is immutable after creation (incident %)', OLD.id
        USING ERRCODE = 'integrity_constraint_violation';
END;
$$;

CREATE TRIGGER trg_incident_mode_immutable
    BEFORE UPDATE OF incident_mode ON incident
    FOR EACH ROW
    WHEN (OLD.incident_mode IS DISTINCT FROM NEW.incident_mode)
    EXECUTE FUNCTION reject_incident_mode_change();

-- ---------------------------------------------------------------- retention role

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'psa_audit_retention') THEN
        CREATE ROLE psa_audit_retention NOLOGIN NOINHERIT;
    END IF;
END;
$$;

-- ---------------------------------------------------------------- retention columns

ALTER TABLE incident_audit_event
    ADD COLUMN retain_until timestamptz,
    ADD COLUMN retention_policy_version_id uuid REFERENCES retention_policy_version(id) ON DELETE RESTRICT;
ALTER TABLE system_audit_event
    ADD COLUMN retain_until timestamptz,
    ADD COLUMN retention_policy_version_id uuid REFERENCES retention_policy_version(id) ON DELETE RESTRICT;

CREATE INDEX ix_incident_audit_retention ON incident_audit_event(retain_until) WHERE retain_until IS NOT NULL;
CREATE INDEX ix_system_audit_retention ON system_audit_event(retain_until) WHERE retain_until IS NOT NULL;

-- Server-computed at insert from the policy effective now; any caller-supplied value is discarded.
-- Runs as its owner so inserting roles need no access to retention_policy_version.
CREATE FUNCTION set_audit_retention() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE
    policy retention_policy_version%ROWTYPE;
BEGIN
    SELECT * INTO policy
    FROM retention_policy_version
    WHERE record_class = upper(TG_ARGV[0]) AND effective_from <= now()
    ORDER BY effective_from DESC, version_number DESC
    LIMIT 1;

    IF FOUND THEN
        NEW.retain_until := now() + make_interval(days => policy.retention_days);
        NEW.retention_policy_version_id := policy.id;
    ELSE
        NEW.retain_until := NULL;
        NEW.retention_policy_version_id := NULL;
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION set_audit_retention() FROM PUBLIC;

CREATE TRIGGER trg_incident_audit_event_retention
    BEFORE INSERT ON incident_audit_event
    FOR EACH ROW EXECUTE FUNCTION set_audit_retention('INCIDENT_AUDIT_EVENT');
CREATE TRIGGER trg_system_audit_event_retention
    BEFORE INSERT ON system_audit_event
    FOR EACH ROW EXECUTE FUNCTION set_audit_retention('SYSTEM_AUDIT_EVENT');

-- ---------------------------------------------------------------- eligibility

-- True only when the deadline has passed and no active legal hold covers the record.
-- Runs as the caller; only the retention role is granted access to legal_hold.
CREATE FUNCTION audit_event_is_purgeable(
    p_record_type text, p_event_id uuid, p_incident_id uuid, p_retain_until timestamptz
) RETURNS boolean
    LANGUAGE sql STABLE SET search_path = pg_catalog, public AS $$
    SELECT p_retain_until IS NOT NULL
       AND p_retain_until <= now()
       AND NOT EXISTS (
           SELECT 1 FROM legal_hold h
           WHERE h.released_at IS NULL
             AND ((h.record_type = p_record_type AND h.record_id = p_event_id)
               OR (p_incident_id IS NOT NULL AND h.record_type = 'INCIDENT' AND h.record_id = p_incident_id)));
$$;
REVOKE ALL ON FUNCTION audit_event_is_purgeable(text, uuid, uuid, timestamptz) FROM PUBLIC;

-- ---------------------------------------------------------------- legal-hold coordination

-- LOCK ... IN SHARE MODE needs UPDATE/DELETE/TRUNCATE on the table, which the retention role must not
-- have (it could otherwise release holds). This helper runs as its owner (the migration user), takes the
-- lock on behalf of the calling transaction, and is executable only by the retention role.
CREATE FUNCTION lock_legal_holds_for_purge() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
BEGIN
    -- isolation-check-begin
    IF current_setting('transaction_isolation') <> 'read committed' THEN
        RAISE EXCEPTION 'audit purge requires READ COMMITTED (current: %): a stricter snapshot could miss a legal hold committed during the lock wait',
            current_setting('transaction_isolation')
            USING ERRCODE = 'invalid_transaction_state';
    END IF;
    -- isolation-check-end
    LOCK TABLE legal_hold IN SHARE MODE;
END;
$$;
REVOKE ALL ON FUNCTION lock_legal_holds_for_purge() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION lock_legal_holds_for_purge() TO psa_audit_retention;

-- Rejects an active hold whose audit target no longer exists (a purge that committed first removed it).
-- Runs as its owner so hold writers need no SELECT on the audit tables. Event-level holds also require
-- READ COMMITTED so the existence check below sees a purge that committed while this write was waiting
-- on the lock held by that purge.
CREATE FUNCTION guard_legal_hold_target() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE
    v_exists boolean;
BEGIN
    IF NEW.released_at IS NOT NULL
       OR NEW.record_type NOT IN ('INCIDENT_AUDIT_EVENT', 'SYSTEM_AUDIT_EVENT', 'INCIDENT') THEN
        RETURN NEW;
    END IF;

    IF NEW.record_type <> 'INCIDENT' AND current_setting('transaction_isolation') <> 'read committed' THEN
        RAISE EXCEPTION 'legal holds on audit events require READ COMMITTED (current: %)',
            current_setting('transaction_isolation')
            USING ERRCODE = 'invalid_transaction_state';
    END IF;

    IF NEW.record_type = 'INCIDENT_AUDIT_EVENT' THEN
        SELECT EXISTS (SELECT 1 FROM incident_audit_event WHERE id = NEW.record_id) INTO v_exists;
    ELSIF NEW.record_type = 'SYSTEM_AUDIT_EVENT' THEN
        SELECT EXISTS (SELECT 1 FROM system_audit_event WHERE id = NEW.record_id) INTO v_exists;
    ELSE
        SELECT EXISTS (SELECT 1 FROM incident WHERE id = NEW.record_id) INTO v_exists;
    END IF;

    IF NOT v_exists THEN
        RAISE EXCEPTION 'legal hold rejected: % % does not exist (already purged or never created)',
            NEW.record_type, NEW.record_id
            USING ERRCODE = 'foreign_key_violation';
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION guard_legal_hold_target() FROM PUBLIC;

CREATE TRIGGER trg_legal_hold_target
    BEFORE INSERT OR UPDATE ON legal_hold
    FOR EACH ROW EXECUTE FUNCTION guard_legal_hold_target();

-- ---------------------------------------------------------------- append-only guards

CREATE FUNCTION reject_audit_modification() RETURNS trigger
    LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION '% on % is not allowed: audit events are append-only', TG_OP, TG_TABLE_NAME
        USING ERRCODE = 'integrity_constraint_violation';
END;
$$;

-- DELETE is allowed only for the retention role and only for expired, unheld rows.
CREATE FUNCTION guard_audit_delete() RETURNS trigger
    LANGUAGE plpgsql AS $$
DECLARE
    v_record_type text := upper(TG_ARGV[0]);
    v_incident_id uuid;
BEGIN
    IF current_user <> 'psa_audit_retention' THEN
        RAISE EXCEPTION 'DELETE on % is not allowed: audit events are append-only; use the retention path', TG_TABLE_NAME
            USING ERRCODE = 'integrity_constraint_violation';
    END IF;

    -- Wait for in-flight legal_hold writers, then block new ones until this transaction ends.
    PERFORM lock_legal_holds_for_purge();

    IF v_record_type = 'INCIDENT_AUDIT_EVENT' THEN
        v_incident_id := OLD.incident_id;
    END IF;

    IF NOT audit_event_is_purgeable(v_record_type, OLD.id, v_incident_id, OLD.retain_until) THEN
        RAISE EXCEPTION 'DELETE on % rejected: event % is unexpired, has no retention deadline, or is under legal hold',
            TG_TABLE_NAME, OLD.id
            USING ERRCODE = 'integrity_constraint_violation';
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_incident_audit_event_no_update
    BEFORE UPDATE ON incident_audit_event
    FOR EACH ROW EXECUTE FUNCTION reject_audit_modification();
CREATE TRIGGER trg_incident_audit_event_delete_guard
    BEFORE DELETE ON incident_audit_event
    FOR EACH ROW EXECUTE FUNCTION guard_audit_delete('INCIDENT_AUDIT_EVENT');
CREATE TRIGGER trg_incident_audit_event_no_truncate
    BEFORE TRUNCATE ON incident_audit_event
    FOR EACH STATEMENT EXECUTE FUNCTION reject_audit_modification();

CREATE TRIGGER trg_system_audit_event_no_update
    BEFORE UPDATE ON system_audit_event
    FOR EACH ROW EXECUTE FUNCTION reject_audit_modification();
CREATE TRIGGER trg_system_audit_event_delete_guard
    BEFORE DELETE ON system_audit_event
    FOR EACH ROW EXECUTE FUNCTION guard_audit_delete('SYSTEM_AUDIT_EVENT');
CREATE TRIGGER trg_system_audit_event_no_truncate
    BEFORE TRUNCATE ON system_audit_event
    FOR EACH STATEMENT EXECUTE FUNCTION reject_audit_modification();

-- ---------------------------------------------------------------- controlled retention path

GRANT SELECT, DELETE ON incident_audit_event, system_audit_event TO psa_audit_retention;
GRANT SELECT ON legal_hold TO psa_audit_retention;

-- Bounded, resumable batch purge. It takes no SELECT ... FOR UPDATE row locks (that would need UPDATE
-- privilege). Owned by the retention role so DELETEs run as that role.
-- The delete triggers re-verify eligibility, so a bug here cannot remove unexpired or held rows.
CREATE FUNCTION purge_expired_audit_events(p_batch_limit integer DEFAULT 1000)
    RETURNS TABLE (incident_audit_deleted bigint, system_audit_deleted bigint)
    LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public AS $$
DECLARE
    v_incident bigint;
    v_system bigint;
BEGIN
    IF p_batch_limit IS NULL OR p_batch_limit < 1 OR p_batch_limit > 10000 THEN
        RAISE EXCEPTION 'p_batch_limit must be between 1 and 10000'
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Take the lock before the DELETE statements so their snapshots see every committed hold.
    PERFORM lock_legal_holds_for_purge();

    DELETE FROM incident_audit_event
    WHERE id IN (
        SELECT e.id FROM incident_audit_event e
        WHERE audit_event_is_purgeable('INCIDENT_AUDIT_EVENT', e.id, e.incident_id, e.retain_until)
        ORDER BY e.retain_until, e.id
        LIMIT p_batch_limit);
    GET DIAGNOSTICS v_incident = ROW_COUNT;

    DELETE FROM system_audit_event
    WHERE id IN (
        SELECT e.id FROM system_audit_event e
        WHERE audit_event_is_purgeable('SYSTEM_AUDIT_EVENT', e.id, NULL, e.retain_until)
        ORDER BY e.retain_until, e.id
        LIMIT p_batch_limit);
    GET DIAGNOSTICS v_system = ROW_COUNT;

    RETURN QUERY SELECT v_incident, v_system;
END;
$$;
REVOKE ALL ON FUNCTION purge_expired_audit_events(integer) FROM PUBLIC;

-- ALTER OWNER requires the new owner to hold CREATE on the schema; grant it only for this statement.
GRANT CREATE ON SCHEMA public TO psa_audit_retention;
ALTER FUNCTION purge_expired_audit_events(integer) OWNER TO psa_audit_retention;
REVOKE CREATE ON SCHEMA public FROM psa_audit_retention;
GRANT USAGE ON SCHEMA public TO psa_audit_retention;
GRANT EXECUTE ON FUNCTION audit_event_is_purgeable(text, uuid, uuid, timestamptz) TO psa_audit_retention;
