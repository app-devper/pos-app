#!/usr/bin/env bash
# Checks local-stack.sh's pid bookkeeping without the stack: a pid file that
# names a live process the script did not start is stale — `status` says so
# and `stop` removes the entry without killing that process. Uses its own
# state directory, so a running stack is never touched.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STACK="$SCRIPT_DIR/local-stack.sh"
STATE="$(mktemp -d "${TMPDIR:-/tmp}/pos-e2e-selftest.XXXXXX")"
failures=0

sleep 300 &
bystander=$!
cleanup() { kill "$bystander" 2>/dev/null || true; rm -rf "$STATE"; }
trap cleanup EXIT

check() {
  if eval "$2"; then printf 'ok   %s\n' "$1"
  else printf 'FAIL %s\n' "$1"; failures=$((failures + 1)); fi
}

stack() { E2E_STACK_STATE="$STATE" "$STACK" "$@"; }

# A pid file naming an unrelated live process (pid reuse after a crash).
mkdir -p "$STATE/pids"
echo "$bystander" > "$STATE/pids/um-api.pid"

out="$(stack status 2>&1)"
check "status reports the unrelated process as stale" \
  'printf "%s" "$out" | grep -q "um-api stale"'

stack stop >/dev/null 2>&1 || true
check "stop leaves the unrelated process alive" 'kill -0 "$bystander" 2>/dev/null'
check "stop removes the stale pid file" '[ ! -f "$STATE/pids/um-api.pid" ]'

# A pid file whose recorded start time differs is stale too.
echo "$bystander" > "$STATE/pids/um-api.pid"
echo "Thu Jan  1 00:00:00 1970" > "$STATE/pids/um-api.started"
stack stop >/dev/null 2>&1 || true
check "stop leaves a process whose start time differs alive" 'kill -0 "$bystander" 2>/dev/null'

# The process the script recorded (same pid and start time) is stopped.
echo "$bystander" > "$STATE/pids/um-api.pid"
ps -p "$bystander" -o lstart= > "$STATE/pids/um-api.started"
out="$(stack status 2>&1)"
check "status reports a recorded process as running" \
  'printf "%s" "$out" | grep -q "um-api running"'
stack stop >/dev/null 2>&1 || true
sleep 1
check "stop stops the recorded process" '! kill -0 "$bystander" 2>/dev/null'

[ "$failures" -eq 0 ] || { printf '%s check(s) failed\n' "$failures"; exit 1; }
printf 'all checks passed\n'
