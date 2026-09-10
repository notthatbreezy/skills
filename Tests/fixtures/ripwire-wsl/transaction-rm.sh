#!/usr/bin/env bash
set -u
failure=''
has_stage=0
has_displaced=0
for argument in "$@"; do
    case "$argument" in
        *.ripwire.backup.*) failure='cleanup-binary-backup' ;;
        *.config.json.backup.*) failure='cleanup-config-backup' ;;
        *.ripwire.failed.*) has_displaced=1 ;;
        *.ripwire.stage.*) has_stage=1 ;;
    esac
done
if ((has_stage && has_displaced)); then
    failure='cleanup-transaction-artifacts'
elif ((has_displaced)); then
    failure='cleanup-failed-binary'
elif ((has_stage)); then
    failure='cleanup-stage'
fi
case ",${TRANSACTION_FAIL_AT:-}," in
    *,"$failure",*) printf 'transaction fixture: rm failure at %s\n' "$failure" >&2; exit 94 ;;
esac
exec /usr/bin/rm "$@"
