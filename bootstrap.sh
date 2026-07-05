#!/bin/bash

BASE="/opt/f2b-ipset"

# CORE
source "$BASE/logger.sh"
source "$BASE/database.sh"

#DASHBOARD
source "$BASE/dashboard.sh"  >/dev/null 2>&1

# CONTEXT
source "$BASE/policy_context.sh"
source "$BASE/policy_context_api.sh"

#TOOL
source "$BASE/net_utils.sh"

# RISK + DECISION
source "$BASE/policy_risk.sh"
source "$BASE/policy/state_engine.sh"
source "$BASE/policy_decision_engine.sh"
source "$BASE/stats/state_manager.sh"

# RULES
source "$BASE/policy_rules/exploit.sh"
source "$BASE/policy_rules/bot.sh"
source "$BASE/policy_rules/bruteforce.sh"
source "$BASE/policy_rules/recon.sh"
source "$BASE/policy_rules/protocol.sh"

# APPLY
source "$BASE/policy_apply.sh"
source "$BASE/infrastructure/ipset.sh"

#BACKEND
source "$BASE/backend/init.sh"
source "$BASE/backend/firewall.sh"

init_backend
init_ipsets
