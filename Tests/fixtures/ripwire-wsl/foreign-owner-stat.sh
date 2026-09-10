#!/bin/bash
set -euo pipefail
if [[ ${1-} == -c && ${2-} == %u ]]; then
    printf '%d\n' "$(( $(id -u) + 1 ))"
else
    exec /usr/bin/stat "$@"
fi
