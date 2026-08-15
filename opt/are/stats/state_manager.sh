#!/bin/bash

state_is_banned() {

    [ "$(state_get "$1")" = "BANNED" ]

}

state_is_tempban() {

    [ "$(state_get "$1")" = "TEMP_BANNED" ]

}

state_is_watch() {

    [ "$(state_get "$1")" = "WATCH" ]

}
