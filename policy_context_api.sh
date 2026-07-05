#!/bin/bash

ctx_get_recon()     { echo "$1" | cut -d'|' -f2; }
ctx_get_exploit()   { echo "$1" | cut -d'|' -f3; }
ctx_get_credential(){ echo "$1" | cut -d'|' -f4; }
ctx_get_protocol()  { echo "$1" | cut -d'|' -f5; }
ctx_get_bot()       { echo "$1" | cut -d'|' -f6; }
ctx_get_total()     { echo "$1" | cut -d'|' -f7; }
ctx_get_events_24h(){ echo "$1" | cut -d'|' -f8; }
ctx_get_updated()   { echo "$1" | cut -d'|' -f9; }
ctx_get_last_event(){ echo "$1" | cut -d'|' -f10; }
