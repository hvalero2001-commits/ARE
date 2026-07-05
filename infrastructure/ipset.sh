#!/bin/bash


existsSet(){

    local SET="$1"

    ipset list "$SET" >/dev/null 2>&1

}

init_ipsets(){

    createSet "$FILTER_SET4" inet
    createSet "$BAN_SET4" inet

    createSet "$FILTER_SET6" inet6
    createSet "$BAN_SET6" inet6

}

#########################################
# Crear IPSET
#########################################
createSet() {

    local SET="$1"
    local FAMILY="$2"

    if existsSet "$SET"; then
        return 0
    fi

    ipset create "$SET" hash:ip family "$FAMILY" timeout 0

    INFO "IPSET creado: $SET"

}

#########################################
# Ban
#########################################

banIP(){

SET="$1"
IP="$2"
TIME="$3"

ipset add "$SET" "$IP" timeout "$TIME" -exist

INFO "BAN $IP ($TIME)"

}

#########################################
# Unban
#########################################

unbanIP(){

SET="$1"
IP="$2"

ipset del "$SET" "$IP" -exist

INFO "UNBAN $IP"

}

existsSet() {

    local SET="$1"

    ipset list "$SET" >/dev/null 2>&1

}

init_ipsets() {

    INFO "Inicializando conjuntos ARE..."

    createSet "$FILTER_SET4" inet
    createSet "$BAN_SET4" inet

    createSet "$FILTER_SET6" inet6
    createSet "$BAN_SET6" inet6

}
