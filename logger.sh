#!/bin/bash

#########################################
# LOGGER
#########################################

LOGTAG=${LOGTAG:-F2B-IPSET}
LOG_LEVEL=${LOG_LEVEL:-INFO}

log_date() {
    date '+%Y-%m-%d %H:%M:%S'
}

DEBUG() {
    [ "$DEBUG" = "1" ] || return 0
    logger -t "$LOGTAG" "[DEBUG] $1"
    echo "[DEBUG] $(log_date) $1" >&2
}


INFO() {
    logger -t "$LOGTAG" "[INFO] $1"
    echo "[INFO ] $(log_date) $1" >&2
}

WARN() {
    logger -t "$LOGTAG" "[WARN] $1"
    echo "[WARN ] $(log_date) $1" >&2
}

ERROR() {
    logger -t "$LOGTAG" "[ERROR] $1"
    echo "[ERROR] $(log_date) $1" >&2
}
