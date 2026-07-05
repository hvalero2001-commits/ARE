risk_add_from_event() {

    local EVENT="$1"

    IFS='|' read -ra PARTS <<< "$EVENT"

    local i=0
    local TYPE SCORE

    while [ $i -lt ${#PARTS[@]} ]; do

        TYPE="${PARTS[$i]}"
        SCORE="${PARTS[$i+1]}"

        [ -z "$TYPE" ] && break
        [ -z "$SCORE" ] && break

        case "$TYPE" in
            BOT) risk_add BOT "$SCORE" ;;
            PROTOCOL) risk_add PROTOCOL "$SCORE" ;;
            EXPLOIT) risk_add EXPLOIT "$SCORE" ;;
        esac

        i=$((i+2))

    done
}
