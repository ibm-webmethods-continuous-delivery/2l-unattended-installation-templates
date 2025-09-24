#!/bin/sh

# shellcheck source-path=SCRIPTDIR/../../../../..

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
    huntForWmuiFile "01.scripts/installation" "setupFunctions.sh"
    if [ ! -f "${WMUI_CACHE_HOME}/01.scripts/installation/setupFunctions.sh" ]; then
        echo "Panic, framework issue! File ${WMUI_CACHE_HOME}/01.scripts/installation/setupFunctions.sh does not exist. WMUI_CACHE_HOME=${WMUI_CACHE_HOME}"
        exit 152
    fi
    . "${WMUI_CACHE_HOME}/01.scripts/installation/setupFunctions.sh"
fi

# ------------------------------ Section 1 - check what the caller MUST provide, Framework related

checkSetupTemplateBasicPrerequisites || exit $?

# ------------------------------ Section 2 - check what the caller MUST provide, related to this specific template


# ------------------------------ Section 3 - the caller MAY provide ( framework commons )

export WMUI_INSTALL_DECLARED_HOSTNAME="${WMUI_INSTALL_DECLARED_HOSTNAME:-localhost}"
export WMUI_INSTALL_INSTALL_DIR="${WMUI_INSTALL_INSTALL_DIR:-/opt/webmethods/products}"
export WMUI_INSTALL_SPM_HTTP_PORT="${WMUI_INSTALL_SPM_HTTP_PORT:-9082}"
export WMUI_INSTALL_SPM_HTTPS_PORT="${WMUI_INSTALL_SPM_HTTPS_PORT:-9083}"

# ------------------------------ Section 4 - the caller MAY provide ( specific )

export WMUI_WMSCRIPT_adminPassword="${WMUI_WMSCRIPT_adminPassword:-manage}"
export WMUI_WMSCRIPT_IntegrationServerdiagnosticPort="${WMUI_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}"
export WMUI_WMSCRIPT_IntegrationServerPort="${WMUI_WMSCRIPT_IntegrationServerPort:-5555}"
export WMUI_WMSCRIPT_IntegrationServersecurePort="${WMUI_WMSCRIPT_IntegrationServersecurePort:-5553}"
export WMUI_WMSCRIPT_YAIHttpPort="${WMUI_WMSCRIPT_YAIHttpPort:-9072}"
export WMUI_WMSCRIPT_YAIHttpsPort="${WMUI_WMSCRIPT_YAIHttpsPort:-9073}"

# ------------------------------ Section 6 - Constants

export WMUI_CURRENT_SETUP_TEMPLATE_PATH="APIGateway/1101/cds-e2e-postgres"

WMUI_WMSCRIPT_CDS_DB_CONN_STRING_URLENCODED=$(urlencode "${WMUI_WMSCRIPT_CDS_CONN_STRING}")
export WMUI_WMSCRIPT_CDS_DB_CONN_STRING_URLENCODED

logI "Template environment sourced successfully"
logEnv4Debug
