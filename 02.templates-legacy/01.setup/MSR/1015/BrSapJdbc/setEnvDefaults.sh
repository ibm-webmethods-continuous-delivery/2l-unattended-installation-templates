#!/bin/sh

# Section 0 - Framework Import
if [ ! "`type -t urlencode`X" == "functionX" ]; then
    if [ ! -f "${WMUI_CACHE_HOME}/installationScripts/commonFunctions.sh" ]; then
        echo "Panic, common functions not sourced and not present locally! Cannot continue"
        exit 100
    fi
    . "$WMUI_CACHE_HOME/installationScripts/commonFunctions.sh"
fi

# Section 1 - the caller MUST provide

if [ -z ${WMUI_SETUP_TEMPLATE_MSR_LICENSE_FILE+x} ]; then
    logE "User must provide a valid MSR license file in the environment variable WMUI_SETUP_TEMPLATE_MSR_LICENSE_FILE"
    exit 1
fi

if [ ! -f "${WMUI_SETUP_TEMPLATE_MSR_LICENSE_FILE}" ]; then
    logE "User must provide a valid MSR license file, the declared file ${WMUI_SETUP_TEMPLATE_MSR_LICENSE_FILE} does not exist!"
    exit 2
fi

if [ -z ${WMUI_SETUP_TEMPLATE_BRMS_LICENSE_FILE+x} ]; then
    logE "User must provide a valid Business Rules license file in the environment variable WMUI_SETUP_TEMPLATE_BRMS_LICENSE_FILE"
    exit 3
fi

if [ ! -f "${WMUI_SETUP_TEMPLATE_BRMS_LICENSE_FILE}" ]; then
    logE "User must provide a valid Business Rules license file, the declared file ${WMUI_SETUP_TEMPLATE_BRMS_LICENSE_FILE} does not exist!"
    exit 4
fi

# Section 2 - the caller MAY provide

export WMUI_INSTALL_TIME_ADMIN_PASSWORD="${WMUI_INSTALL_TIME_ADMIN_PASSWORD:-manage}"

export WMUI_INSTALL_DECLARED_HOSTNAME="${WMUI_INSTALL_DECLARED_HOSTNAME:-localhost}"
## MSR related
export WMUI_INSTALL_MSR_MAIN_HTTP_PORT="${WMUI_INSTALL_MSR_MAIN_HTTP_PORT:-5555}"
export WMUI_INSTALL_MSR_MAIN_HTTPS_PORT="${WMUI_INSTALL_MSR_MAIN_HTTPS_PORT:-5553}"
export WMUI_INSTALL_MSR_DIAGS_HTTP_PORT="${WMUI_INSTALL_MSR_DIAGS_HTTP_PORT:-9999}"

# Section 3 - Computed values

WMUI_SETUP_TEMPLATE_MSR_LICENSE_UrlEncoded=$(urlencode "${WMUI_SETUP_TEMPLATE_MSR_LICENSE_FILE}")
export WMUI_SETUP_TEMPLATE_MSR_LICENSE_UrlEncoded
WMUI_SETUP_TEMPLATE_BRMS_LICENSE_UrlEncoded=$(urlencode "${WMUI_SETUP_TEMPLATE_BRMS_LICENSE_FILE}")
export WMUI_SETUP_TEMPLATE_BRMS_LICENSE_UrlEncoded

# Section 4 - Constants

export WMUI_CURRENT_SETUP_TEMPLATE_PATH="MSR/1015/BrSapJdbc"
logI "Template environment sourced successfully"
logEnv4Debug
