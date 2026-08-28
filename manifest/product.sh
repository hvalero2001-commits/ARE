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
PRODUCT_VERSION="2.7.0"
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
    scripts
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
    are-web-correlation.service
    are-web-correlation.timer
)
##################################################
# Optional Systemd Units
#
# Se copian en toda instalación, pero no se habilitan
# automáticamente — requieren configuración explícita del
# administrador antes de tener sentido (IDEA-012).
##################################################
PRODUCT_SYSTEMD_UNITS_OPTIONAL=(
    are-whitelist-sync.service
    are-whitelist-sync.timer
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
    web_correlation
)
PRODUCT_EXECUTABLE_FILES=(
    are-installer
    are.sh
    sensors/fail2ban.sh
    sensors/apache_evasive.sh
    sensors/spamassassin.sh
    sensors/web_correlation.sh
    scripts/install.sh
    scripts/build-package.sh
    scripts/sync_whitelist.sh
)
