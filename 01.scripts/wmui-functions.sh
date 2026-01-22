#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#
# WARNING: POSIX compatibility is pursued, but this is not a strict POSIX script.
# The following exceptions apply
# - local variables for functions
# shellcheck disable=SC3043

## Framework variables

# Convention for messaging: WMUI prefixes all messages

# Function 01 - internal init
_init() {
  # Verify that PU audit is loaded
  # shellcheck disable=SC2154
  if [ ! -d "${__2__audit_session_dir}" ]; then
    echo "WMUI|01|FATAL: commonFunctions.sh requires posix-shell-utils (2.audit.sh) to be sourced first!"
    echo "WMUI|01|INFO : Please source 2l-posix-shell-utils/code/2.audit.sh before sourcing commonFunctions.sh"
    return 101
  fi

  # WMUI-specific configuration
  # Online/offline mode: true=online (default), anything else=offline
  # Means WMUI may attempt to download generic files if needed
  export __wmui_online_mode="${WMUI_ONLINE_MODE:-true}"

  # assure our own home folder and url in case of online mode
  if [ ! "${__wmui_online_mode}" = "true" ]; then
    # Offline mode: caller MUST provide WMUI_HOME
    if [ ! -f "${WMUI_HOME}/01.scripts/wmui-functions.sh" ]; then
      pu_log_e "WMUI|01| ${WMUI_HOME}/01.scripts/wmui-functions.sh not found in offline mode!"
      pu_log_e "WMUI|01| Set WMUI_HOME variable (current value=${WMUI_HOME})"
      return 102
    fi
    export __wmui_cache_home="${WMUI_HOME}"
  else
    # Online mode: use GitHub repository
    export __wmui_home_url="${WMUI_HOME_URL:-"https://raw.githubusercontent.com/ibm-webmethods-continuous-delivery/2l-unattended-installation-templates/main"}"
    export __wmui_cache_home="${WMUI_CACHE_HOME:-"/tmp/wmuiCacheHome"}"
    mkdir -p "${__wmui_cache_home}"
  fi

  # WMUI-specific configuration
  # Online/offline mode: true=online (default), anything else=offline
  # Means WMUI may download webMethods related content
  export __wmui_product_online_mode="${WMUI_PRODUCT_ONLINE_MODE:-true}"

  # in some UX systems, /dev/shm is not available, allow for explicit setting
  export __wmui_temp_fs_quick="${WMUI_TEMP_FS_QUICK:-/dev/shm}"
}

_init || exit $?

# Function 02 - hunt for file if needed
wmui_hunt_for_file() {
  # Parameters - wmui_hunt_for_file
  # $1 - relative Path to __wmui_cache_home
  # $2 - filename
  if [ ! -f "${__wmui_cache_home}/${1}/${2}" ]; then
    if [ "${__wmui_online_mode}" -eq 0 ]; then
      pu_log_e "WMUI|02| File ${__wmui_cache_home}/${1}/${2} not found! Will not attempt download, as we are working offline!"
      return 1 # File should exist, but it does not
    fi
    pu_log_i "WMUI|02| File ${__wmui_cache_home}/${1}/${2} not found in local cache, attempting download"
    mkdir -p "${__wmui_cache_home}/${1}"
    pu_log_i "WMUI|02| Downloading from ${__wmui_home_url}/${1}/${2} ..."
    curl "${__wmui_home_url}/${1}/${2}" --silent -o "${__wmui_cache_home}/${1}/${2}"
    local RESULT_curl=$?
    if [ ${RESULT_curl} -ne 0 ]; then
      pu_log_e "WMUI|02| curl failed, code ${RESULT_curl}"
      return 2
    fi
    pu_log_i "WMUI|02| File ${__wmui_cache_home}/${1}/${2} downloaded successfully"
  fi
}

# Function 03 - assure default installer
wmui_assure_default_installer() {
  # Parameters
  # $1 - OPTIONAL installer binary location, defaulted to ${WMUI_INSTALL_INSTALLER_BIN}, which is also defaulted to /tmp/default-installer.bin
  local default_installer_url="https://delivery04.dhe.ibm.com/sar/CMA/OSA/0cx80/2/IBM_webMethods_Install_Linux_x64.bin"
  local installer_sha256_sum="07ecdff4efe4036cb5ef6744e1a60b0a7e92befed1a00e83b5afe9cdfd6da8d3"
  local installer_bin="${1:-/tmp/default-installer.bin}"
  if ! pu_assure_downloadable_file "${installer_bin}" "${default_installer_url}" "${installer_sha256_sum}"; then
    pu_log_e "WMUI|03| Cannot assure default installer!"
    return 1
  fi
  pu_log_d "WMUI|04| Default installer correctly assured in ${installer_bin}"
  chmod u+x "${installer_bin}"
}

# Function 04 - assure default installer
wmui_assure_default_umgr() {
  # Parameters
  # $1 - OPTIONAL umgr binary location, defaulted to ${WMUI_INSTALL_INSTALLER_BIN}, which is also defaulted to /tmp/default-umgr.bin
  local default_umgr_url="https://delivery04.dhe.ibm.com/sar/CMA/OSA/0crqw/0/IBM_webMethods_Update_Mnger_Linux_x64.bin"
  local umgr_sha256_sum="a997a690c00efbb4668323d434fa017a05795c6bf6064905b640fa99a170ff55"
  local umgr_bin="${1:-/tmp/default-umgr.bin}"
  if ! pu_assure_downloadable_file "${umgr_bin}" "${default_umgr_url}" "${umgr_sha256_sum}"; then
    pu_log_e "WMUI|04| Cannot assure default update manager!"
    return 1
  fi
  pu_log_d "WMUI|04| Default update manager correctly assured in ${umgr_bin}"
  chmod u+x "${umgr_bin}"
}

# Function 05 - Generating an inventory file from a given product list, usually from a template
wmui_generate_inventory_from_products_list() {
  # Parameters - generateInventoryFileFromProductsList
  # $1 - input file path (products list file)
  # $2 - output file path (JSON inventory file)
  # $3 - OPTIONAL: sum version string, defaults to "27.1.0"
  # $4 - OPTIONAL: platform string, defaults to "LNXAMD64"
  # $5 - OPTIONAL: update manager version, defaults to "27.0.0.0000-0117"
  # $6 - OPTIONAL: platform group string, defaults to "\"UNX-ANY\",\"LNX-ANY\""
  local input_file="${1}"
  local output_file="${2}"
  local umgr_version_string="${3:-27.1.0}"
  local umgr_platform_string="${4:-LNXAMD64}"
  local umgr_version="${5:-27.0.0.0000-0117}"
  local sumPlatformGroupString="${6:-\"UNX-ANY\",\"LNX-ANY\"}"

  # Check required parameters
  if [ -z "$input_file" ] || [ -z "$output_file" ]; then
    pu_log_e "WMUI|05| Both input file and output file are required"
    return 1
  fi

  # Check if input file exists
  if [ ! -f "$input_file" ]; then
    pu_log_e "WMUI|05| Input file '$input_file' does not exist"
    return 2
  fi

  # Read all non-empty lines from the products list file
  local product_lines
  product_lines=$(grep -v '^[[:space:]]*$' "$input_file")

  if [ -z "$product_lines" ]; then
    pu_log_e "WMUI|05| No products found in file '$input_file'"
    return 3
  fi

  # Create temporary files for processing
  local tempDir
  tempDir=$(mktemp -d)
  local product_file="$tempDir/products.tmp"

  # Cleanup function
  cleanup() {
    rm -rf "$tempDir"
  }
  trap cleanup EXIT

  # Process each product line
  echo "$product_lines" | while IFS= read -r product_line; do
    # Parse format: e2ei/27/PRODUCT_VERSION.LATEST/Category/ProductCode
    # Use parameter expansion to split the path
    local remaining="$product_line"
    local part1="${remaining%%/*}"; remaining="${remaining#*/}"
    local part2="${remaining%%/*}"; remaining="${remaining#*/}"
    local versionPart="${remaining%%/*}"; remaining="${remaining#*/}"
    local part4="${remaining%%/*}"; remaining="${remaining#*/}"
    local productCode="$remaining"

    if [ -n "$productCode" ] && [ -n "$versionPart" ]; then
      # Clean up product_code (remove any trailing whitespace or newlines)
      productCode=$(printf '%s' "$productCode" | tr -d '\n\r' | sed 's/[[:space:]]*$//')

      # Extract version from format like "PRODUCT_11.1.0.0.LATEST"
      # Use sed to extract version pattern
      local productVersion
      productVersion=$(echo "$versionPart" | sed -n 's/.*_\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)\..*$/\1/p')

      # If version extraction failed, use default
      if [ -z "$productVersion" ]; then
        productVersion="$umgr_version_string"
      fi

      # Store product code and version (using unique keys)
      echo "$productCode:$productVersion" >> "$productsFile"
    fi
  done

  # Check if any products were processed
  if [ ! -f "$product_file" ] || [ ! -s "$product_file" ]; then
    pu_log_e "WMUI|05| No products could be parsed from file '$input_file'"
    cleanup
    return 4
  fi

  # Function to escape JSON strings
  escape_json() {
    # Remove any trailing newlines and escape JSON special characters
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | tr -d '\n'
  }

  # Generate JSON output
  {
    echo "{"
    echo "    \"installedProducts\": ["

    # Process unique products and generate JSON entries
    sort -u "$product_file" | {
      local first=true
      while IFS=: read -r productId productVersion; do
        if [ "$first" = true ]; then
          first=false
        else
          echo ","
        fi
        echo "        {"
        echo "            \"productId\": \"$(escape_json "$productId")\","
        echo "            \"version\": \"$(escape_json "$productVersion")\","
        echo "            \"displayName\": \"$(escape_json "$productId")\""
        printf "        }"
      done
      echo ""
    }

    echo "    ],"
    echo "    \"installedFixes\": [],"
    echo "    \"installedSupportPatches\": [],"
    echo "    \"envVariables\": {"
    echo "        \"platformGroup\": [$sumPlatformGroupString],"
    echo "        \"UpdateManagerVersion\": \"$umgr_version\","
    echo "        \"Hostname\": \"localhost\","
    echo "        \"platform\": \"$umgr_platform_string\""
    echo "    }"
    echo "}"
  } > "$output_file"

  cleanup
  pu_log_i "WMUI|05| Successfully generated inventory file: $output_file"
  return 0
}

# Function 05 assure and get the products list file for a template
wmui_get_product_list_of_template() {
  # Get the products list file for a template
  #
  # Args:
  #   $1 - template name
  #   $2 -return latest or not
  #
  # Returns:
  #   Path to products list file

  # Hunt for products list files and create enhanced template
  local use_latest="${2:-true}"
  local template_products_list_file="ProductsLatestList.txt"

  if [ ! "${use_latest}" = "true" ]; then
    template_products_list_file="ProductsVersionedList.txt"
  fi

  wmui_hunt_for_file "02.templates/01.setup/${1}" "${template_products_list_file}"

  if [ ! -f "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${template_products_list_file}" ]; then
    pu_log_e "WMUI|05| Products list file not found: ${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${template_products_list_file}"
    echo "not found"
    return 1
  fi

  echo "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${template_products_list_file}"
}


######### Functions 21 - 30 - zip files generation

# Function 21 - Generate products.zip image file from a list of products
# TODO: a subset of function 22. To refactor.
wmui_generate_products_zip_from_list(){
  # Parameters
  # $1 -> product csv list
  # $2 -> OPTIONAL - installer binary location, default /tmp/installer.bin
  # $3 -> OPTIONAL - output folder, default /tmp/images
  # $4 -> OPTIONAL - platform string, default LNXAMD64

  pu_log_i "WMUI|21| Addressing products image for a given csv list..."
  pu_log_d "WMUI|21| InstallProducts=${1}"

  local installer_bin="${2:-/tmp/installer.bin}"
  if [ ! -f "${installer_bin}" ]; then
    pu_log_w "WMUI|22| Installer file ${installer_bin} not found, attempting to use the default one..."
    assureDefaultInstaller "${installer_bin}" || return 1
  fi
  local output_folder="${3:-/tmp/images}"
  local products_zip="${output_folder}/${1}/products.zip"
  local dbg_log="${output_folder}/${1}/debug.log"
  local img_creation_script="${output_folder}/${1}/createProductImage.wmscript"
  local products_csv="${1:-none}"

  if [ "${products_csv}" = "none" ]; then
    pu_log_e "WMUI|22| No product csv list provided, cannot generate an image!"
    return 2
  fi

  if [ -f "${products_zip}" ]; then
    pu_log_i "WMUI|21| Products image for template ${1} already exists, nothing to do."
    return 0
  fi

  if [ -f "${img_creation_script}" ]; then
    pu_log_i "WMUI|21| Permanent product image creation script file already present... Using the existing one."
  else
    pu_log_i "WMUI|21| Permanent product image creation script file not present, creating now..."
    local platform_string="${4:-LNXAMD64}"

    #Address download server URL
    local lSdcServerUrl
    case "${1}" in
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

    pu_log_i "WMUI|21| Creating permanent product image creation script from template file ${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/template.wmscript "
    mkdir -p "${output_folder}/${1}"
    {
      echo "###Generated"
      echo "LicenseAgree=Accept"
      echo "InstallLocProducts="
      echo "imagePlatform=${platform_string}"
      echo "imageFile=${products_zip}"
      echo "ServerURL=${lSdcServerUrl}"
      echo "InstallProducts=${products_csv}"
    } >"${img_creation_script}"

    pu_log_i "WMUI|21| Permanent product image creation script file created"
  fi

  pu_log_i "WMUI|21| Creating the volatile script ..."
  local epoch
  epoch=$(date +%s)
  local ephemeral_script="${__wmui_temp_fs_quick}/WMUI/${epoch}/createProductImage.wmscript"
  mkdir -p "${__wmui_temp_fs_quick}/WMUI/setup/templates/${epoch}/"
  cp "${img_creation_script}" "${ephemeral_script}"
  # TODO: assure credential variables
  echo "Username=${WMUI_EMPOWER_USER}" >>"${ephemeral_script}"
  echo "Password=${WMUI_EMPOWER_PASSWORD}" >>"${ephemeral_script}"
  pu_log_i "WMUI|21| Volatile script created."

  ## TODO: check if error management enforcement is needed: what if the grep produced nothing?
  ## TODO: deal with \ escaping in the password. For now avoid using '\' - backslash in the password string

  ## TODO: not space safe, but it shouldn't matter for now
  local cmd="${installer_bin} -console -readScript ${ephemeral_script}"
  # shellcheck disable=SC2154
  if [ "${__1__debug_mode}" = "true" ]; then
    cmd="${cmd} -debugFile '${dbg_log}' -debugLvl verbose"
  fi
  cmd="${cmd} -writeImage ${products_zip}"
  # explicitly tell installer we are running unattended
  cmd="${cmd} -scriptErrorInteract no"

  # avoid downloading what we already have
  if [ -s "${__wmui_temp_fs_quick}/productsImagesList.txt" ]; then
    cmd="${cmd} -existingImages \"${__wmui_temp_fs_quick}/productsImagesList.txt\""
  fi

  pu_log_i "WMUI|21| Creating the product image ${products_zip}... This may take some time..."
  pu_log_d "WMUI|21| Command is ${cmd}"
  pu_audited_exec "${cmd}" "Create-products-image-for-template-$(pu_str_substitute "$1" "/" "-")"
  local create_result=$?
  pu_log_i "WMUI|21| Image ${products_zip} creation completed, result: ${create_result}"
  rm -f "${ephemeral_script}"

  return ${create_result}

}

# Function 22 - Generating a products image zip file for a template
# NOTE: pass download credentials in env variables WMUI_EMPOWER_USER and WMUI_EMPOWER_PASSWORD
# NOTE: ${__wmui_temp_fs_quick}/productsImagesList.txt may be created upfront if image caches are available
wmui_generate_products_zip_from_template() {
  # Parameters
  # $1 -> setup template
  # $2 -> OPTIONAL - installer binary location, default /tmp/installer.bin
  # $3 -> OPTIONAL - output folder, default /tmp/images
  # $4 -> OPTIONAL - platform string, default LNXAMD64
  # $5 -> OPTIONAL: useLatest (YES/NO), default YES. If YES, uses ProductsLatestList.txt, if NO uses ProductsVersionedList.txt

  pu_log_i "WMUI|22| Addressing products image for setup template ${1}..."
  local template_products_list_file
  template_products_list_file=$(wmui_get_product_list_of_template "${1}" "${5}")

  local products_csv
  products_csv=$(pu_lines_to_csv "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${template_products_list_file}")

  wmui_generate_products_zip_from_list "${products_csv}" "${2}" "${3}" "${4}"
}

# Function 23 - Generating a products image zip file for a list of templates
wmui_generate_products_zip_from_templates_list() {
  # Parameters
  # $1 -> setup templates list, space separated
  # $2 -> OPTIONAL - installer binary location, default /tmp/installer.bin
  # $3 -> OPTIONAL - output folder, default /tmp/images
  # $4 -> OPTIONAL - platform string, default LNXAMD64
  # $5 -> OPTIONAL: useLatest (YES/NO), default YES. If YES, uses ProductsLatestList.txt, if NO uses ProductsVersionedList.txt
  pu_log_i "WMUI|23| Generating a single products zip file for the list of templates [ ${1} ]" ...
  pu_log_i "To implement"
}

# Function 26 - Generating fixes zip file for list of products
# TODO: it is a subset of the current function 27
wmui_generate_fixes_zip_from_list_on_file() {
  # Parameters
  # $1 -> file containing the product list
  # $2 -> OPTIONAL - output folder, default /tmp/images/product
  # $3 -> OPTIONAL - fixes tag. Defaulted to current day
  # $4 -> OPTIONAL - platform string, default LNXAMD64
  # $5 -> OPTIONAL - update manager home, default /tmp/upd-mgr-v11
  # $6 -> OPTIONAL - upd-mgr-bootstrap binary location, default /tmp/upd-mgr-bootstrap.bin
  # $7 -> OPTIONAL: useLatest (YES/NO), default YES. If YES, uses ProductsLatestList.txt, if NO uses ProductsVersionedList.txt
  local products_list_file="${1:-none}"
  if [ "${products_list_file}" = "none" ]; then
    pu_log_e "WMUI|09| No product list file provided"
    return 1
  fi

  local lCrtDate
  lCrtDate="$(date +%y-%m-%d)"
  local d
  d="$(date +%y-%m-%dT%H.%M.%S_%3N)"
  local lFixesTag="${3:-$lCrtDate}"
  pu_log_i "WMUI|09| Addressing fixes image for setup template ${1} and tag ${lFixesTag}..."

  local lOutputDir="${2:-/tmp/images/fixes}"
  local lFixesDir="${lOutputDir}/${1}/${lFixesTag}"
  mkdir -p "${lFixesDir}"
  local lFixesImageFile="${lFixesDir}/fixes.zip"
  local lPermanentInventoryFile="${lFixesDir}/inventory.json"
  local lPermanentScriptFile="${lFixesDir}/createFixesImage.wmscript"
  local lPlatformString="${4:-LNXAMD64}"

  if [ -f "${lFixesImageFile}" ]; then
    pu_log_i "WMUI|09| Fixes image for template ${1} and tag ${lFixesTag} already exists, nothing to do."
    return 0
  fi

  local lUpdMgrHome="${5:-/tmp/upd-mgr-v11}"
  if [ ! -d "${lUpdMgrHome}/bin" ]; then
    pu_log_w "WMUI|09| UPD_MGR Home does not contain a UPD_MGR installation, trying to bootstrap now..."
    local lUpdMgrBootstrapBin="${6:-/tmp/upd-mgr-bootstrap.bin}"
    if [ ! -f "${lUpdMgrBootstrapBin}" ]; then
      pu_log_w "WMUI|09| UPD_MGR Bootstrap binary not found, trying to obtain the default one..."
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
    pu_log_i "WMUI|09| Inventory file ${lPermanentInventoryFile} already exists, skipping creation."
  else
    pu_log_i "WMUI|09| Inventory file ${lPermanentInventoryFile} does not exists, creating now."

    wmui_hunt_for_file "02.templates/01.setup/${1}" "template.wmscript"

    if [ ! -f "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/template.wmscript" ]; then
      pu_log_e "WMUI|09| Required file ${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/template.wmscript not found, cannot continue"
      return 2
    fi

    # Parameters - generateInventoryFileFromProductsList
    # $1 - input file path (products list file)
    # $2 - output file path (JSON inventory file)
    # $3 - OPTIONAL: sum version string, defaults to "27.1.0"
    # $4 - OPTIONAL: platform string, defaults to "LNXAMD64"
    # $5 - OPTIONAL: update manager version, defaults to "27.0.0.0000-0117"
    # $6 - OPTIONAL: platform group string, defaults to "\"UNX-ANY\",\"LNX-ANY\""
    generateInventoryFileFromProductsList \
      "${WMUI_CACHE_HOME}/02.templates/01.setup/${1}/${products_list_file}" \
      "${lPermanentInventoryFile}" \
      "" "${lPlatformString}"
  fi

  if [ -f "${lPermanentScriptFile}" ]; then
    pu_log_i "WMUI|09| Permanent script file ${lPermanentScriptFile} already exists, skipping creation..."
  else
    pu_log_i "WMUI|26| Permanent script file ${lPermanentScriptFile} does not exist, creating now..."
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
    pu_log_w "WMUI|26| Fix image creation for template ${1} failed with code ${lResultFixCreation}! Saving troubleshooting information into the destination folder"
    pu_log_i "WMUI|26| Archiving destination folder results, which are partial at best..."
    cd "${lFixesDir}" || return 1
    tar czf "dump.tgz" ./* --remove-files
    mkdir -p "${lFixesDir}/$d"
    mv "dump.tgz" "${lFixesDir}/$d"/
    cd "${lUpdMgrHome}" || return 1
    pu_log_d "WMUI|26| Listing all log files produced by Update Manager"
    find . -type f -name "*.log"

    # ensure the password is not in the logs before sending them to archiving
    cmd="grep -rl '${WMUI_EMPOWER_PASSWORD}' . | xargs sed -i 's/${WMUI_EMPOWER_PASSWORD}/HIDDEN_PASSWORD/g'"
    eval "${cmd}"
    unset cmd

    find . -type f -regex '\(.*\.log\|.*\.log\.[0-9]*\)' -print0 | xargs -0 tar cfvz "${lFixesDir}/$d/sum_logs.tgz"
    pu_log_i "WMUI|26| Dump complete"
    cd "${crtDir}" || return 4
    return 3
  fi

  cd "${crtDir}" || return 5
  pu_log_i "WMUI|26| Fix image creation for template ${1} finished successfully"

}

# Function 27 - Generating a products image zip file for a template
# NOTE: pass SDC credentials in env variables WMUI_EMPOWER_USER and WMUI_EMPOWER_PASSWORD
wmui_generate_fixes_zip__from_template() {
  # Parameters
  # $1 -> setup template
  # $2 -> OPTIONAL - output folder, default /tmp/images/product
  # $3 -> OPTIONAL - fixes tag. Defaulted to current day
  # $4 -> OPTIONAL - platform string, default LNXAMD64
  # $5 -> OPTIONAL - update manager home, default /tmp/upd-mgr-v11
  # $6 -> OPTIONAL - upd-mgr-bootstrap binary location, default /tmp/upd-mgr-bootstrap.bin
  # $7 -> OPTIONAL: useLatest (YES/NO), default YES. If YES, uses ProductsLatestList.txt, if NO uses ProductsVersionedList.txt
  # Hunt for products list files and create enhanced template


  pu_log_i "WMUI|27| Addressing fixes image for setup template ${1}..."
  local template_products_list_file
  template_products_list_file=$(wmui_get_product_list_of_template "${1}" "${7}")
  wmui_generate_fixes_zip_from_list_on_file "${template_products_list_file}" "${2}" "${3}" "${4}" "${5}" "${6}"
}

pu_log_d "WMUI|--| WMUI commonFunctions.sh initialized"
pu_log_d "WMUI|--| Using posix utils audit folder __2__audit_session_dir=${__2__audit_session_dir}"


# Parameters - applyPostSetupTemplate
# $1 - Setup template directory, relative to <repo_home>/02.templates/02.post-setup
wmui_apply_post_setup_template() {
  pu_log_i "[commonFunctions.sh:applyPostSetupTemplate()] - Applying post-setup template ${1}"
  wmui_hunt_for_file "02.templates/02.post-setup/${1}" "apply.sh"
  local RESULT_wmui_hunt_for_file=$?
  if [ ${RESULT_wmui_hunt_for_file} -ne 0 ]; then
    pu_log_e "[commonFunctions.sh:applyPostSetupTemplate()] - File ${__wmui_cache_home}/02.templates/02.post-setup/${1}/apply.sh not found!"
    return 1
  fi
  chmod u+x "${__wmui_cache_home}/02.templates/02.post-setup/${1}/apply.sh"
  local RESULT_chmod=$?
  if [ ${RESULT_chmod} -ne 0 ]; then
    pu_log_w "[commonFunctions.sh:applyPostSetupTemplate()] - chmod command for apply.sh failed. This is not always a problem, continuing"
  fi
  pu_log_i "[commonFunctions.sh:applyPostSetupTemplate()] - Calling apply.sh for template ${1}"
  #controlledExec "${__wmui_cache_home}/02.templates/02.post-setup/${1}/apply.sh" "PostSetupTemplateApply"
  "${__wmui_cache_home}/02.templates/02.post-setup/${1}/apply.sh"
  local RESULT_apply=$?
  if [ ${RESULT_apply} -ne 0 ]; then
    pu_log_e "[commonFunctions.sh:applyPostSetupTemplate()] - Application of post-setup template ${1} failed, code ${RESULT_apply}"
    return 3
  fi
  pu_log_i "[commonFunctions.sh:applyPostSetupTemplate()] - Post setup template ${1} applied successfully"
}
