#!/bin/bash

is_whitelisted() {

    local IP="$1"

    [ -z "$IP" ] && return 1
    [ -r "$WHITELIST" ] || return 1

    grep -Fqx -- "$IP" "$WHITELIST"
}
