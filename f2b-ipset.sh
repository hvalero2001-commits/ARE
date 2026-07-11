#!/bin/bash
#########################################################################
#
#  F2B-IPSET
#
#  Version : 1.1
#
#########################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/config.conf"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Configuración no encontrada: $CONFIG"
    exit 1
fi

source "$CONFIG"

BASE="$ARE_HOME"

##############################################

# Cargar configuración

##############################################

if [ ! -f "$CONFIG" ]
then
    echo "No existe $CONFIG"
    exit 1
fi

source "$CONFIG"

##############################################

# Cargar módulos

##############################################

source "$BASE/bootstrap.sh"

##############################################
# Inicializar Base de Datos
##############################################

db_init

##############################################
# Parámetros
##############################################

ACTION="$1"
IP="$2"
JAIL="$3"
PORT="$4"
PROTO="$5"

handle_found() {

    local ip="$IP"
    local jail="$JAIL"

    INFO "FOUND recibido: $ip desde $jail"

    db_init_reputation "$ip"

    local profile
    profile=$(db_get_jail_profile "$jail")

    if [ -z "$profile" ]; then
        WARN "Jail desconocido: $jail"
        return
    fi

    local weight confidence category

    weight=$(echo "$profile" | cut -d'|' -f1)
    confidence=$(echo "$profile" | cut -d'|' -f2)
    category=$(echo "$profile" | cut -d'|' -f3)

    local score
    score=$(printf "%.0f" "$(echo "$weight * $confidence * 0.25" | bc -l)")

    if [ "$score" -lt 1 ]; then
        score=1
    fi

    db_add_score "$ip" "$category" "$score"
    db_recalculate_total "$ip"

    INFO "Score FOUND aplicado: $score a $ip"

    state_update "$ip"

    TOTAL=$(db_get_score "$ip")
    STATUS=$(db_get_status "$ip")

    DECISION=$(policy_decide "$TOTAL" "$STATUS")

    ACTION=$(echo "$DECISION" | cut -d'|' -f1)
    REASON=$(echo "$DECISION" | cut -d'|' -f3)

    INFO "Policy decision: $ACTION ($REASON)"

    apply_decision "$ip" "$DECISION"

    db_add_event "$ip" "FOUND" "$jail" "0"
}

##############################################
# Acción
##############################################
handle_unban() {

    local ip="$IP"

    INFO "UNBAN solicitado para $ip"

    local ban_set
    local filter_set

    if [[ "$ip" == *:* ]]; then
        ban_set="$BAN_SET6"
        filter_set="$FILTER_SET6"
    else
        ban_set="$BAN_SET4"
        filter_set="$FILTER_SET4"
    fi

    unbanIP "$ban_set" "$ip"
    unbanIP "$filter_set" "$ip"

    db_add_event "$ip" "UNBAN" "fail2ban" "0"

    INFO "UNBAN aplicado a $ip"

}

handle_external_unban() {

    local ip="$IP"
    local jail="$JAIL"

    [ -z "$jail" ] && jail="fail2ban"

    INFO "UNBAN externo recibido para $ip desde $jail"

    db_init_reputation "$ip"

    db_add_event "$ip" "EXTERNAL_UNBAN" "$jail" "0"

    state_update "$ip"

    local total status decision action reason

    total=$(db_get_score "$ip")
    status=$(db_get_status "$ip")

    decision=$(policy_decide "$total" "$status")

    action=$(echo "$decision" | cut -d'|' -f1)
    reason=$(echo "$decision" | cut -d'|' -f3)

    INFO "Policy decision after external unban: $action ($reason)"

    apply_decision "$ip" "$decision"
}

handle_ban() {

    local ip="$IP"
    local jail="$JAIL"

    INFO "Evento recibido: $ip desde $jail"

    db_init_reputation "$ip"

    local profile
    profile=$(db_get_jail_profile "$jail")

    if [ -z "$profile" ]; then
        WARN "Jail desconocido: $jail"
        return
    fi

    local weight confidence category

    weight=$(echo "$profile" | cut -d'|' -f1)
    confidence=$(echo "$profile" | cut -d'|' -f2)
    category=$(echo "$profile" | cut -d'|' -f3)

    local score
    score=$(printf "%.0f" "$(echo "$weight * $confidence" | bc -l)")

    db_add_score "$ip" "$category" "$score"
    db_recalculate_total "$ip"

    INFO "Score aplicado: $score a $ip"

    state_update "$ip"

    SCORE=$(db_get_score "$ip")

    #############################################
    #DEBUG
    #############################################
    [ "$DEBUG" = "1" ] && echo "INFO: TOTAL SCORE =] '$SCORE'"
    [ "$DEBUG" = "1" ] && STATE=$(db_get_status "$ip")
    [ "$DEBUG" = "1" ] && echo "[INFO =] '$STATE'"
    #############################################

    state_update "$ip"

    TOTAL=$(db_get_score "$ip")
    STATUS=$(db_get_status "$ip")

    DECISION=$(policy_decide "$TOTAL" "$STATUS")

    ACTION=$(echo "$DECISION" | cut -d'|' -f1)
    TIMEOUT=$(echo "$DECISION" | cut -d'|' -f2)
    REASON=$(echo "$DECISION" | cut -d'|' -f3)

    INFO "Policy decision: $ACTION ($REASON)"

    apply_decision "$ip" "$DECISION"

    db_add_event "$ip" "BAN" "$jail" "0"

}

handle_sanction_test() {

    local ip="$IP"

    INFO "Prueba controlada de sanction_state para $ip"

    db_init_sanction "$ip"
    db_increment_ban_level "$ip" "$BAN_LEVEL_MAX"

    local level
    level=$(db_get_ban_level "$ip")

    INFO "Nivel de sanción actual: $level"
}

handle_ban_lifecycle_test() {

    local ip="$IP"
    local decision

    decision=$(ban_lifecycle_calculate "$ip")

    INFO "Ban Lifecycle decision: $decision"
}

handle_sanction_apply_test() {

    local ip="$IP"

    INFO "Prueba integrada de escalado permanente para $ip"

    apply_decision "$ip" "TEMP_BAN|0|SANCTION_TEST"
}

case "$ACTION" in
stats)
    dashboard_stats
;;
test)
    db_info
;;
top)
    dashboard_top
;;
external-unban)
    handle_external_unban
;;
autoban)
    auto_enforce_ban
;;
ban)
    handle_ban
;;
unban)
    handle_unban
;;
found)
    handle_found
;;
score)
    dashboard_score "$IP"
;;
events)
    dashboard_events "$IP"
;;
decay-dry-run)
    reputation_decay_dry_run
;;
decay-apply)
    reputation_decay_apply
;;
sanction-test)
    handle_sanction_test
;;
ban-lifecycle-test)
    handle_ban_lifecycle_test
;;
sanction-apply-test)
    handle_sanction_apply_test
;;
*)
    ERROR "Acción desconocida: $ACTION"
    exit 1
;;
esac

exit 0
