#!/bin/bash

BASE="/opt/f2b-ipset"

# CORE
source "$BASE/logger.sh"
source "$BASE/database.sh"
source "$BASE/decay.sh"
source "/etc/f2b-ipset/policy.conf"

#DASHBOARD
source "$BASE/dashboard.sh"  >/dev/null 2>&1

# CONTEXT
source "$BASE/policy/context.sh"
source "$BASE/policy/context_api.sh"

#TOOL
source "$BASE/net_utils.sh"

# RISK + DECISION
source "$BASE/policy/risk.sh"
source "$BASE/policy/state_engine.sh"
source "$BASE/policy/decision_engine.sh"
source "$BASE/stats/state_manager.sh"

# RULES
source "$BASE/policy/rules/exploit.sh"
source "$BASE/policy/rules/bot.sh"
source "$BASE/policy/rules/bruteforce.sh"
source "$BASE/policy/rules/recon.sh"
source "$BASE/policy/rules/protocol.sh"
source "$BASE/policy/rules/anomaly.sh"

# APPLY
source "$BASE/policy/apply.sh"
source "$BASE/infrastructure/ipset.sh"
source "$BASE/policy/ban_lifecycle.sh"

#BACKEND
source "$BASE/backend/init.sh"
source "$BASE/backend/firewall.sh"

init_backend
