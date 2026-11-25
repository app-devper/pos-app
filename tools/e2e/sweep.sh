#!/usr/bin/env bash
# Cleans up what an interrupted e2e run left. Run it ONLY when no run is in
# progress, on any machine: it cancels a running file's bills and deletes
# its product.
#
# It acts on run names only, `E2E-<yyyyMMddHHmmss>-<pid> <what>`
# (RunData.runNamePattern): never the kept `E2E customer` or `E2E supplier`,
# nor anything else merely starting `E2E-`.
# - bills of the last 3 days whose every line is a run-named product:
#   cancelled, whoever rang them up; a bill mixing one with anything else is
#   left and reported;
# - run-named products not yet deleted: lots zeroed, stock rows deleted,
#   product deleted;
# - run-named customers: removed on the local target, kept on hosted;
# - draft receipts whose reference starts with a run id followed by a space,
#   a hyphen or nothing (`^[0-9]{14}-[0-9]+`); a reference is free text, so
#   a real one typed that way would match too.
# See packages/applications/pos/e2e/maintenance/sweep_earlier_runs.dart.
#
#   tools/e2e/sweep.sh local    the local stack
#   tools/e2e/sweep.sh hosted   the hosted API; run by the owner only
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() { printf 'usage: %s <local|hosted>\n' "$0" >&2; exit 2; }
[ "$#" -eq 1 ] || usage
case "$1" in local|hosted) ;; *) usage ;; esac

printf 'sweep: run this only when no e2e run is in progress, on any machine:\n'
printf 'sweep: it cancels bills made wholly of run-named products (E2E-<yyyyMMddHHmmss>-<pid> …),\n'
printf 'sweep: deletes run-named products and their stock rows, removes run-named customers (local only)\n'
printf 'sweep: and cancels draft receipts whose reference starts with a run id.\n'

# run.sh prints the hosted API and "run by the owner", and refuses without
# .env.e2e, exactly as for a test file.
log="$(mktemp "${TMPDIR:-/tmp}/pos-e2e-sweep.XXXXXX")"
set +e
"$SCRIPT_DIR/run.sh" "$1" maintenance/sweep_earlier_runs.dart > "$log" 2>&1
code=$?
set -e
tr '\r' '\n' < "$log" | grep -E '^(run.sh:|local-stack:|E2E sweep|  - |E2E: sign-ins)' || true
if [ "$code" -ne 0 ]; then
  printf 'sweep: FAILED (exit %s); full log in %s\n' "$code" "$log" >&2
  exit "$code"
fi
printf 'sweep: done; full log in %s\n' "$log"
