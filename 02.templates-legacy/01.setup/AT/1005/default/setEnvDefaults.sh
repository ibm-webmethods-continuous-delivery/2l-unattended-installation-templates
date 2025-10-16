#!/bin/sh

if [ ! "`type -t urlencode`X" == "functionX" ]; then
    if [ ! -f "${WMUI_CACHE_HOME}/installationScripts/commonFunctions.sh" ]; then
        echo "Panic, common functions not sourced and not present locally! Cannot continue"
        exit 500
    fi
    . "$WMUI_CACHE_HOME/installationScripts/commonFunctions.sh"
fi

# Section 1 - the caller MUST provide
## Framework - Install
export WMUI_INSTALL_INSTALLER_BIN=${WMUI_INSTALL_INSTALLER_BIN:-"/path/to/installer.bin"}
export WMUI_INSTALL_IMAGE_FILE=${WMUI_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}

## Framework - Patch
export WMUI_PATCH_SUM_BOOTSTRAP_BIN=${WMUI_PATCH_SUM_BOOTSTRAP_BIN:-"/path/to/sum-boostrap.bin"}
export WMUI_PATCH_FIXES_IMAGE_FILE=${WMUI_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

## Current Template
export WMUI_SETUP_TEMPLATE_IS_LICENSE_FILE=${WMUI_SETUP_TEMPLATE_IS_LICENSE_FILE:-"/provide/path/to/IS-license.xml"}
export WMUI_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE=${WMUI_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE:-"/provide/path/to/MFTSERVER-license.xml"}

# Section 2 - the caller MAY provide
## Framework - Install
export WMUI_INSTALL_INSTALL_DIR=${WMUI_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export WMUI_INSTALL_SPM_HTTPS_PORT=${WMUI_INSTALL_SPM_HTTPS_PORT:-"9083"}
export WMUI_INSTALL_SPM_HTTP_PORT=${WMUI_INSTALL_SPM_HTTP_PORT:-"9082"}
export WMUI_INSTALL_DECLARED_HOSTNAME=${WMUI_INSTALL_DECLARED_HOSTNAME:-"localhost"}
## Framework - Patch
export WMUI_SUM_HOME=${WMUI_SUM_HOME:-"/opt/sag/sum"}
## YAI related
export WMUI_INSTALL_IS_MAIN_HTTP_PORT=${WMUI_INSTALL_IS_MAIN_HTTP_PORT:-"5555"}
export WMUI_INSTALL_IS_DIAGS_HTTP_PORT=${WMUI_INSTALL_IS_DIAGS_HTTP_PORT:-"9999"}

## AT related
export WMUI_INSTALL_MFTSERVER_PORT=${WMUI_INSTALL_MFTSERVER_PORT:-"8500"}

export WMUI_SETUP_TEMPLATE_IS_LICENSE_UrlEncoded=$(urlencode ${WMUI_SETUP_TEMPLATE_IS_LICENSE_FILE})
export WMUI_SETUP_TEMPLATE_MFTSERVER_LICENSE_UrlEncoded=$(urlencode ${WMUI_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE})

# database
## User MUST provide
export WMUI_SQLSERVER_HOSTNAME=${WMUI_SQLSERVER_HOSTNAME:-"ProvideDBHostName!"}
export WMUI_SQLSERVER_DATABASE_NAME=${WMUI_SQLSERVER_DATABASE_NAME:-"ProvideDatabaseName!"}
export WMUI_SQLSERVER_USER_NAME=${WMUI_SQLSERVER_USER_NAME:-"ProvideUserName!"}
export WMUI_SQLSERVER_PASSWORD=${WMUI_SQLSERVER_PASSWORD:-"ProvideUserPAssowrd!"}
## User MAY provide
export WMUI_SQLSERVER_DB_CONN_ALIAS=${WMUI_SQLSERVER_DB_CONN_ALIAS:-"mftDbConn"}
export WMUI_SQLSERVER_PORT=${WMUI_SQLSERVER_PORT:-"1433"}

logI "Template environment sourced successfully"
logEnv4Debug
