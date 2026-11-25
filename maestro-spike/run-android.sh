#!/usr/bin/env bash
# Spike: runs one Android flow with the local admin's credentials from .env.e2e.local (never printed).
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
env_file="$here/../packages/applications/pos/.env.e2e.local"
user="$(sed -n 's/^E2E_ADMIN_USERNAME=//p' "$env_file")"
pass="$(sed -n 's/^E2E_ADMIN_PASSWORD=//p' "$env_file")"
export MAESTRO_CLI_NO_ANALYTICS=1 MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true MAESTRO_DISABLE_UPDATE_CHECK=true
adb="$HOME/Library/Android/sdk/platform-tools/adb"
"$adb" reverse tcp:8585 tcp:8585 >/dev/null
"$adb" reverse tcp:8586 tcp:8586 >/dev/null
"$here/../tools/e2e/local-stack.sh" reset-limits >/dev/null
out="${OUT:-$here/out}"; mkdir -p "$out"
exec maestro --device emulator-5554 test -e USERNAME="$user" -e PASSWORD="$pass" -e OUT="$out" --test-output-dir "$out" "$@"
