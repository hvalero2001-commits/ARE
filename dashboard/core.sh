#############################################################
# Module : Dashboard - Core
#
# Responsibility
#   Show reputation information for one IP.
#
# Dependencies
#   - database.sh
#   - logger.sh
#
# Exports
#   calc_threat_level()
#############################################################

calc_threat_level() {
    local TOTAL="$1"

    if [ "$TOTAL" -le 20 ]; then
        echo "LOW"
    elif [ "$TOTAL" -le 60 ]; then
        echo "MEDIUM"
    elif [ "$TOTAL" -le 120 ]; then
        echo "HIGH"
    else
        echo "CRITICAL"
    fi
}
