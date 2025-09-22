#!/bin/sh

# Section 0 - Validations

# Check if commons have been sourced, we need urlencode() for the license
if ! command -V "urlencode" 2>/dev/null | grep function >/dev/null; then 
    echo "sourcing commonFunctions.sh ..."
    if [ ! -f "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue! File ${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh does not exist. WMUI_CACHE_HOME=${WMUI_CACHE_HOME}"
        exit 151
    fi
    . "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh"
fi

# Check if install commons have been sourced, we need checkSetupTemplateBasicPrerequisites()
if ! command -V "checkSetupTemplateBasicPrerequisites" 2>/dev/null | grep function >/dev/null; then 
    echo "sourcing setupFunctions.sh ..."
    huntForSuifFile "01.scripts/installation" "setupFunctions.sh"
    if [ ! -f "${WMUI_CACHE_HOME}/01.scripts/installation/setupFunctions.sh" ]; then
        echo "Panic, framework issue! File ${WMUI_CACHE_HOME}/01.scripts/installation/setupFunctions.sh does not exist. WMUI_CACHE_HOME=${WMUI_CACHE_HOME}"
        exit 152
    fi
    . "${WMUI_CACHE_HOME}/01.scripts/installation/setupFunctions.sh"
fi

# ------------------------------ Section 1 - check what the caller MUST provide, Framework related

checkSetupTemplateBasicPrerequisites || exit $?

# ------------------------------ Section 2 - check what the caller MUST provide, related to this specific template
if [ -z "${WMUI_SETUP_TEMPLATE_CSS_LICENSE_FILE+x}" ]; then
    logE "User must provide a valid license file in the WMUI_SETUP_TEMPLATE_CSS_LICENSE_FILE variable"
    exit 21
fi

if [ ! -f "${WMUI_SETUP_TEMPLATE_CSS_LICENSE_FILE}" ]; then
    logE "User must provide a valid CloudStreams Server license file, ${WMUI_SETUP_TEMPLATE_CSS_LICENSE_FILE} not found"
    exit 22
fi

# ------------------------------ Section 3 - the caller MAY provide

## MSR related
export WMUI_WMSCRIPT_adminPassword="${WMUI_WMSCRIPT_adminPassword:-manage}"
export WMUI_WMSCRIPT_IntegrationServerPort="${WMUI_WMSCRIPT_IntegrationServerPort:-5555}"
export WMUI_WMSCRIPT_IntegrationServersecurePort="${WMUI_WMSCRIPT_IntegrationServersecurePort:-5553}"
export WMUI_WMSCRIPT_IntegrationServerdiagnosticPort="${WMUI_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}"

# ------------------------------ Section 4 - Computed values

WMUI_WMSCRIPT_integrationServerLicenseFiletext=$(urlencode "${WMUI_SETUP_TEMPLATE_CSS_LICENSE_FILE}")
export WMUI_WMSCRIPT_integrationServerLicenseFiletext

# ------------------------------ Section 5 - Constants

export WMUI_CURRENT_SETUP_TEMPLATE_PATH="CloudStreamServer/1011/lean"

logI "Template environment sourced successfully"
logEnv4Debug
