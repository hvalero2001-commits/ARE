#!/bin/bash
state_update() {

    local IP="$1"

    local SCORE
    local STATUS

    SCORE=$(db_get_score "$IP")
    STATUS=$(db_get_status "$IP")

    if [ "$SCORE" -ge 150 ]; then

        [ "$STATUS" != "BANNED" ] && \
            db_set_status "$IP" "BANNED"

        return
    fi

    if [ "$SCORE" -ge 80 ]; then

        [ "$STATUS" != "WATCH" ] && \
            db_set_status "$IP" "WATCH"

        return
    fi

    db_set_status "$IP" "NEW"
}
