#!/usr/bin/env bash
set -u
source_path="${@: -2:1}"
destination="${@: -1}"
failure=''
case "$source_path|$destination" in
    */ripwire\|*.ripwire.backup.*) failure='binary-backup' ;;
    *.ripwire.stage.*\|*/ripwire) failure='binary-swap' ;;
    */ripwire\|*.ripwire.failed.*) failure='rollback-displace' ;;
    *.ripwire.backup.*\|*/ripwire) failure='rollback-binary-restore' ;;
    *.config.json\|*.config.json.backup.*) failure='config-backup' ;;
    *.config.json.stage.*\|*.config.json) failure='config-commit' ;;
    *.config.json.backup.*\|*.config.json) failure='rollback-config-restore' ;;
esac
case ",${TRANSACTION_FAIL_AT:-}," in
    *,"$failure",*) printf 'transaction fixture: mv failure at %s\n' "$failure" >&2; exit 93 ;;
esac
exec /usr/bin/mv "$@"
