#!/bin/sh

# shellcheck source=/dev/null

# shellcheck disable=SC3043
# shellcheck disable=SC3044
# shellcheck disable=SC3060

# our WMUI related parameters

assureVariables(){
  WMUI_INSTALL_INSTALLER_BIN="${TEST_OUTPUT_FOLDER}/installer.bin"
  export WMUI_INSTALL_INSTALLER_BIN

  WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN="${TEST_OUTPUT_FOLDER}/upd-mgr-bootstrap.bin"
  export WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN

  WMUI_PRODUCT_IMAGES_SHARED_DIRECTORY="${TEST_OUTPUT_FOLDER}/products"
  export WMUI_PRODUCT_IMAGES_SHARED_DIRECTORY
  WMUI_FIX_IMAGES_SHARED_DIRECTORY="${TEST_OUTPUT_FOLDER}/fixes"
  export WMUI_FIX_IMAGES_SHARED_DIRECTORY

  WMUI_AUDIT_BASE_DIR="${WMUI_AUDIT_BASE_DIR:-$TEST_OUTPUT_FOLDER/audit}"
  export WMUI_AUDIT_BASE_DIR

  WMUI_SESSION_TIMESTAMP="${WMUI_SESSION_TIMESTAMP:-$(date +%Y-%m-%dT%H.%M.%S_%3N)}"
  export WMUI_SESSION_TIMESTAMP

  WMUI_UPD_MGR_HOME="${WMUI_UPD_MGR_HOME:-"/tmp/upd-mgr-v11"}"
  export WMUI_UPD_MGR_HOME

  WMUI_FIXES_DATE_TAG="$(date +%y-%m-%d)"
  export WMUI_FIXES_DATE_TAG

  WMUI_PRODUCT_IMAGES_PLATFORM="LNXAMD64"
  export WMUI_PRODUCT_IMAGES_PLATFORM

  TEST_Templates=${TEST_Templates:-"MSR/1015/lean"}
  export TEST_Templates
}

assureVariables

. "${WMUI_HOME}/01.scripts/commonFunctions.sh"
. "${WMUI_HOME}/01.scripts/installation/setupFunctions.sh"

assureDefaultInstaller         || logW "Default installer not assured! Eventually clean the output folder."
assureDefaultUpdMgrBootstrap   || logW "Default Update Manager Bootstrap not assured! Eventually clean the output folder."

logI "Installing Update Manager..."
if ! bootstrapUpdMgr "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}" "" "${WMUI_UPD_MGR_HOME}"; then
  logE "Update Manager bootstrap failed with code $?, stopping for debug. CTRL-C for the next instructions"
  tail -f /dev/null
fi

# Params:
# $1 - Template ID
processTemplate() {
  logI "Processing template ${template}..."

  if [ -f "${WMUI_PRODUCT_IMAGES_SHARED_DIRECTORY}/${1}}/products.zip" ]; then
    logI "Products image for template ${1} already exists, nothing to do."
  else
    # Parameters
    # $1 -> setup template
    # $2 -> OPTIONAL - installer binary location, default /tmp/installer.bin
    # $3 -> OPTIONAL - output folder, default /tmp/images/product
    # $4 -> OPTIONAL - platform string, default LNXAMD64
    # NOTE: default URLs for download are fit for Europe. Use the ones without "-hq" for Americas
    # NOTE: pass SDC credentials in env variables WMUI_EMPOWER_USER and WMUI_EMPOWER_PASSWORD
    # NOTE: /dev/shm/productsImagesList.txt may be created upfront if image caches are available
    generateProductsImageFromTemplate \
      "${template}" \
      "${WMUI_INSTALL_INSTALLER_BIN}" \
      "${WMUI_PRODUCT_IMAGES_SHARED_DIRECTORY}" \
      "${WMUI_PRODUCT_IMAGES_PLATFORM}"
    
    logI "Products file generated for template ${template}"
  fi

  if [ -f "${WMUI_FIX_IMAGES_SHARED_DIRECTORY}/${1}/${WMUI_FIXES_DATE_TAG}/fixes.zip" ]; then
    logI "Fixes image for template ${1} and tag ${WMUI_FIXES_DATE_TAG} already exists, nothing to do."
  else
    # TODO: generalize
    # Parameters
    # $1 -> setup template
    # $2 -> OPTIONAL - output folder, default /tmp/images/product
    # $3 -> OPTIONAL - fixes tag. Defaulted to current day
    # $4 -> OPTIONAL - platform string, default LNXAMD64
    # $5 -> OPTIONAL - upd-mgr home, default /tmp/upd-mgr-v11
    # $6 -> OPTIONAL - upd-mgr-bootstrap binary location, default /tmp/upd-mgr-bootstrap.bin
    # NOTE: pass SDC credentials in env variables WMUI_EMPOWER_USER and WMUI_EMPOWER_PASSWORD
    generateFixesImageFromTemplate "${template}" \
      "${WMUI_FIX_IMAGES_SHARED_DIRECTORY}" \
      "${WMUI_FIXES_DATE_TAG}" \
      "${WMUI_PRODUCT_IMAGES_PLATFORM}" \
      "${WMUI_UPD_MGR_HOME}"

    logI "Fixes file generated for template ${template}"
  fi

  logI "Template $template processed."
}

for template in ${TEST_Templates}; do
  processTemplate "${template}"
done

# logI "stopping for debug"
# tail -f /dev/null