#!/bin/bash

state_update() {

    local IP="$1"

    local SCORE
    SCORE=$(db_get_score "$IP")

    if [ "$SCORE" -ge 80 ]; then
        db_set_status "$IP" "BANNED"
        return
    fi

    if [ "$SCORE" -ge 50 ]; then
        db_set_status "$IP" "WATCH"
        return
    fi

    if [ "$SCORE" -ge 20 ]; then
        db_set_status "$IP" "FILTER"
        return
    fi

    if [ "$SCORE" -gt 0 ]; then
        db_set_status "$IP" "WATCH"
        return
    fi

    db_set_status "$IP" "NEW"
}
