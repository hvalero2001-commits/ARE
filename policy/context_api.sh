#!/bin/bash
#############################################################
# Module : Policy - Context API
#
# Responsibility
#   Exponer accesores de solo lectura sobre el contexto
#   generado por policy_get_context(), para que las reglas no
#   necesiten conocer el formato interno (posición de campos)
#   del contexto.
#
# Dependencies
#   - policy/context.sh (formato CTX_V2)
#
# Exports
#   ctx_get_recon(), ctx_get_exploit(), ctx_get_credential(),
#   ctx_get_protocol(), ctx_get_bot(), ctx_get_anomaly(),
#   ctx_get_malware(), ctx_get_dos(), ctx_get_social(),
#   ctx_get_total(), ctx_get_events_24h(), ctx_get_updated(),
#   ctx_get_last_event()
#############################################################

ctx_get_recon()      { echo "$1" | cut -d'|' -f2; }
ctx_get_exploit()    { echo "$1" | cut -d'|' -f3; }
ctx_get_credential()  { echo "$1" | cut -d'|' -f4; }
ctx_get_protocol()   { echo "$1" | cut -d'|' -f5; }
ctx_get_bot()        { echo "$1" | cut -d'|' -f6; }
ctx_get_anomaly()    { echo "$1" | cut -d'|' -f7; }
ctx_get_malware()    { echo "$1" | cut -d'|' -f8; }
ctx_get_dos()        { echo "$1" | cut -d'|' -f9; }
ctx_get_social()     { echo "$1" | cut -d'|' -f10; }
ctx_get_total()      { echo "$1" | cut -d'|' -f11; }
ctx_get_events_24h() { echo "$1" | cut -d'|' -f12; }
ctx_get_updated()    { echo "$1" | cut -d'|' -f13; }
ctx_get_last_event() { echo "$1" | cut -d'|' -f14; }
