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
PRODUCT_VERSION="2.3.0"
PRODUCT_LICENSE="GPL-3.0"

##################################################
# Installation Layout
##################################################

PRODUCT_ROOT="${ARE_INSTALL_ROOT:-}"
PRODUCT_ROOT="${PRODUCT_ROOT%/}"

PRODUCT_HOME="${PRODUCT_ROOT}/opt/are"
PRODUCT_CONFIG="$PRODUCT_HOME/config"
PRODUCT_DATA="${PRODUCT_ROOT}/var/lib/are"
PRODUCT_SYSTEMD="${PRODUCT_ROOT}/etc/systemd/system"
PRODUCT_BIN="${PRODUCT_ROOT}/usr/local/sbin"
PRODUCT_LOG="${PRODUCT_ROOT}/var/log/are"
PRODUCT_LOGROTATE="${PRODUCT_ROOT}/etc/logrotate.d"

##################################################
# Core Directories
##################################################

PRODUCT_DIRS=(
    backend
    admin
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
    admin.sh
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
    jail_scale.conf
)

##################################################
# Systemd Units
##################################################

PRODUCT_SYSTEMD_UNITS=(
    are-fail2ban-found.service
    are-fail2ban-found.timer
    are-fail2ban-decay.service
    are-fail2ban-decay.timer
    are-restore-ipsets.service
    are-spamassassin.service
    are-spamassassin.timer
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
    are.db
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
    mod_evasive_report
    admin_audit
)

PRODUCT_EXECUTABLE_FILES=(
    are-installer
    are.sh
    sensors/fail2ban.sh
    sensors/apache_evasive.sh
    sensors/spamassassin.sh
)
