#############################################################
# Module : Dashboard - Events
#
# Responsibility
#   Show reputation information for one IP.
#
# Dependencies
#   - database.sh
#   - logger.sh
#
# Exports
#   dashboard_events()
#############################################################
dashboard_events() {

    local IP="$1"

    if [ -z "$IP" ]; then
        ERROR "Uso: events <IP>"
        return 1
    fi

    db_get_events "$IP"
}
