#!/bin/sh

# Dependency 1
if [ ! "`type -t huntForSuifFile`X" == "functionX" ]; then
    echo "sourcing commonFunctions.sh ..."
    if [ ! -f "$WMUI_CACHE_HOME/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue!"
        exit 500
    fi
    . "$WMUI_CACHE_HOME/01.scripts/commonFunctions.sh"
fi

# Dependency 2

if [ ! "`type -t patchInstallation`X" == "functionX" ]; then
    huntForSuifFile "01.scripts/installation" "setupFunctions.sh"

    if [ ! -f "$WMUI_CACHE_HOME/01.scripts/installation/setupFunctions.sh" ];then
        logE "setupFunctions.sh not available, cannot continue."
        exit 1
    fi

    logI "Sourcing setup functions"
    . "$WMUI_CACHE_HOME/01.scripts/installation/setupFunctions.sh"
fi

thisFolder="02.templates/02.post-setup/UpdateManager/v11/PatchInstallation/default"

huntForSuifFile "${thisFolder}" "setEnvDefaults.sh"

if [ ! -f "${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" ]; then
    logE "File not found: ${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
    exit 100
fi

. "${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"

# Parameters - patchInstallation
# $1 - Fixes Image (this will allways happen offline in this framework)
# $2 - OTPIONAL SUM Home, default /opt/sag/sum
# $3 - OTPIONAL Products Home, default /opt/sag/products
patchInstallation "${WMUI_PATCH_FIXES_IMAGE_FILE}" "${WMUI_SUM_HOME}" "${WMUI_INSTALL_INSTALL_DIR}" "${WMUI_ENG_PATCH_MODE}" "${WMUI_ENG_PATCH_DIAGS_KEY}"
