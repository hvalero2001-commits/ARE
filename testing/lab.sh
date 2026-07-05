#!/bin/bash
#############################################################
# ARE - Test Laboratory
#
# Responsable:
#   Administrar el laboratorio de pruebas de ARE.
#
# No modifica políticas.
# No calcula riesgo.
# No toma decisiones.
#
# Exclusivo para desarrollo.
#############################################################

#############################################################
# LAB IP CONSTANTS
#############################################################

LAB_STATE="198.18.0.10"
LAB_RISK="198.18.0.20"
LAB_DECISION="198.18.0.30"
LAB_APPLY="198.18.0.40"
LAB_POLICY="198.18.0.50"
LAB_DASHBOARD="198.18.0.60"
LAB_INTEGRATION="198.18.0.70"
LAB_END2END="198.18.0.80"
LAB_STRESS="198.18.0.90"
LAB_FREE="198.18.0.99"

#############################################################
# LAB FUNCTIONS
#############################################################

lab_info() {

    echo "=================================================="
    echo "ARE TEST LAB"
    echo "=================================================="
    echo ""
    echo "$LAB_STATE    State Manager"
    echo "$LAB_RISK     Risk Engine"
    echo "$LAB_DECISION Decision Engine"
    echo "$LAB_APPLY    Apply Engine"
    echo "$LAB_POLICY   Policy Engine"
    echo "$LAB_DASHBOARD Dashboard"
    echo "$LAB_INTEGRATION Integration"
    echo "$LAB_END2END  End-to-End"
    echo "$LAB_STRESS   Stress"
    echo "$LAB_FREE    Free"
    echo ""
    echo "=================================================="
}

lab_bootstrap() {

    db_init_reputation "$LAB_STATE"
    db_init_reputation "$LAB_RISK"
    db_init_reputation "$LAB_DECISION"
    db_init_reputation "$LAB_APPLY"

    state_set "$LAB_STATE" NEW
    state_set "$LAB_RISK" NEW
    state_set "$LAB_DECISION" NEW
    state_set "$LAB_APPLY" NEW
}
