#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#
# Source Posix Utilities
# shellcheck source=../../../../../2l-posix-shell-utils/code/1.init.sh
. "${PU_HOME}/code/1.init.sh"
# shellcheck source=../../../../../2l-posix-shell-utils/code/2.audit.sh
. "${PU_HOME}/code/2.audit.sh"
# shellcheck source=../../../../../2l-posix-shell-utils/code/3.ingester.sh
. "${PU_HOME}/code/3.ingester.sh"

# shellcheck source=../../../../01-scripts/wmui-functions.sh
. "${WMUI_HOME}/01-scripts/wmui-functions.sh"

__err_no=0

wmui_assure_default_installer "${TEST_INSTALLER_V12_BIN}" || __err_no=$((__err_no+1))
wmui_assure_default_umgr_bin "${TEST_UMGR_V12_BIN}" || __err_no=$((__err_no+1))
export WMUI_WM_MAJOR_VERSION=11
# shellcheck source=../../../../01-scripts/wmui-functions.sh
. "${WMUI_HOME}/01-scripts/wmui-functions.sh"
wmui_assure_default_installer "${TEST_INSTALLER_V11_BIN}" || __err_no=$((__err_no+1))
wmui_assure_default_umgr_bin "${TEST_UMGR_V11_BIN}" || __err_no=$((__err_no+1))

pu_log_i "Returning exit code $__err_no"

if [ $__err_no -ne 0 ]; then
  pu_log_e "TEST FAILED!"
  tail -f /dev/null
else
  pu_log_i "SUCCESS"
fi

exit $__err_no