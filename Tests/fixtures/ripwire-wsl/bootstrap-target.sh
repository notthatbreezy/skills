#!/bin/bash
set -euo pipefail
[[ -d $TMPDIR && -d $XDG_CACHE_HOME ]] || exit 92
root=$1
shift
exec python3 "$@" "$root"
