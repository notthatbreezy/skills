#!/bin/bash
set -euo pipefail

fail() {
    printf '%s\n' "$1" >&2
    exit "${2:-70}"
}

is_absolute_clean_path() {
    [[ $1 == /* && $1 != *[[:cntrl:]]* && $1 != *//* &&
       $1 != */./* && $1 != */../* && $1 != */. && $1 != */.. ]]
}

json_string() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\t'/\\t}
    printf '"%s"' "$value"
}

[[ ${1-} == -- ]] || fail RIPWIRE_WSL_MISSING_SEPARATOR 64
shift
[[ $# -ge 1 ]] || fail RIPWIRE_WSL_MISSING_ROOT 64
root=$1
shift

for name in GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR RIPWIRE_BIN TMPDIR XDG_CACHE_HOME; do
    value=${!name-}
    is_absolute_clean_path "$value" || fail "RIPWIRE_WSL_INVALID_PATH: $name" 64
done
[[ $root == "$GIT_WORK_TREE" ]] || fail RIPWIRE_WSL_MISMATCHED_ROOT 64
[[ ${GIT_OPTIONAL_LOCKS-} == 0 ]] || fail RIPWIRE_WSL_INVALID_OPTIONAL_LOCKS 64
[[ ${RIPWIRE_WSL_DIAGNOSTIC-} == 0 || ${RIPWIRE_WSL_DIAGNOSTIC-} == 1 ]] ||
    fail RIPWIRE_WSL_INVALID_DIAGNOSTIC_MODE 64
operation=${RIPWIRE_WSL_OPERATION-analysis}
case "$operation:$RIPWIRE_WSL_DIAGNOSTIC" in
    analysis:0|clear:0|diagnostic:1) ;;
    *) fail RIPWIRE_WSL_INVALID_OPERATION 64 ;;
esac
[[ ${GIT_CONFIG_COUNT-} =~ ^(0|[1-9][0-9]*)$ ]] ||
    fail RIPWIRE_WSL_INVALID_GIT_CONFIG_COUNT 64

declare -A indexed=()
while IFS= read -r name; do
    if [[ $name =~ ^GIT_CONFIG_(KEY|VALUE)_([0-9]+)$ ]]; then
        index=${BASH_REMATCH[2]}
        (( index < GIT_CONFIG_COUNT )) || fail "RIPWIRE_WSL_EXTRA_GIT_CONFIG_ENTRY: $name" 64
        indexed["$name"]=1
    fi
done < <(compgen -e)
(( ${#indexed[@]} == 2 * GIT_CONFIG_COUNT )) || fail RIPWIRE_WSL_INVALID_GIT_CONFIG_ENTRIES 64
for ((i=0; i<GIT_CONFIG_COUNT; i++)); do
    key=GIT_CONFIG_KEY_$i
    value=GIT_CONFIG_VALUE_$i
    [[ -v $key && -n ${!key} && -v $value ]] ||
        fail "RIPWIRE_WSL_MISSING_GIT_CONFIG_ENTRY: $i" 64
done

namespace=${TMPDIR%/tmp}
[[ $TMPDIR == "$namespace/tmp" && $XDG_CACHE_HOME == "$namespace/xdg" && $namespace != "$TMPDIR" ]] ||
    fail RIPWIRE_WSL_INVALID_CACHE_NAMESPACE 70
case "$namespace/" in
    /mnt/*|/run/desktop/mnt/host/*) fail RIPWIRE_WSL_WINDOWS_BACKED_CACHE 70 ;;
esac
for forbidden in "$GIT_WORK_TREE" "$GIT_DIR" "$GIT_COMMON_DIR" "$(dirname "$RIPWIRE_BIN")"; do
    case "$namespace/" in "$forbidden/"* ) fail RIPWIRE_WSL_CACHE_OVERLAP 70 ;; esac
    case "$forbidden/" in "$namespace/"* ) fail RIPWIRE_WSL_CACHE_OVERLAP 70 ;; esac
done

key=${namespace##*/}
architecture_path=${namespace%/*}
architecture=${architecture_path##*/}
release_path=${architecture_path%/*}
release=${release_path##*/}
releases_path=${release_path%/*}
cache_root=${releases_path%/*}
[[ $key =~ ^[0-9a-f]{64}$ && $architecture =~ ^(x64|arm64)$ &&
   $release =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ && ${releases_path##*/} == releases ]] ||
    fail RIPWIRE_WSL_INVALID_CACHE_NAMESPACE 70
[[ $cache_root != / && -d $cache_root && ! -L $cache_root ]] ||
    fail RIPWIRE_WSL_INVALID_CACHE_ROOT 70
namespace_identity="$release/$architecture/$key"
lock_path="$cache_root/locks/$namespace_identity.lock"
lock_directory=$(dirname "$lock_path")
[[ $(stat -c %u -- "$cache_root") == "$(id -u)" ]] || fail RIPWIRE_WSL_CACHE_OWNER_MISMATCH 70
mode=$(stat -c %a -- "$cache_root")
[[ $mode == 700 ]] || fail RIPWIRE_WSL_CACHE_PERMISSIONS 70
filesystem=$(stat -f -c %T -- "$cache_root")
case "$filesystem" in
    ext2/ext3|tmpfs|btrfs|xfs) ;;
    *) fail "RIPWIRE_WSL_UNSUPPORTED_CACHE_FILESYSTEM: $filesystem" 70 ;;
esac
resolved_root=$(realpath -e -- "$cache_root")
resolved_namespace=$(realpath -m -- "$namespace")
[[ $resolved_root == "${cache_root%/}" ]] || fail RIPWIRE_WSL_CACHE_SYMLINK 70
case "$resolved_namespace/" in "$resolved_root/"*) ;; *) fail RIPWIRE_WSL_ESCAPED_CACHE_PATH 70 ;; esac
validate_components() {
    local target=$1
    local current=$resolved_root
    local relative=${target#"$cache_root"/}
    local part
    local -a parts
    [[ $relative != "$target" ]] || fail RIPWIRE_WSL_ESCAPED_CACHE_PATH 70
    IFS=/ read -r -a parts <<< "$relative"
    for part in "${parts[@]}"; do
        current="$current/$part"
        [[ ! -L $current ]] || fail "RIPWIRE_WSL_CACHE_SYMLINK: $current" 70
        if [[ -e $current ]]; then
            [[ -d $current && $(stat -c %u -- "$current") == "$(id -u)" ]] ||
                fail "RIPWIRE_WSL_CACHE_OWNER_OR_TYPE: $current" 70
            [[ $(stat -c %a -- "$current") == 700 ]] ||
                fail "RIPWIRE_WSL_CACHE_PERMISSIONS: $current" 70
        fi
    done
}
validate_components "$TMPDIR"
validate_components "$XDG_CACHE_HOME"
validate_components "$lock_directory"
validate_lock() {
    [[ ! -L $lock_path ]] || fail RIPWIRE_WSL_CACHE_LOCK_SYMLINK 70
    if [[ -e $lock_path ]]; then
        [[ -f $lock_path && $(stat -c %u -- "$lock_path") == "$(id -u)" &&
           $(stat -c %a -- "$lock_path") == 600 && $(stat -c %h -- "$lock_path") == 1 ]] ||
            fail RIPWIRE_WSL_INVALID_CACHE_LOCK 70
    fi
}
validate_lock
validate_cache_entries() {
    if [[ -d $namespace ]]; then
        local unsafe_entry
        unsafe_entry=$(find -P "$namespace" \( -type l -o ! -user "$(id -u)" -o -perm /0077 \) -print -quit)
        [[ -z $unsafe_entry ]] || fail "RIPWIRE_WSL_UNSAFE_CACHE_ENTRY: $unsafe_entry" 70
    fi
}

export "GIT_CONFIG_KEY_$GIT_CONFIG_COUNT=core.fsmonitor"
export "GIT_CONFIG_VALUE_$GIT_CONFIG_COUNT=false"
export GIT_CONFIG_COUNT=$((GIT_CONFIG_COUNT + 1))

if [[ $RIPWIRE_WSL_DIAGNOSTIC == 1 ]]; then
    validate_cache_entries
    ready=false
    if [[ -d $namespace && ! -L $namespace &&
          $(stat -c %u -- "$namespace") == "$(id -u)" &&
          $(stat -c %a -- "$namespace") == 700 ]]; then
        ready=true
    fi
    printf '{'
    printf '"root":'; json_string "$GIT_WORK_TREE"
    printf ',"gitDirectory":'; json_string "$GIT_DIR"
    printf ',"commonDirectory":'; json_string "$GIT_COMMON_DIR"
    printf ',"binaryPath":'; json_string "$RIPWIRE_BIN"
    printf ',"cacheNamespace":'; json_string "$namespace"
    printf ',"cacheLock":'; json_string "$lock_path"
    printf ',"cacheReady":%s' "$ready"
    printf ',"gitConfigCount":%d' "$GIT_CONFIG_COUNT"
    printf '}\n'
    exit 0
fi

umask 077
mkdir -p -- "$lock_directory"
validate_components "$lock_directory"
validate_lock

lock_timeout=${RIPWIRE_WSL_LOCK_TIMEOUT_SECONDS-30}
[[ $lock_timeout =~ ^([1-9]|[1-9][0-9]|[12][0-9][0-9]|300)$ ]] ||
    fail RIPWIRE_WSL_INVALID_LOCK_TIMEOUT 70
# Keep the lock inode outside the data namespace so clear cannot split coordination.
exec 9>>"$lock_path"
validate_lock
flock -x -w "$lock_timeout" 9 || fail RIPWIRE_WSL_CACHE_LOCK_TIMEOUT 75
validate_components "$TMPDIR"
validate_components "$XDG_CACHE_HOME"
validate_cache_entries
if [[ $operation == clear ]]; then
    rm -rf -- "$namespace"
    printf '{"clearedNamespace":'
    json_string "$namespace"
    printf '}\n'
    exit 0
fi
mkdir -p -- "$TMPDIR" "$XDG_CACHE_HOME"
validate_components "$TMPDIR"
validate_components "$XDG_CACHE_HOME"
exec "$RIPWIRE_BIN" "$root" "$@"
