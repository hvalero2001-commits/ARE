state_get() {

    local IP="$1"

    db_get_status "$IP"
}

state_set() {

    local IP="$1"
    local NEW_STATE="$2"

    local CURRENT_STATE

    CURRENT_STATE=$(state_get "$IP")

    if ! state_can_transition "$CURRENT_STATE" "$NEW_STATE"; then
        return 1
    fi

    db_set_status "$IP" "$NEW_STATE"

    return $?
}
