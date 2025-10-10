#!/bin/sh

# Depends on framework commons
if [ ! "`type -t urlencode`X" == "functionX" ]; then
    echo "Need the function urlencode(), sourcing commonFunctions.sh "
    if [ ! -f "$WMUI_CACHE_HOME/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue!"
        exit 500
    fi
    . "$WMUI_CACHE_HOME/01.scripts/commonFunctions.sh"
fi

# Section 1 - the caller MUST provide
## Framework - Install
export WMUI_INSTALL_INSTALLER_BIN=${WMUI_INSTALL_INSTALLER_BIN:-"/path/to/installer.bin"}
export WMUI_INSTALL_IMAGE_FILE=${WMUI_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}
## Framework - Patch
export WMUI_PATCH_SUM_BOOTSTRAP_BIN=${WMUI_PATCH_SUM_BOOTSTRAP_BIN:-"/path/to/sum-boostrap.bin"}
export WMUI_PATCH_FIXES_IMAGE_FILE=${WMUI_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}
## Current Template
export WMUI_SETUP_TEMPLATE_TES_LICENSE_FILE=${WMUI_SETUP_TEMPLATE_TES_LICENSE_FILE:-"/provide/path/to/terracotta-license.key"}

# Section 2 - the caller MAY provide
## Framework - Install
export WMUI_INSTALL_INSTALL_DIR=${WMUI_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export WMUI_INSTALL_SPM_HTTPS_PORT=${WMUI_INSTALL_SPM_HTTPS_PORT:-"9083"}
export WMUI_INSTALL_SPM_HTTP_PORT=${WMUI_INSTALL_SPM_HTTP_PORT:-"9082"}
## Framework - Patch
export WMUI_SUM_HOME=${WMUI_SUM_HOME:-"/opt/sag/sum"}

## Section 3 - Post processing
## eventually provided values are overwritten!
export WMUI_SETUP_TEMPLATE_TES_LICENSE_UrlEncoded=$(urlencode ${WMUI_SETUP_TEMPLATE_TES_LICENSE_FILE})
