#!/usr/bin/env bash
set -u
version="${TRANSACTION_FAKE_VERSION:-0.5.0}"
if [[ "${TRANSACTION_POST_HEALTH_FAIL:-0}" == 1 && "${0##*/}" == ripwire ]]; then
    version='post-swap-failure'
fi
printf 'ripwire %s (transaction fixture)\n' "$version"
