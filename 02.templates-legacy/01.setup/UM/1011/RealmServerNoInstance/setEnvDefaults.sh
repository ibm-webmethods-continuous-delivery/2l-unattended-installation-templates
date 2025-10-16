#!/bin/sh

if [ ! "`type -t urlencode`X" == "functionX" ]; then
    if [ ! -f "${WMUI_CACHE_HOME}/installationScripts/commonFunctions.sh" ]; then
        echo "Panic, common functions not sourced and not present locally! Cannot continue"
        exit 500
    fi
    . "$WMUI_CACHE_HOME/installationScripts/commonFunctions.sh"
fi

############## Section 1 - the caller MUST provide
## Framework - Install
export WMUI_INSTALL_INSTALLER_BIN=${WMUI_INSTALL_INSTALLER_BIN:-"/path/to/installer.bin"}
export WMUI_INSTALL_IMAGE_FILE=${WMUI_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}

## Framework - Patch
export WMUI_PATCH_SUM_BOOTSTRAP_BIN=${WMUI_PATCH_SUM_BOOTSTRAP_BIN:-"/path/to/sum-boostrap.bin"}
export WMUI_PATCH_FIXES_IMAGE_FILE=${WMUI_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

## Template Specific
export WMUI_WMSCRIPT_NUMLicenseFile=${WMUI_WMSCRIPT_NUMLicenseFile:-'/path/to/NUMLicense.xml'}
export WMUI_WMSCRIPT_NUMRealmServerLicenseFiletext=$(urlencode ${WMUI_WMSCRIPT_NUMLicenseFile})
############## Section 1 END - the caller MUST provide

## Current Template

############## Section 2 - the caller MAY provide
## Framework - Install
export WMUI_INSTALL_INSTALL_DIR=${WMUI_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export WMUI_INSTALL_DECLARED_HOSTNAME=${WMUI_INSTALL_DECLARED_HOSTNAME:-"localhost"}
## Framework - Patch
export WMUI_SUM_HOME=${WMUI_SUM_HOME:-"/opt/sag/sum"}
## Template specific
export WMUI_WMSCRIPT_SPMHttpPort=${WMUI_WMSCRIPT_SPMHttpPort:-8092}
export WMUI_WMSCRIPT_SPMHttpsPort=${WMUI_WMSCRIPT_SPMHttpsPort:-8093}
############## Section 2 END - the caller MAY provide

logI "Template environment sourced successfully"
logEnv4Debug
