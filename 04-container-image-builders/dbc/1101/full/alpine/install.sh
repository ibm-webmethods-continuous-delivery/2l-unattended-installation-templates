#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#

# Convention: WMUI_CIB_ are variables pertinent to CIB - Container Image Builder

set -e

## 01. Defaults
  export PU_DEBUG_MODE='false'
  export PU_ONLINE_MODE='false'

  export PU_HOME="${PU_HOME:-/tmp/pu}"
  export WMUI_CIB_PU_TAG="${WMUI_CIB_PU_TAG:-v0.1.5}"

  export WMUI_HOME="${WMUI_HOME:-/tmp/WMUI_HOME}"
  export WMUI_CIB_WMUI_TAG="${WMUI_CIB_WMUI_TAG:-v0.0.2}"

  export WMUI_WMSCRIPT_InstallDir="${WMUI_WMSCRIPT_InstallDir:-/opt/webmethods}"

  export WMUI_CIB_TEMPLATE="${WMUI_CIB_TEMPLATE:-dbc/1101/full}"
  export WMUI_CIB_UMGR_HOME_DIR="${WMUI_CIB_UMGR_HOME_DIR:-/tmp/umgr}"

## 01. Prerequisites for setup

  echo "Cloning WMUI for tag ${WMUI_CIB_WMUI_TAG}..."

  git clone -b "${WMUI_CIB_PU_TAG}" --single-branch --depth 1 \
  https://github.com/ibm-webmethods-continuous-delivery/2l-posix-shell-utils.git \
  "${PU_HOME}"

  # shellcheck source=../../../../../../2l-posix-shell-utils/code/1.init.sh
  . "${PU_HOME}/code/1.init.sh"

  # shellcheck source=../../../../../../2l-posix-shell-utils/code/7.data.sh
  . "${PU_HOME}/code/7.data.sh"

  pu_log_i "[WMUI_CIB] Cloning WMUI for tag ${WMUI_CIB_WMUI_TAG}..."

  git clone -b "${WMUI_CIB_WMUI_TAG}" --single-branch --depth 1 \
  https://github.com/ibm-webmethods-continuous-delivery/2l-unattended-installation-templates.git \
  "${WMUI_HOME}"

  sleep 10

  # shellcheck source=../../../../../01-scripts/wmui-functions.sh
  . "${WMUI_HOME}/01-scripts/wmui-functions.sh"

  sleep 10

## 02. Bootstrap Update Manager
  pu_log_i "[WMUI_CIB] Bootstrapping Update Manager..."
  # Parameters - wmui_bootstrap_umgr
  # $1 - Update Manager Bootstrap file
  # $2 - Fixes image file, mandatory for offline mode
  # $3 - OPTIONAL Where to install (webMethods Update Manager Home), default ${__wmui_default_umgr_home}
  if ! wmui_bootstrap_umgr \
          "${WMUI_CIB_UMGR_BOOTSTRAP_BIN}" \
          "${WMUI_CIB_FIXES_IMAGE_FILE}" \
          "${WMUI_CIB_UMGR_HOME_DIR}" ; then
    pu_log_e "Cannot bootstrap update manager, cannot continue (code $?)!"
    exit 2
  fi

## 03. Installation and patching
  pu_log_i "[WMUI_CIB] WMUI env before installation:"
  env | grep WMUI_ | sort
  pu_log_i "[WMUI_CIB] Installing Product according to template ${WMUI_TEMPLATE}..."
  # Parameters
  # $1 - Template id
  # $2 - OPTIONAL: use latest versions (default passthrough to wmui_install_template_products)
  # $3 - OPTIONAL: Installer binary location, default passthrough to wmui_install_template_products
  # $4 - OPTIONAL: debugLevel for installer, default verbose
  # $5 - OPTIONAL: fixes file image. Absent means skip patching
  # $6 - OPTIONAL: Update manager home, default ${__wmui_default_umgr_home}
  if ! wmui_setup_products_and_fixes_from_template \
          "${WMUI_CIB_TEMPLATE}" \
          "" \
          "${WMUI_CIB_INSTALLER_BIN}" \
          "" \
          "${WMUI_CIB_FIXES_IMAGE_FILE}" \
          "${WMUI_CIB_UMGR_HOME_DIR}" ; then
    pu_log_e "Failed to setup products and fixes from template"
    exit 3
  fi
  pu_log_i "Product installation successful"

## 04. Save audit for debugging

  cd "${WMUI_WMSCRIPT_InstallDir}" || exit 4
  # shellcheck disable=SC2082
  tar czf build-time-audit.tgz "${__2__audit_session_dir}"
