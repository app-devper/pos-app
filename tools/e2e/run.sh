#!/usr/bin/env bash
# Runs one e2e file of the POS app against a real backend.
#
#   tools/e2e/run.sh local  <file under e2e/>   the local stack (started and seeded if needed)
#   tools/e2e/run.sh hosted <file under e2e/>   the hosted API; run by the owner only
#
# Exits with the test's exit code.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../../packages/applications/pos" && pwd)"
HOSTED_API="https://api.devper.app"

usage() { printf 'usage: %s <local|hosted> <file under e2e/>\n' "$0" >&2; exit 2; }

[ "$#" -eq 2 ] || usage
target="$1"
file="$2"
[ -f "$APP_DIR/e2e/$file" ] || { printf 'run.sh: no such file: e2e/%s\n' "$file" >&2; exit 2; }

case "$target" in
  local)
    config=e2e-local
    env_file=.env.e2e.local
    "$SCRIPT_DIR/local-stack.sh" start
    # um-api allows 5 sign-ins a minute per address; a run signs in several times.
    "$SCRIPT_DIR/local-stack.sh" reset-limits
    ;;
  hosted)
    config=app
    env_file=.env.e2e
    printf 'run.sh: target API %s — run by the owner\n' "$HOSTED_API"
    printf 'run.sh: the API allows 5 sign-ins a minute; a full run may pause 65s to wait it out\n'
    [ -f "$APP_DIR/$env_file" ] || {
      printf 'run.sh: %s/%s is missing (copy .env.e2e.example and fill it in)\n' "$APP_DIR" "$env_file" >&2
      exit 2
    }
    ;;
  *) usage ;;
esac

# run-all.sh passes one run id for all its files.
run_id="${E2E_RUN_ID:-$(date +%Y%m%d%H%M%S)-$$}"
cd "$APP_DIR"
# Only the file's path is passed: the test reads the credentials at run time,
# so they are neither compiled into the test nor visible in `ps`.
set +e
fvm flutter test "e2e/$file" \
  --dart-define=ENV="$config" \
  --dart-define=E2E_RUN_ID="$run_id" \
  --dart-define=E2E_ENV_FILE="$APP_DIR/$env_file"
code=$?
set -e
exit "$code"
