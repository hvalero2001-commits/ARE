install_firewall_rules(){

    iptables -C INPUT -m set --match-set "$BAN_SET4" src -j DROP 2>/dev/null \
        || iptables -I INPUT 1 -m set --match-set "$BAN_SET4" src -j DROP

    iptables -C INPUT -m set --match-set "$FILTER_SET4" src -j DROP 2>/dev/null \
        || iptables -I INPUT 2 -m set --match-set "$FILTER_SET4" src -j DROP

    ip6tables -C INPUT -m set --match-set "$BAN_SET6" src -j DROP 2>/dev/null \
        || ip6tables -I INPUT 1 -m set --match-set "$BAN_SET6" src -j DROP

    ip6tables -C INPUT -m set --match-set "$FILTER_SET6" src -j DROP 2>/dev/null \
        || ip6tables -I INPUT 2 -m set --match-set "$FILTER_SET6" src -j DROP
}
