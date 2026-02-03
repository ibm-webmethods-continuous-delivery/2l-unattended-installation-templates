#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#
apk add --no-cache curl

# Source Posix Utilities
# shellcheck source=../../../../../2l-posix-shell-utils/code/1.init.sh
. "${PU_HOME}/code/1.init.sh"
# shellcheck source=../../../../../2l-posix-shell-utils/code/3.ingester.sh
. "${PU_HOME}/code/3.ingester.sh"

# shellcheck source=../../../../01-scripts/wmui-functions.sh
. "${WMUI_HOME}/01-scripts/wmui-functions.sh"

__err_no=0

wmui_assure_default_installer "${TEST_INSTALLER_BIN}" || __err_no=$((__err_no+1))
wmui_assure_default_umgr_bin "${TEST_UMGR_BIN}" || __err_no=$((__err_no+1))

pu_log_i "Returning exit code $__err_no"

if [ $__err_no -ne 0 ]; then
  pu_log_e "TEST FAILED!"
else
  pu_log_i "SUCCESS"
fi

exit $__err_no
