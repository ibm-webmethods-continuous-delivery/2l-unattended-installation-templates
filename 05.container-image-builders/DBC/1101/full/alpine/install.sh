#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#

export WMUI_TAG="${WMUI_TAG:-main}"
export WMUI_HOME="${WMUI_HOME:-/tmp/WMUI_HOME}"
export WMUI_TEMPLATE="${WMUI_TEMPLATE:-DBC/1101/full}"

echo "Cloning WMUI for tag ${WMUI_TAG}..."

git clone -b "${WMUI_TAG}" --single-branch \
  https://github.com/ibm-webmethods-continuous-delivery/2l-unattended-installation-templates.git \
  "${WMUI_HOME}"

# shellcheck source=/dev/null
. "${WMUI_HOME}/01.scripts/commonFunctions.sh"

# shellcheck source=/dev/null
. "${WMUI_HOME}/01.scripts/installation/setupFunctions.sh"

logI "WMUI env before installation:"
env | grep WMUI_ | sort

logI "Installing Product according to template ${WMUI_TEMPLATE}..."

applySetupTemplate "${WMUI_TEMPLATE}"

installResult=$?

if [ "${installResult}" -ne 0 ]; then
  logE "Installation failed, code ${installResult}"

  grep -rnw "error" "$WMUI_AUDIT_SESSION_DIR"
  exit 1
fi

logI "Product installation successful"
