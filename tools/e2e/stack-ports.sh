# Sourced by local-stack.sh, maestro.sh and maestro-data.sh: the ports of one
# local test stack. E2E_STACK_PORT_OFFSET (a whole number, default 0) moves all
# four, so a second stack can run beside the first. APP_UM_PORT / APP_POS_PORT
# are the ports the app itself was built to call (config/e2e-local.json); on
# the Android emulator `adb reverse` maps them onto the stack's real ones.
case "${E2E_STACK_PORT_OFFSET:-0}" in
  ''|*[!0-9]*) echo "E2E_STACK_PORT_OFFSET must be a whole number, not '${E2E_STACK_PORT_OFFSET}'" >&2; exit 2 ;;
esac
STACK_PORT_OFFSET="${E2E_STACK_PORT_OFFSET:-0}"
APP_UM_PORT=8585
APP_POS_PORT=8586
MONGO_PORT=$((27719 + STACK_PORT_OFFSET))
REDIS_PORT=$((6390 + STACK_PORT_OFFSET))
UM_PORT=$((APP_UM_PORT + STACK_PORT_OFFSET))
POS_PORT=$((APP_POS_PORT + STACK_PORT_OFFSET))
