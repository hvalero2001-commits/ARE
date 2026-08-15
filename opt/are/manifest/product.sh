#!/bin/bash

##################################################
# ARE Product Manifest
# Single Source of Truth
##################################################

##################################################
# Product Information
##################################################

PRODUCT_NAME="ARE"
PRODUCT_DESCRIPTION="Abuse Reputation Engine"
PRODUCT_VERSION="1.1.0"
PRODUCT_LICENSE="GPL-3.0"

##################################################
# Installation Layout
##################################################

PRODUCT_HOME="opt/are"
PRODUCT_CONFIG="$PRODUCT_HOME/config"
PRODUCT_DATA="var/lib/are"
PRODUCT_SYSTEMD="etc/systemd/system"
PRODUCT_BIN="usr/local/sbin"
PRODUCT_LOG="var/log/are"
PRODUCT_LOGROTATE="etc/logrotate.d"

##################################################
# Core Directories
##################################################

PRODUCT_DIRS=(
    backend
    dashboard
    docs
    infrastructure
    manifest
    policy
    sensors
    stats
    systemd
    templates
)

##################################################
# Core Files
##################################################

PRODUCT_FILES=(
    are-installer
    bootstrap.sh
    dashboard.sh
    database.sh
    decay.sh
    are.sh
    logger.sh
    net_utils.sh
    validator.sh
    README.md
    LICENSE
    VERSION
)

##################################################
# Configuration Files
##################################################

PRODUCT_CONFIG_FILES=(
    config.conf
    policy.conf
    whitelist.conf
)

##################################################
# Systemd Units
##################################################

PRODUCT_SYSTEMD_UNITS=(
    are-fail2ban-found.service
    are-fail2ban-found.timer
    are-fail2ban-decay.service
    are-fail2ban-decay.timer
)

##################################################
# Executable Links
##################################################

PRODUCT_EXECUTABLE_LINKS=(
    "are:$PRODUCT_HOME/are.sh"
    "are-installer:$PRODUCT_HOME/are-installer"
    "are-fail2ban-sensor:$PRODUCT_HOME/sensors/fail2ban.sh"
)

##################################################
# Persistent Data
##################################################

PRODUCT_DATA_FILES=(
    f2b.db
)

##################################################
# Excluded Components
##################################################

PRODUCT_EXCLUDED=(
    .git
    testing
    tmp
    database-test.sh
    docs/TODO.md.save
)

PRODUCT_LOGROTATE_FILES=(
    are
)

PRODUCT_EXECUTABLE_FILES=(
    are-installer
    are.sh
    sensors/fail2ban.sh
)
