#!/bin/bash

#########################################
# LOGGER
#########################################

LOGTAG="${LOGTAG:-ARE}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"
ARE_LOG_DIR="${ARE_LOG_DIR:-/var/log/are}"
ARE_LOG_FILE="${ARE_LOG_FILE:-$ARE_LOG_DIR/are.log}"

log_date() {
    date '+%Y-%m-%d %H:%M:%S'
}

log_prepare() {

    if [ ! -d "$ARE_LOG_DIR" ]; then
        mkdir -p "$ARE_LOG_DIR" 2>/dev/null || return 1
    fi

    if [ ! -e "$ARE_LOG_FILE" ]; then
        touch "$ARE_LOG_FILE" 2>/dev/null || return 1
    fi
}

log_write() {

    local level="$1"
    shift

    local message="$*"
    local line

    line="[$level] $(log_date) $message"

    log_prepare

    if [ -w "$ARE_LOG_FILE" ]; then
        printf '%s\n' "$line" >> "$ARE_LOG_FILE"
    fi

    printf '%s\n' "$line" >&2
}

DEBUG() {
    [ "${DEBUG:-0}" = "1" ] || return 0
    log_write "DEBUG" "$*"
}

INFO() {
    log_write "INFO " "$*"
}

WARN() {
    log_write "WARN " "$*"
}

ERROR() {
    log_write "ERROR" "$*"
}
