#!/bin/bash
#############################################################
# Module : Dashboard - Status
#
# Responsibility
#   Show the operational status of ARE.
#
# Dependencies
#   - database.sh
#   - decay.sh
#   - infrastructure/ipset.sh
#   - backend/firewall.sh
#
# Exports
#   dashboard_status()
#############################################################

dashboard_status() {

    local DB_STATUS="OK"
    local FW4_STATUS="OK"
    local FW6_STATUS="OK"
    local BAN4_STATUS="OK"
    local FILTER4_STATUS="OK"
    local BAN6_STATUS="OK"
    local FILTER6_STATUS="OK"

    local IPS ACTIVE BANNED CANDIDATES

    IPS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM reputation;" 2>/dev/null)
    ACTIVE=$(db_count_active_ips 2>/dev/null)
    BANNED=$(sqlite3 "$DB_FILE" \
        "SELECT COUNT(*) FROM reputation WHERE status='BANNED';" 2>/dev/null)

    [ -z "$IPS" ] && DB_STATUS="ERROR"
    [ -z "$ACTIVE" ] && DB_STATUS="ERROR"
    [ -z "$BANNED" ] && DB_STATUS="ERROR"

    existsSet "$BAN_SET4" || BAN4_STATUS="ERROR"
    existsSet "$FILTER_SET4" || FILTER4_STATUS="ERROR"
    existsSet "$BAN_SET6" || BAN6_STATUS="ERROR"
    existsSet "$FILTER_SET6" || FILTER6_STATUS="ERROR"

    rule_exists_ipv4 INPUT \
        -m set --match-set "$BAN_SET4" src -j DROP \
        || FW4_STATUS="ERROR"

    rule_exists_ipv4 INPUT \
        -m set --match-set "$FILTER_SET4" src -j DROP \
        || FW4_STATUS="ERROR"

    rule_exists_ipv6 INPUT \
        -m set --match-set "$BAN_SET6" src -j DROP \
        || FW6_STATUS="ERROR"

    rule_exists_ipv6 INPUT \
        -m set --match-set "$FILTER_SET6" src -j DROP \
        || FW6_STATUS="ERROR"

    CANDIDATES=$(sqlite3 "$DB_FILE" "
        SELECT COUNT(*)
        FROM reputation
        WHERE total_score > 0
          AND updated IS NOT NULL
          AND (strftime('%s','now') - updated) >= ${DECAY_MIN_AGE:-86400}
          AND (
                last_decay = 0
                OR (strftime('%s','now') - last_decay) >= ${DECAY_MIN_AGE:-86400}
              );
    " 2>/dev/null)

    echo "=================================================="
    echo "ARE - SYSTEM STATUS"
    echo "=================================================="
    echo
    echo "DATABASE"
    echo "  Estado................ $DB_STATUS"
    echo "  IPs totales........... ${IPS:-0}"
    echo "  IPs activas........... ${ACTIVE:-0}"
    echo "  IPs baneadas.......... ${BANNED:-0}"
    echo
    echo "DECAY"
    echo "  Candidatas............ ${CANDIDATES:-0}"
    echo
    echo "FIREWALL"
    echo "  IPv4.................. $FW4_STATUS"
    echo "  IPv6.................. $FW6_STATUS"
    echo
    echo "IPSET"
    echo "  IPv4 BAN.............. $BAN4_STATUS"
    echo "  IPv4 FILTER........... $FILTER4_STATUS"
    echo "  IPv6 BAN.............. $BAN6_STATUS"
    echo "  IPv6 FILTER........... $FILTER6_STATUS"
    echo
    echo "=================================================="
}
