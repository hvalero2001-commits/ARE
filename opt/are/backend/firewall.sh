#!/bin/bash

#########################################
# Verifica si existe una regla IPv4
#########################################

rule_exists_ipv4() {

    iptables -C "$@" >/dev/null 2>&1

}

#########################################
# Verifica si existe una regla IPv6
#########################################

rule_exists_ipv6() {

    ip6tables -C "$@" >/dev/null 2>&1

}

#########################################
# Inicializar Firewall
#########################################

init_firewall() {

    INFO "Inicializando reglas ARE..."

    #
    # IPv4 - FILTER
    #
    if ! rule_exists_ipv4 INPUT -m set --match-set "$FILTER_SET4" src -j DROP
    then

        iptables -I INPUT \
            -m set --match-set "$FILTER_SET4" src \
            -j DROP

        INFO "Regla IPv4 instalada: $FILTER_SET4"

    fi

    #
    # IPv4 - BLACKLIST
    #
    if ! rule_exists_ipv4 INPUT -m set --match-set "$BAN_SET4" src -j DROP
    then

        iptables -I INPUT \
            -m set --match-set "$BAN_SET4" src \
            -j DROP

        INFO "Regla IPv4 instalada: $BAN_SET4"

    fi

    #
    # IPv6 - FILTER
    #
    if ! rule_exists_ipv6 INPUT -m set --match-set "$FILTER_SET6" src -j DROP
    then

        ip6tables -I INPUT \
            -m set --match-set "$FILTER_SET6" src \
            -j DROP

        INFO "Regla IPv6 instalada: $FILTER_SET6"

    fi

    #
    # IPv6 - BLACKLIST
    #
    if ! rule_exists_ipv6 INPUT -m set --match-set "$BAN_SET6" src -j DROP
    then

        ip6tables -I INPUT \
            -m set --match-set "$BAN_SET6" src \
            -j DROP

        INFO "Regla IPv6 instalada: $BAN_SET6"

    fi

}
