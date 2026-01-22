#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#
# WARNING: POSIX compatibility is pursued, but this is not a strict POSIX script.
# The following exceptions apply
# - local variables for functions
# shellcheck disable=SC3043

# BREAKING CHANGE: This file now requires posix-shell-utils (2.audit.sh) to be sourced first
# Verify that PU audit is loaded
if [ -z "${__2__audit_session_dir}" ]; then
  echo "FATAL: setupFunctions.sh requires posix-shell-utils (2.audit.sh) to be sourced first!"
  echo "Please source 2l-posix-shell-utils/code/2.audit.sh before sourcing setupFunctions.sh"
  exit 202
fi

if [ ! -d "${__2__audit_session_dir}" ]; then
  echo "FATAL: ${__2__audit_session_dir} does not exist, posix utils audit MUST be correctly sourced before using the setup functions!"
  exit 203
fi

# Source commonFunctions.sh for WMUI-specific utility functions
if [ -f "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
  # shellcheck source=/dev/null
  . "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh"
else
  echo "WARNING: ${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh not found"
fi

init() {
  # Section 1 - the caller MUST provide
  ## Framework - Install
  export WMUI_INSTALL_INSTALLER_BIN="${WMUI_INSTALL_INSTALLER_BIN:-/tmp/installer.bin}"
  export WMUI_INSTALL_IMAGE_FILE="${WMUI_INSTALL_IMAGE_FILE:-/path/to/install/product.image.zip}"
  export WMUI_PATCH_AVAILABLE="${WMUI_PATCH_AVAILABLE:-0}"
  ## Framework - Patch
  export WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN="${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN:-/tmp/upd-mgr-bootstrap.bin}"
  export WMUI_PATCH_FIXES_IMAGE_FILE="${WMUI_PATCH_FIXES_IMAGE_FILE:-/path/to/install/fixes.image.zip}"

  # Section 2 - the caller MAY provide
  ## Framework - Install
  export WMUI_INSTALL_INSTALL_DIR="${WMUI_INSTALL_INSTALL_DIR:-/opt/webmethods/products}"
  export WMUI_INSTALL_SPM_HTTPS_PORT="${WMUI_INSTALL_SPM_HTTPS_PORT:-9083}"
  export WMUI_INSTALL_SPM_HTTP_PORT="${WMUI_INSTALL_SPM_HTTP_PORT:-9082}"
  export WMUI_INSTALL_DECLARED_HOSTNAME="${WMUI_INSTALL_DECLARED_HOSTNAME:-localhost}"
  ## Framework - Patch
  export WMUI_UPD_MGR_HOME="${WMUI_UPD_MGR_HOME:-/opt/webmethods/upd-mgr}"

  ## Section 3 - Extra portability
  export WMUI_TEMP_FS_QUICK="${WMUI_TEMP_FS_QUICK:-/dev/shm}"
  # in some UX systems, /dev/shm is not available, allow for explicit setting
}

init

# Online mode for SDC separated from Online mode for WMUI:
export WMUI_ONLINE_MODE="${WMUI_ONLINE_MODE:-1}"         # default is online for WMUI
export WMUI_SDC_ONLINE_MODE="${WMUI_SDC_ONLINE_MODE:-0}" # default if offline for SDC

# Parameters - installProducts
# $1 - installer binary file
# $2 - script file for installer
# $3 - OPTIONAL: debugLevel for installer
wmui_install_products() {

  if [ ! -f "${1}" ]; then
    pu_log_e "[setupFunctions.sh:installProducts()] - Product installation failed: invalid installer file: ${1}"
    return 1
  fi

  if [ ! -f "${2}" ]; then
    pu_log_e "[setupFunctions.sh:installProducts()] - Product installation failed: invalid installer script file: ${2}"
    return 2
  fi

  if [ ! "$(which envsubst)" ]; then
    pu_log_e "[setupFunctions.sh:installProducts()] - Product installation requires envsubst to be installed!"
    return 3
  fi

  pu_log_i "[setupFunctions.sh:installProducts()] - Installing according to script ${2}"

  local debugLevel="${3:-"verbose"}"
  local d
  d=$(date +%Y-%m-%dT%H.%M.%S_%3N)
  local tempInstallScript="${WMUI_TEMP_FS_QUICK}/install.wmscript"

  # apply environment substitutions
  envsubst <"${2}" >"${tempInstallScript}" || return 5

  # if [ "${WMUI_DEBUG_ON}" -ne 0 ]; then
  #   # preserve in the audit what we are using for installation
  #   # this may contain other passwords, thus do not do this in production
  #   cp "${tempInstallScript}" "${__2__audit_session_dir}/install_$(date +%s).wmscript"
  # fi

  local installCmd="${1} -readScript \"${tempInstallScript}\" -console"
  local installCmd="${installCmd} -debugLvl ${debugLevel}"
  if [ "${WMUI_DEBUG_ON}" -ne 0 ]; then
    local installCmd="${installCmd} -scriptErrorInteract yes"
  else
    local installCmd="${installCmd} -scriptErrorInteract no"
  fi
  local installCmd="${installCmd} -debugFile "'"'"${__2__audit_session_dir}/debugInstall.log"'"'
  pu_audited_exec "${installCmd}" "product-install"

  RESULT_installProducts=$?
  if [ ${RESULT_installProducts} -eq 0 ]; then
    pu_log_i "Product installation successful"
  else
    pu_log_e "[setupFunctions.sh:installProducts()] - Product installation failed, code ${RESULT_installProducts}"
    pu_log_d "[setupFunctions.sh:installProducts()] - Dumping the install.wmscript file into the session audit folder..."
    if [ "${WMUI_DEBUG_ON}" -ne 0 ]; then
      cp "${tempInstallScript}" "${__2__audit_session_dir}/"
    fi
    pu_log_e "[setupFunctions.sh:installProducts()] - Looking for APP_ERROR in the debug file..."
    grep 'APP_ERROR' "${__2__audit_session_dir}/debugInstall.log"
    pu_log_e "[setupFunctions.sh:installProducts()] - returning code 4"
    return 4
  fi
  rm -f "${tempInstallScript}"
}

installProducts() {
  pu_log_e "installProducts is deprecated, use pu_install_products instead"
  pu_install_products "${@}"
}

# Parameters - bootstrapUpdMgr
# $1 - Update Manager Bootstrap file
# $2 - Fixes image file, mandatory for offline mode
# $3 - OPTIONAL Where to install (SUM Home), default /opt/webmethods/upd-mgr
bootstrapUpdMgr() {
  if [ ! -f "${1}" ]; then
    pu_log_e "[setupFunctions.sh:bootstrapUpdMgr()] - Software AG Update Manager Bootstrap file not found: ${1}"
    return 1
  fi

  if [ "${WMUI_SDC_ONLINE_MODE}" -eq 0 ]; then
    if [ ! -f "${2}" ]; then
      pu_log_e "[setupFunctions.sh:bootstrapUpdMgr()] - Fixes image file not found: ${2}"
      return 2
    fi
  fi

  local UPD_MGR_HOME="${3:-"/opt/webmethods/upd-mgr"}"

  if [ -d "${UPD_MGR_HOME}/UpdateManager" ]; then
    pu_log_i "[setupFunctions.sh:bootstrapUpdMgr()] - Update manager already present, skipping bootstrap, attempting to update from given image..."
    patchUpdMgr "${2}" "${UPD_MGR_HOME}"
    return 0
  fi

  local d
  d=$(date +%Y-%m-%dT%H.%M.%S_%3N)

  local bootstrapCmd="${1} --accept-license -d "'"'"${UPD_MGR_HOME}"'"'
  if [ "${WMUI_SDC_ONLINE_MODE}" -eq 0 ]; then
    bootstrapCmd="${bootstrapCmd} -i ${2}"
    # note: everything is always offline except this, as it is not requiring empower credentials
    pu_log_i "[setupFunctions.sh:bootstrapUpdMgr()] - Bootstrapping UPD_MGR from ${1} using image ${2} into ${UPD_MGR_HOME}..."
  else
    pu_log_i "[setupFunctions.sh:bootstrapUpdMgr()] - Bootstrapping UPD_MGR from ${1} into ${UPD_MGR_HOME} using ONLINE mode"
  fi
  pu_audited_exec "${bootstrapCmd}" "upd-mgr-bootstrap"
  RESULT_controlledExec=$?

  if [ ${RESULT_controlledExec} -eq 0 ]; then
    pu_log_i "[setupFunctions.sh:bootstrapUpdMgr()] - UPD_MGR Bootstrap successful"
  else
    pu_log_e "[setupFunctions.sh:bootstrapUpdMgr()] - UPD_MGR Bootstrap failed, code ${RESULT_controlledExec}"
    return 3
  fi
}

# Parameters - patchUpdMgr()
# $1 - Fixes Image (this will allways happen offline in this framework)
# $2 - OPTIONAL UPD_MGR Home, default /opt/webmethods/upd-mgr
patchUpdMgr() {
  if [ "${WMUI_SDC_ONLINE_MODE}" -ne 0 ]; then
    pu_log_i "[setupFunctions.sh:patchUpdMgr()] - patchUpdMgr() ignored in online mode"
    return 0
  fi

  if [ ! -f "${1}" ]; then
    pu_log_e "[setupFunctions.sh:patchUpdMgr()] - Fixes images file ${1} does not exist!"
  fi
  local UPD_MGR_HOME="${2:-'/opt/webmethods/upd-mgr'}"
  local d
  d="$(date +%y-%m-%dT%H.%M.%S_%3N)"

  if [ ! -d "${UPD_MGR_HOME}/UpdateManager" ]; then
    pu_log_i "[setupFunctions.sh:patchUpdMgr()] - Update manager missing, nothing to patch..."
    return 0
  fi

  pu_log_i "[setupFunctions.sh:patchUpdMgr()] - Updating UPD_MGR from image ${1} ..."
  local crtDir
  crtDir=$(pwd)
  cd "${UPD_MGR_HOME}/bin" || return 2
  pu_audited_exec "./UpdateManagerCMD.sh -selfUpdate true -installFromImage "'"'"${1}"'"' "patchUpdMgr"
  RESULT_controlledExec=$?
  if [ "${RESULT_controlledExec}" -ne 0 ]; then
    pu_log_e "[setupFunctions.sh:patchUpdMgr()] - Update Manager Self Update failed with code ${RESULT_controlledExec}"
    return 1
  fi
  cd "${crtDir}" || return 3
}

# Parameters - removeDiagnoserPatch
# $1 - Engineering patch diagnoser key (e.g. "5437713_PIE-68082_5")
# $2 - Engineering patch ids list (expected one id only, but we never know e.g. "5437713_PIE-68082_1.0.0.0005-0001")
# $3 - OPTIONAL UPD_MGR Home, default /opt/webmethods/upd-mgr
# $4 - OPTIONAL Products Home, default /opt/webmethods/products
removeDiagnoserPatch() {
  local UPD_MGR_HOME="${3:-"/opt/webmethods/upd-mgr"}"
  if [ ! -f "${UPD_MGR_HOME}/bin/UpdateManagerCMD.sh" ]; then
    pu_log_e "[setupFunctions.sh:removeDiagnoserPatch()] - Update manager not found at the indicated location ${UPD_MGR_HOME}"
    return 1
  fi
  local PRODUCTS_HOME="${4:-"/opt/webmethods/products"}"
  if [ ! -d "${PRODUCTS_HOME}" ]; then
    pu_log_e "[setupFunctions.sh:removeDiagnoserPatch()] - Product installation folder is missing: ${PRODUCTS_HOME}"
    return 2
  fi

  local d
  d=$(date +%y-%m-%dT%H.%M.%S_%3N)
  local tmpScriptFile="${WMUI_TEMP_FS_QUICK}/fixes.${d}.wmscript.txt"

  {
    echo "installSP=Y"
    echo "diagnoserKey=${1}"
    echo "installDir=${PRODUCTS_HOME}"
    echo "selectedFixes=${2}"
    echo "action=Uninstall fixes"
  } >"${tmpScriptFile}"

  local crtDir
  crtDir=$(pwd)
  cd "${UPD_MGR_HOME}/bin" || return 4

  pu_log_i "[setupFunctions.sh:removeDiagnoserPatch()] - Taking a snapshot of existing fixes..."
  pu_audited_exec './UpdateManagerCMD.sh -action viewInstalledFixes -installDir "'"${PRODUCTS_HOME}"'"' "FixesBeforeSPRemoval"

  pu_log_i "[setupFunctions.sh:removeDiagnoserPatch()] - Removing support patch ${1} from installation ${PRODUCTS_HOME} using UPD_MGR in ${UPD_MGR_HOME}..."
  pu_audited_exec "./UpdateManagerCMD.sh -readScript \"${tmpScriptFile}\"" "SPFixRemoval"
  RESULT_controlledExec=$?

  pu_log_i "[setupFunctions.sh:removeDiagnoserPatch()] - Taking a snapshot of fixes after the execution of SP removal..."
  pu_audited_exec './UpdateManagerCMD.sh -action viewInstalledFixes -installDir "'"${PRODUCTS_HOME}"'"' "FixesAfterSPRemoval"

  cd "${crtDir}" || return 5

  if [ ${RESULT_controlledExec} -eq 0 ]; then
    pu_log_i "[setupFunctions.sh:removeDiagnoserPatch()] - Support patch removal was successful"
  else
    pu_log_e "[setupFunctions.sh:removeDiagnoserPatch()] - Support patch removal failed, code ${RESULT_controlledExec}"
    if [ "${WMUI_DEBUG_ON}" ]; then
      pu_log_d "Recovering Update Manager logs for further investigations"
      mkdir -p "${__2__audit_session_dir}/UpdateManager"
      cp -r "${UPD_MGR_HOME}"/logs "${__2__audit_session_dir}"/
      cp -r "${UPD_MGR_HOME}"/UpdateManager/logs "${__2__audit_session_dir}"/UpdateManager/
      cp "${tmpScriptFile}" "${__2__audit_session_dir}"/
    fi
    return 3
  fi

  if [ "${WMUI_DEBUG_ON}" -ne 0 ]; then
    # if we are debugging, we want to see the generated script
    cp "${tmpScriptFile}" "${__2__audit_session_dir}/fixes.D.${d}.wmscript.txt"
  fi

  rm -f "${tmpScriptFile}"
}

# Parameters - patchInstallation
# $1 - Fixes Image (this will always happen offline in this framework)
# $2 - OPTIONAL UPD_MGR Home, default /opt/webmethods/upd-mgr
# $3 - OPTIONAL Products Home, default /opt/webmethods/products
# $4 - OPTIONAL Engineering patch modifier (default "N")
# $5 - OPTIONAL Engineering patch diagnoser key (default "5437713_PIE-68082_5", however user must provide if $4=Y)
patchInstallation() {
  if [ ! -f "${1}" ]; then
    pu_log_e "[setupFunctions.sh:patchInstallation()] - Fixes image file not found: ${1}"
    return 1
  fi

  local UPD_MGR_HOME="${2:-"/opt/webmethods/upd-mgr"}"
  local PRODUCTS_HOME="${3:-"/opt/webmethods/products"}"
  local d
  d=$(date +%y-%m-%dT%H.%M.%S_%3N)
  local epm="${4:-"N"}"
  local fixesScriptFile="${WMUI_TEMP_FS_QUICK}/fixes.wmscript.txt"

  {
    echo "installSP=${epm}"
    echo "installDir=${PRODUCTS_HOME}"
    echo "selectedFixes=spro:all"
    echo "action=Install fixes from image"
    echo "imageFile=${1}"
    if [ "${epm}" = "Y" ]; then
      local dKey="${5:-"5437713_PIE-68082_5"}"
      echo "diagnoserKey=${dKey}"
    fi
  } >"${fixesScriptFile}"

  local crtDir
  crtDir=$(pwd)
  cd "${UPD_MGR_HOME}/bin" || return 3

  pu_log_i "[setupFunctions.sh:patchInstallation()] - Taking a snapshot of existing fixes..."
  pu_audited_exec './UpdateManagerCMD.sh -action viewInstalledFixes -installDir "'"${PRODUCTS_HOME}"'"' "FixesBeforePatching"

  pu_log_i "[setupFunctions.sh:patchInstallation()] - Explicitly patch UPD_MGR itself, if required..."
  patchUpdMgr "${1}" "${UPD_MGR_HOME}"

  pu_log_i "[setupFunctions.sh:patchInstallation()] - Applying fixes from image ${1} to installation ${PRODUCTS_HOME} using UPD_MGR in ${UPD_MGR_HOME}..."

  pu_audited_exec "./UpdateManagerCMD.sh -readScript \"${fixesScriptFile}\"" "PatchInstallation"
  RESULT_controlledExec=$?

  pu_log_i "[setupFunctions.sh:patchInstallation()] - Taking a snapshot of fixes after the patching..."
  pu_audited_exec './UpdateManagerCMD.sh -action viewInstalledFixes -installDir "'"${PRODUCTS_HOME}"'"' "FixesAfterPatching"

  cd "${crtDir}" || return 4

  if [ ${RESULT_controlledExec} -eq 0 ]; then
    pu_log_i "[setupFunctions.sh:patchInstallation()] - Patch successful"
  else
    pu_log_e "[setupFunctions.sh:patchInstallation()] - Patch failed, code ${RESULT_controlledExec}"
    if [ "${WMUI_DEBUG_ON}" ]; then
      pu_log_d "[setupFunctions.sh:patchInstallation()] - Recovering Update Manager logs for further investigations"
      mkdir -p "${__2__audit_session_dir}/UpdateManager"
      cp -r "${UPD_MGR_HOME}"/logs "${__2__audit_session_dir}"/
      cp -r "${UPD_MGR_HOME}"/UpdateManager/logs "${__2__audit_session_dir}"/UpdateManager/
      cp "${fixesScriptFile}" "${__2__audit_session_dir}"/
    fi
    return 2
  fi

  if [ "${WMUI_DEBUG_ON}" -ne 0 ]; then
    # if we are debugging, we want to see the generated script
    cp "${fixesScriptFile}" "${__2__audit_session_dir}/fixes.${d}.wmscript.txt"
  fi

  rm -f "${fixesScriptFile}"
}

# Parameters - setupProductsAndFixes
# $1 - Installer binary file
# $2 - Script file for installer
# $3 - Update Manager Bootstrap file
# $4 - Fixes Image (this will always happen offline in this framework)
# $5 - OPTIONAL Where to install (SUM Home), default /opt/webmethods/upd-mgr
# $6 - OPTIONAL: debugLevel for installer
setupProductsAndFixes() {

  if [ ! -f "${1}" ]; then
    pu_log_e "[setupFunctions.sh:setupProductsAndFixes()] - Installer binary file not found: ${1}"
    return 1
  fi
  if [ ! -f "${2}" ]; then
    pu_log_e "[setupFunctions.sh:setupProductsAndFixes()] - Installer script file not found: ${2}"
    return 2
  fi

  if [ "${WMUI_PATCH_AVAILABLE}" -ne 0 ]; then
    if [ ! -f "${3}" ]; then
      pu_log_e "[setupFunctions.sh:setupProductsAndFixes()] - Update Manager bootstrap binary file not found: ${3}"
      return 3
    fi
    if [ ! -f "${4}" ]; then
      pu_log_e "[setupFunctions.sh:setupProductsAndFixes()] - Fixes image file not found: ${4}"
      return 4
    fi
  fi
  if [ ! "$(which envsubst)" ]; then
    pu_log_e "[setupFunctions.sh:setupProductsAndFixes()] - Product installation requires envsubst to be installed!"
    return 5
  fi
  # apply environment substitutions
  # Note: this is done twice for reusability reasons
  local installWmscriptFile="${WMUI_TEMP_FS_QUICK}/install.wmscript.tmp"
  envsubst <"${2}" >"${installWmscriptFile}"

  local lProductImageFile
  lProductImageFile=$(grep imageFile "${installWmscriptFile}" | cut -d "=" -f 2)

  # note no inline returns from now as we need to clean locally allocated resources
  if [ ! -f "${lProductImageFile}" ]; then
    pu_log_e "[setupFunctions.sh:setupProductsAndFixes()] - Product image file not found: ${lProductImageFile}. Does the wmscript have the imageFile=... line?"
    RESULT_setupProductsAndFixes=6
  else
    local lInstallDir
    lInstallDir=$(grep InstallDir "${installWmscriptFile}" | cut -d "=" -f 2)
    if [ -d "${lInstallDir}" ]; then
      pu_log_w "[setupFunctions.sh:setupProductsAndFixes()] - Install folder already present..."
      # shellcheck disable=SC2012,SC2046
      if [ $(ls -1A "${lInstallDir}" | wc -l) -gt 0 ]; then
        pu_log_w "[setupFunctions.sh:setupProductsAndFixes()] - Install folder is not empty!"
      fi
    else
      mkdir -p "${lInstallDir}"
    fi
    if [ ! -d "${lInstallDir}" ]; then
      pu_log_e "[setupFunctions.sh:setupProductsAndFixes()] - Cannot create the installation directory!"
      RESULT_setupProductsAndFixes=7
    else
      local d
      d=$(date +%y-%m-%dT%H.%M.%S_%3N)
      local installerDebugLevel="${6:-verbose}"

      # Parameters - installProducts
      # $1 - installer binary file
      # $2 - script file for installer
      # $3 - OPTIONAL: debugLevel for installer
      installProducts "${1}" "${2}" "${installerDebugLevel}"
      RESULT_installProducts=$?
      if [ ${RESULT_installProducts} -ne 0 ]; then
        pu_log_e "[setupFunctions.sh:setupProductsAndFixes()] - installProducts failed, code ${RESULT_installProducts}!"
        RESULT_setupProductsAndFixes=8
      else

        if [ "${WMUI_PATCH_AVAILABLE}" -ne 0 ]; then

          # Parameters - bootstrapUpdMgr
          # $1 - Update Manager Bootstrap file
          # $2 - OPTIONAL Where to install (SUM Home), default /opt/webmethods/upd-mgr
          local lUpdMgrHome="${5:-/opt/webmethods/upd-mgr}"
          bootstrapUpdMgr "${3}" "${4}" "${lUpdMgrHome}"
          local RESULT_bootstrapUpdMgr=$?
          if [ ${RESULT_bootstrapUpdMgr} -ne 0 ]; then
            pu_log_e "[setupFunctions.sh:setupProductsAndFixes()] - Update Manager bootstrap failed, code ${RESULT_bootstrapUpdMgr}!"
            RESULT_setupProductsAndFixes=9
          else
            # Parameters - patchInstallation
            # $1 - Fixes Image (this will always happen offline in this framework)
            # $2 - OPTIONAL UPD_MGR Home, default /opt/webmethods/upd-mgr
            # $3 - OPTIONAL Products Home, default /opt/webmethods/products
            patchInstallation "${4}" "${lUpdMgrHome}" "${lInstallDir}"
            RESULT_patchInstallation=$?
            if [ ${RESULT_patchInstallation} -ne 0 ]; then
              pu_log_e "[setupFunctions.sh:setupProductsAndFixes()] - Patch Installation failed, code ${RESULT_patchInstallation}!"
              RESULT_setupProductsAndFixes=10
            else
              pu_log_i "[setupFunctions.sh:setupProductsAndFixes()] - Product and Fixes setup completed successfully"
              RESULT_setupProductsAndFixes=0
            fi
          fi
        else
          pu_log_i "[setupFunctions.sh:setupProductsAndFixes()] - Skipping patch installation, fixes not available."
          RESULT_setupProductsAndFixes=0
        fi
      fi
    fi
  fi
  rm -f "${installWmscriptFile}"
  return "${RESULT_setupProductsAndFixes}"
}

# Parameters - applySetupTemplate
# $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
# $2 - OPTIONAL: useLatest (YES/NO), default YES. If YES, uses ProductsLatestList.txt, if NO uses ProductsVersionedList.txt
# Environment must have valid values for vars WMUI_CACHE_HOME, WMUI_INSTALL_INSTALLER_BIN, WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN, WMUI_UPD_MGR_HOME
# Environment must also have valid values for the vars required by the referred template
applySetupTemplate() {
  # TODO: render checkPrerequisites.sh optional
  pu_log_i "[setupFunctions.sh:applySetupTemplate()] - Applying Setup Template ${1}"
  wmui_hunt_for_file "02.templates/01.setup/${1}" "template.wmscript" || return 1

  # Hunt for products list files and create enhanced template
  local useLatest="${2:-YES}"
  local productsListFile

  if [ "${useLatest}" = "NO" ]; then
    productsListFile="ProductsVersionedList.txt"
  else
    productsListFile="ProductsLatestList.txt"
  fi

  wmui_hunt_for_file "02.templates/01.setup/${1}" "${productsListFile}" || return 2

  if [ ! -f "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${productsListFile}" ]; then
    pu_log_e "[setupFunctions.sh:applySetupTemplate()] - Products list file not found: ${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${productsListFile}"
    return 2
  fi

  # Create temporary enhanced template with InstallProducts line
  local d
  d=$(date +%Y-%m-%dT%H.%M.%S_%3N)
  local tempEnhancedTemplate="${__2__audit_session_dir}/template_enhanced_${d}.wmscript"

  # Copy original template
  cp "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/template.wmscript" "${tempEnhancedTemplate}"

  # Create sorted CSV from products list and append to template
  local productsListSorted="${__2__audit_session_dir}/products_sorted_${d}.tmp"
  sort "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${productsListFile}" > "${productsListSorted}"
  local productsCsv
  productsCsv=$(linesFileToCsvString "${productsListSorted}")
  local RESULT_linesFileToCsvString=$?

  if [ ${RESULT_linesFileToCsvString} -ne 0 ]; then
    pu_log_e "[setupFunctions.sh:applySetupTemplate()] - Failed to create CSV string from products list"
    rm -f "${productsListSorted}" "${tempEnhancedTemplate}"
    return 3
  fi

  echo "InstallProducts=${productsCsv}" >> "${tempEnhancedTemplate}"
  rm -f "${productsListSorted}"

  pu_log_i "[setupFunctions.sh:applySetupTemplate()] - Created enhanced template with $(wc -l < "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${productsListFile}") products from ${productsListFile}"

  # environment defaults for setup
  pu_log_i "[setupFunctions.sh:applySetupTemplate()] - Sourcing variable values for template ${1} ..."
  wmui_hunt_for_file "02.templates/01.setup/${1}" "setEnvDefaults.sh"
  if [ ! -f "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/setEnvDefaults.sh" ]; then
    pu_log_i "[setupFunctions.sh:applySetupTemplate()] - Template ${1} does not have any default variable values, file ${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/setEnvDefaults.sh has not been provided."
  else
    pu_log_i "[setupFunctions.sh:applySetupTemplate()] - Sourcing ${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/setEnvDefaults.sh ..."
    chmod u+x "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/setEnvDefaults.sh" >/dev/null
    #shellcheck source=/dev/null
    . "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/setEnvDefaults.sh"
  fi

  checkSetupTemplateBasicPrerequisites
  local RESULT_checkSetupTemplateBasicPrerequisites=$?
  if [ ${RESULT_checkSetupTemplateBasicPrerequisites} -ne 0 ]; then
    pu_log_e "[setupFunctions.sh:applySetupTemplate()] - Basic prerequisites check failed with code ${RESULT_checkSetupTemplateBasicPrerequisites}"
    return 100
  fi

  ### Eventually check prerequisites
  wmui_hunt_for_file "02.templates/01.setup/${1}" "checkPrerequisites.sh" || pu_log_i
  if [ -f "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/checkPrerequisites.sh" ]; then
    pu_log_i "[setupFunctions.sh:applySetupTemplate()] - Checking installation prerequisites for template ${1} ..."
    chmod u+x "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/checkPrerequisites.sh" >/dev/null
    "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/checkPrerequisites.sh" || return 5
  else
    pu_log_i "[setupFunctions.sh:applySetupTemplate()] - Check prerequisites script not present, skipping check..."
  fi

  pu_log_i "[setupFunctions.sh:applySetupTemplate()] - Setting up products and fixes for template ${1} ..."
  setupProductsAndFixes \
    "${WMUI_INSTALL_INSTALLER_BIN}" \
    "${tempEnhancedTemplate}" \
    "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}" \
    "${WMUI_PATCH_FIXES_IMAGE_FILE}" \
    "${WMUI_UPD_MGR_HOME}" \
    "verbose"
  local RESULT_setupProductsAndFixes=$?

  # Clean up temporary enhanced template
  rm -f "${tempEnhancedTemplate}"

  if [ ${RESULT_setupProductsAndFixes} -ne 0 ]; then
    pu_log_e "[setupFunctions.sh:applySetupTemplate()] - Setup for template ${1} failed, code ${RESULT_setupProductsAndFixes}"
    return 4
  fi
}

# # Parameters - assureDownloadableFile
# # $1 - Target File: a local path of the file to be assured
# # $2 - URL from where to get
# # $3 - SHA256 sum of the file (Use before reuse: for now we only need sha256sum)
# # $4 - Optional (future TODO - BA user for the URL)
# # $5 - Optional (future TODO - BA pass for the URL)
# assureDownloadableFile() {
#   if [ ! -f "${1}" ]; then
#     pu_log_i "[setupFunctions.sh:assureDownloadableFile()] - File ${1} does not exist, attempting download from ${2}"
#     if ! which sha256sum > /dev/null; then
#       pu_log_e "[setupFunctions.sh:assureDownloadableFile()] - Cannot find sha256sum"
#       return 5
#     fi

#     if ! which curl > /dev/null; then
#       pu_log_e "[setupFunctions.sh:assureDownloadableFile()] - Cannot find curl"
#       return 1
#     fi

#     if ! curl "${2}" -o "${1}"; then
#       pu_log_e "[setupFunctions.sh:assureDownloadableFile()] - Cannot download from ${2}"
#       return 2
#     fi

#     if [ ! -f "${1}" ]; then
#       pu_log_e "[setupFunctions.sh:assureDownloadableFile()] - File ${1} waa not downloaded even if curl command succeded"
#       return 3
#     fi
#   fi
#   if ! echo "${3}  ${1}" | sha256sum -c -; then
#     pu_log_e "[setupFunctions.sh:assureDownloadableFile()] - sha256sum check for file ${1} failed"
#     pu_log_e "[setupFunctions.sh:assureDownloadableFile()] - sha256sum expected was ${3}, actual is"
#     sha256sum "${1}"
#     return 4
#   fi
# }

# # Parameters
# # $1 - OPTIONAL installer binary location, defaulted to ${WMUI_INSTALL_INSTALLER_BIN}, which is also defaulted to /tmp/installer.bin
# assureDefaultInstaller() {
#   local installerUrl="https://delivery04.dhe.ibm.com/sar/CMA/OSA/0cx80/2/IBM_webMethods_Install_Linux_x64.bin"
#   local installerSha256Sum="07ecdff4efe4036cb5ef6744e1a60b0a7e92befed1a00e83b5afe9cdfd6da8d3"
#   WMUI_INSTALL_INSTALLER_BIN="${WMUI_INSTALL_INSTALLER_BIN:-/tmp/installer.bin}"
#   local installerBin="${1:-$WMUI_INSTALL_INSTALLER_BIN}"
#   if ! assureDownloadableFile "${installerBin}" "${installerUrl}" "${installerSha256Sum}"; then
#     pu_log_e "[setupFunctions.sh:assureDefaultInstaller()] - Cannot assure default installer!"
#     return 1
#   fi
#   chmod u+x "${installerBin}"
# }

# # Parameters
# # $1 - OPTIONAL UPD_MGR bootstrap binary location, defaulted to ${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}, which is also defaulted to /tmp/upd-mgr-bootstrap.bin
# assureDefaultUpdMgrBootstrap() {
#   local updMgrBootstrapUrl="https://delivery04.dhe.ibm.com/sar/CMA/OSA/0crqw/0/IBM_webMethods_Update_Mnger_Linux_x64.bin"
#   local updMgrBootstrapSha256Sum="a997a690c00efbb4668323d434fa017a05795c6bf6064905b640fa99a170ff55"
#   WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN="${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN:-/tmp/upd-mgr-bootstrap.bin}"
#   local lUpdMgrBootstrap="${1:-$WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}"
#   if ! assureDownloadableFile "${lUpdMgrBootstrap}" "${updMgrBootstrapUrl}" "${updMgrBootstrapSha256Sum}"; then
#     pu_log_e "[setupFunctions.sh:assureDefaultUpdMgrBootstrap()] - Cannot assure default sum bootstrap!"
#     return 1
#   fi
#   chmod u+x "${lUpdMgrBootstrap}"
# }

# TODO: generalize
# Parameters
# $1 -> setup template
# $2 -> OPTIONAL - output folder, default /tmp/images/product
# $3 -> OPTIONAL - fixes tag. Defaulted to current day
# $4 -> OPTIONAL - platform string, default LNXAMD64
# $5 -> OPTIONAL - update manager home, default /tmp/upd-mgr-v11
# $6 -> OPTIONAL - upd-mgr-bootstrap binary location, default /tmp/upd-mgr-bootstrap.bin
# $7 -> OPTIONAL: useLatest (YES/NO), default YES. If YES, uses ProductsLatestList.txt, if NO uses ProductsVersionedList.txt

# NOTE: pass SDC credentials in env variables WMUI_EMPOWER_USER and WMUI_EMPOWER_PASSWORD
generateFixesImageFromTemplate() {
  local lCrtDate
  lCrtDate="$(date +%y-%m-%d)"
  local d
  d="$(date +%y-%m-%dT%H.%M.%S_%3N)"
  local lFixesTag="${3:-$lCrtDate}"
  pu_log_i "[setupFunctions.sh:generateFixesImageFromTemplate()] - Addressing fixes image for setup template ${1} and tag ${lFixesTag}..."

  local lOutputDir="${2:-/tmp/images/fixes}"
  local lFixesDir="${lOutputDir}/${1}/${lFixesTag}"
  mkdir -p "${lFixesDir}"
  local lFixesImageFile="${lFixesDir}/fixes.zip"
  local lPermanentInventoryFile="${lFixesDir}/inventory.json"
  local lPermanentScriptFile="${lFixesDir}/createFixesImage.wmscript"
  local lPlatformString="${4:-LNXAMD64}"

  if [ -f "${lFixesImageFile}" ]; then
    pu_log_i "[setupFunctions.sh:generateFixesImageFromTemplate()] - Fixes image for template ${1} and tag ${lFixesTag} already exists, nothing to do."
    return 0
  fi

  local lUpdMgrHome="${5:-/tmp/upd-mgr-v11}"
  if [ ! -d "${lUpdMgrHome}/bin" ]; then
    pu_log_w "[setupFunctions.sh:generateFixesImageFromTemplate()] - UPD_MGR Home does not contain a UPD_MGR installation, trying to bootstrap now..."
    local lUpdMgrBootstrapBin="${6:-/tmp/upd-mgr-bootstrap.bin}"
    if [ ! -f "${lUpdMgrBootstrapBin}" ]; then
      pu_log_w "[setupFunctions.sh:generateFixesImageFromTemplate()] - UPD_MGR Bootstrap binary not found, trying to obtain the default one..."
      assureDefaultUpdMgrBootstrap "${lUpdMgrBootstrapBin}" || return $?
      # Parameters - bootstrapUpdMgr
      # $1 - Update Manager Bootstrap file
      # $2 - Fixes image file, mandatory for offline mode
      # $3 - OPTIONAL Where to install (UPD_MGR Home), default /opt/webmethods/upd-mgr
      # NOTE: WMUI_SDC_ONLINE_MODE must be 1 (non 0)
      bootstrapUpdMgr "${lUpdMgrBootstrapBin}" '' "${lUpdMgrHome}" || return $?
    fi
  fi

  if [ -f "${lPermanentInventoryFile}" ]; then
    pu_log_i "[setupFunctions.sh:generateFixesImageFromTemplate()] - Inventory file ${lPermanentInventoryFile} already exists, skipping creation."
  else
    pu_log_i "[setupFunctions.sh:generateFixesImageFromTemplate()] - Inventory file ${lPermanentInventoryFile} does not exists, creating now."

    wmui_hunt_for_file "02.templates/01.setup/${1}" "template.wmscript"

    if [ ! -f "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/template.wmscript" ]; then
      pu_log_e "[setupFunctions.sh:generateFixesImageFromTemplate()] - Required file ${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/template.wmscript not found, cannot continue"
      return 2
    fi

    # Hunt for products list files and create enhanced template
    local lUseLatest="${7:-YES}"
    local lProductsListFile="ProductsLatestList.txt"

    if [ "${lUseLatest}" = "NO" ]; then
      lProductsListFile="ProductsVersionedList.txt"
    fi

    wmui_hunt_for_file "02.templates/01.setup/${1}" "${lProductsListFile}"

    if [ ! -f "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${lProductsListFile}" ]; then
      pu_log_e "[setupFunctions.sh:applySetupTemplate()] - Products list file not found: ${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${productsListFile}"
      return 2
    fi

    # Parameters - generateInventoryFileFromProductsList
    # $1 - input file path (products list file)
    # $2 - output file path (JSON inventory file)
    # $3 - OPTIONAL: sum version string, defaults to "10.5.0"
    # $4 - OPTIONAL: platform string, defaults to "LNXAMD64"
    # $5 - OPTIONAL: WMUI version string, defaults to "1005"
    # $6 - OPTIONAL: update manager version, defaults to "11.0.0.0000-0117"
    # $7 - OPTIONAL: platform group string, defaults to "\"UNX-ANY\",\"LNX-ANY\""
    generateInventoryFileFromProductsList \
      "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${lProductsListFile}" \
      "${lPermanentInventoryFile}" \
      "" "${lPlatformString}"
  fi

  if [ -f "${lPermanentScriptFile}" ]; then
    pu_log_i "[setupFunctions.sh:generateFixesImageFromTemplate()] - Permanent script file ${lPermanentScriptFile} already exists, skipping creation..."
  else
    pu_log_i "[setupFunctions.sh:generateFixesImageFromTemplate()] - Permanent script file ${lPermanentScriptFile} does not exist, creating now..."
    {
      echo "# Generated"
      echo "scriptConfirm=N"
      # use before reuse -> diagnosers not covered for now
      echo "installSP=N"
      echo "action=Create or add fixes to fix image"
      echo "selectedFixes=spro:all"
      echo "installDir=${lPermanentInventoryFile}"
      echo "imagePlatform=${lPlatformString}"
      echo "createEmpowerImage=C"
    } >"${lPermanentScriptFile}"
  fi

  local lCmd="./UpdateManagerCMD.sh -selfUpdate false -readScript "'"'"${lPermanentScriptFile}"'"'
  lCmd="${lCmd} -installDir "'"'"${lPermanentInventoryFile}"'"'
  lCmd="${lCmd} -imagePlatform ${lPlatformString}"
  lCmd="${lCmd} -createImage "'"'"${lFixesImageFile}"'"'
  lCmd="${lCmd} -empowerUser ${WMUI_EMPOWER_USER}"
  pu_log_d "SUM command to execute: ${lCmd} -empowerPass ***"
  lCmd="${lCmd} -empowerPass '${WMUI_EMPOWER_PASSWORD}'"

  local crtDir
  crtDir=$(pwd)

  cd "${lUpdMgrHome}/bin" || return 3

  pu_audited_exec "${lCmd}" "Create-fixes-image-for-template-$(pu_str_substitute "$1" "/" "-")-tag-${lFixesTag}"
  local lResultFixCreation=$?

  if [ ${lResultFixCreation} -ne 0 ]; then
    pu_log_w "[setupFunctions.sh:generateFixesImageFromTemplate()] - Fix image creation for template ${1} failed with code ${lResultFixCreation}! Saving troubleshooting information into the destination folder"
    pu_log_i "[setupFunctions.sh:generateFixesImageFromTemplate()] - Archiving destination folder results, which are partial at best..."
    cd "${lFixesDir}" || return 1
    tar czf "dump.tgz" ./* --remove-files
    mkdir -p "${lFixesDir}/$d"
    mv "dump.tgz" "${lFixesDir}/$d"/
    cd "${lUpdMgrHome}" || return 1
    pu_log_d "[setupFunctions.sh:generateFixesImageFromTemplate()] - Listing all log files produced by Update Manager"
    find . -type f -name "*.log"

    # ensure the password is not in the logs before sending them to archiving
    cmd="grep -rl '${WMUI_EMPOWER_PASSWORD}' . | xargs sed -i 's/${WMUI_EMPOWER_PASSWORD}/HIDDEN_PASSWORD/g'"
    eval "${cmd}"
    unset cmd

    find . -type f -regex '\(.*\.log\|.*\.log\.[0-9]*\)' -print0 | xargs -0 tar cfvz "${lFixesDir}/$d/sum_logs.tgz"
    pu_log_i "[setupFunctions.sh:generateFixesImageFromTemplate()] - Dump complete"
    cd "${crtDir}" || return 4
    return 3
  fi

  cd "${crtDir}" || return 5
  pu_log_i "[setupFunctions.sh:generateFixesImageFromTemplate()] - Fix image creation for template ${1} finished successfully"
}

# Parameters
# $1 -> setup template
# $2 -> OPTIONAL - installer binary location, default /tmp/installer.bin
# $3 -> OPTIONAL - output folder, default /tmp/images/product
# $4 -> OPTIONAL - platform string, default LNXAMD64
# $5 -> OPTIONAL: useLatest (YES/NO), default YES. If YES, uses ProductsLatestList.txt, if NO uses ProductsVersionedList.txt

# NOTE: default URLs for download are fit for Europe. Use the ones without "-hq" for Americas
# NOTE: pass SDC credentials in env variables WMUI_EMPOWER_USER and WMUI_EMPOWER_PASSWORD
# NOTE: ${WMUI_TEMP_FS_QUICK}/productsImagesList.txt may be created upfront if image caches are available
generateProductsImageFromTemplate() {

  local lDebugOn="${WMUI_DEBUG_ON:-0}"

  pu_log_i "[setupFunctions.sh:generateProductsImageFromTemplate()] - Addressing products image for setup template ${1}..."
  local lInstallerBin="${2:-/tmp/installer.bin}"
  if [ ! -f "${lInstallerBin}" ]; then
    pu_log_e "[setupFunctions.sh:generateProductsImageFromTemplate()] - Installer file ${lInstallerBin} not found, attempting to use the default one..."
    assureDefaultInstaller "${lInstallerBin}" || return 1
  fi
  local lProductImageOutputDir="${3:-/tmp/images/product}"
  local lProductsImageFile="${lProductImageOutputDir}/${1}/products.zip"

  if [ -f "${lProductsImageFile}" ]; then
    pu_log_i "[setupFunctions.sh:generateProductsImageFromTemplate()] - Products image for template ${1} already exists, nothing to do."
    return 0
  fi

  local lDebugLogFile="${lProductImageOutputDir}/${1}/debug.log"

  local lPermanentScriptFile="${lProductImageOutputDir}/${1}/createProductImage.wmscript"
  if [ -f "${lPermanentScriptFile}" ]; then
    pu_log_i "[setupFunctions.sh:generateProductsImageFromTemplate()] - Permanent product image creation script file already present... Using the existing one."
  else
    pu_log_i "[setupFunctions.sh:generateProductsImageFromTemplate()] - Permanent product image creation script file not present, creating now..."
    local lPlatformString="${4:-LNXAMD64}"

    #Address download server URL
    local lSdcServerUrl
    case "${1}" in
    *"/1005/"*)
      lSdcServerUrl=${WMUI_SDC_SERVER_URL_1005:-"https\://sdc.webmethods.io/cgi-bin/dataservewebM105.cgi"}
      ;;
    *"/1007/"*)
      lSdcServerUrl=${WMUI_SDC_SERVER_URL_1007:-"https\://sdc.webmethods.io/cgi-bin/dataservewebM107.cgi"}
      ;;
    *"/1011/"*)
      lSdcServerUrl=${WMUI_SDC_SERVER_URL_1011:-"https\://sdc.webmethods.io/cgi-bin/dataservewebM1011.cgi"}
      ;;
    *"/1015/"*)
      lSdcServerUrl=${WMUI_SDC_SERVER_URL_1015:-"https\://sdc.webmethods.io/cgi-bin/dataservewebM1015.cgi"}
      ;;
    *"/1101/"*)
      lSdcServerUrl=${WMUI_SDC_SERVER_URL_1101:-"https\://sdc.webmethods.io/cgi-bin/dataservewebM111.cgi"}
      ;;
    *)
      lSdcServerUrl=${WMUI_SDC_SERVER_URL_DEFAULT:-"https\://sdc.webmethods.io/cgi-bin/dataservewebM111.cgi"}
      ;;
    esac

    wmui_hunt_for_file "02.templates/01.setup/${1}" "template.wmscript"

    if [ ! -f "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/template.wmscript" ]; then
      pu_log_e "[setupFunctions.sh:generateProductsImageFromTemplate()] - Template script ${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/template.wmscript cannot be recovered, cannot continue"
      return 1
    fi

    # Hunt for products list files and create enhanced template
    local useLatest="${5:-YES}"
    local lProductsListFile="ProductsLatestList.txt"

    if [ "${lUseLatest}" == "NO" ]; then
      lProductsListFile="ProductsVersionedList.txt"
    fi

    wmui_hunt_for_file "02.templates/01.setup/${1}" "${lProductsListFile}"

    if [ ! -f "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${lProductsListFile}" ]; then
      pu_log_e "[setupFunctions.sh:applySetupTemplate()] - Products list file not found: ${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${productsListFile}"
      return 2
    fi

    local lProductsCsv
    lProductsCsv=$(linesFileToCsvString "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${lProductsListFile}")

    pu_log_i "[setupFunctions.sh:generateProductsImageFromTemplate()] - Creating permanent product image creation script from template file ${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/template.wmscript "
    mkdir -p "${lProductImageOutputDir}/${1}"
    {
      echo "###Generated"
      echo "LicenseAgree=Accept"
      echo "InstallLocProducts="
      # shellcheck disable=SC2002
      cat "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/template.wmscript" | grep "InstallProducts"
      echo "imagePlatform=${lPlatformString}"
      echo "imageFile=${lProductsImageFile}"
      echo "ServerURL=${lSdcServerUrl}"
      echo "InstallProducts=${lProductsCsv}"
    } >"${lPermanentScriptFile}"

    pu_log_i "[setupFunctions.sh:generateProductsImageFromTemplate()] - Permanent product image creation script file created"
  fi

  pu_log_i "[setupFunctions.sh:generateProductsImageFromTemplate()] - Creating the volatile script ..."
  local lVolatileScriptFile="${WMUI_TEMP_FS_QUICK}/WMUI/setup/templates/${1}/createProductImage.wmscript"
  mkdir -p "${WMUI_TEMP_FS_QUICK}/WMUI/setup/templates/${1}/"
  cp "${lPermanentScriptFile}" "${lVolatileScriptFile}"
  echo "Username=${WMUI_EMPOWER_USER}" >>"${lVolatileScriptFile}"
  echo "Password=${WMUI_EMPOWER_PASSWORD}" >>"${lVolatileScriptFile}"
  pu_log_i "[setupFunctions.sh:generateProductsImageFromTemplate()] - Volatile script created."

  ## TODO: check if error management enforcement is needed: what if the grep produced nothing?
  ## TODO: deal with \ escaping in the password. For now avoid using '\' - backslash in the password string

  ## TODO: not space safe, but it shouldn't matter for now
  local lCmd="${lInstallerBin} -console -readScript ${lVolatileScriptFile}"
  if [ "${lDebugOn}" -ne 0 ]; then
    lCmd="${lCmd} -debugFile '${lDebugLogFile}' -debugLvl verbose"
  fi
  lCmd="${lCmd} -writeImage ${lProductsImageFile}"
  # explicitly tell installer we are running unattended
  lCmd="${lCmd} -scriptErrorInteract no"

  # avoid downloading what we already have
  if [ -s "${WMUI_TEMP_FS_QUICK}/productsImagesList.txt" ]; then
    lCmd="${lCmd} -existingImages \"${WMUI_TEMP_FS_QUICK}/productsImagesList.txt\""
  fi

  pu_log_i "[setupFunctions.sh:generateProductsImageFromTemplate()] - Creating the product image ${lProductsImageFile}... This may take some time..."
  pu_log_d "[setupFunctions.sh:generateProductsImageFromTemplate()] - Command is ${lCmd}"
  pu_audited_exec "${lCmd}" "Create-products-image-for-template-$(pu_str_substitute "$1" "/" "-")"
  local lCreateImgResult=$?
  pu_log_i "[setupFunctions.sh:generateProductsImageFromTemplate()] - Image ${lProductsImageFile} creation completed, result: ${lCreateImgResult}"
  rm -f "${lVolatileScriptFile}"

  return ${lCreateImgResult}
}

# No params. This function checks the basic prerequisites for any setup template
checkSetupTemplateBasicPrerequisites() {

  errCount=0

  # check WMUI_INSTALL_INSTALLER_BIN
  if [ -z "${WMUI_INSTALL_INSTALLER_BIN+x}" ]; then
    pu_log_e "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - Variable WMUI_INSTALL_INSTALLER_BIN was not set!"
    errCount=$((errCount+1))
  else
    if [ ! -f "${WMUI_INSTALL_INSTALLER_BIN}" ]; then
      pu_log_e "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - Declared variable WMUI_INSTALL_INSTALLER_BIN=${WMUI_INSTALL_INSTALLER_BIN} does not point to a valid file."
      errCount=$((errCount+1))
    else
      pu_log_i "WMUI_INSTALL_INSTALLER_BIN=${WMUI_INSTALL_INSTALLER_BIN}"
      if [ ! -x "${WMUI_INSTALL_INSTALLER_BIN}" ]; then
        pu_log_w "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - Declared variable WMUI_INSTALL_INSTALLER_BIN=${WMUI_INSTALL_INSTALLER_BIN} point to a file that is not executable. Attempting to chmod now..."
        chmod u+x "${WMUI_INSTALL_INSTALLER_BIN}"
        local RESULT_chmod=$?
        if [ ! -x "${WMUI_INSTALL_INSTALLER_BIN}" ]; then
          pu_log_e "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - chmod u+x ${WMUI_INSTALL_INSTALLER_BIN} failed! Command return code was ${RESULT_chmod}"
          errCount=$((errCount+1))
        fi
      fi
    fi
  fi

  # check WMUI_INSTALL_IMAGE_FILE
  if [ -z "${WMUI_INSTALL_IMAGE_FILE+x}" ]; then
    pu_log_e "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - Variable WMUI_INSTALL_IMAGE_FILE was not set!"
    errCount=$((errCount+1))
  else
    if [ ! -f "${WMUI_INSTALL_IMAGE_FILE}" ]; then
      pu_log_e "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - Declared variable WMUI_INSTALL_IMAGE_FILE=${WMUI_INSTALL_IMAGE_FILE} does not point to a valid file."
      errCount=$((errCount+1))
    else
      pu_log_i "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - WMUI_INSTALL_IMAGE_FILE=${WMUI_INSTALL_IMAGE_FILE}"
    fi
  fi

  pu_log_i "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - WMUI_INSTALL_INSTALLER_BIN=${WMUI_INSTALL_INSTALLER_BIN}"
  pu_log_i "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - WMUI_INSTALL_IMAGE_FILE=${WMUI_INSTALL_IMAGE_FILE}"
  pu_log_i "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - WMUI_PATCH_AVAILABLE=${WMUI_PATCH_AVAILABLE}"

  if [ "${WMUI_PATCH_AVAILABLE}" -ne 0 ]; then
    # check WMUI_INSTALL_IMAGE_FILE
    if [ -z "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN+x}" ]; then
      pu_log_e "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - Variable WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN was not set!"
      errCount=$((errCount+1))
    else
      if [ ! -f "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}" ]; then
        pu_log_e "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - File declared in the variable WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN=${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN} does not exist!"
        errCount=$((errCount+1))
      else
        pu_log_i "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN=${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}"
        if [ ! -x "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}" ]; then
          pu_log_w "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - Declared variable WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN=${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN} file exists, but is not executable. Attempting to chmod now..."
          chmod u+x "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}"
          local RESULT_chmod=$?
          if [ ! -x "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}" ]; then
            pu_log_e "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - chmod u+x ${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN} Failed! The command exit code was ${RESULT_chmod}."
            errCount=$((errCount+1))
          fi
        fi
      fi
    fi

    if [ -z "${WMUI_PATCH_FIXES_IMAGE_FILE+x}" ]; then
      pu_log_e "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - Variable WMUI_PATCH_FIXES_IMAGE_FILE was not set!"
      errCount=$((errCount+1))
    else
      if [ ! -f "${WMUI_PATCH_FIXES_IMAGE_FILE}" ]; then
        pu_log_e "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - Declared variable WMUI_PATCH_FIXES_IMAGE_FILE=${WMUI_PATCH_FIXES_IMAGE_FILE} does not point to a valid file."
        errCount=$((errCount+1))
      else
        pu_log_i "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - WMUI_PATCH_FIXES_IMAGE_FILE=${WMUI_PATCH_FIXES_IMAGE_FILE}"
      fi
    fi

  fi

  if [ $errCount -ne 0 ]; then
    pu_log_e "[setupFunctions.sh:checkSetupTemplateBasicPrerequisites()] - $errCount errors found! Cannot continue!"
    return 100
  fi
}

# # Parameters - generateInventoryFileFromProductsList
# # $1 - input file path (products list file)
# # $2 - output file path (JSON inventory file)
# # $3 - OPTIONAL: sum version string, defaults to "10.5.0"
# # $4 - OPTIONAL: platform string, defaults to "LNXAMD64"
# # $5 - OPTIONAL: WMUI version string, defaults to "1005"
# # $6 - OPTIONAL: update manager version, defaults to "11.0.0.0000-0117"
# # $7 - OPTIONAL: platform group string, defaults to "\"UNX-ANY\",\"LNX-ANY\""
# generateInventoryFileFromProductsList() {
#   local inputFile="${1}"
#   local outputFile="${2}"
#   local sumVersionString="${3:-10.5.0}"
#   local sumPlatformString="${4:-LNXAMD64}"
#   local wmuiVersionString="${5:-1005}"
#   local updateManagerVersion="${6:-11.0.0.0000-0117}"
#   local sumPlatformGroupString="${7:-\"UNX-ANY\",\"LNX-ANY\"}"

#   # Check required parameters
#   if [ -z "$inputFile" ] || [ -z "$outputFile" ]; then
#     pu_log_e "[setupFunctions.sh:generateInventoryFileFromProductsList()] - Both input file and output file are required"
#     return 1
#   fi

#   # Check if input file exists
#   if [ ! -f "$inputFile" ]; then
#     pu_log_e "[setupFunctions.sh:generateInventoryFileFromProductsList()] - Input file '$inputFile' does not exist"
#     return 2
#   fi

#   # Read all non-empty lines from the products list file
#   local productLines
#   productLines=$(grep -v '^[[:space:]]*$' "$inputFile")

#   if [ -z "$productLines" ]; then
#     pu_log_e "[setupFunctions.sh:generateInventoryFileFromProductsList()] - No products found in file '$inputFile'"
#     return 3
#   fi

#   # Create temporary files for processing
#   local tempDir
#   tempDir=$(mktemp -d)
#   local productsFile="$tempDir/products.tmp"

#   # Cleanup function
#   cleanup() {
#     rm -rf "$tempDir"
#   }
#   trap cleanup EXIT

#   # Process each product line
#   echo "$productLines" | while IFS= read -r productLine; do
#     # Parse format: e2ei/11/PRODUCT_VERSION.LATEST/Category/ProductCode
#     # Use parameter expansion to split the path
#     local remaining="$productLine"
#     local part1="${remaining%%/*}"; remaining="${remaining#*/}"
#     local part2="${remaining%%/*}"; remaining="${remaining#*/}"
#     local versionPart="${remaining%%/*}"; remaining="${remaining#*/}"
#     local part4="${remaining%%/*}"; remaining="${remaining#*/}"
#     local productCode="$remaining"

#     if [ -n "$productCode" ] && [ -n "$versionPart" ]; then
#       # Clean up product_code (remove any trailing whitespace or newlines)
#       productCode=$(printf '%s' "$productCode" | tr -d '\n\r' | sed 's/[[:space:]]*$//')

#       # Extract version from format like "PRODUCT_11.1.0.0.LATEST"
#       # Use sed to extract version pattern
#       local productVersion
#       productVersion=$(echo "$versionPart" | sed -n 's/.*_\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)\..*$/\1/p')

#       # If version extraction failed, use default
#       if [ -z "$productVersion" ]; then
#         productVersion="$sumVersionString"
#       fi

#       # Store product code and version (using unique keys)
#       echo "$productCode:$productVersion" >> "$productsFile"
#     fi
#   done

#   # Check if any products were processed
#   if [ ! -f "$productsFile" ] || [ ! -s "$productsFile" ]; then
#     pu_log_e "[setupFunctions.sh:generateInventoryFileFromProductsList()] - No products could be parsed from file '$inputFile'"
#     cleanup
#     return 4
#   fi

#   # Function to escape JSON strings
#   escape_json() {
#     # Remove any trailing newlines and escape JSON special characters
#     printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | tr -d '\n'
#   }

#   # Generate JSON output
#   {
#     echo "{"
#     echo "    \"installedProducts\": ["

#     # Process unique products and generate JSON entries
#     sort -u "$productsFile" | {
#       local first=true
#       while IFS=: read -r productId productVersion; do
#         if [ "$first" = true ]; then
#           first=false
#         else
#           echo ","
#         fi
#         echo "        {"
#         echo "            \"productId\": \"$(escape_json "$productId")\","
#         echo "            \"version\": \"$(escape_json "$productVersion")\","
#         echo "            \"displayName\": \"$(escape_json "$productId")\""
#         printf "        }"
#       done
#       echo ""
#     }

#     echo "    ],"
#     echo "    \"installedFixes\": [],"
#     echo "    \"installedSupportPatches\": [],"
#     echo "    \"envVariables\": {"
#     echo "        \"platformGroup\": [$sumPlatformGroupString],"
#     echo "        \"UpdateManagerVersion\": \"$updateManagerVersion\","
#     echo "        \"Hostname\": \"localhost\","
#     echo "        \"platform\": \"$sumPlatformString\""
#     echo "    }"
#     echo "}"
#   } > "$outputFile"

#   cleanup
#   pu_log_i "[setupFunctions.sh:generateInventoryFileFromProductsList()] - Successfully generated inventory file: $outputFile"
#   return 0
# }

setupFunctionsSourced(){
  return 0
}

pu_log_i "[setupFunctions.sh] - Setup Functions sourced"


# Parameters - mergeProductLists
# $1 - Space-separated list of template IDs (e.g., "DBC/1101/full APIGateway/1101/cds-e2e-postgres")
# $2 - Label for the output file (e.g., "combined")
# $3 - OPTIONAL: Destination folder (default: /tmp)
# Output: Creates a file named ${2}.productlist.txt in the destination folder
# The file contains the union of all ProductsLatestList.txt files from the specified templates,
# sorted and deduplicated.
## Note this function and its unit tests have been created by Project Bob
mergeProductLists() {
  if [ -z "${1}" ]; then
    pu_log_e "[setupFunctions.sh:mergeProductLists()] - Template list is required (parameter 1)"
    return 1
  fi

  if [ -z "${2}" ]; then
    pu_log_e "[setupFunctions.sh:mergeProductLists()] - Output label is required (parameter 2)"
    return 2
  fi

  local templateList="${1}"
  local outputLabel="${2}"
  local destFolder="${3:-/tmp}"
  local outputFile="${destFolder}/${outputLabel}.productlist.txt"
  local templatesBaseDir="${WMUI_CACHE_HOME}/02.templates/01.setup"

  # Check if base templates directory exists
  if [ ! -d "${templatesBaseDir}" ]; then
    pu_log_e "[setupFunctions.sh:mergeProductLists()] - Templates base directory not found: ${templatesBaseDir}"
    return 3
  fi

  # Check if destination folder exists, create if not
  if [ ! -d "${destFolder}" ]; then
    pu_log_i "[setupFunctions.sh:mergeProductLists()] - Creating destination folder: ${destFolder}"
    mkdir -p "${destFolder}" || {
      pu_log_e "[setupFunctions.sh:mergeProductLists()] - Failed to create destination folder: ${destFolder}"
      return 4
    }
  fi

  # Create a temporary file for collecting all products
  local tempFile="${destFolder}/.${outputLabel}.productlist.tmp.$$"
  : > "${tempFile}"  # Create empty file

  local templateCount=0
  local foundCount=0

  # Process each template
  for templateId in ${templateList}; do
    templateCount=$((templateCount + 1))
    local productListFile="${templatesBaseDir}/${templateId}/ProductsLatestList.txt"

    if [ -f "${productListFile}" ]; then
      pu_log_i "[setupFunctions.sh:mergeProductLists()] - Processing template: ${templateId}"
      cat "${productListFile}" >> "${tempFile}"
      foundCount=$((foundCount + 1))
    else
      pu_log_w "[setupFunctions.sh:mergeProductLists()] - ProductsLatestList.txt not found for template: ${templateId}"
      pu_log_w "[setupFunctions.sh:mergeProductLists()] - Expected at: ${productListFile}"
    fi
  done

  if [ ${foundCount} -eq 0 ]; then
    pu_log_e "[setupFunctions.sh:mergeProductLists()] - No valid ProductsLatestList.txt files found in any of the ${templateCount} templates"
    rm -f "${tempFile}"
    return 5
  fi

  # Sort, deduplicate, and write to output file
  pu_log_i "[setupFunctions.sh:mergeProductLists()] - Merging ${foundCount} product lists..."
  sort -u "${tempFile}" > "${outputFile}"
  local lineCount
  lineCount=$(wc -l < "${outputFile}")

  # Clean up temporary file
  rm -f "${tempFile}"

  pu_log_i "[setupFunctions.sh:mergeProductLists()] - Successfully created ${outputFile} with ${lineCount} unique products"
  return 0
}
