-- Local-only behavior test for V2. Uses synthetic data inside one transaction that is rolled back.
-- Run: docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -P pager=off' < tests/v2_audit_and_mode_integrity_test.sql
-- Must run as the migration user (superuser/owner): it creates temporary roles and briefly disables a
-- retention trigger to seed already-expired rows (the server otherwise always computes retain_until).
BEGIN;
CREATE TEMP TABLE r(seq serial, test text, result text);

-- expect_state: 'OK' = statement succeeds; otherwise the SQLSTATE class prefix it must fail with
-- ('23' integrity_constraint_violation from our triggers, '42' insufficient privilege/invalid parameter etc.).
CREATE FUNCTION pg_temp.expect(p_test text, p_role text, p_sql text, p_expect text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_state text;
BEGIN
    BEGIN
        EXECUTE format('SET LOCAL ROLE %I', p_role);
        EXECUTE p_sql;
        RESET ROLE;
        INSERT INTO r(test, result) VALUES (p_test, CASE WHEN p_expect = 'OK' THEN 'PASS' ELSE 'FAIL: statement succeeded' END);
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE;
        RESET ROLE;
        INSERT INTO r(test, result) VALUES (p_test,
            CASE WHEN p_expect <> 'OK' AND v_state LIKE p_expect || '%' THEN 'PASS'
                 ELSE 'FAIL: got ' || v_state || ' ' || SQLERRM END);
    END;
END $$;

CREATE FUNCTION pg_temp.check_that(p_test text, p_ok boolean) RETURNS void
LANGUAGE sql AS $$ INSERT INTO r(test, result) VALUES (p_test, CASE WHEN p_ok THEN 'PASS' ELSE 'FAIL' END) $$;

CREATE ROLE psa_test_app NOLOGIN;      -- ordinary application role with broad table privileges
CREATE ROLE psa_test_job NOLOGIN;      -- retention job: may only call the purge function
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON incident, incident_audit_event, system_audit_event TO psa_test_app;
GRANT EXECUTE ON FUNCTION purge_expired_audit_events(integer) TO psa_test_job;

-- ---- fixtures
CREATE TEMP TABLE ids(k text PRIMARY KEY, id uuid);
GRANT ALL ON ids TO PUBLIC;
DO $$
DECLARE u uuid; i1 uuid; i2 uuid; x uuid;
BEGIN
    INSERT INTO user_account(display_name) VALUES ('Tester') RETURNING id INTO u;
    INSERT INTO retention_policy_version(record_class, version_number, retention_days, changed_by_user_id, effective_from)
    VALUES ('INCIDENT_AUDIT_EVENT', 1, 30, u, now() - interval '1 day'),
           ('SYSTEM_AUDIT_EVENT',   1, 30, u, now() - interval '1 day');
    INSERT INTO incident(user_id, trigger_source, incident_mode, triggered_at) VALUES (u, 'MANUAL', 'PRACTICE', now()) RETURNING id INTO i1;
    INSERT INTO incident(user_id, trigger_source, incident_mode, triggered_at) VALUES (u, 'MANUAL', 'PRACTICE', now()) RETURNING id INTO i2;
    INSERT INTO ids VALUES ('user', u), ('i1', i1), ('i2', i2);
END $$;

-- ---- incident_mode immutability
SELECT pg_temp.expect('mode change rejected (app role)', 'psa_test_app',
  format('UPDATE incident SET incident_mode = ''LIVE'' WHERE id = %L', (SELECT id FROM ids WHERE k='i1')), '23');
SELECT pg_temp.expect('bulk mode change rejected', 'psa_test_app', 'UPDATE incident SET incident_mode = ''LIVE''', '23');
SELECT pg_temp.expect('other-column update allowed', 'psa_test_app',
  format('UPDATE incident SET severity = ''HIGH'', state_version = 2 WHERE id = %L', (SELECT id FROM ids WHERE k='i1')), 'OK');
SELECT pg_temp.expect('same-mode write allowed', 'psa_test_app',
  format('UPDATE incident SET incident_mode = ''PRACTICE'' WHERE id = %L', (SELECT id FROM ids WHERE k='i1')), 'OK');

-- ---- inserts and server-computed retention
SELECT pg_temp.expect('incident audit insert allowed (app role)', 'psa_test_app',
  format('INSERT INTO incident_audit_event(incident_id, action) VALUES (%L, ''CREATED'')', (SELECT id FROM ids WHERE k='i1')), 'OK');
SELECT pg_temp.expect('system audit insert allowed (app role)', 'psa_test_app',
  'INSERT INTO system_audit_event(action, target_type) VALUES (''CFG'', ''config'')', 'OK');
SELECT pg_temp.expect('caller-supplied retain_until accepted but overridden', 'psa_test_app',
  format('INSERT INTO incident_audit_event(incident_id, action, retain_until) VALUES (%L, ''BACKDATED'', now() - interval ''1 year'')', (SELECT id FROM ids WHERE k='i1')), 'OK');
SELECT pg_temp.check_that('retain_until computed from policy (~30 days) and policy version recorded',
  (SELECT bool_and(retain_until BETWEEN now() + interval '29 days' AND now() + interval '31 days' AND retention_policy_version_id IS NOT NULL)
   FROM incident_audit_event WHERE action IN ('CREATED', 'BACKDATED')));

-- ---- seed already-expired and special rows (trigger disabled only for seeding)
ALTER TABLE incident_audit_event DISABLE TRIGGER trg_incident_audit_event_retention;
ALTER TABLE system_audit_event   DISABLE TRIGGER trg_system_audit_event_retention;
DO $$
DECLARE i1 uuid := (SELECT id FROM ids WHERE k='i1'); i2 uuid := (SELECT id FROM ids WHERE k='i2'); u uuid := (SELECT id FROM ids WHERE k='user'); x uuid;
BEGIN
    INSERT INTO incident_audit_event(incident_id, action, retain_until) VALUES (i1,'E1 expired',     now() - interval '1 hour') RETURNING id INTO x; INSERT INTO ids VALUES ('E1', x);
    INSERT INTO incident_audit_event(incident_id, action, retain_until) VALUES (i1,'E2 row hold',    now() - interval '1 hour') RETURNING id INTO x; INSERT INTO ids VALUES ('E2', x);
    INSERT INTO incident_audit_event(incident_id, action, retain_until) VALUES (i2,'E3 incident hold',now() - interval '1 hour') RETURNING id INTO x; INSERT INTO ids VALUES ('E3', x);
    INSERT INTO incident_audit_event(incident_id, action, retain_until) VALUES (i1,'E4 no deadline', NULL)                       RETURNING id INTO x; INSERT INTO ids VALUES ('E4', x);
    INSERT INTO incident_audit_event(incident_id, action, retain_until) VALUES (i1,'E5 unexpired',   now() + interval '1 hour')  RETURNING id INTO x; INSERT INTO ids VALUES ('E5', x);
    INSERT INTO incident_audit_event(incident_id, action, retain_until) VALUES (i1,'E6 hold released',now() - interval '1 hour') RETURNING id INTO x; INSERT INTO ids VALUES ('E6', x);
    INSERT INTO system_audit_event(action, target_type, retain_until) VALUES ('S1 expired','t', now() - interval '1 hour') RETURNING id INTO x; INSERT INTO ids VALUES ('S1', x);
    INSERT INTO system_audit_event(action, target_type, retain_until) VALUES ('S2 row hold','t', now() - interval '1 hour') RETURNING id INTO x; INSERT INTO ids VALUES ('S2', x);
    INSERT INTO system_audit_event(action, target_type, retain_until) VALUES ('S3 unexpired','t', now() + interval '1 hour') RETURNING id INTO x; INSERT INTO ids VALUES ('S3', x);
    INSERT INTO system_audit_event(action, target_type, retain_until) VALUES ('S4 no deadline','t', NULL)                  RETURNING id INTO x; INSERT INTO ids VALUES ('S4', x);

    INSERT INTO legal_hold(record_type, record_id, hold_reason, created_by_user_id) VALUES
        ('INCIDENT_AUDIT_EVENT', (SELECT id FROM ids WHERE k='E2'), 'test', u),
        ('INCIDENT',             i2,                                'test', u),
        ('SYSTEM_AUDIT_EVENT',   (SELECT id FROM ids WHERE k='S2'), 'test', u);
    INSERT INTO legal_hold(record_type, record_id, hold_reason, created_by_user_id, released_by_user_id, released_at)
        VALUES ('INCIDENT_AUDIT_EVENT', (SELECT id FROM ids WHERE k='E6'), 'test', u, u, now());
END $$;
ALTER TABLE incident_audit_event ENABLE TRIGGER trg_incident_audit_event_retention;
ALTER TABLE system_audit_event   ENABLE TRIGGER trg_system_audit_event_retention;

-- ---- ordinary role: all changes blocked, even for an expired row, even with full table privileges
SELECT pg_temp.expect('app UPDATE incident audit rejected', 'psa_test_app', 'UPDATE incident_audit_event SET action = ''X''', '23');
SELECT pg_temp.expect('app UPDATE system audit rejected',   'psa_test_app', 'UPDATE system_audit_event SET action = ''X''', '23');
SELECT pg_temp.expect('app UPDATE of retain_until rejected','psa_test_app', 'UPDATE incident_audit_event SET retain_until = now() - interval ''1 year''', '23');
SELECT pg_temp.expect('app DELETE expired incident audit rejected', 'psa_test_app',
  format('DELETE FROM incident_audit_event WHERE id = %L', (SELECT id FROM ids WHERE k='E1')), '23');
SELECT pg_temp.expect('app DELETE expired system audit rejected', 'psa_test_app',
  format('DELETE FROM system_audit_event WHERE id = %L', (SELECT id FROM ids WHERE k='S1')), '23');
SELECT pg_temp.expect('app TRUNCATE incident audit rejected', 'psa_test_app', 'TRUNCATE incident_audit_event', '23');
SELECT pg_temp.expect('app TRUNCATE system audit rejected',   'psa_test_app', 'TRUNCATE system_audit_event', '23');
SELECT pg_temp.expect('app setting a GUC cannot unlock delete', 'psa_test_app',
  format('SELECT set_config(''psa.audit_purge'', ''on'', true); DELETE FROM incident_audit_event WHERE id = %L', (SELECT id FROM ids WHERE k='E1')), '23');
SELECT pg_temp.expect('app cannot call purge function', 'psa_test_app', 'SELECT * FROM purge_expired_audit_events(10)', '42501');
-- SET ROLE is checked against the session user, so authenticate as the app role first.
SELECT pg_temp.expect('app session cannot SET ROLE to retention role', session_user::text,
  'SET LOCAL SESSION AUTHORIZATION psa_test_app; SET ROLE psa_audit_retention', '42501');
SELECT pg_temp.expect('app cannot read legal_hold', 'psa_test_app', 'SELECT * FROM legal_hold', '42501');

-- ---- retention role used directly: still cannot edit, truncate, or remove ineligible rows
SELECT pg_temp.expect('retention role UPDATE rejected', 'psa_audit_retention', 'UPDATE incident_audit_event SET action = ''X''', '42501');
SELECT pg_temp.expect('retention role TRUNCATE rejected', 'psa_audit_retention', 'TRUNCATE incident_audit_event', '42501');
SELECT pg_temp.expect('retention role DELETE unexpired (E5) rejected', 'psa_audit_retention',
  format('DELETE FROM incident_audit_event WHERE id = %L', (SELECT id FROM ids WHERE k='E5')), '23');
SELECT pg_temp.expect('retention role DELETE no-deadline (E4) rejected', 'psa_audit_retention',
  format('DELETE FROM incident_audit_event WHERE id = %L', (SELECT id FROM ids WHERE k='E4')), '23');
SELECT pg_temp.expect('retention role DELETE row-held (E2) rejected', 'psa_audit_retention',
  format('DELETE FROM incident_audit_event WHERE id = %L', (SELECT id FROM ids WHERE k='E2')), '23');
SELECT pg_temp.expect('retention role DELETE incident-held (E3) rejected', 'psa_audit_retention',
  format('DELETE FROM incident_audit_event WHERE id = %L', (SELECT id FROM ids WHERE k='E3')), '23');
SELECT pg_temp.expect('retention role DELETE unexpired system (S3) rejected', 'psa_audit_retention',
  format('DELETE FROM system_audit_event WHERE id = %L', (SELECT id FROM ids WHERE k='S3')), '23');
SELECT pg_temp.expect('retention role DELETE held system (S2) rejected', 'psa_audit_retention',
  format('DELETE FROM system_audit_event WHERE id = %L', (SELECT id FROM ids WHERE k='S2')), '23');
SELECT pg_temp.expect('retention role bulk DELETE with any ineligible row rejected', 'psa_audit_retention',
  'DELETE FROM incident_audit_event', '23');
SELECT pg_temp.check_that('ineligible rows still present after attempts',
  (SELECT count(*) FROM incident_audit_event WHERE id IN (SELECT id FROM ids WHERE k IN ('E1','E2','E3','E4','E5','E6'))) = 6
  AND (SELECT count(*) FROM system_audit_event WHERE id IN (SELECT id FROM ids WHERE k IN ('S1','S2','S3','S4'))) = 4);

-- ---- permitted retention cleanup through the controlled function
SELECT pg_temp.expect('purge batch_limit 0 rejected', 'psa_test_job', 'SELECT * FROM purge_expired_audit_events(0)', '22');
SELECT pg_temp.expect('purge batch_limit 10001 rejected', 'psa_test_job', 'SELECT * FROM purge_expired_audit_events(10001)', '22');
SELECT pg_temp.expect('purge function callable by granted job role', 'psa_test_job', 'SELECT * FROM purge_expired_audit_events(1000)', 'OK');
SELECT pg_temp.check_that('expired unheld rows removed (E1, E6, S1)',
  NOT EXISTS (SELECT 1 FROM ids WHERE k IN ('E1','E6','S1') AND id IN (SELECT id FROM incident_audit_event UNION ALL SELECT id FROM system_audit_event)));
SELECT pg_temp.check_that('held, unexpired and no-deadline rows retained (E2,E3,E4,E5,S2,S3,S4)',
  (SELECT count(*) FROM incident_audit_event WHERE id IN (SELECT id FROM ids WHERE k IN ('E2','E3','E4','E5'))) = 4
  AND (SELECT count(*) FROM system_audit_event WHERE id IN (SELECT id FROM ids WHERE k IN ('S2','S3','S4'))) = 3);
SELECT pg_temp.check_that('rows inserted via the normal path (30-day retention) retained',
  (SELECT count(*) FROM incident_audit_event WHERE action IN ('CREATED','BACKDATED')) = 2);

-- releasing a hold makes the row eligible; a second run is then idempotent
UPDATE legal_hold SET released_by_user_id = (SELECT id FROM ids WHERE k='user'), released_at = now()
 WHERE record_type = 'INCIDENT_AUDIT_EVENT' AND record_id = (SELECT id FROM ids WHERE k='E2');
UPDATE legal_hold SET released_by_user_id = (SELECT id FROM ids WHERE k='user'), released_at = now()
 WHERE record_type = 'INCIDENT' AND record_id = (SELECT id FROM ids WHERE k='i2');
SELECT pg_temp.expect('purge after hold release', 'psa_test_job', 'SELECT * FROM purge_expired_audit_events(1000)', 'OK');
SELECT pg_temp.check_that('released-hold rows removed (E2, E3); S2 still held',
  NOT EXISTS (SELECT 1 FROM incident_audit_event WHERE id IN (SELECT id FROM ids WHERE k IN ('E2','E3')))
  AND EXISTS (SELECT 1 FROM system_audit_event WHERE id = (SELECT id FROM ids WHERE k='S2')));
SELECT pg_temp.expect('purge run with nothing eligible is a no-op', 'psa_test_job', 'SELECT * FROM purge_expired_audit_events(1000)', 'OK');
SELECT pg_temp.check_that('E4, E5, S2, S3, S4 and normal rows still retained',
  (SELECT count(*) FROM incident_audit_event) = 4 AND (SELECT count(*) FROM system_audit_event) = 4);

-- batch limit bounds the work per run
ALTER TABLE incident_audit_event DISABLE TRIGGER trg_incident_audit_event_retention;
INSERT INTO incident_audit_event(incident_id, action, retain_until)
  SELECT (SELECT id FROM ids WHERE k='i1'), 'bulk ' || g, now() - interval '1 hour' FROM generate_series(1, 5) g;
ALTER TABLE incident_audit_event ENABLE TRIGGER trg_incident_audit_event_retention;
CREATE TEMP TABLE purge_out(i bigint, s bigint);
GRANT ALL ON purge_out TO PUBLIC;
SELECT pg_temp.expect('purge with batch_limit 2', 'psa_test_job', 'INSERT INTO purge_out SELECT * FROM purge_expired_audit_events(2)', 'OK');
SELECT pg_temp.check_that('batch_limit 2 deleted exactly 2 incident rows', (SELECT i FROM purge_out) = 2);

SELECT seq, test, result FROM r ORDER BY seq;
SELECT count(*) FILTER (WHERE result = 'PASS') AS passed, count(*) FILTER (WHERE result <> 'PASS') AS failed FROM r;
ROLLBACK;
