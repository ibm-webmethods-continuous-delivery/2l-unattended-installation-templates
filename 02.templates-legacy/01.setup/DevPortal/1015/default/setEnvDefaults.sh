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
if [ ! -f "${WMUI_SETUP_TEMPLATE_DPO_LICENSE_FILE}" ]; then
  logE "User must provide a valid Developer Portal license file, declared in the variable WMUI_SETUP_TEMPLATE_DPO_LICENSE_FILE"
  exit 202
fi

# Section 2 - the caller MAY provide
export WMUI_INSTALL_TIME_ADMIN_PASSWORD="${WMUI_INSTALL_TIME_ADMIN_PASSWORD:-manage}"

## DPO related
export WMUI_WMSCRIPT_CELHTTPPort=${WMUI_WMSCRIPT_CELHTTPPort:-9240}
export WMUI_WMSCRIPT_CELTCPPort=${WMUI_WMSCRIPT_CELTCPPort:-9340}
export WMUI_WMSCRIPT_DPO_HTTP_Port=${WMUI_WMSCRIPT_DPO_HTTP_Port:-18101}
export WMUI_WMSCRIPT_DPO_HTTPS_Port=${WMUI_WMSCRIPT_DPO_HTTPS_Port:-18102}

# Section 3 - Computed values

WMUI_SETUP_TEMPLATE_DPO_LICENSE_UrlEncoded=$(urlencode "${WMUI_SETUP_TEMPLATE_DPO_LICENSE_FILE}")
export WMUI_SETUP_TEMPLATE_DPO_LICENSE_UrlEncoded

# Section 4 - Constants

export WMUI_CURRENT_SETUP_TEMPLATE_PATH="DevPortal/1015/default"

logI "Template environment sourced successfully"
logEnv4Debug
