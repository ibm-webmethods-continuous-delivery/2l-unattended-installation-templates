#!/bin/sh

# Section 0 - Framework Import
if [ ! "`type -t urlencode`X" == "functionX" ]; then
    if [ ! -f "${WMUI_CACHE_HOME}/installationScripts/commonFunctions.sh" ]; then
        echo "Panic, common functions not sourced and not present locally! Cannot continue"
        exit 500
    fi
    . "$WMUI_CACHE_HOME/installationScripts/commonFunctions.sh"
fi

# Section 1 - the caller MUST provide

if [[ "x${WMUI_INSTALL_TIME_ADMIN_PASSWORD}" == "x" ]]; then
    logE "User must provide an admin installation password (variable WMUI_INSTALL_TIME_ADMIN_PASSWORD), this template does not accept default passwords"
    exit 1
fi

export WMUI_SETUP_TEMPLATE_MSR_LICENSE_FILE=${WMUI_SETUP_TEMPLATE_MSR_LICENSE_FILE:-"/provide/path/to/IS-license.xml"}

if [ ! -f ${WMUI_SETUP_TEMPLATE_MSR_LICENSE_FILE} ]; then
    logE "User must provide a valid MSR license file"
    exit 2
fi

# TODO: enforce 
export WMUI_WMSCRIPT_CDSConnectionName=${WMUI_WMSCRIPT_CDSConnectionName:-"User MUST provide WMUI_WMSCRIPT_CDSConnectionName"}
export WMUI_WMSCRIPT_CDSPasswordName=${WMUI_WMSCRIPT_CDSPasswordName:-"User MUST provide WMUI_WMSCRIPT_CDSPasswordName"}
export WMUI_WMSCRIPT_CDSUrlName=${WMUI_WMSCRIPT_CDSUrlName:-"User MUST provide WMUI_WMSCRIPT_CDSUrlName"}
export WMUI_WMSCRIPT_CDSUserName=${WMUI_WMSCRIPT_CDSUserName:-"User MUST provide WMUI_WMSCRIPT_CDSUserName"}

# Section 2 - the caller MAY provide

export WMUI_INSTALL_DECLARED_HOSTNAME=${WMUI_INSTALL_DECLARED_HOSTNAME:-"localhost"}
## MSR related
export WMUI_INSTALL_MSR_MAIN_HTTP_PORT=${WMUI_INSTALL_MSR_MAIN_HTTP_PORT:-"5555"}
export WMUI_INSTALL_MSR_MAIN_HTTPS_PORT=${WMUI_INSTALL_MSR_MAIN_HTTPS_PORT:-"5553"}
export WMUI_INSTALL_MSR_DIAGS_HTTP_PORT=${WMUI_INSTALL_MSR_DIAGS_HTTP_PORT:-"9999"}

# Section 3 - Computed values

export WMUI_SETUP_TEMPLATE_MSR_LICENSE_UrlEncoded=$(urlencode ${WMUI_SETUP_TEMPLATE_MSR_LICENSE_FILE})

# Section 4 - Constants

export WMUI_CURRENT_SETUP_TEMPLATE_PATH="MSR/1011/AdaptersSet1"
logI "Template environment sourced successfully"
logEnv4Debug
