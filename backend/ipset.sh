backend_create_sets() {

    createSet "$FILTER_SET4" inet
    createSet "$BAN_SET4" inet

    createSet "$FILTER_SET6" inet6
    createSet "$BAN_SET6" inet6

}

backend_install_ipv4() {

    iptables -C INPUT \
        -m set --match-set "$BAN_SET4" src \
        -j DROP 2>/dev/null ||
    iptables -I INPUT \
        -m set --match-set "$BAN_SET4" src \
        -j DROP

    iptables -C INPUT \
        -m set --match-set "$FILTER_SET4" src \
        -j DROP 2>/dev/null ||
    iptables -I INPUT \
        -m set --match-set "$FILTER_SET4" src \
        -j DROP

}

backend_install_ipv6() {

    ip6tables -C INPUT \
        -m set --match-set "$BAN_SET6" src \
        -j DROP 2>/dev/null ||
    ip6tables -I INPUT \
        -m set --match-set "$BAN_SET6" src \
        -j DROP

    ip6tables -C INPUT \
        -m set --match-set "$FILTER_SET6" src \
        -j DROP 2>/dev/null ||
    ip6tables -I INPUT \
        -m set --match-set "$FILTER_SET6" src \
        -j DROP

}
