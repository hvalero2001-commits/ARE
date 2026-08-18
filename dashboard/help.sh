#!/bin/bash
#############################################################
# Module : Dashboard - Help
#
# Responsibility
#   Show help for the ARE dashboard.
#
# Dependencies
#   - logger.sh
#
# Exports
#   dashboard_help()
#############################################################

dashboard_help() {

    echo "=================================================="
    echo "ARE - DASHBOARD"
    echo "=================================================="
    echo
    echo "Consulta de reputación y actividad de IPs."
    echo
    echo "COMANDOS:"
    echo
    echo "  score <IP>"
    echo "      Muestra la reputación completa de una IP."
    echo
    echo "  events <IP>"
    echo "      Muestra los eventos registrados para una IP."
    echo
    echo "  top"
    echo "      Muestra las IPs con mayor nivel de amenaza."
    echo
    echo "  stats"
    echo "      Muestra estadísticas generales de ARE."
    echo
    echo "  help"
    echo "      Muestra esta ayuda."
    echo
    echo "  status"
    echo "      Estado operativo de ARE."
    echo
    echo "EJEMPLOS:"
    echo
    echo "  are.sh score 8.8.8.8"
    echo "  are.sh events 8.8.8.8"
    echo "  are.sh top"
    echo "  are.sh stats"
    echo "  are.sh help"
    echo "  are.sh status"
    echo
    echo "=================================================="
}
