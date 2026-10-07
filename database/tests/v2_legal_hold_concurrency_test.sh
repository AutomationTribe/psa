#!/usr/bin/env bash
# Local-only two-session concurrency test for legal-hold creation vs audit purge (V2).
# Copies the migrated Local database into a scratch database, runs coordinated sessions, then drops it.
# Usage (from database/, with the Local stack running and migrated):
#   tests/v2_legal_hold_concurrency_test.sh                 # expect every check to PASS
#   NEGATIVE_CONTROL=1 tests/v2_legal_hold_concurrency_test.sh   # removes the locks; checks must FAIL
#   NEGATIVE_CONTROL=isolation tests/v2_legal_hold_concurrency_test.sh   # removes only the READ COMMITTED
#                                                                       # enforcement; S6 checks must FAIL
# Isolation: all sessions use the server default (READ COMMITTED) unless a scenario states otherwise.
# S1-S5 and S3c-S3e run under READ COMMITTED; S6 runs the purge and direct DELETE under REPEATABLE READ
# and SERIALIZABLE, which the retention path must refuse.
set -u
cd "$(dirname "$0")/.."
SCRATCH=psa_concurrency_test
WORK=$(mktemp -d)
PASS=0; FAIL=0

admin() { docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d postgres -At -v ON_ERROR_STOP=1' ; }
scratch() { docker compose exec -T postgres sh -c "psql -U \"\$POSTGRES_USER\" -d $SCRATCH -At -v ON_ERROR_STOP=1" ; }
q() { echo "$1" | scratch; }

check() { # name, condition (shell exit status)
  if [ "$2" = "0" ]; then PASS=$((PASS+1)); echo "PASS  $1"; else FAIL=$((FAIL+1)); echo "FAIL  $1"; fi
}

# ---- long-lived psql sessions fed through FIFOs; output goes to $WORK/<name>.out
# bash 3.2 (macOS) has no {var} fds: session A uses fd 3, session B uses fd 4.
start_session() {
  local n=$1 fd=$2
  mkfifo "$WORK/$n.in"
  docker compose exec -T postgres sh -c "psql -U \"\$POSTGRES_USER\" -d $SCRATCH -At -v VERBOSITY=terse" \
    < "$WORK/$n.in" > "$WORK/$n.out" 2>&1 &
  eval "exec $fd>\"$WORK/$n.in\""
}
send() { local fd; case $1 in A) fd=3;; B) fd=4;; esac; printf '%s\n' "$2" >&$fd; }
# Negative-control runs expect waits to fail, so cap them to keep the run short.
CAP=${NEGATIVE_CONTROL:+6}
wait_for() { # session, text, seconds
  local i s=${3:-30}; [ -n "$CAP" ] && [ "$s" -gt "$CAP" ] && s=$CAP
  for ((i=0; i<s*5; i++)); do grep -q -- "$2" "$WORK/$1.out" && return 0; sleep 0.2; done; return 1
}
wait_blocked() { # query fragment that must be waiting on a lock
  local i n lim=75; [ -n "$CAP" ] && lim=15
  for ((i=0; i<lim; i++)); do
    n=$(q "select count(*) from pg_stat_activity where datname='$SCRATCH' and wait_event_type='Lock' and query ilike '%$1%'")
    [ "$n" -ge 1 ] && return 0; sleep 0.2; done; return 1
}
still_blocked() { # true if still waiting after a short pause (it must not have progressed)
  sleep 1; wait_blocked "$1"
}
exists() { [ "$(q "select count(*) from incident_audit_event where id='$1'")" = "1" ]; }
gone()   { ! exists "$1"; }

echo "== setup scratch database from migrated $(docker compose exec -T postgres sh -c 'echo $POSTGRES_DB')"
docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d postgres -At -c "DROP DATABASE IF EXISTS '"$SCRATCH"' WITH (FORCE)" -c "CREATE DATABASE '"$SCRATCH"' TEMPLATE $POSTGRES_DB"' >/dev/null || { echo "cannot create scratch db"; exit 2; }

scratch >/dev/null <<'SQL'
CREATE FUNCTION seed_event(p_label text) RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE x uuid; i uuid := (SELECT id FROM incident LIMIT 1);
BEGIN
  ALTER TABLE incident_audit_event DISABLE TRIGGER trg_incident_audit_event_retention;
  INSERT INTO incident_audit_event(incident_id, action, retain_until)
    VALUES (i, p_label, now() - interval '1 hour') RETURNING id INTO x;
  ALTER TABLE incident_audit_event ENABLE TRIGGER trg_incident_audit_event_retention;
  RETURN x;
END $$;
INSERT INTO user_account(display_name) VALUES ('Concurrency tester');
INSERT INTO incident(user_id, trigger_source, incident_mode, triggered_at)
  SELECT id, 'MANUAL', 'PRACTICE', now() FROM user_account LIMIT 1;
SQL
USER_ID=$(q "select id from user_account limit 1")

if [ "${NEGATIVE_CONTROL:-0}" = "isolation" ]; then
  echo "== NEGATIVE CONTROL (isolation): removing only the READ COMMITTED enforcement from the lock helper"
  q "select pg_get_functiondef('lock_legal_holds_for_purge()'::regprocedure)" \
    | sed '/isolation-check-begin/,/isolation-check-end/d' | scratch >/dev/null
elif [ "${NEGATIVE_CONTROL:-0}" = "1" ]; then
  echo "== NEGATIVE CONTROL: removing the legal-hold lock call from purge function and delete guard"
  for fn in "purge_expired_audit_events(integer)" "guard_audit_delete()"; do
    q "select pg_get_functiondef('$fn'::regprocedure)" | sed '/PERFORM lock_legal_holds_for_purge/d' | scratch >/dev/null
  done
fi

hold_sql() { echo "INSERT INTO legal_hold(record_type, record_id, hold_reason, created_by_user_id) VALUES ('INCIDENT_AUDIT_EVENT','$1','concurrency test','$USER_ID');"; }

start_session A 3   # writes legal holds
start_session B 4   # runs purge / delete
send A "SELECT 'A-ready:' || current_setting('transaction_isolation');"; send B "SELECT 'B-ready:' || current_setting('transaction_isolation');"
wait_for A A-ready 20; wait_for B B-ready 20
grep -q "A-ready:read committed" "$WORK/A.out"; check "session A (hold writer) isolation is READ COMMITTED" $?
grep -q "B-ready:read committed" "$WORK/B.out"; check "session B (purge) isolation is READ COMMITTED" $?

echo "== S1: hold committed before purge starts"
E1=$(q "select seed_event('S1 held')"); E2=$(q "select seed_event('S1 unheld')")
q "$(hold_sql $E1)" >/dev/null
send B "SELECT 'S1:' || incident_audit_deleted FROM purge_expired_audit_events(1000); SELECT 'S1-done';"
wait_for B S1-done 30
exists $E1; check "S1 held row retained" $?
gone $E2;   check "S1 unheld expired row purged" $?

echo "== S2: hold in flight (uncommitted) when purge starts; hold then commits"
E3=$(q "select seed_event('S2 held')"); E4=$(q "select seed_event('S2 unheld')")
send A "BEGIN; $(hold_sql $E3) SELECT 'S2-hold-written';"
wait_for A S2-hold-written 20
send B "SELECT 'S2:' || incident_audit_deleted FROM purge_expired_audit_events(1000); SELECT 'S2-done';"
wait_blocked "purge_expired_audit_events"; check "S2 purge waits for the in-flight hold writer" $?
still_blocked "purge_expired_audit_events"; check "S2 purge still waiting while hold uncommitted" $?
exists $E3; check "S2 held row not deleted while waiting" $?
send A "COMMIT; SELECT 'S2-hold-committed';"
wait_for A S2-hold-committed 20; wait_for B S2-done 30
exists $E3; check "S2 row covered by the committed hold retained" $?
gone $E4;   check "S2 unheld expired row purged after the wait" $?

echo "== S3: hold created while purge transaction is open (purge commits first); the hold must not commit as an orphan"
E5=$(q "select seed_event('S3 expired')")
orph0=$(grep -c "does not exist" "$WORK/A.out")
send B "BEGIN; SELECT 'S3:' || incident_audit_deleted FROM purge_expired_audit_events(1000); SELECT 'S3-purge-open';"
wait_for B S3-purge-open 30
send A "$(hold_sql $E5) SELECT 'S3-hold-done';"
wait_blocked "INSERT INTO legal_hold"; check "S3 hold write waits while purge is in progress" $?
still_blocked "INSERT INTO legal_hold"; check "S3 hold cannot commit during the purge" $?
[ "$(q "select count(*) from legal_hold where record_id='$E5'")" = "0" ]; check "S3 no committed hold visible during purge" $?
send B "COMMIT; SELECT 'S3-purge-committed';"
wait_for B S3-purge-committed 20; wait_for A S3-hold-done 30
gone $E5; check "S3 purge committed first: row removed before any hold committed" $?
[ "$(grep -c "does not exist" "$WORK/A.out")" -gt "$orph0" ]; check "S3 woken hold write was rejected as an orphan (target already purged)" $?
[ "$(q "select count(*) from legal_hold where record_id='$E5'")" = "0" ]; check "S3 no orphan hold row committed for the purged event" $?

echo "== S3c: hold attempted after the purge committed is also rejected"
orph1=$(grep -c "does not exist" "$WORK/A.out")
send A "$(hold_sql $E5) SELECT 'S3c-done';"; wait_for A S3c-done 20
[ "$(grep -c "does not exist" "$WORK/A.out")" -gt "$orph1" ]; check "S3c sequential hold on a purged event rejected" $?
[ "$(q "select count(*) from legal_hold where record_id='$E5'")" = "0" ]; check "S3c no orphan hold row" $?

echo "== S3d: re-activating a released hold on a purged event is rejected"
E9=$(q "select seed_event('S3d expired')")
q "$(hold_sql $E9)" >/dev/null
q "update legal_hold set released_at=now(), released_by_user_id='$USER_ID' where record_id='$E9'" >/dev/null
send B "SELECT 'S3d:' || incident_audit_deleted FROM purge_expired_audit_events(1000); SELECT 'S3d-purged';"; wait_for B S3d-purged 30
gone $E9; check "S3d event with released hold purged" $?
orph2=$(grep -c "does not exist" "$WORK/A.out")
send A "UPDATE legal_hold SET released_at = NULL, released_by_user_id = NULL WHERE record_id='$E9'; SELECT 'S3d-done';"; wait_for A S3d-done 20
[ "$(grep -c "does not exist" "$WORK/A.out")" -gt "$orph2" ]; check "S3d re-activation of hold on purged event rejected" $?
[ "$(q "select count(*) from legal_hold where record_id='$E9' and released_at is null")" = "0" ]; check "S3d no active orphan hold" $?

echo "== S3e: event-level hold writer must itself run at READ COMMITTED"
E10=$(q "select seed_event('S3e unexpired-later')")
rr0=$(grep -c "require READ COMMITTED" "$WORK/A.out")
send A "BEGIN ISOLATION LEVEL REPEATABLE READ; SELECT 1; $(hold_sql $E10) ROLLBACK; SELECT 'S3e-done';"; wait_for A S3e-done 20
[ "$(grep -c "require READ COMMITTED" "$WORK/A.out")" -gt "$rr0" ]; check "S3e hold write under REPEATABLE READ rejected" $?
[ "$(q "select count(*) from legal_hold where record_id='$E10'")" = "0" ]; check "S3e no hold row created" $?
send B "SELECT 'S3e-cleanup:' || incident_audit_deleted FROM purge_expired_audit_events(1000); SELECT 'S3e-purged';"; wait_for B S3e-purged 30

echo "== S3b: purge rolls back; hold then commits and protects the row"
E6=$(q "select seed_event('S3b expired')")
send B "BEGIN; SELECT 'S3b:' || incident_audit_deleted FROM purge_expired_audit_events(1000); SELECT 'S3b-purge-open';"
wait_for B S3b-purge-open 30
send A "$(hold_sql $E6) SELECT 'S3b-hold-committed';"
wait_blocked "INSERT INTO legal_hold"; check "S3b hold write waits while purge is in progress" $?
send B "ROLLBACK; SELECT 'S3b-rolled-back';"
wait_for B S3b-rolled-back 20; wait_for A S3b-hold-committed 30
exists $E6; check "S3b row restored by rollback and covered by hold" $?
send B "SELECT 'S3b2:' || incident_audit_deleted FROM purge_expired_audit_events(1000); SELECT 'S3b2-done';"
wait_for B S3b2-done 30
exists $E6; check "S3b later purge keeps the held row" $?

echo "== S4: direct DELETE by retention role, hold commits after the statement began"
E7=$(q "select seed_event('S4 held')")
send A "BEGIN; $(hold_sql $E7) SELECT 'S4-hold-written';"
wait_for A S4-hold-written 20
send B "SET ROLE psa_audit_retention; DELETE FROM incident_audit_event WHERE id='$E7'; RESET ROLE; SELECT 'S4-done';"
wait_blocked "DELETE FROM incident_audit_event"; check "S4 delete waits on the in-flight hold writer" $?
send A "COMMIT; SELECT 'S4-hold-committed';"
wait_for A S4-hold-committed 20; wait_for B S4-done 30
exists $E7; check "S4 row covered by the committed hold not deleted" $?
grep -q "legal hold" "$WORK/B.out"; check "S4 delete was rejected by the guard (not silently skipped)" $?

echo "== S5: purges do not block each other on the legal-hold lock"
# Nothing is eligible here, so the two purges select no common rows; this checks only that the shared
# legal_hold lock itself does not serialize them. (Purges that select the same rows still wait on each
# other's row locks until the first commits.)
send B "BEGIN; SELECT 'S5a:' || incident_audit_deleted FROM purge_expired_audit_events(1000); SELECT 'S5-first-open';"
wait_for B S5-first-open 30
second_purge() { echo "SELECT incident_audit_deleted FROM purge_expired_audit_events(1000)" | docker compose exec -T postgres sh -c "psql -U \"\$POSTGRES_USER\" -d $SCRATCH -At"; }
export -f second_purge; export SCRATCH
perl -e 'alarm 20; exec @ARGV' bash -c second_purge >/dev/null; check "S5 second purge completes while first purge transaction is open" $?
send B "COMMIT; SELECT 'S5-committed';"; wait_for B S5-committed 20

echo "== S6: purge and direct DELETE must refuse REPEATABLE READ and SERIALIZABLE"
# Ordering under test: a hold is written but uncommitted when the purge begins. Under READ COMMITTED the purge
# waits and then sees the hold (S2). Under a stricter level its snapshot would predate the hold's commit, so
# the retention path must refuse to run instead of waiting.
for LEVEL in "REPEATABLE READ" "SERIALIZABLE"; do
  TAG=$(echo "$LEVEL" | tr -d ' ' | cut -c1-6)
  E=$(q "select seed_event('S6 $LEVEL')")
  send A "BEGIN; $(hold_sql $E) SELECT 'S6-$TAG-hold-written';"; wait_for A "S6-$TAG-hold-written" 20
  rej0=$(grep -c "requires READ COMMITTED" "$WORK/B.out")
  send B "BEGIN ISOLATION LEVEL $LEVEL; SELECT 'S6-$TAG:' || incident_audit_deleted FROM purge_expired_audit_events(1000); COMMIT; SELECT 'S6-$TAG-purge-done';"
  wait_for B "S6-$TAG-purge-done" 4; check "S6 purge under $LEVEL returns immediately (does not wait on the hold)" $?
  [ "$(grep -c "requires READ COMMITTED" "$WORK/B.out")" -gt "$rej0" ]; check "S6 purge under $LEVEL rejected with READ COMMITTED error" $?
  send A "COMMIT; SELECT 'S6-$TAG-hold-committed';"; wait_for A "S6-$TAG-hold-committed" 20
  wait_for B "S6-$TAG-purge-done" 30
  exists $E; check "S6 row covered by committed hold retained after the $LEVEL attempt" $?
done

# Direct DELETE by the retention role (not via the purge function) with a hold in flight.
E=$(q "select seed_event('S6 direct delete')")
send A "BEGIN; $(hold_sql $E) SELECT 'S6-direct-hold-written';"; wait_for A S6-direct-hold-written 20
rej1=$(grep -c "requires READ COMMITTED" "$WORK/B.out")
send B "BEGIN ISOLATION LEVEL REPEATABLE READ; SET LOCAL ROLE psa_audit_retention; DELETE FROM incident_audit_event WHERE id='$E'; COMMIT; SELECT 'S6-direct-done';"
wait_for B S6-direct-done 4; check "S6 direct DELETE under REPEATABLE READ returns immediately (does not wait on the hold)" $?
[ "$(grep -c "requires READ COMMITTED" "$WORK/B.out")" -gt "$rej1" ]; check "S6 direct DELETE under REPEATABLE READ rejected" $?
send A "COMMIT; SELECT 'S6-direct-hold-committed';"; wait_for A S6-direct-hold-committed 20; wait_for B S6-direct-done 30
exists $E; check "S6 direct-DELETE row covered by committed hold retained" $?
q "update legal_hold set released_at=now(), released_by_user_id='$USER_ID' where record_id='$E'" >/dev/null

send B "SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL REPEATABLE READ; SELECT 'S6-default:' || current_setting('transaction_isolation');"
send B "SELECT * FROM purge_expired_audit_events(1000); SELECT 'S6-session-done';"
wait_for B S6-session-done 20
send B "SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL READ COMMITTED; SELECT 'S6-reset';"; wait_for B S6-reset 20
exists $E; check "S6 purge with session default REPEATABLE READ leaves the row (rejected)" $?
send B "SELECT 'S6-final:' || incident_audit_deleted FROM purge_expired_audit_events(1000); SELECT 'S6-final-done';"; wait_for B S6-final-done 30
gone $E; check "S6 same purge succeeds once back at READ COMMITTED" $?

send A '\q'; send B '\q'; sleep 1
docker compose exec -T postgres sh -c 'psql -U "$POSTGRES_USER" -d postgres -At -c "DROP DATABASE IF EXISTS '"$SCRATCH"' WITH (FORCE)"' >/dev/null
rm -rf "$WORK"
echo "== result: $PASS passed, $FAIL failed"
[ "$FAIL" = "0" ]
