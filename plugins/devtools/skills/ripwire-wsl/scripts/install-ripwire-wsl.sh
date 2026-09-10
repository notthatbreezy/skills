#!/usr/bin/env bash
set -u

fail() {
    printf '%s\n' "$1" >&2
    exit "${2:-70}"
}

require_tool() {
    command -v "$1" >/dev/null 2>&1 || fail "RIPWIRE_WSL_LINUX_TOOL_MISSING: $1" 69
}

reject_symlink_components() {
    local path="$1" current='/'
    IFS='/' read -r -a parts <<<"${path#/}"
    for part in "${parts[@]}"; do
        [[ -z "$part" ]] && continue
        current="${current%/}/$part"
        [[ -L "$current" ]] && fail "RIPWIRE_WSL_PATH_SYMLINK: $current"
        [[ -e "$current" ]] || break
    done
}

validate_owned_directory() {
    local path="$1" label="$2" mode owner fs
    [[ "$path" == /* && "$path" != / ]] || fail "RIPWIRE_WSL_INVALID_${label}: absolute Linux path required"
    reject_symlink_components "$path"
    if [[ -e "$path" ]]; then
        [[ -d "$path" && ! -L "$path" ]] || fail "RIPWIRE_WSL_INVALID_${label}: not a real directory"
        owner="$(stat -c '%u' -- "$path")" || fail "RIPWIRE_WSL_${label}_STAT_FAILED"
        [[ "$owner" == "$(id -u)" ]] || fail "RIPWIRE_WSL_${label}_OWNER_MISMATCH"
        mode="$(stat -c '%a' -- "$path")" || fail "RIPWIRE_WSL_${label}_STAT_FAILED"
        (( (8#$mode & 077) == 0 )) || fail "RIPWIRE_WSL_${label}_PERMISSIONS"
    fi
    local existing="$path"
    while [[ ! -e "$existing" ]]; do existing="${existing%/*}"; [[ -n "$existing" ]] || existing='/'; done
    fs="$(stat -f -c '%T' -- "$existing")" || fail "RIPWIRE_WSL_${label}_FILESYSTEM_UNKNOWN"
    case "$fs" in
        ext2/ext3|tmpfs|btrfs|xfs) ;;
        *) fail "RIPWIRE_WSL_${label}_UNSUPPORTED_FILESYSTEM: $fs" ;;
    esac
}

paths_overlap() {
    [[ "$1" == "$2" || "$1" == "$2/"* || "$2" == "$1/"* ]]
}

probe() {
    require_tool bash
    require_tool git
    require_tool tar
    require_tool flock
    for tool in uname id stat readlink realpath mkdir mv rm chmod sed du find; do require_tool "$tool"; done
    local install_root='' cache_root='' version='v0.5.0'
    while (($#)); do
        case "$1" in
            --install-root) install_root="$2"; shift 2 ;;
            --cache-root) cache_root="$2"; shift 2 ;;
            --version) version="$2"; shift 2 ;;
            *) fail "RIPWIRE_WSL_SETUP_INVALID_ARGUMENT: $1" 64 ;;
        esac
    done
    [[ -r /etc/os-release ]] || fail 'RIPWIRE_WSL_OS_RELEASE_MISSING' 69
    # shellcheck disable=SC1091
    . /etc/os-release
    install_root="${install_root:-$HOME/.local/share/brownch-devtools/ripwire-wsl}"
    cache_root="${cache_root:-$HOME/.cache/brownch-devtools/ripwire-wsl}"
    [[ "$install_root" == /* && "$cache_root" == /* ]] ||
        fail 'RIPWIRE_WSL_SETUP_PATH_NOT_ABSOLUTE' 69
    reject_symlink_components "$install_root"
    reject_symlink_components "$cache_root"
    install_root="$(realpath -m -- "$install_root")"
    cache_root="$(realpath -m -- "$cache_root")"
    paths_overlap "$install_root" "$cache_root" &&
        fail 'RIPWIRE_WSL_CACHE_INSTALL_OVERLAP' 69
    validate_owned_directory "$install_root" INSTALL_ROOT
    validate_owned_directory "$cache_root" CACHE_ROOT
    [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'RIPWIRE_WSL_SETUP_INVALID_VERSION' 64
    local machine
    machine="$(uname -m)"
    printf 'DISTRO_ID=%s\n' "${ID:-}"
    printf 'DISTRO_VERSION=%s\n' "${VERSION_ID:-}"
    printf 'MACHINE=%s\n' "$machine"
    printf 'HOME=%s\n' "$HOME"
    printf 'INSTALL_ROOT=%s\n' "$install_root"
    printf 'CACHE_ROOT=%s\n' "$cache_root"
    printf 'BINARY_PATH=%s/%s/bin/ripwire\n' "$install_root" "$version"
}

validate_archive() {
    local archive="$1" archive_root="$2" payload="$3"
    shift 3
    local entry normalized line payload_count=0 root_count=0
    local mode='' value=''
    local -a archive_files=() archive_directories=()
    local -A file_seen=() directory_seen=()
    while (($#)); do
        case "$1" in
            --archive-file) mode='file'; value="$2"; shift 2 ;;
            --archive-directory) mode='directory'; value="$2"; shift 2 ;;
            *) fail "RIPWIRE_WSL_SETUP_INVALID_ARCHIVE_DECLARATION: $1" 64 ;;
        esac
        [[ "$value" =~ ^[A-Za-z0-9._+-]+$ && "$value" != '.' && "$value" != '..' ]] ||
            fail "RIPWIRE_WSL_SETUP_INVALID_ARCHIVE_DECLARATION: $value" 64
        if [[ "$mode" == file ]]; then
            [[ -z "${file_seen[$value]+x}" && -z "${directory_seen[$value]+x}" ]] ||
                fail "RIPWIRE_WSL_SETUP_DUPLICATE_ARCHIVE_DECLARATION: $value" 64
            file_seen["$value"]=0
            archive_files+=("$value")
        else
            [[ -z "${file_seen[$value]+x}" && -z "${directory_seen[$value]+x}" ]] ||
                fail "RIPWIRE_WSL_SETUP_DUPLICATE_ARCHIVE_DECLARATION: $value" 64
            directory_seen["$value"]=0
            archive_directories+=("$value")
        fi
    done
    [[ "${#archive_files[@]}" -gt 0 ]] || fail 'RIPWIRE_WSL_SETUP_ARCHIVE_FILES_MISSING' 64
    local listing verbose
    listing="$(tar --quoting-style=escape -tzf "$archive")" ||
        fail 'RIPWIRE_WSL_ARCHIVE_LIST_FAILED'
    while IFS= read -r entry; do
        [[ -n "$entry" ]] || fail 'RIPWIRE_WSL_ARCHIVE_EMPTY_ENTRY'
        [[ "$entry" =~ ^[A-Za-z0-9._/+:-]+$ ]] ||
            fail "RIPWIRE_WSL_ARCHIVE_UNSAFE_NAME: $entry"
        [[ "$entry" != /* && "$entry" != *\\* ]] ||
            fail "RIPWIRE_WSL_ARCHIVE_UNSAFE_PATH: $entry"
        normalized="${entry%/}"
        if [[ "$normalized" == "$archive_root" ]]; then
            ((root_count+=1))
            continue
        fi
        IFS='/' read -r -a components <<<"$normalized"
        [[ "${components[0]}" == "$archive_root" ]] ||
            fail "RIPWIRE_WSL_ARCHIVE_UNEXPECTED_ROOT: $entry"
        for component in "${components[@]}"; do
            [[ "$component" != '..' && "$component" != '.' && -n "$component" ]] ||
                fail "RIPWIRE_WSL_ARCHIVE_TRAVERSAL: $entry"
        done
        [[ "${#components[@]}" -ge 2 ]] || fail "RIPWIRE_WSL_ARCHIVE_UNEXPECTED_LAYOUT: $entry"
        local top="${components[1]}" allowed=0
        if [[ "${#components[@]}" -eq 2 && -n "${file_seen[$top]+x}" ]]; then
            file_seen["$top"]=$((file_seen["$top"] + 1))
            allowed=1
        elif [[ -n "${directory_seen[$top]+x}" ]]; then
            if [[ "${#components[@]}" -eq 2 ]]; then
                directory_seen["$top"]=$((directory_seen["$top"] + 1))
            fi
            allowed=1
        fi
        ((allowed)) || fail "RIPWIRE_WSL_ARCHIVE_UNEXPECTED_ENTRY: $entry"
        [[ "$normalized" == "$payload" ]] && ((payload_count+=1))
    done <<<"$listing"
    [[ "$root_count" -eq 1 ]] || fail 'RIPWIRE_WSL_ARCHIVE_ROOT_COUNT'
    [[ "$payload_count" -eq 1 ]] || fail 'RIPWIRE_WSL_ARCHIVE_PAYLOAD_COUNT'
    for value in "${archive_files[@]}"; do
        [[ "${file_seen[$value]}" -eq 1 ]] || fail "RIPWIRE_WSL_ARCHIVE_EXPECTED_FILE_COUNT: $value"
    done
    for value in "${archive_directories[@]}"; do
        [[ "${directory_seen[$value]}" -eq 1 ]] || fail "RIPWIRE_WSL_ARCHIVE_EXPECTED_DIRECTORY_COUNT: $value"
    done
    verbose="$(tar --quoting-style=escape --numeric-owner -tvzf "$archive")" ||
        fail 'RIPWIRE_WSL_ARCHIVE_VERBOSE_LIST_FAILED'
    local payload_metadata='' payload_metadata_count=0
    while IFS= read -r line; do
        [[ "${line:0:1}" == '-' || "${line:0:1}" == 'd' ]] ||
            fail "RIPWIRE_WSL_ARCHIVE_UNSAFE_TYPE: $line"
        entry="${line##* }"
        normalized="${entry%/}"
        if [[ "$normalized" == "$archive_root" ]]; then
            [[ "${line:0:1}" == 'd' ]] || fail 'RIPWIRE_WSL_ARCHIVE_ROOT_NOT_DIRECTORY'
            continue
        fi
        IFS='/' read -r -a components <<<"$normalized"
        local top="${components[1]}"
        if [[ "${#components[@]}" -eq 2 && -n "${file_seen[$top]+x}" ]]; then
            [[ "${line:0:1}" == '-' ]] || fail "RIPWIRE_WSL_ARCHIVE_EXPECTED_FILE_TYPE: $top"
        elif [[ "${#components[@]}" -eq 2 && -n "${directory_seen[$top]+x}" ]]; then
            [[ "${line:0:1}" == 'd' ]] || fail "RIPWIRE_WSL_ARCHIVE_EXPECTED_DIRECTORY_TYPE: $top"
        fi
        if [[ "$normalized" == "$payload" ]]; then
            payload_metadata="$line"
            ((payload_metadata_count+=1))
        fi
    done <<<"$verbose"
    [[ "$payload_metadata_count" -eq 1 ]] || fail 'RIPWIRE_WSL_ARCHIVE_PAYLOAD_METADATA'
    local permissions="${payload_metadata%% *}"
    [[ "${permissions:0:1}" == '-' && "${permissions:3:1}" == 'x' ]] ||
        fail 'RIPWIRE_WSL_ARCHIVE_PAYLOAD_NOT_EXECUTABLE'
}

transaction() {
    local archive='' archive_root='' payload='' version='' install_root='' cache_root=''
    local -a archive_declarations=()
    local config='' config_stage='' config_backup='' transaction_id=''
    while (($#)); do
        case "$1" in
            --archive) archive="$2"; shift 2 ;;
            --archive-root) archive_root="$2"; shift 2 ;;
            --archive-file|--archive-directory)
                archive_declarations+=("$1" "$2"); shift 2 ;;
            --payload) payload="$2"; shift 2 ;;
            --version) version="$2"; shift 2 ;;
            --install-root) install_root="$2"; shift 2 ;;
            --cache-root) cache_root="$2"; shift 2 ;;
            --config) config="$2"; shift 2 ;;
            --config-stage) config_stage="$2"; shift 2 ;;
            --config-backup) config_backup="$2"; shift 2 ;;
            --transaction-id) transaction_id="$2"; shift 2 ;;
            *) fail "RIPWIRE_WSL_SETUP_INVALID_ARGUMENT: $1" 64 ;;
        esac
    done
    [[ -n "$archive" && -n "$archive_root" && -n "$payload" && "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
        fail 'RIPWIRE_WSL_SETUP_INVALID_TRANSACTION'
    [[ "$transaction_id" =~ ^[0-9a-f]{32}$ ]] || fail 'RIPWIRE_WSL_SETUP_INVALID_TRANSACTION_ID'
    validate_owned_directory "$install_root" INSTALL_ROOT
    validate_owned_directory "$cache_root" CACHE_ROOT
    paths_overlap "$install_root" "$cache_root" && fail 'RIPWIRE_WSL_CACHE_INSTALL_OVERLAP'
    reject_symlink_components "$config"
    reject_symlink_components "$config_stage"
    reject_symlink_components "$config_backup"
    [[ "${config%/*}" == "${config_stage%/*}" && "${config%/*}" == "${config_backup%/*}" ]] ||
        fail 'RIPWIRE_WSL_CONFIG_TRANSACTION_NOT_SIBLINGS'
    [[ -f "$config_stage" && ! -L "$config_stage" ]] || fail 'RIPWIRE_WSL_CONFIG_STAGE_INVALID'
    validate_archive "$archive" "$archive_root" "$payload" "${archive_declarations[@]}"

    umask 077
    mkdir -p -- "$install_root" "$cache_root" || fail 'RIPWIRE_WSL_SETUP_DIRECTORY_CREATE_FAILED'
    chmod 700 -- "$install_root" "$cache_root" || fail 'RIPWIRE_WSL_SETUP_DIRECTORY_MODE_FAILED'
    validate_owned_directory "$install_root" INSTALL_ROOT
    validate_owned_directory "$cache_root" CACHE_ROOT
    local lock="$install_root/.install.lock"
    [[ ! -L "$lock" ]] || fail 'RIPWIRE_WSL_INSTALL_LOCK_SYMLINK'
    exec 9>>"$lock" || fail 'RIPWIRE_WSL_INSTALL_LOCK_OPEN_FAILED'
    chmod 600 -- "$lock" || fail 'RIPWIRE_WSL_INSTALL_LOCK_MODE_FAILED'
    flock -w 30 9 || fail 'RIPWIRE_WSL_INSTALL_LOCK_TIMEOUT' 75

    local bin_parent="$install_root/$version/bin" destination stage backup displaced
    bin_parent="$install_root/$version/bin"
    destination="$bin_parent/ripwire"
    stage="$bin_parent/.ripwire.stage.$transaction_id"
    backup="$bin_parent/.ripwire.backup.$transaction_id"
    displaced="$bin_parent/.ripwire.failed.$transaction_id"
    reject_symlink_components "$bin_parent"
    mkdir -p -- "$bin_parent" || fail 'RIPWIRE_WSL_INSTALL_DIRECTORY_CREATE_FAILED'
    chmod 700 -- "$install_root/$version" "$bin_parent" || fail 'RIPWIRE_WSL_INSTALL_DIRECTORY_MODE_FAILED'
    validate_owned_directory "$install_root/$version" INSTALL_VERSION
    validate_owned_directory "$bin_parent" INSTALL_BIN
    [[ ! -e "$stage" && ! -e "$backup" && ! -e "$displaced" && ! -e "$config_backup" ]] ||
        fail 'RIPWIRE_WSL_TRANSACTION_PATH_EXISTS'
    abort_before_swap() {
        local code="$1" detail="${2:-}" cleanup=''
        if [[ -e "$stage" ]] && ! rm -f -- "$stage"; then cleanup='stage-cleanup'; fi
        printf 'ROLLBACK=NotRequired\n'
        printf 'ROLLBACK_ERRORS=\n'
        printf 'CLEANUP_ERRORS=%s\n' "$cleanup"
        fail "$code${detail:+: $detail}"
    }
    tar -xOzf "$archive" -- "$payload" >"$stage" || {
        abort_before_swap 'RIPWIRE_WSL_ARCHIVE_EXTRACT_FAILED'
    }
    chmod 700 -- "$stage" || abort_before_swap 'RIPWIRE_WSL_STAGE_CHMOD_FAILED'
    [[ -f "$stage" && ! -L "$stage" && -x "$stage" ]] ||
        abort_before_swap 'RIPWIRE_WSL_STAGE_INVALID'
    local expected="${version#v}" health
    health="$("$stage" --version 2>&1)" ||
        abort_before_swap 'RIPWIRE_WSL_STAGE_HEALTH_FAILED' "$health"
    case "$health" in
        "ripwire $expected"|"ripwire $expected "*) ;;
        *) abort_before_swap 'RIPWIRE_WSL_STAGE_VERSION_MISMATCH' "$health" ;;
    esac

    local had_binary=0 had_config=0 config_backed=0
    local rollback_errors=() cleanup_errors=()
    if [[ -e "$destination" ]]; then
        [[ -f "$destination" && ! -L "$destination" ]] ||
            abort_before_swap 'RIPWIRE_WSL_EXISTING_BINARY_INVALID'
        mv -- "$destination" "$backup" ||
            abort_before_swap 'RIPWIRE_WSL_BINARY_BACKUP_RENAME_FAILED'
        had_binary=1
    fi
    if ! mv -- "$stage" "$destination"; then
        if ((had_binary)) && ! mv -- "$backup" "$destination"; then
            rollback_errors+=('binary-backup-restore-after-swap')
        fi
        if [[ -e "$stage" ]] && ! rm -f -- "$stage"; then cleanup_errors+=('stage-cleanup'); fi
        printf 'ROLLBACK=%s\n' "$((${#rollback_errors[@]} == 0))" | sed 's/1/Succeeded/;s/0/Failed/'
        printf 'ROLLBACK_ERRORS=%s\n' "$(IFS='|'; echo "${rollback_errors[*]}")"
        printf 'CLEANUP_ERRORS=%s\n' "$(IFS='|'; echo "${cleanup_errors[*]}")"
        fail 'RIPWIRE_WSL_BINARY_SWAP_RENAME_FAILED'
    fi
    local post_health_failed=0
    health="$("$destination" --version 2>&1)" || post_health_failed=1
    case "$health" in
        "ripwire $expected"|"ripwire $expected "*) ;;
        *) post_health_failed=1 ;;
    esac
    if ((post_health_failed)); then
        mv -- "$destination" "$displaced" || rollback_errors+=('new-binary-displace')
        if ((had_binary)); then mv -- "$backup" "$destination" || rollback_errors+=('binary-backup-restore'); fi
        rm -f -- "$displaced" || cleanup_errors+=('failed-binary-cleanup')
        printf 'ROLLBACK=%s\n' "$((${#rollback_errors[@]} == 0))" | sed 's/1/Succeeded/;s/0/Failed/'
        printf 'ROLLBACK_ERRORS=%s\n' "$(IFS='|'; echo "${rollback_errors[*]}")"
        printf 'CLEANUP_ERRORS=%s\n' "$(IFS='|'; echo "${cleanup_errors[*]}")"
        fail 'RIPWIRE_WSL_POST_SWAP_HEALTH_FAILED'
    fi
    if [[ -e "$config" ]]; then
        if [[ ! -f "$config" || -L "$config" ]]; then
            mv -- "$destination" "$displaced" || rollback_errors+=('new-binary-displace')
            if ((had_binary)); then mv -- "$backup" "$destination" || rollback_errors+=('binary-backup-restore'); fi
            rm -f -- "$displaced" || cleanup_errors+=('failed-binary-cleanup')
            printf 'ROLLBACK=%s\n' "$((${#rollback_errors[@]} == 0))" | sed 's/1/Succeeded/;s/0/Failed/'
            printf 'ROLLBACK_ERRORS=%s\n' "$(IFS='|'; echo "${rollback_errors[*]}")"
            printf 'CLEANUP_ERRORS=%s\n' "$(IFS='|'; echo "${cleanup_errors[*]}")"
            fail 'RIPWIRE_WSL_EXISTING_CONFIG_INVALID'
        fi
        if ! mv -- "$config" "$config_backup"; then
            mv -- "$destination" "$displaced" || rollback_errors+=('new-binary-displace')
            if ((had_binary)); then mv -- "$backup" "$destination" || rollback_errors+=('binary-backup-restore'); fi
            rm -f -- "$displaced" || cleanup_errors+=('failed-binary-cleanup')
            printf 'ROLLBACK=%s\n' "$((${#rollback_errors[@]} == 0))" | sed 's/1/Succeeded/;s/0/Failed/'
            printf 'ROLLBACK_ERRORS=%s\n' "$(IFS='|'; echo "${rollback_errors[*]}")"
            printf 'CLEANUP_ERRORS=%s\n' "$(IFS='|'; echo "${cleanup_errors[*]}")"
            fail 'RIPWIRE_WSL_CONFIG_BACKUP_RENAME_FAILED'
        fi
        had_config=1
        config_backed=1
    fi
    if ! mv -- "$config_stage" "$config"; then
        if ((config_backed)); then mv -- "$config_backup" "$config" || rollback_errors+=('config-backup-restore'); fi
        mv -- "$destination" "$displaced" || rollback_errors+=('new-binary-displace')
        if ((had_binary)); then mv -- "$backup" "$destination" || rollback_errors+=('binary-backup-restore'); fi
        rm -f -- "$displaced" || cleanup_errors+=('failed-binary-cleanup')
        printf 'ROLLBACK=%s\n' "$((${#rollback_errors[@]} == 0))" | sed 's/1/Succeeded/;s/0/Failed/'
        printf 'ROLLBACK_ERRORS=%s\n' "$(IFS='|'; echo "${rollback_errors[*]}")"
        printf 'CLEANUP_ERRORS=%s\n' "$(IFS='|'; echo "${cleanup_errors[*]}")"
        fail 'RIPWIRE_WSL_CONFIG_COMMIT_RENAME_FAILED'
    fi
    if ((had_binary)); then rm -f -- "$backup" || cleanup_errors+=('binary-backup-cleanup'); fi
    if ((had_config)); then rm -f -- "$config_backup" || cleanup_errors+=('config-backup-cleanup'); fi
    rm -f -- "$stage" "$displaced" || cleanup_errors+=('transaction-artifact-cleanup')
    printf 'ROLLBACK=NotRequired\n'
    printf 'ROLLBACK_ERRORS=\n'
    printf 'CLEANUP_ERRORS=%s\n' "$(IFS='|'; echo "${cleanup_errors[*]}")"
    printf 'BINARY_PATH=%s\n' "$destination"
}

case "${1:-}" in
    probe) shift; probe "$@" ;;
    transaction) shift; transaction "$@" ;;
    *) fail 'RIPWIRE_WSL_SETUP_USAGE' 64 ;;
esac
