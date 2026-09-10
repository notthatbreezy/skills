#!/bin/bash
set -euo pipefail
fail() { printf '%s\n' "$1" >&2; exit 70; }
[[ $# == 3 ]] || fail RIPWIRE_WSL_INVALID_INSPECTION
binary=$1
cache=$2
version=$3
for path in "$binary" "$cache"; do
    [[ $path == /* && $path != / && $path != *[[:cntrl:]]* &&
       $(realpath -m -- "$path") == "$path" ]] || fail RIPWIRE_WSL_UNSAFE_INSPECTION_PATH
done
[[ -f $binary && ! -L $binary && -x $binary ]] || fail RIPWIRE_WSL_BINARY_MISSING_OR_INVALID
reported=$("$binary" --version)
[[ $reported == "ripwire ${version#v} "* || $reported == "ripwire ${version#v}" ]] ||
    fail RIPWIRE_WSL_BINARY_VERSION_MISMATCH
[[ -d $cache && ! -L $cache ]] || fail RIPWIRE_WSL_CACHE_ROOT_MISSING
[[ $(stat -c %u -- "$cache") == "$(id -u)" && $(stat -c %a -- "$cache") == 700 ]] ||
    fail RIPWIRE_WSL_CACHE_OWNER_OR_PERMISSIONS
case $(stat -f -c %T -- "$cache") in
    ext2/ext3|tmpfs|btrfs|xfs) ;;
    *) fail RIPWIRE_WSL_UNSUPPORTED_CACHE_FILESYSTEM ;;
esac
binary_directory=$(dirname -- "$binary")
case "$cache/" in "$binary_directory/"*) fail RIPWIRE_WSL_CACHE_INSTALL_OVERLAP ;; esac
case "$binary_directory/" in "$cache/"*) fail RIPWIRE_WSL_CACHE_INSTALL_OVERLAP ;; esac
usage=$(du -s -B1 -- "$cache")
usage=${usage%%$'\t'*}
[[ $usage =~ ^[0-9]+$ ]] || fail RIPWIRE_WSL_INVALID_CACHE_USAGE
printf '{"binaryReady":true,"cacheRootReady":true,"cacheBytes":%s}\n' "$usage"
