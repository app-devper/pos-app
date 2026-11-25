#!/usr/bin/env bash
# Spike: runs one web flow against the build served on 127.0.0.1:8090 with the local admin's credentials (never printed).
# Extra args go to `maestro test` (e.g. --headless, --screen-size 1400x900).
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
env_file="$here/../packages/applications/pos/.env.e2e.local"
user="$(sed -n 's/^E2E_ADMIN_USERNAME=//p' "$env_file")"
pass="$(sed -n 's/^E2E_ADMIN_PASSWORD=//p' "$env_file")"
export MAESTRO_CLI_NO_ANALYTICS=1 MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true MAESTRO_DISABLE_UPDATE_CHECK=true
"$here/../tools/e2e/local-stack.sh" reset-limits >/dev/null
out="${OUT:-$here/out}"; mkdir -p "$out"
exec maestro test -e USERNAME="$user" -e PASSWORD="$pass" --test-output-dir "$out" "$@"
