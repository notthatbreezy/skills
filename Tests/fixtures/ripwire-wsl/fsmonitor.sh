#!/bin/sh
set -eu
: > "$GIT_WORK_TREE/../fsmonitor-fired"
printf 'probe-token\000'
