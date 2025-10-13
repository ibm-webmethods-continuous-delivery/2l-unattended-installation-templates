#!/bin/sh

# Section 0 - Framework Import

# Check if commons have been sourced, we need urlencode() for the license
if ! command -V "urlencode" 2>/dev/null | grep function >/dev/null; then 
  echo "sourcing commonFunctions.sh ..."
  if [ ! -f "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
    echo "Panic, framework issue! File ${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh does not exist. WMUI_CACHE_HOME=${WMUI_CACHE_HOME}"
    exit 151
  fi

  # shellcheck source=SCRIPTDIR/../../../../../01.scripts/commonFunctions.sh
  . "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh"
fi

# Section 1 - the caller MUST provide

__err_count=0

if [ -z "${WMUI_WMSCRIPT_CDS_DB_PASSWORD+x}" ]; then
  echo "ERROR: WMUI_WMSCRIPT_CDS_DB_PASSWORD is required but not provided or empty"
  __err_count=$((__err_count + 1))
fi

if [ -z "${WMUI_WMSCRIPT_CDS_DB_USER+x}" ]; then
  echo "ERROR: WMUI_WMSCRIPT_CDS_DB_USER is required but not provided or empty"
  __err_count=$((__err_count + 1))
fi

if [ -z "${WMUI_WMSCRIPT_CDS_CONN_STRING+x}" ]; then
  echo "ERROR: WMUI_WMSCRIPT_CDS_CONN_STRING is required but not provided or empty"
  __err_count=$((__err_count + 1))
fi

if [ "${__err_count}" -ne 0 ]; then
  exit 1
fi

WMUI_WMSCRIPT_CDS_DB_CONN_STRING_URLENCODED=$(urlencode "${WMUI_WMSCRIPT_CDS_CONN_STRING}")
export WMUI_WMSCRIPT_CDS_DB_CONN_STRING_URLENCODED

# Section 2 - the caller MAY provide
export WMUI_WMSCRIPT_adminPassword="${WMUI_WMSCRIPT_adminPassword:-manage}"
export WMUI_INSTALL_DECLARED_HOSTNAME="${WMUI_INSTALL_DECLARED_HOSTNAME:-localhost}"
export WMUI_INSTALL_INSTALL_DIR="${WMUI_INSTALL_INSTALL_DIR:-/opt/webmethods/1101/msr-sel-250904}"

## MSR related
export WMUI_WMSCRIPT_IntegrationServerPort="${WMUI_WMSCRIPT_IntegrationServerPort:-5555}"
export WMUI_WMSCRIPT_IntegrationServersecurePort="${WMUI_WMSCRIPT_IntegrationServersecurePort:-5553}"
export WMUI_WMSCRIPT_IntegrationServerdiagnosticPort="${WMUI_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}"

# Section 3 - Computed values

# Section 4 - Constants

export WMUI_CURRENT_SETUP_TEMPLATE_PATH="MSR/1101/selection-20250924"

logI "Template environment sourced successfully"
logEnv4Debug
