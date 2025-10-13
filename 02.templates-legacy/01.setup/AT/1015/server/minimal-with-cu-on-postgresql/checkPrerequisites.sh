#!/bin/sh

if ! command -V "logE" 2>/dev/null | grep function >/dev/null; then
  echo "sourcing commonFunctions.sh again (lost?)"
  if [ ! -f "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
    echo "[checkPrerequisites.sh] - Panic, framework issue!"
    exit 151
  fi
  # shellcheck source=SCRIPTDIR/../../../../../01.scripts/commonFunctions.sh
  . "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh"
fi

# No checks for now
errCount=0
logPrefix="02.templates/01.setup/AT/1015/minimal-with-cu-on-postgresql/checkPrerequisites.sh"

if [ ! -f "$WMUI_SETUP_TEMPLATE_IS_LICENSE_FILE" ]; then
  logE "$logPrefix -- WMUI_SETUP_TEMPLATE_IS_LICENSE_FILE = $WMUI_SETUP_TEMPLATE_IS_LICENSE_FILE does not exist!"
  errCount=$((errCount + 1))
fi

if [ ! -f "$WMUI_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE" ]; then
  logE "$logPrefix -- WMUI_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE = $WMUI_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE does not exist!"
  errCount=$((errCount + 1))
fi

if [ $errCount -ne 0 ]; then
  logE "$logPrefix -- $errCount errors found. Exitting with code 254"
  exit 254
fi
