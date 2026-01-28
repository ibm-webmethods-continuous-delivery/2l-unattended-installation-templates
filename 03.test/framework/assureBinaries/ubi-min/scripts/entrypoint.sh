#!/bin/sh

microdnf -y install which

# Source Posix Utilities
# shellcheck source=../../../../../../2l-posix-shell-utils/code/1.init.sh
. "${PU_HOME}/code/1.init.sh"
# shellcheck source=../../../../../../2l-posix-shell-utils/code/3.ingester.sh
. "${PU_HOME}/code/3.ingester.sh"

# shellcheck source=../../../../../01.scripts/wmui-functions.sh
. "${WMUI_HOME}/01.scripts/wmui-functions.sh"

errNo=0

wmui_assure_default_installer "${TEST_INSTALLER_BIN}" || errNo=$((errNo+1))
wmui_assure_default_umgr_bin "${TEST_UMGR_BIN}" || errNo=$((errNo+1))

pu_log_i "Returning exit code $errNo"

if [ $errNo -ne 0 ]; then
  pu_log_e "TEST FAILED!"
else
  pu_log_i "SUCCESS"
fi

exit $errNo