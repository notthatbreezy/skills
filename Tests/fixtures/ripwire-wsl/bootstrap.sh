#!/bin/bash
set -euo pipefail
[[ ${1-} == -- ]] || { echo 'PROBE_MISSING_SEPARATOR' >&2; exit 64; }
shift
for name in GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR RIPWIRE_BIN; do
    [[ ${!name-} == /* ]] || { echo "PROBE_INVALID_PATH: $name" >&2; exit 64; }
done
[[ ${GIT_CONFIG_COUNT-} =~ ^(0|[1-9][0-9]*)$ ]] ||
    { echo 'PROBE_INVALID_GIT_CONFIG_COUNT' >&2; exit 64; }
for ((i=0; i<GIT_CONFIG_COUNT; i++)); do
    key="GIT_CONFIG_KEY_$i"
    value="GIT_CONFIG_VALUE_$i"
    [[ -n ${!key-} && -v $value ]] ||
        { echo 'PROBE_MISSING_GIT_CONFIG_ENTRY' >&2; exit 64; }
done
export "GIT_CONFIG_KEY_$GIT_CONFIG_COUNT=core.fsmonitor"
export "GIT_CONFIG_VALUE_$GIT_CONFIG_COUNT=false"
export GIT_CONFIG_COUNT=$((GIT_CONFIG_COUNT + 1))
exec "$RIPWIRE_BIN" "$@"
