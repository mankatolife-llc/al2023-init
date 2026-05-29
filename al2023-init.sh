#!/bin/bash

###############################################################################
# al2023-init.sh
#
# Purpose
# -------
# Establish the universal Bedrock substrate on a new Amazon Linux 2023
# instance.
#
# Responsibilities
# ----------------
# - Update the operating system
# - Install universal Bedrock packages
# - Validate package installation
# - Emit INIT_SUCCESS or INIT_FAILURE
#
# Non-Responsibilities
# --------------------
# - Service activation
# - User creation
# - Site provisioning
# - SSL provisioning
# - Host-specific configuration
# - Environment-specific configuration
# - Application deployment
# - Orchestration
#
# Philosophy
# ----------
# Init creates capabilities.
# Launch templates and user-data activate behavior.
#
# Success Artifact
# ----------------
# /root/INIT_SUCCESS
#
# Failure Artifact
# ----------------
# /root/INIT_FAILURE
#
###############################################################################

INIT_VERSION="0.1.1"

set -euo pipefail

RESULT_FILE="/root/INIT_IN_PROGRESS"

rm -f /root/INIT_SUCCESS /root/INIT_FAILURE /root/INIT_IN_PROGRESS

touch "${RESULT_FILE}"

log() {
  echo "$1" | tee -a "${RESULT_FILE}"
}

fail() {
  log ""
  log "Version: ${INIT_VERSION}"
  log "Result: FAILURE"
  log "Completed: $(date -u)"
  log "[FAIL] $1"

  mv "${RESULT_FILE}" /root/INIT_FAILURE || exit 1
  exit 1
}

install_package() {
  local package="$1"

  if dnf install -y "${package}" >/dev/null 2>&1; then
    log "[PASS] ${package}"
  else
    fail "${package} installation failed"
  fi
}

log "AL2023 INIT REPORT"
log "=================="
log "Version: ${INIT_VERSION}"
log "Started: $(date -u)"
log ""

log "[INFO] Updating operating system"

if dnf upgrade -y >/dev/null 2>&1; then
  log "[PASS] System update"
else
  fail "System update failed"
fi

log ""
log "[INFO] Installing Bedrock substrate packages"
log ""

PACKAGES=(
  git
  jq

  httpd

  php
  php-fpm
  php-mysqlnd
  php-json
  php-gd
  php-intl
  php-mbstring
  php-cli

  mariadb105-server

  mod_ssl

  certbot
  python3-certbot-apache
)

for package in "${PACKAGES[@]}"
do
  install_package "${package}"
done

log ""
log "[INFO] Validation"

for package in "${PACKAGES[@]}"
do
  rpm -q "${package}" >/dev/null 2>&1 \
    || fail "${package} validation failed"
done

log "[PASS] Validation"

log ""
log "Version: ${INIT_VERSION}"
log "Result: SUCCESS"
log "Completed: $(date -u)"

mv "${RESULT_FILE}" /root/INIT_SUCCESS || exit 1

exit 0