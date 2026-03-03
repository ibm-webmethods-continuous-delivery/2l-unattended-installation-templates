#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#
# Convention: WMUI_LI_ are variables dedicated to this local installer script
#
# This scripts installs according to a template, requiring the
# binaries to be present in the host, in particular, the caller MUST
# assure the following variables:
#
# 1. WMUI_LI_TEMPLATE MUST exist and contain the template id of the installation, e.g. msr/1101/simple
# 2. WMUI_LI_INSTALLER_BIN MUST exist and point to the installer binary file
# 3. WMUI_WMSCRIPT_imageFile MUST exist and point to an installer image containing the products mentioned by the template
# 4. WMUI_LI_UMGR_BOOTSTRAP_BIN is OPTIONAL. If it exists, it must point to a valid Update Manager Bootstrap file
# 5. WMUI_LI_FIXES_IMAGE_FILE is OPTIONAL. If it exists, it must point to a valid installer image containing the fixes mentioned by the template
# 6. WMUI_LI_PRESERVE_AUDIT is OPTIONAL, no default value. Set it to true to preserve audit logs
# 7. Any other mandatory environment variable required by the installed template MUST be set before calling this script

set -e

## 01. Defaults
  # Enable PU debug mode only when debugging
  export PU_DEBUG_MODE="${PU_DEBUG_MODE:-false}"
  export PU_ONLINE_MODE='false' # Design decision

  export PU_HOME="${PU_HOME:-/tmp/pu}"
  export WMUI_LI_PU_TAG="${WMUI_LI_PU_TAG:-v0.1.5}"

  export WMUI_HOME="${WMUI_HOME:-/tmp/WMUI_HOME}"
  export WMUI_LI_WMUI_TAG="${WMUI_LI_WMUI_TAG:-v0.0.5}"

  export WMUI_WMSCRIPT_InstallDir="${WMUI_WMSCRIPT_InstallDir:-/opt/webmethods}"

  export WMUI_LI_UMGR_HOME_DIR="${WMUI_LI_UMGR_HOME_DIR:-/tmp/umgr}"

## 02. Prerequisites for setup

  echo "Cloning WMUI for tag ${WMUI_LI_WMUI_TAG}..."

  git config --global advice.detachedHead false

  git clone -b "${WMUI_LI_PU_TAG}" --single-branch --depth 1 \
    https://github.com/ibm-webmethods-continuous-delivery/2l-posix-shell-utils.git \
    "${PU_HOME}" || exit 1

  # shellcheck source=../../2l-posix-shell-utils/code/1.init.sh
  . "${PU_HOME}/code/1.init.sh"

  # shellcheck source=../../2l-posix-shell-utils/code/7.data.sh
  . "${PU_HOME}/code/7.data.sh"

  pu_log_i "[WMUI_LI] Cloning WMUI for tag ${WMUI_LI_WMUI_TAG}..."

  git clone -b "${WMUI_LI_WMUI_TAG}" --single-branch --depth 1 \
    https://github.com/ibm-webmethods-continuous-delivery/2l-unattended-installation-templates.git \
    "${WMUI_HOME}" || exit 2

  # shellcheck source=wmui-functions.sh
  . "${WMUI_HOME}/01-scripts/wmui-functions.sh"

## 03. Bootstrap Update Manager
  if [ -z "${WMUI_LI_UMGR_BOOTSTRAP_BIN+x}" ]; then
    pu_log_w "[WMUI_LI] Update Manager Bootstrap file not provided, skipping..."
  else
    if [ -f "${WMUI_LI_UMGR_BOOTSTRAP_BIN}" ]; then
      pu_log_i "[WMUI_LI] Bootstrapping Update Manager..."
      # Parameters - wmui_bootstrap_umgr
      # $1 - Update Manager Bootstrap file
      # $2 - Fixes image file, mandatory for offline mode
      # $3 - OPTIONAL Where to install (webMethods Update Manager Home), default ${__wmui_default_umgr_home}
      if ! wmui_bootstrap_umgr \
            "${WMUI_LI_UMGR_BOOTSTRAP_BIN}" \
            "${WMUI_LI_FIXES_IMAGE_FILE}" \
            "${WMUI_LI_UMGR_HOME_DIR}" ; then
        pu_log_e "Cannot bootstrap update manager, cannot continue (code $?)!"
        exit 2
      fi
    else
      pu_log_e "[WMUI_LI] Update Manager Bootstrap file not found, skipping Update Manager bootstrap"
      exit 1
    fi
  fi

## 04. Installation and patching
  pu_log_i "[WMUI_LI] WMUI env before installation:"
  env | grep WMUI_ | sort
  pu_log_i "[WMUI_LI] Installing Product according to template ${WMUI_TEMPLATE}..."

  if [ -d "${WMUI_LI_UMGR_HOME_DIR}" ]; then
    pu_log_w "[WMUI_LI] Setting up products and fixes from template ${WMUI_LI_TEMPLATE}"
    # Parameters
    # $1 - Template id
    # $2 - OPTIONAL: use latest versions (default passthrough to wmui_install_template_products)
    # $3 - OPTIONAL: Installer binary location, default passthrough to wmui_install_template_products
    # $4 - OPTIONAL: debugLevel for installer, default verbose
    # $5 - OPTIONAL: fixes file image. Absent means skip patching
    # $6 - OPTIONAL: Update manager home, default ${__wmui_default_umgr_home}
    if ! wmui_setup_products_and_fixes_from_template \
            "${WMUI_LI_TEMPLATE}" \
            "" \
            "${WMUI_LI_INSTALLER_BIN}" \
            "" \
            "${WMUI_LI_FIXES_IMAGE_FILE}" \
            "${WMUI_LI_UMGR_HOME_DIR}" ; then
      pu_log_e "Failed to setup products and fixes from template"
      exit 3
    fi
  else
    pu_log_w "[WMUI_LI] Setting up products only from template ${WMUI_LI_TEMPLATE}"
    if ! wmui_setup_products_and_fixes_from_template \
            "${WMUI_LI_TEMPLATE}" \
            "" \
            "${WMUI_LI_INSTALLER_BIN}"; then
      pu_log_e "Failed to setup products and fixes from template"
      exit 4
    fi
  fi
  pu_log_i "Product installation successful"

## 05. Save audit for debugging
  if [ "${WMUI_LI_PRESERVE_AUDIT}" = 'true' ]; then
    cd "${WMUI_WMSCRIPT_InstallDir}" || exit 4
    # shellcheck disable=SC2082
    tar czf build-time-audit.tgz "${__2__audit_session_dir}"
  fi
