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
    echo "WMUI|01|FATAL: wmui-functions.sh requires posix-shell-utils (2.audit.sh) to be sourced first!"
    echo "WMUI|01|INFO : Please source 2l-posix-shell-utils/code/2.audit.sh before sourcing commonFunctions.sh"
    return 101
  fi

  __wmui_default_artifacts_folder='/tmp/WMUI'

  # Default values for the framework - Paths
  __wmui_default_installation_home='/opt/webmethods'
  __wmui_default_installer_bin=${__wmui_default_artifacts_folder}/installer.bin
  __wmui_default_umgr_bin=${__wmui_default_artifacts_folder}/umgr-bootstrap.bin
  __wmui_default_umgr_home='/opt/wm-umgr'

  # Default values - Temporary paths
  __wmui_default_output_folder=${__wmui_default_artifacts_folder}/images
  __wmui_default_output_folder_fixes=${__wmui_default_artifacts_folder}/images/fixes

  # Default values - URLs and checksums
  __wmui_default_installer_url='https://delivery04.dhe.ibm.com/sar/CMA/OSA/0cx80/2/IBM_webMethods_Install_Linux_x64.bin'
  __wmui_default_installer_sha256='07ecdff4efe4036cb5ef6744e1a60b0a7e92befed1a00e83b5afe9cdfd6da8d3'
  __wmui_default_umgr_url='https://delivery04.dhe.ibm.com/sar/CMA/OSA/0crqw/0/IBM_webMethods_Update_Mnger_Linux_x64.bin'
  __wmui_default_umgr_sha256='a997a690c00efbb4668323d434fa017a05795c6bf6064905b640fa99a170ff55'

  # Default values - Version and platform for Update Manager inventory files
  __wmui_default_umgr_version_string='27.1.0'
  __wmui_default_platform_string='LNXAMD64'
  __wmui_default_umgr_version='27.0.0.0000-0117'
  __wmui_default_platform_group_string='"UNX-ANY","LNX-ANY"'

  # Default values - Flags and options
  __wmui_default_use_latest='true'
  __wmui_default_debug_level='verbose'
  __wmui_default_epm='N'
  __wmui_default_diagnoser_key='5437713_PIE-68082_5'
  __wmui_default_products_csv='none'

  # WMUI-specific configuration
  # Online/offline mode: true=online (default), anything else=offline
  # Means WMUI may attempt to download generic files if needed
  # export __wmui_online_mode="${WMUI_ONLINE_MODE:-true}"
  # replaced with __1__online_mode -> PU online mode

  # assure our own home folder and url in case of online mode
  # shellcheck disable=SC2154
  if [ ! "${__1__online_mode}" = "true" ]; then
    # Offline mode: caller MUST provide WMUI_HOME
    if [ ! -f "${WMUI_HOME}/01-scripts/wmui-functions.sh" ]; then
      pu_log_e "WMUI|01| ${WMUI_HOME}/01-scripts/wmui-functions.sh not found in offline mode!"
      pu_log_e "WMUI|01| Set WMUI_HOME variable (current value=${WMUI_HOME})"
      return 102
    fi
    export __wmui_cache_home="${WMUI_HOME}"
  else
    # Online mode: use GitHub repository
    export __wmui_home_url="${WMUI_HOME_URL:-"https://raw.githubusercontent.com/ibm-webmethods-continuous-delivery/2l-unattended-installation-templates/main"}"
    export __wmui_cache_home="${__wmui_cache_home:-"/tmp/wmuiCacheHome"}"
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
    if [ ! "${__1__online_mode}" = "true" ]; then
      pu_log_e "WMUI|02| File ${__wmui_cache_home}/${1}/${2} not found! Will not attempt download, as we are working offline!"
      return 1 # File should exist, but it does not
    fi
    pu_log_i "WMUI|02| File ${__wmui_cache_home}/${1}/${2} not found in local cache, attempting download"
    mkdir -p "${__wmui_cache_home}/${1}"
    pu_log_i "WMUI|02| Downloading from ${__wmui_home_url}/${1}/${2} ..."
    curl "${__wmui_home_url}/${1}/${2}" --silent -o "${__wmui_cache_home}/${1}/${2}"
    local l_result_curl=$?
    if [ ${l_result_curl} -ne 0 ]; then
      pu_log_e "WMUI|02| curl failed, code ${l_result_curl}"
      return 2
    fi
    pu_log_i "WMUI|02| File ${__wmui_cache_home}/${1}/${2} downloaded successfully"
  fi
}

# Function 03 - assure default installer
wmui_assure_default_installer() {
  # Parameters
  # $1 - OPTIONAL installer binary location, defaulted to ${__wmui_default_installer_bin}
  local l_default_installer_url="${__wmui_default_installer_url}"
  local l_installer_sha256_sum="${__wmui_default_installer_sha256}"
  local l_installer_bin="${1:-${__wmui_default_installer_bin}}"
  if ! pu_assure_public_file "${l_default_installer_url}" "${l_installer_bin}" "${l_installer_sha256_sum}"; then
    pu_log_e "WMUI|03| Cannot assure default installer!"
    return 1
  fi
  pu_log_d "WMUI|03| Default installer correctly assured in ${l_installer_bin}"
  chmod u+x "${l_installer_bin}"
  return 0
}

# Function 04 - assure default installer
wmui_assure_default_umgr_bin() {
  # Parameters
  # $1 - OPTIONAL umgr binary location, defaulted to ${__wmui_default_umgr_bin}
  local l_default_umgr_url="${__wmui_default_umgr_url}"
  local l_umgr_sha256_sum="${__wmui_default_umgr_sha256}"
  local l_umgr_bin="${1:-${__wmui_default_umgr_bin}}"
  if ! pu_assure_public_file "${l_default_umgr_url}" "${l_umgr_bin}" "${l_umgr_sha256_sum}"; then
    pu_log_e "WMUI|04| Cannot assure default update manager!"
    return 1
  fi
  pu_log_d "WMUI|04| Default update manager correctly assured in ${l_umgr_bin}"
  chmod u+x "${l_umgr_bin}"
  return 0
}

# Function 05 assure and get the products list file for a template
wmui_get_product_list_of_template() {
  # Get the products list file for a template
  #
  # Args:
  #   $1 - template id
  #   $2 - return latest or not
  #
  # Returns:
  #   Path to products list file

  # Hunt for products list files and create enhanced template
  local l_use_latest="${2:-${__wmui_default_use_latest}}"
  local l_template_products_list_file="products-latest-list.txt"

  if [ ! "${l_use_latest}" = "true" ]; then
    l_template_products_list_file="products-versioned-list.txt"
  fi

  wmui_hunt_for_file "02-templates/01-setup/${1}" "${l_template_products_list_file}"

  if [ ! -f "${__wmui_cache_home}/02-templates/01-setup/${1}/${l_template_products_list_file}" ]; then
    pu_log_e "WMUI|05| Products list file not found: ${__wmui_cache_home}/02-templates/01-setup/${1}/${l_template_products_list_file}"
    echo "not found"
    return 1
  fi

  echo "${__wmui_cache_home}/02-templates/01-setup/${1}/${l_template_products_list_file}"
}

# Function 07 - Merge multiple product list files into one unified list
wmui_merge_product_lists() {
  # Parameters
  # $1 - output file path (merged products list file)
  # $2+ - input file paths (one or more product list files to merge)

  local l_output_file="${1}"
  shift  # Remove first argument, remaining are input files

  # Check required parameters
  if [ -z "$l_output_file" ]; then
    pu_log_e "WMUI|07| Output file path is required"
    return 1
  fi

  if [ $# -eq 0 ]; then
    pu_log_e "WMUI|07| At least one input file is required"
    return 2
  fi

  # Check if all input files exist
  for l_input_file in "$@"; do
    if [ ! -f "$l_input_file" ]; then
      pu_log_e "WMUI|07| Input file does not exist: $l_input_file"
      return 3
    fi
  done

  pu_log_i "WMUI|07| Merging ${#} product list files into ${l_output_file}..."

  # Create temporary file for merging
  local l_temp_file="${l_output_file}.tmp"

  # Clear temp file
  true > "${l_temp_file}"

  # Concatenate all input files
  for l_input_file in "$@"; do
    pu_log_d "WMUI|07| Adding products from ${l_input_file}"
    cat "${l_input_file}" >> "${l_temp_file}"
  done

  # Sort, remove duplicates, and save to output file
  # Note: assumes all product list files have EOF on newline
  sort "${l_temp_file}" | uniq > "${l_output_file}"

  # Clean up temp file
  rm -f "${l_temp_file}"

  local l_product_count
  l_product_count=$(wc -l < "${l_output_file}")
  pu_log_i "WMUI|07| Successfully merged product lists: ${l_product_count} unique products"

  return 0
}

# Function 06 - Generating an inventory file from a given product list, usually from a template
wmui_generate_inventory_from_products_list() {
  # Parameters - generateInventoryFileFromProductsList
  # $1 - input file path (products list file)
  # $2 - output file path (JSON inventory file)
  # $3 - OPTIONAL: sum version string, defaults to ${__wmui_default_umgr_version_string}
  # $4 - OPTIONAL: platform string, defaults to ${__wmui_default_platform_string}
  # $5 - OPTIONAL: update manager version, defaults to ${__wmui_default_umgr_version}
  # $6 - OPTIONAL: platform group string, defaults to ${__wmui_default_platform_group_string}
  local l_input_file="${1}"
  local l_output_file="${2}"
  local l_umgr_version_string="${3:-${__wmui_default_umgr_version_string}}"
  local l_umgr_platform_string="${4:-${__wmui_default_platform_string}}"
  local l_umgr_version="${5:-${__wmui_default_umgr_version}}"
  local l_umgr_platform_group_string="${6:-${__wmui_default_platform_group_string}}"

  # Check required parameters
  if [ -z "$l_input_file" ] || [ -z "$l_output_file" ]; then
    pu_log_e "WMUI|06| Both input file and output file input variables are required"
    return 1
  fi

  # Check if input file exists
  if [ ! -f "$l_input_file" ]; then
    pu_log_e "WMUI|06| Input file '$l_input_file' does not exist"
    return 2
  fi

  # Read all non-empty lines from the products list file
  local l_product_lines
  l_product_lines=$(grep -v '^[[:space:]]*$' "$l_input_file")

  if [ -z "$l_product_lines" ]; then
    pu_log_e "WMUI|06| No products found in file '$l_input_file'"
    return 3
  fi

  # Create temporary files for processing
  local l_temp_dir
  l_temp_dir=$(mktemp -d)
  local l_product_file="$l_temp_dir/products.tmp"

  # Process each product line
  echo "$l_product_lines" | while IFS= read -r l_product_line; do
    # Parse format: e2ei/27/PRODUCT_VERSION.LATEST/Category/ProductCode
    # Use parameter expansion to split the path
    local l_remaining="$l_product_line"
    local l_part1="${l_remaining%%/*}"; l_remaining="${l_remaining#*/}"
    local l_part2="${l_remaining%%/*}"; l_remaining="${l_remaining#*/}"
    local l_version_part="${l_remaining%%/*}"; l_remaining="${l_remaining#*/}"
    local l_part4="${l_remaining%%/*}"; l_remaining="${l_remaining#*/}"
    local l_product_code="$l_remaining"

    if [ -n "$l_product_code" ] && [ -n "$l_version_part" ]; then
      # Clean up product_code (remove any trailing whitespace or newlines)
      l_product_code=$(printf '%s' "$l_product_code" | tr -d '\n\r' | sed 's/[[:space:]]*$//')

      # Extract version from format like "PRODUCT_11.1.0.0.LATEST"
      # Use sed to extract version pattern
      local l_product_version
      l_product_version=$(echo "$l_version_part" | sed -n 's/.*_\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)\..*$/\1/p')

      # If version extraction failed, use default
      if [ -z "$l_product_version" ]; then
        l_product_version="$l_umgr_version_string"
      fi

      # Store product code and version (using unique keys)
      echo "$l_product_code:$l_product_version" >> "$l_product_file"
    fi
  done

  # Check if any products were processed
  if [ ! -f "$l_product_file" ] || [ ! -s "$l_product_file" ]; then
    pu_log_e "WMUI|06| No products could be parsed from file '$l_input_file'"
    rm -rf "$l_temp_dir"
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
    sort -u "$l_product_file" | {
      local l_first=true
      while IFS=: read -r l_product_id l_product_version; do
        if [ "$l_first" = true ]; then
          l_first=false
        else
          echo ","
        fi
        echo "        {"
        echo "            \"productId\": \"$(escape_json "$l_product_id")\","
        echo "            \"version\": \"$(escape_json "$l_product_version")\","
        echo "            \"displayName\": \"$(escape_json "$l_product_id")\""
        printf "        }"
      done
      echo ""
    }

    echo "    ],"
    echo "    \"installedFixes\": [],"
    echo "    \"installedSupportPatches\": [],"
    echo "    \"envVariables\": {"
    echo "        \"platformGroup\": [$l_umgr_platform_group_string],"
    echo "        \"UpdateManagerVersion\": \"$l_umgr_version\","
    echo "        \"Hostname\": \"localhost\","
    echo "        \"platform\": \"$l_umgr_platform_string\""
    echo "    }"
    echo "}"
  } > "$l_output_file"

  rm -rf "$l_temp_dir"
  pu_log_i "WMUI|06| Successfully generated inventory file: $l_output_file"
  return 0
}

######### Functions 21 - 30 - zip files generation

# Function 21 - Generate products.zip image file from a list of products
# TODO: a subset of function 22. To refactor.
wmui_generate_products_zip_from_list(){
  # Parameters
  # $1 -> product csv list
  # $2 -> OPTIONAL - installer binary location, default ${__wmui_default_installer_bin}
  # $3 -> OPTIONAL - output folder, default ${__wmui_default_output_folder}
  # $4 -> OPTIONAL - platform string, default ${__wmui_default_platform_string}

  pu_log_i "WMUI|21| Addressing products image for a given csv list..."
  pu_log_d "WMUI|21| InstallProducts=${1}"

  local l_installer_bin="${2:-${__wmui_default_installer_bin}}"
  if [ ! -f "${l_installer_bin}" ]; then
    pu_log_w "WMUI|21| Installer file ${l_installer_bin} not found, attempting to use the default one..."
    wmui_assure_default_installer "${l_installer_bin}" || return 1
  fi
  local l_output_folder="${3:-${__wmui_default_output_folder}}"
  pu_log_d "WMUI|21| l_output_folder=${l_output_folder}"
  local l_products_zip="${l_output_folder}/products.zip"
  local l_dbg_log="${l_output_folder}/product_zip_creation_debug.log"
  local l_img_creation_script="${l_output_folder}/createProductZipImage.wmscript"
  local l_products_csv="${1:-${__wmui_default_products_csv}}"

  if [ "${l_products_csv}" = "${__wmui_default_products_csv}" ]; then
    pu_log_e "WMUI|22| No product csv list provided, cannot generate an image!"
    return 2
  fi

  if [ -f "${l_products_zip}" ]; then
    pu_log_i "WMUI|21| Products zip image file ${l_products_zip} already exists, nothing to do."
    return 0
  fi

  if [ -f "${l_img_creation_script}" ]; then
    pu_log_i "WMUI|21| Permanent product image creation script file already present... Using the existing one."
  else
    pu_log_i "WMUI|21| Permanent product image creation script file not present, creating now..."
    local l_platform_string="${4:-${__wmui_default_platform_string}}"

    #Address download server URL
    local l_sdc_server_url
    case "${1}" in
    *"/1011/"*)
      l_sdc_server_url=${WMUI_SDC_SERVER_URL_1011:-"https\://sdc.webmethods.io/cgi-bin/dataservewebM1011.cgi"}
      ;;
    *"/1015/"*)
      l_sdc_server_url=${WMUI_SDC_SERVER_URL_1015:-"https\://sdc.webmethods.io/cgi-bin/dataservewebM1015.cgi"}
      ;;
    *"/1101/"*)
      l_sdc_server_url=${WMUI_SDC_SERVER_URL_1101:-"https\://sdc.webmethods.io/cgi-bin/dataservewebM111.cgi"}
      ;;
    *)
      l_sdc_server_url=${WMUI_SDC_SERVER_URL_DEFAULT:-"https\://sdc.webmethods.io/cgi-bin/dataservewebM111.cgi"}
      ;;
    esac

    pu_log_i "WMUI|21| Creating permanent product image creation script from template file ${__wmui_cache_home}/02-templates/01-setup/${1}/template.wmscript "
    mkdir -p "${l_output_folder}/${1}"
    {
      echo "###Generated"
      echo "LicenseAgree=Accept"
      echo "InstallLocProducts="
      echo "imagePlatform=${l_platform_string}"
      echo "imageFile=${l_products_zip}"
      echo "ServerURL=${l_sdc_server_url}"
      echo "InstallProducts=${l_products_csv}"
    } >"${l_img_creation_script}"

    pu_log_i "WMUI|21| Permanent product image creation script file created"
  fi

  pu_log_i "WMUI|21| Creating the volatile script ..."
  local l_epoch
  l_epoch=$(date +%s)
  local l_ephemeral_script="${__wmui_temp_fs_quick}/WMUI/setup/${l_epoch}/createProductImage.wmscript"
  mkdir -p "${__wmui_temp_fs_quick}/WMUI/setup/${l_epoch}/"
  cp "${l_img_creation_script}" "${l_ephemeral_script}"
  # TODO: assure credential variables
  echo "Username=${WMUI_DOWNLOAD_USER}" >>"${l_ephemeral_script}"
  echo "Password=${WMUI_DOWNLOAD_PASSWORD}" >>"${l_ephemeral_script}"
  pu_log_i "WMUI|21| Volatile script created."

  ## TODO: check if error management enforcement is needed: what if the grep produced nothing?
  ## TODO: deal with \ escaping in the password. For now avoid using '\' - backslash in the password string

  ## TODO: not space safe, but it shouldn't matter for now
  local l_temp_installer_bin="/tmp/installer-${l_epoch}.bin"
  cp "${l_installer_bin}" "${l_temp_installer_bin}"
  chmod u+x "${l_temp_installer_bin}"
  local l_cmd="${l_temp_installer_bin} -console -readScript ${l_ephemeral_script}"
  # shellcheck disable=SC2154
  if [ "${__1__debug_mode}" = "true" ]; then
    l_cmd="${l_cmd} -debugFile '${l_dbg_log}' -debugLvl verbose"
  fi
  l_cmd="${l_cmd} -writeImage ${l_products_zip}"
  # explicitly tell installer we are running unattended
  l_cmd="${l_cmd} -scriptErrorInteract no"

  # avoid downloading what we already have
  if [ -s "${__wmui_temp_fs_quick}/productsImagesList.txt" ]; then
    pu_log_d "WMUI|21| Using cached zip images specified in file __""${__wmui_temp_fs_quick}/productsImagesList.txt""__ "
    l_cmd="${l_cmd} -existingImages ""${__wmui_temp_fs_quick}/productsImagesList.txt"""
  fi

  pu_log_i "WMUI|21| Creating the product image ${l_products_zip}... This may take some time..."
  pu_log_d "WMUI|21| Command is ${l_cmd}"
  pu_audited_exec "${l_cmd}" "Create-all-products-image"
  local l_create_result=$?
  if [ $l_create_result -ne 0 ] ; then
    pu_log_e "WMUI|21| Image ${l_products_zip} creation failed with result: ${l_create_result}"
    pu_log_e "WMUI|21| Saving the ephemeral script into the output folder..."
    mv "${l_ephemeral_script}" "${__wmui_temp_fs_quick}/WMUI/setup/${l_epoch}"/
    if [ -f "${l_products_zip}" ]; then
      pu_log_e "WMUI|21| Moving away the resulting file, most likely corrupted or incomplete."
      mv "${l_products_zip}" "${l_products_zip}.${l_epoch}.err.zip"
    fi
  else
    pu_log_i "WMUI|21| Image ${l_products_zip} creation successfully completed"
  fi
  rm -f "${l_ephemeral_script}" "${l_temp_installer_bin}"

  return ${l_create_result}
}

# Function 22 - Generating a products image zip file for a template
# NOTE: pass download credentials in env variables WMUI_DOWNLOAD_USER and WMUI_DOWNLOAD_PASSWORD
# NOTE: ${__wmui_temp_fs_quick}/productsImagesList.txt may be created upfront if image caches are available
wmui_generate_products_zip_from_template() {
  # Parameters
  # $1 -> setup template
  # $2 -> OPTIONAL - installer binary location, default /tmp/installer.bin
  # $3 -> OPTIONAL - output folder, default /tmp/images/products
  # $4 -> OPTIONAL - platform string, default LNXAMD64
  # $5 -> OPTIONAL - useLatest (true/false), default true. If true, uses products-latest-list.txt, otherwise uses products-versioned-list.txt

  pu_log_i "WMUI|22| Addressing products image for setup template ${1}..."
  local l_template_products_list_file
  l_template_products_list_file=$(wmui_get_product_list_of_template "${1}" "${5}")

  local l_products_csv
  # l_template_products_list_file already contains the full path from Function 05
  l_products_csv=$(pu_lines_to_csv "${l_template_products_list_file}")

  local l_output_folder_specialization='versioned'
    if [ "${5}" = "true" ]; then
      l_output_folder_specialization='latest'
    fi

  local l_output_folder="${3:-/tmp/images/products}/${1}/${l_output_folder_specialization}"
  pu_log_d "WMUI|23| Products image for setup template ${1} will be generated in ${l_output_folder}..."
  mkdir -p "${l_output_folder}"

  wmui_generate_products_zip_from_list \
    "${l_products_csv}" "${2}" "${l_output_folder}" "${4}"
}

# Function 23 - Generating a products image zip file for a list of templates
wmui_generate_products_zip_from_templates_list() {
  # Parameters
  # $1 -> setup templates list, space separated
  # $2 -> OPTIONAL - installer binary location, default /tmp/installer.bin
  # $3 -> OPTIONAL - output folder, default /tmp/images
  # $4 -> OPTIONAL - platform string, default LNXAMD64
  # $5 -> OPTIONAL: useLatest (true/false), default true. If true, uses products-latest-list.txt, otherwise uses products-versioned-list.txt

  local l_templates_list="${1}"
  local l_installer_bin="${2:-${__wmui_default_installer_bin}}"
  local l_output_folder="${3:-${__wmui_default_output_folder}}"
  local l_platform_string="${4:-${__wmui_default_platform_string}}"
  local l_use_latest="${5:-${__wmui_default_use_latest}}"

  if [ -z "$l_templates_list" ]; then
    pu_log_e "WMUI|23| Templates list is required"
    return 1
  fi

  pu_log_i "WMUI|23| Generating a single products zip file for the list of templates [ ${l_templates_list} ]"

  # Create temporary file for merged products list
  local l_epoch
  l_epoch=$(date +%s)
  local l_temp_merged_list="/tmp/wmui_merged_products_${l_epoch}.txt"

  # Collect all product list files
  local l_product_list_files=""
  for l_template in ${l_templates_list}; do
    local l_template_list_file
    l_template_list_file=$(wmui_get_product_list_of_template "${l_template}" "${l_use_latest}")
    if [ $? -ne 0 ]; then
      pu_log_e "WMUI|23| Failed to get product list for template ${l_template}"
      rm -f "${l_temp_merged_list}"
      return 2
    fi
    l_product_list_files="${l_product_list_files} ${l_template_list_file}"
  done

  local l_output_folder_specialization='versioned'
    if [ "${l_use_latest}" = "true" ]; then
      l_output_folder_specialization='latest'
    fi

  mkdir -p "${l_output_folder}/${l_output_folder_specialization}"

  # Merge all product lists using Function 07
  # shellcheck disable=SC2086
  if ! wmui_merge_product_lists "${l_temp_merged_list}" ${l_product_list_files} ; then
    pu_log_e "WMUI|23| Failed to merge product lists"
    rm -f "${l_temp_merged_list}"
    return 3
  fi

  # Convert merged list to CSV
  local l_products_csv
  l_products_csv=$(pu_lines_to_csv "${l_temp_merged_list}")

  # Generate products zip from merged CSV
  wmui_generate_products_zip_from_list \
    "${l_products_csv}" \
    "${l_installer_bin}" \
    "${l_output_folder}/${l_output_folder_specialization}" \
    "${l_platform_string}"
  local l_result=$?

  # Cleanup
  rm -f "${l_temp_merged_list}"

  if [ ${l_result} -ne 0 ]; then
    pu_log_e "WMUI|23| Failed to generate products zip, code ${l_result}"
    return 4
  fi

  pu_log_i "WMUI|23| Successfully generated products zip for templates list"
  return 0
}

# Function 26 - Generating fixes zip file for list of products
wmui_generate_fixes_zip_from_list_on_file() {
  # Parameters
  # $1 -> file containing the product list
  # $2 -> OPTIONAL - output folder, default ${__wmui_default_output_folder_fixes}
  # $3 -> OPTIONAL - fixes tag. Defaulted to current day
  # $4 -> OPTIONAL - platform string, default ${__wmui_default_platform_string}
  # $5 -> OPTIONAL - update manager home, default ${__wmui_default_umgr_home}
  # $6 -> OPTIONAL - upd-mgr-bootstrap binary location, default ${__wmui_default_umgr_bin}

  local l_products_list_file="${1:-${__wmui_default_products_csv}}"
  if [ "${l_products_list_file}" = "${__wmui_default_products_csv}" ]; then
    pu_log_e "WMUI|26| No product list file provided"
    return 1
  fi

  local l_crt_date
  l_crt_date="$(date +%y-%m-%d)"
  local l_d
  l_d="$(date +%y-%m-%dT%H.%M.%S_%3N)"
  local l_fixes_tag="${3:-$l_crt_date}"
  pu_log_i "WMUI|26| Addressing fixes image from given product list file ${1} using tag ${l_fixes_tag}..."

  local l_output_dir="${2:-${__wmui_default_output_folder_fixes}}"
  local l_fixes_dir="${l_output_dir}/${l_fixes_tag}"
  mkdir -p "${l_fixes_dir}"
  local l_fixes_image_file="${l_fixes_dir}/fixes.zip"
  local l_permanent_inventory_file="${l_fixes_dir}/inventory.json"
  local l_permanent_script_file="${l_fixes_dir}/createFixesImage.wmscript"
  local l_platform_string="${4:-${__wmui_default_platform_string}}"

  if [ -f "${l_fixes_image_file}" ]; then
    pu_log_i "WMUI|26| Fixes image ${l_fixes_image_file} already exists, nothing to do."
    return 0
  fi

  local l_upd_mgr_home="${5:-${__wmui_default_umgr_home}}"
  if [ ! -d "${l_upd_mgr_home}/bin" ]; then
    pu_log_w "WMUI|26| UPD_MGR Home does not contain a UPD_MGR installation, trying to bootstrap now..."
    local l_upd_mgr_bootstrap_bin="${6:-${__wmui_default_umgr_bin}}"
    if [ ! -f "${l_upd_mgr_bootstrap_bin}" ]; then
      pu_log_w "WMUI|26| UPD_MGR Bootstrap binary not found, trying to obtain the default one..."
      wmui_assure_default_umgr_bin "${l_upd_mgr_bootstrap_bin}" || return $?
      # Parameters - wmui_bootstrap_umgr
      # $1 - Update Manager Bootstrap file
      # $2 - Fixes image file, mandatory for offline mode
      # $3 - OPTIONAL Where to install (UPD_MGR Home), default ${__wmui_default_umgr_home}
      # NOTE: WMUI_PRODUCT_ONLINE_MODE must be true for online mode
      wmui_bootstrap_umgr "${l_upd_mgr_bootstrap_bin}" '' "${l_upd_mgr_home}" || return $?
    fi
  fi

  if [ -f "${l_permanent_inventory_file}" ]; then
    pu_log_i "WMUI|26| Inventory file ${l_permanent_inventory_file} already exists, skipping creation."
  else
    pu_log_i "WMUI|26| Inventory file ${l_permanent_inventory_file} does not exist, creating now."

    # Ensure directory exists before creating inventory file
    local l_inventory_dir
    l_inventory_dir=$(dirname "${l_permanent_inventory_file}")
    mkdir -p "${l_inventory_dir}"

    # Parameters - wmui_generate_inventory_from_products_list
    # $1 - input file path (products list file)
    # $2 - output file path (JSON inventory file)
    # $3 - OPTIONAL: sum version string, defaults to ${__wmui_default_umgr_version_string}
    # $4 - OPTIONAL: platform string, defaults to ${__wmui_default_platform_string}
    # $5 - OPTIONAL: update manager version, defaults to ${__wmui_default_umgr_version}
    # $6 - OPTIONAL: platform group string, defaults to ${__wmui_default_platform_group_string}
    wmui_generate_inventory_from_products_list \
      "${l_products_list_file}" \
      "${l_permanent_inventory_file}" \
      "" \
      "${l_platform_string}"
  fi

  if [ -f "${l_permanent_script_file}" ]; then
    pu_log_i "WMUI|26| Permanent script file ${l_permanent_script_file} already exists, skipping creation..."
  else
    pu_log_i "WMUI|26| Permanent script file ${l_permanent_script_file} does not exist, creating now..."

    # Ensure directory exists before creating script file
    local l_script_dir
    l_script_dir=$(dirname "${l_permanent_script_file}")
    mkdir -p "${l_script_dir}"

    {
      echo "# Generated"
      echo "scriptConfirm=N"
      # use before reuse -> diagnosers not covered for now
      echo "installSP=N"
      echo "action=Create or add fixes to fix image"
      echo "selectedFixes=spro:all"
      echo "installDir=${l_permanent_inventory_file}"
      echo "imagePlatform=${l_platform_string}"
      echo "createEmpowerImage=C"
    } >"${l_permanent_script_file}"
  fi

  local l_cmd="./UpdateManagerCMD.sh -selfUpdate false -readScript "'"'"${l_permanent_script_file}"'"'
  l_cmd="${l_cmd} -installDir "'"'"${l_permanent_inventory_file}"'"'
  l_cmd="${l_cmd} -imagePlatform ${l_platform_string}"
  l_cmd="${l_cmd} -createImage "'"'"${l_fixes_image_file}"'"'
  l_cmd="${l_cmd} -empowerUser ${WMUI_DOWNLOAD_USER}"
  pu_log_d "webMethods Update Manager command to execute: ${l_cmd} -empowerPass ***"
  l_cmd="${l_cmd} -empowerPass '${WMUI_DOWNLOAD_PASSWORD}'"

  local l_crt_dir
  l_crt_dir=$(pwd)

  cd "${l_upd_mgr_home}/bin" || return 3

  pu_audited_exec "${l_cmd}" "Create-all-fixes-image-tag-${l_fixes_tag}"
  local l_result_fix_creation=$?

  if [ ${l_result_fix_creation} -ne 0 ]; then
    pu_log_w "WMUI|26| All fixes image creation failed with code ${l_result_fix_creation}! Saving troubleshooting information into the destination folder"
    pu_log_i "WMUI|26| Archiving destination folder results, which are partial at best..."
    cd "${l_fixes_dir}" || return 1
    tar czf "dump.tgz" ./* --remove-files
    mkdir -p "${l_fixes_dir}/$l_d"
    mv "dump.tgz" "${l_fixes_dir}/$l_d"/
    cd "${l_upd_mgr_home}" || return 1
    pu_log_d "WMUI|26| Listing all log files produced by Update Manager"
    find . -type f -name "*.log"

    # ensure the password is not in the logs before sending them to archiving
    l_cmd="grep -rl '${WMUI_DOWNLOAD_PASSWORD}' . | xargs sed -i 's/${WMUI_DOWNLOAD_PASSWORD}/HIDDEN_PASSWORD/g'"
    eval "${l_cmd}"
    unset l_cmd

    find . -type f -regex '\(.*\.log\|.*\.log\.[0-9]*\)' -print0 | xargs -0 tar cfvz "${l_fixes_dir}/$l_d/sum_logs.tgz"
    pu_log_i "WMUI|26| Dump complete"
    cd "${l_crt_dir}" || return 4
    return 3
  fi

  cd "${l_crt_dir}" || return 5
  pu_log_i "WMUI|26| Fix image creation for product list file ${1} finished successfully"

}

# Function 27 - Generating a products image zip file for a template
# NOTE: pass SDC credentials in env variables WMUI_DOWNLOAD_USER and WMUI_DOWNLOAD_PASSWORD
wmui_generate_fixes_zip_from_template() {
  # Parameters
  # $1 -> setup template
  # $2 -> OPTIONAL - output folder, default ${__wmui_default_output_folder_fixes}
  # $3 -> OPTIONAL - fixes tag. Defaulted to current day
  # $4 -> OPTIONAL - platform string, default ${__wmui_default_platform_string}
  # $5 -> OPTIONAL - update manager home, default ${__wmui_default_umgr_home}
  # $6 -> OPTIONAL - upd-mgr-bootstrap binary location, default ${__wmui_default_umgr_bin}
  # $7 -> OPTIONAL - use-latest (true/false), default ${__wmui_default_use_latest}. If true, uses products-latest-list.txt, otherwise uses products-versioned-list.txt

  pu_log_i "WMUI|27| Addressing fixes image for setup template ${1}..."
  local l_template_products_list_file l_use_latest l_output_dir
  l_template_products_list_file=$(wmui_get_product_list_of_template "${1}" "${7}")
  l_use_latest=${7:-true}
  pu_log_d "WMUI|27| l_use_latest=${l_use_latest};l_template_products_list_file=${l_template_products_list_file}"

  local l_output_folder_specialization='versioned'
    if [ "${7}" = "true" ]; then
      l_output_folder_specialization='latest'
    fi

  l_output_dir="${2:-${__wmui_default_output_folder_fixes}}/${l_output_folder_specialization}"
  mkdir -p "${l_output_dir}"

  if ! wmui_generate_fixes_zip_from_list_on_file \
        "${l_template_products_list_file}" \
        "${l_output_dir}" \
        "${3}" "${4}" "${5}" "${6}" ; then
    pu_log_e "WMUI|27| ERROR: Failed to generate fixes image for setup template ${1}."
    return 1
  fi
}

# Function 28 - Generate all zip files for a list of templates (orchestration function)
wmui_generate_all_zips_for_templates_list() {
  # Parameters:
  # $1 -> templates list (space-separated)
  # $2 -> OPTIONAL - installer binary location, default ${__wmui_default_installer_bin}
  # $3 -> OPTIONAL - global output directory (for merged zips), default ${__wmui_default_output_folder}
  # $4 -> OPTIONAL - per-template products output directory, default ${__wmui_default_output_folder}/products
  # $5 -> OPTIONAL - per-template fixes output directory, default ${__wmui_default_output_folder}/fixes
  # $6 -> OPTIONAL - platform string, default ${__wmui_default_platform_string}
  # $7 -> OPTIONAL - fixes date tag, default current date
  # $8 -> OPTIONAL - update manager home, default ${__wmui_default_umgr_home}
  # $9 -> OPTIONAL - update manager bootstrap binary, default ${__wmui_default_umgr_bin}
  # $10 -> OPTIONAL - useLatest flag, default ${__wmui_default_use_latest}
  # $11 -> OPTIONAL - unified images only, default false

  local l_templates_list="${1}"
  local l_installer_bin="${2:-${__wmui_default_installer_bin}}"
  local l_per_template_products_dir="${4:-${__wmui_default_output_folder}/products}"
  local l_per_template_fixes_dir="${5:-${__wmui_default_output_folder}/fixes}"
  local l_platform_string="${6:-${__wmui_default_platform_string}}"
  local l_crt_date
  l_crt_date="$(date +%y-%m-%d)"
  local l_fixes_tag="${7:-$l_crt_date}"
  local l_umgr_home="${8:-${__wmui_default_umgr_home}}"
  local l_umgr_bootstrap_bin="${9:-${__wmui_default_umgr_bin}}"
  local l_use_latest="${10:-${__wmui_default_use_latest}}"
  local l_output_folder_specialization='versioned'
    if [ "${l_use_latest}" = "true" ] ; then
      pu_log_i "WMUI|28| Using latest products"
      l_output_folder_specialization='latest'
    fi

  local l_global_output_dir="${3:-${__wmui_default_output_folder}}/${l_output_folder_specialization}"

  if [ -z "$l_templates_list" ]; then
    pu_log_e "WMUI|28| Templates list is required"
    return 1
  fi

  # Count templates
  local l_template_count
  l_template_count=$(echo "$l_templates_list" | wc -w)

  pu_log_i "WMUI|28| Generating zip files for ${l_template_count} template(s): ${l_templates_list}"

  if [ "$l_template_count" -eq 1 ]; then
    # Single template: Skip Phase 1, generate only per-template zips
    pu_log_i "WMUI|28| Single template detected - skipping global zip generation"
    pu_log_i "WMUI|28| Generating per-template zips directly"

    for l_template in $l_templates_list; do
      local l_template_fixes_base="${l_per_template_fixes_dir}/${l_template}"

      # Generate products zip for template
      pu_log_i "WMUI|28| Generating products zip for template ${l_template}"
      mkdir -p "${l_per_template_products_dir}"
      if ! wmui_generate_products_zip_from_template \
        "${l_template}" \
        "${l_installer_bin}" \
        "${l_per_template_products_dir}" \
        "${l_platform_string}" \
        "${l_use_latest}" ; then
        pu_log_e "WMUI|28| Failed to generate products zip for template ${l_template}"
        return 2
      fi

      # Generate fixes zip for template
      pu_log_i "WMUI|28| Generating fixes zip for template ${l_template}"
      mkdir -p "${l_template_fixes_base}"
      if ! wmui_generate_fixes_zip_from_template \
        "${l_template}" \
        "${l_template_fixes_base}" \
        "${l_fixes_tag}" \
        "${l_platform_string}" \
        "${l_umgr_home}" \
        "${l_umgr_bootstrap_bin}" \
        "${l_use_latest}" ; then
        pu_log_e "WMUI|28| Failed to generate fixes zip for template ${l_template}"
        return 3
      fi
    done

    pu_log_i "WMUI|28| Successfully generated per-template zips for single template"
    return 0

  else
    # Multiple templates: Execute both phases
    pu_log_i "WMUI|28| Multiple templates detected - executing two-phase generation"

    # Phase 1: Generate global (merged) zips
    pu_log_i "WMUI|28| Phase 1: Generating global zips for ${l_template_count} templates"

    # Create temporary file for merged products list
    local l_epoch
    l_epoch=$(date +%s)
    local l_temp_merged_list="/tmp/wmui_merged_products_${l_epoch}.txt"
    local l_temp_inventory="/tmp/wmui_inventory_${l_epoch}.json"

    # Collect all product list files
    local l_product_list_files=""
    for l_template in $l_templates_list; do
      local l_template_list_file
      if ! l_template_list_file=$(wmui_get_product_list_of_template \
                                  "${l_template}" \
                                  "${l_use_latest}") ; then
        pu_log_e "WMUI|28| Failed to get product list for template ${l_template}"
        rm -f "${l_temp_merged_list}" "${l_temp_inventory}"
        return 4
      fi
      l_product_list_files="${l_product_list_files} ${l_template_list_file}"
    done

    # Merge all product lists using Function 07
    # shellcheck disable=SC2086
    if ! wmui_merge_product_lists \
      "${l_temp_merged_list}" \
      ${l_product_list_files} ; then
      pu_log_e "WMUI|28| Failed to merge product lists"
      rm -f "${l_temp_merged_list}" "${l_temp_inventory}"
      return 5
    fi

    # Generate inventory from merged list
    if ! wmui_generate_inventory_from_products_list \
      "${l_temp_merged_list}" \
      "${l_temp_inventory}" \
      "" \
      "${l_platform_string}" ; then
      pu_log_e "WMUI|28| Failed to generate inventory from merged products list"
      rm -f "${l_temp_merged_list}" "${l_temp_inventory}"
      return 6
    fi

    # Generate global products zip
    local l_products_csv
    l_products_csv=$(pu_lines_to_csv "${l_temp_merged_list}")

    mkdir -p "${l_global_output_dir}"
    if ! wmui_generate_products_zip_from_list \
      "${l_products_csv}" \
      "${l_installer_bin}" \
      "${l_global_output_dir}" \
      "${l_platform_string}"; then
      pu_log_e "WMUI|28| Failed to generate global products zip"
      rm -f "${l_temp_merged_list}" "${l_temp_inventory}"
      return 7
    fi

    # Set global products zip as cache for Phase 2
    local l_global_products_zip="${l_global_output_dir}/products.zip"
    echo "${l_global_products_zip}" > "${__wmui_temp_fs_quick}/productsImagesList.txt"
    pu_log_i "WMUI|28| Global products zip set as cache: ${l_global_products_zip}"

    # Generate global fixes zip
    if ! wmui_generate_fixes_zip_from_list_on_file \
      "${l_temp_merged_list}" \
      "${l_global_output_dir}" \
      "${l_fixes_tag}" \
      "${l_platform_string}" \
      "${l_umgr_home}" \
      "${l_umgr_bootstrap_bin}" ; then
      pu_log_e "WMUI|28| Failed to generate global fixes zip"
      rm -f "${l_temp_merged_list}" "${l_temp_inventory}"
      return 8
    fi

    # Cleanup temporary files
    rm -f "${l_temp_merged_list}" "${l_temp_inventory}"

    pu_log_i "WMUI|28| Phase 1 complete - global zips generated"

    pu_log_d "WMUI|28| param 11=${11}"

    if [ ! "${11}" = "true " ]; then
      # Phase 2: Generate per-template zips
      pu_log_i "WMUI|28| Phase 2: Generating per-template zips"

      for l_template in $l_templates_list; do
        local l_template_fixes_base="${l_per_template_fixes_dir}/${l_template}"

        # Generate products zip for template (will use cache from Phase 1)
        pu_log_i "WMUI|28| Generating products zip for template ${l_template}"
        mkdir -p "${l_per_template_products_dir}"
        if ! wmui_generate_products_zip_from_template \
          "${l_template}" \
          "${l_installer_bin}" \
          "${l_per_template_products_dir}" \
          "${l_platform_string}" \
          "${l_use_latest}" ; then
          pu_log_w "WMUI|28| Failed to generate products zip for template ${l_template}, continuing..."
        fi

        # Generate fixes zip for template
        pu_log_i "WMUI|28| Generating fixes zip for template ${l_template}"
        mkdir -p "${l_template_fixes_base}"
        if ! wmui_generate_fixes_zip_from_template \
          "${l_template}" \
          "${l_template_fixes_base}" \
          "${l_fixes_tag}" \
          "${l_platform_string}" \
          "${l_umgr_home}" \
          "${l_umgr_bootstrap_bin}" \
          "${l_use_latest}" ; then
          pu_log_w "WMUI|28| Failed to generate fixes zip for template ${l_template}, continuing..."
        fi
      done
      pu_log_i "WMUI|28| Phase 2 complete - per-template zips generated"
    fi

    pu_log_i "WMUI|28| Successfully generated all zips for ${l_template_count} templates"
    return 0
  fi
}

######### Functions 41 - 50 - setup functions

# Function 41 - bootstrap update manager from binary file
wmui_bootstrap_umgr() {
  # Parameters - wmui_bootstrap_umgr
  # $1 - Update Manager Bootstrap file
  # $2 - Fixes image file, mandatory for offline mode
  # $3 - OPTIONAL Where to install (webMethods Update Manager Home), default ${__wmui_default_umgr_home}

  local l_umgr_bin="${1:-${__wmui_default_umgr_bin}}"
  local l_umgr_home="${3:-${__wmui_default_umgr_home}}"

  if [ ! -f "${l_umgr_bin}" ]; then
    pu_log_e "WMUI|41| webMethods Update Manager Bootstrap file not found: ${l_umgr_bin}"
    return 1
  fi

  if [ ! "${__wmui_product_online_mode}" = "true" ]; then
    if [ ! -f "${2}" ]; then
      pu_log_e "WMUI|41| Fixes image file not found: ${2}"
      return 2
    fi
  fi

  if [ -d "${l_umgr_home}/UpdateManager" ]; then
    pu_log_i "WMUI|41| Update manager already present, skipping bootstrap, attempting to update from given image..."
    wmui_patch_umgr "${2}" "${l_umgr_home}" || return $?
    return 0
  fi

  local l_work_dir
  l_work_dir="/tmp/wmui-bootstrap-$(date +%s)"

  mkdir -p "${l_work_dir}" || return $?

  cp "${l_umgr_bin}" "${l_work_dir}/umgr-bootstrap.bin"
  chmod u+x "${l_work_dir}/umgr-bootstrap.bin"

  local l_bootstrap_cmd="${l_work_dir}/umgr-bootstrap.bin --accept-license -d "'"'"${l_umgr_home}"'"'
  if [ "${__wmui_product_online_mode}" = "true" ]; then
    pu_log_i "WMUI|41| Bootstrapping UPD_MGR from ${l_umgr_bin} into ${l_umgr_home} using ONLINE mode"
  else
    l_bootstrap_cmd="${l_bootstrap_cmd} -i ${2}"
    # note: everything is always offline except this, as it is not requiring empower credentials
    pu_log_i "WMUI|41| Bootstrapping UPD_MGR from ${l_umgr_bin} using image ${2} into ${l_umgr_home}..."
  fi
  pu_audited_exec "${l_bootstrap_cmd}" "upd-mgr-bootstrap"
  local l_res_cexec=$?
  # TODO: this is 0 even if setup fails. To investigate
  if [ ${l_res_cexec} -ne 0 ]; then
    pu_log_e "WMUI|41| UPD_MGR Bootstrap failed, code ${l_res_cexec}. Check audit files and folder ${l_work_dir} for issues."
    return 3
  fi

  if [ ! -d "${l_umgr_home}/UpdateManager" ]; then
    pu_log_e "WMUI|41| UPD_MGR Bootstrap failed, without returning an error code. Check audit files and folder ${l_work_dir} for issues."
    return 4
  fi

  pu_log_i "WMUI|41| UPD_MGR Bootstrap successful"
  rm -rf "${l_work_dir}"
  return 0
}

# Function 42 - patch existing update manager installation
wmui_patch_umgr() {
  # Parameters - wmui_patch_umgr()
  # $1 - Fixes Image (this will always happen offline in this framework)
  # $2 - OPTIONAL UPD_MGR Home, takes framework default
  if [ ! "${__wmui_product_online_mode}" = "true" ]; then
    pu_log_i "WMUI|42| wmui_patch_umgr() ignored in online mode"
    return 0
  fi

  if [ ! -f "${1}" ]; then
    pu_log_w "WMUI|42| Fixes images file ${1} does not exist! Skipping patching..."
    return 0
  fi
  local l_umgr_home="${2:-${__wmui_default_umgr_home}}"

  if [ ! -d "${l_umgr_home}/UpdateManager" ]; then
    pu_log_i "WMUI|42| Update manager missing, nothing to patch..."
    return 0
  fi

  pu_log_i "WMUI|42| Updating webMethods Update Manager in ${l_umgr_home} from image ${1} ..."
  local l_crt_dir
  l_crt_dir=$(pwd)
  cd "${l_umgr_home}/bin" || return 2
  pu_audited_exec "./UpdateManagerCMD.sh -selfUpdate true -installFromImage "'"'"${1}"'"' "wmui_patch_umgr"
  local l_res_cexec=$?
  if [ "${l_res_cexec}" -ne 0 ]; then
    pu_log_e "WMUI|42| Update Manager Self Update failed with code ${l_res_cexec}"
    return 1
  fi
  cd "${l_crt_dir}" || return 3
}

# Function 43 - Install products
wmui_install_products() {
  # Parameters
  # $1 - script file for installer
  # $2 - OPTIONAL: installer binary file, default is ${__wmui_default_installer_bin}
  # $3 - OPTIONAL: debugLevel for installer

  local l_installer_bin="${2:-${__wmui_default_installer_bin}}"
  if [ ! -f "${l_installer_bin}" ]; then
    pu_log_e "WMUI|43| Product installation failed: invalid installer file: ${l_installer_bin}"
    return 1
  fi

  if [ ! -f "${1}" ]; then
    pu_log_e "WMUI|43| Product installation failed: invalid installer script file: ${2}"
    return 2
  fi

  pu_log_i "WMUI|43| Installing according to script ${2}"

  local l_work_dir
  l_work_dir="/tmp/wm-install/$(date '+%s')"
  mkdir -p "${l_work_dir}" || return 3

  cp "${1}" "${l_work_dir}/installer.bin"
  chmod u+x "${l_work_dir}/installer.bin"

  local l_debug_level="${3:-${__wmui_default_debug_level}}"

  local l_install_cmd="${l_work_dir}/installer.bin -readScript \"${2}\" -console"
  l_install_cmd="${l_install_cmd} -debugLvl ${l_debug_level}"
  if [ "${__1__debug_mode}" = "true" ]; then
    l_install_cmd="${l_install_cmd} -scriptErrorInteract yes"
  else
    l_install_cmd="${l_install_cmd} -scriptErrorInteract no"
  fi
  l_install_cmd="${l_install_cmd} -debugFile "'"'"${__2__audit_session_dir}/debugInstall.log"'"'
  pu_log_d "WMUI|43| Installation command is: ${l_install_cmd}"
  pu_audited_exec "${l_install_cmd}" "product-install"

  l_result_install_products=$?
  if [ ${l_result_install_products} -eq 0 ]; then
    pu_log_i "WMUI|43| Product installation successful"
  else
    pu_log_e "WMUI|43| Product installation failed, code ${l_result_install_products}"
    pu_log_e "WMUI|43| Looking for APP_ERROR in the debug file..."
    grep 'APP_ERROR' "${__2__audit_session_dir}/debugInstall.log"
    pu_log_e "WMUI|43| returning code 4"
    return 4
  fi

  rm -rf "${l_work_dir}"
}

# Function 44 - Patch installation
wmui_patch_installation() {
  # Parameters
  # $1 - Fixes Image (this will always happen offline in this framework)
  # $2 - OPTIONAL UPD_MGR Home, default ${__wmui_default_umgr_home}
  # $3 - OPTIONAL Installation Home, default ${__wmui_default_installation_home}
  # $4 - OPTIONAL Engineering patch modifier (default ${__wmui_default_epm})
  # $5 - OPTIONAL Engineering patch diagnoser key (default ${__wmui_default_diagnoser_key}, however user must provide if $4=Y)

  if [ ! -f "${1}" ]; then
    pu_log_e "WMUI|44| Fixes image file not found: ${1}"
    return 1
  fi

  local l_upd_mgr_home="${2:-${__wmui_default_umgr_home}}"
  local l_install_dir="${3:-${__wmui_default_installation_home}}"
  local l_d
  l_d=$(date +%y-%m-%dT%H.%M.%S_%3N)
  local l_epm="${4:-${__wmui_default_epm}}"
  local l_fixes_script_file="${__wmui_temp_fs_quick}/fixes.wmscript.txt"

  {
    echo "installSP=${l_epm}"
    echo "installDir=${l_install_dir}"
    echo "selectedFixes=spro:all"
    echo "action=Install fixes from image"
    echo "imageFile=${1}"
    if [ "${l_epm}" = "Y" ]; then
      local l_d_key="${5:-${__wmui_default_diagnoser_key}}"
      echo "diagnoserKey=${l_d_key}"
    fi
  } >"${l_fixes_script_file}"

  local l_crt_dir
  l_crt_dir=$(pwd)
  cd "${l_upd_mgr_home}/bin" || return 3

  pu_log_i "WMUI|44| Taking a snapshot of existing fixes..."
  pu_audited_exec './UpdateManagerCMD.sh -action viewInstalledFixes -installDir "'"${l_install_dir}"'"' "FixesBeforePatching"

  pu_log_i "WMUI|44| Explicitly patch UPD_MGR itself, if required..."
  wmui_patch_umgr "${1}" "${l_upd_mgr_home}"

  pu_log_i "WMUI|44| Applying fixes from image ${1} to installation ${l_install_dir} using UPD_MGR in ${l_upd_mgr_home}..."

  pu_audited_exec "./UpdateManagerCMD.sh -readScript \"${l_fixes_script_file}\"" "PatchInstallation"
  local l_res_cexec=$?

  pu_log_i "WMUI|44| Taking a snapshot of fixes after the patching..."
  pu_audited_exec './UpdateManagerCMD.sh -action viewInstalledFixes -installDir "'"${l_install_dir}"'"' "FixesAfterPatching"

  cd "${l_crt_dir}" || return 4

  if [ ${l_res_cexec} -eq 0 ]; then
    pu_log_i "WMUI|44| Patch successful"
  else
    pu_log_e "WMUI|44| Patch failed, code ${l_res_cexec}"
    if [ "${__1__debug_mode}" = "true" ]; then
      pu_log_d "WMUI|44| Recovering Update Manager logs for further investigations"
      mkdir -p "${__2__audit_session_dir}/UpdateManager"
      cp -r "${l_upd_mgr_home}"/logs "${__2__audit_session_dir}"/
      cp -r "${l_upd_mgr_home}"/UpdateManager/logs "${__2__audit_session_dir}"/UpdateManager/
      cp "${l_fixes_script_file}" "${__2__audit_session_dir}"/
    fi
    return 2
  fi

  if [ "${__1__debug_mode}" = "true" ]; then
    # if we are debugging, we want to see the generated script
    cp "${l_fixes_script_file}" "${__2__audit_session_dir}/fixes.${l_d}.wmscript.txt"
  fi

  rm -f "${l_fixes_script_file}"
}

# Function 45 - Remove diagnoser patch
wmui_remove_diagnoser_patch() {
  # Parameters
  # $1 - Engineering patch diagnoser key (e.g. "5437713_PIE-68082_5")
  # $2 - Engineering patch ids list (expected one id only, but we never know e.g. "5437713_PIE-68082_1.0.0.0005-0001")
  # $3 - OPTIONAL UPD_MGR Home, default ${__wmui_default_umgr_home}
  # $4 - OPTIONAL Installation Home, default ${__wmui_default_installation_home}

  local l_upd_mgr_home="${3:-${__wmui_default_umgr_home}}"
  if [ ! -f "${l_upd_mgr_home}/bin/UpdateManagerCMD.sh" ]; then
    pu_log_e "WMUI|45| Update manager not found at the indicated location ${l_upd_mgr_home}"
    return 1
  fi
  local l_install_dir="${4:-${__wmui_default_installation_home}}"
  if [ ! -d "${l_install_dir}" ]; then
    pu_log_e "WMUI|45| Product installation folder is missing: ${l_install_dir}"
    return 2
  fi

  local l_d
  l_d=$(date +%y-%m-%dT%H.%M.%S_%3N)
  local l_tmp_script_file="${__wmui_temp_fs_quick}/fixes.${l_d}.wmscript.txt"

  {
    echo "installSP=Y"
    echo "diagnoserKey=${1}"
    echo "installDir=${l_install_dir}"
    echo "selectedFixes=${2}"
    echo "action=Uninstall fixes"
  } >"${l_tmp_script_file}"

  local l_crt_dir
  l_crt_dir=$(pwd)
  cd "${l_upd_mgr_home}/bin" || return 4

  pu_log_i "WMUI|45| Taking a snapshot of existing fixes..."
  pu_audited_exec './UpdateManagerCMD.sh -action viewInstalledFixes -installDir "'"${l_install_dir}"'"' "FixesBeforeSPRemoval"

  pu_log_i "WMUI|45| Removing support patch ${1} from installation ${l_install_dir} using UPD_MGR in ${l_upd_mgr_home}..."
  pu_audited_exec "./UpdateManagerCMD.sh -readScript \"${l_tmp_script_file}\"" "SPFixRemoval"
  local l_res_cexec=$?

  pu_log_i "WMUI|45| Taking a snapshot of fixes after the execution of SP removal..."
  pu_audited_exec './UpdateManagerCMD.sh -action viewInstalledFixes -installDir "'"${l_install_dir}"'"' "FixesAfterSPRemoval"

  cd "${l_crt_dir}" || return 5

  if [ ${l_res_cexec} -eq 0 ]; then
    pu_log_i "WMUI|45| Support patch removal was successful"
  else
    pu_log_e "WMUI|45| Support patch removal failed, code ${l_res_cexec}"
    if [ "${__1__debug_mode}" = "true" ]; then
      pu_log_d "WMUI|45| Recovering Update Manager logs for further investigations"
      mkdir -p "${__2__audit_session_dir}/UpdateManager"
      cp -r "${l_upd_mgr_home}"/logs "${__2__audit_session_dir}"/
      cp -r "${l_upd_mgr_home}"/UpdateManager/logs "${__2__audit_session_dir}"/UpdateManager/
      cp "${l_tmp_script_file}" "${__2__audit_session_dir}"/
    fi
    return 3
  fi

  if [ "${__1__debug_mode}" = "true" ]; then
    # if we are debugging, we want to see the generated script
    cp "${l_tmp_script_file}" "${__2__audit_session_dir}/fixes.D.${l_d}.wmscript.txt"
  fi

  rm -f "${l_tmp_script_file}"
}

# Function 46 - Setup products and fixes
wmui_setup_products_and_fixes_from_template() {
  # Parameters
  # $1 - Template id
  # $2 - OPTIONAL: use latest versions (default passthrough to wmui_install_template_products)
  # $3 - OPTIONAL: Installer binary location, default passthrough to wmui_install_template_products
  # $4 - OPTIONAL: debugLevel for installer, default verbose
  # $5 - OPTIONAL: fixes file image. Absent means skip patching
  # $6 - OPTIONAL: Update manager home, default ${__wmui_default_umgr_home}

  pu_log_i "WMUI|46| Setting up product and fixes for template ${1}"
    if ! wmui_install_template_products "${1}" "${2}" "${3}" "${4}" ; then
      pu_log_e "WMUI|46| Failed to install products and fixes for template ${1}"
      return 1
    fi

  if [ -z "${5+x}" ]; then
    pu_log_i "WMUI|46| Fixes image not received, skipping patching"
    return 0
  fi
  if [ ! -f "${5}" ]; then
    pu_log_e "WMUI|46| Wrong fixes file, cannot continue: ${5}"
    return 2
  fi

  # WMUI_WMSCRIPT_InstallDir MUST be passed in environment otherwise installation fails above
  # shellcheck disable=SC2154
  if ! wmui_patch_installation "${5}" "${6}" "${WMUI_WMSCRIPT_InstallDir}" ; then
    pu_log_e "WMUI|46| Failed to patch installation"
    return 3
  fi

  return 0
}

# Function 47 - Setup products for template
wmui_install_template_products() {
  # Parameters
  # $1 - Template id
  # $2 - OPTIONAL: use latest versions, default passthrough to wmui_install_products
  # $3 - OPTIONAL: Installer binary location, default passthrough to wmui_install_products
  # $4 - OPTIONAL: debugLevel for installer, default verbose

  ## 1. Preliminary checks and env setup
    local l_prerequisite_errors=0
    if [ ! "$(which envsubst)" ]; then
      pu_log_e "WMUI|47| Product installation from template requires envsubst to be installed!"
      l_prerequisite_errors=$((l_prerequisite_errors + 1))
    fi

    if [ -z "${WMUI_WMSCRIPT_imageFile+x}" ]; then
      pu_log_e "WMUI_WMSCRIPT_imageFile is unset. this framework always installs from local zip images"
      l_prerequisite_errors=$((l_prerequisite_errors + 1))
    fi

    if ! wmui_hunt_for_file "02-templates/01-setup/${1}" "template.wmscript" ; then
      pu_log_e "WMUI|47| Setup for template ${1} failed, file not found. is [${1}] an existing template?"
      l_prerequisite_errors=$((l_prerequisite_errors + 1))
    fi

    if [ ${l_prerequisite_errors} -ne 0 ] ; then
      pu_log_e "WMUI|47| Framework prerequisites check failed for template ${2}"
      return 1
    fi

    if ! wmui_hunt_for_file "02-templates/01-setup/${1}" "check-prerequisites.sh" ; then
      pu_log_w "WMUI|47| Cannot find check-prerequisites.sh for template [${1}]. Ignoring prerequisites check..."
    else
      if [ -f "${__wmui_cache_home}/02-templates/01-setup/${1}/check-prerequisites.sh" ]; then
        pu_log_i "WMUI|47| Checking installation prerequisites for template ${1} ..."
        chmod u+x "${__wmui_cache_home}/02-templates/01-setup/${1}/check-prerequisites.sh" >/dev/null
        "${__wmui_cache_home}/02-templates/01-setup/${1}/check-prerequisites.sh" || return 3
      else
        pu_log_w "WMUI|47| Check prerequisites script not present even after successful hunting. This should not happen. Skipping check..."
      fi
    fi

    if ! wmui_hunt_for_file "02-templates/01-setup/${1}" "set-env-defaults.sh" ; then
      pu_log_w "WMUI|47| Cannot find set-env-defaults.sh for template [${1}]. Using framework's defaults..."
    else
      if [ -f "${__wmui_cache_home}/02-templates/01-setup/${1}/set-env-defaults.sh" ]; then
        pu_log_i "WMUI|47| Applying defaults for template ${1} ..."
        chmod u+x "${__wmui_cache_home}/02-templates/01-setup/${1}/set-env-defaults.sh" >/dev/null
        # shellcheck source=/dev/null
        . "${__wmui_cache_home}/02-templates/01-setup/${1}/set-env-defaults.sh" || return 4
      else
        pu_log_w "WMUI|47| set-env-defaults.sh for template [${1}] missing even if successfully hunted for.This should not happen. Using framework's defaults..."
      fi
    fi

  ## 2. Get the products list file
    local \
      l_use_latest \
      l_products_file \
      l_d \
      l_product_lines \
      l_temp_enhanced_template
    l_use_latest="${3:-true}"
    l_products_file=$(wmui_get_product_list_of_template "${1}" "${2}")
    l_d=$(date +%s)

    pu_log_i "WMUI|47| Setup products for template ${1}, use latest: ${l_use_latest}"

    # Create temporary enhanced template with InstallProducts line
    l_temp_enhanced_template="${__2__audit_session_dir}/template_enhanced_${l_d}.wmscript"

    # Copy original template
    envsubst \
      <"${__wmui_cache_home}/02-templates/01-setup/${1}/template.wmscript" \
      >"${l_temp_enhanced_template}" || return 5

    echo "InstallProducts=$(pu_lines_to_csv "${l_products_file}")"\
      >> "${l_temp_enhanced_template}"

  ## 3. Call installation function
    if ! wmui_install_products \
      "${3}" \
      "${l_temp_enhanced_template}" \
      "${2}" ; then
      pu_log_e "WMUI|47| Error while installing products according to template ${1}"
      pu_log_d "WMUI|47| Leaving temp file ${l_temp_enhanced_template} for diagnostics"
      return 1
    else
      pu_log_i "WMUI|47| Products installed successfully according to template ${1}"
      rm -f "${l_temp_enhanced_template}"
    fi

  return 0
}

######## Functions 61+ Post setup ########

# Function 61 - Apply post-setup template
wmui_apply_post_setup_template() {
  # Parameters
  # $1 - Setup template directory, relative to <repo_home>/02-templates/02.post-setup

  pu_log_i "WMUI|47| Applying post-setup template ${1}..."

  ## Part 01 - defaults
    if wmui_hunt_for_file "02-templates/02-post-setup/${1}" "01-set-env-defaults.sh" ; then
      pu_log_d "WMUI|47| 01-set-env-defaults.sh found, using it to set defaults..."
      # shellcheck disable=SC1090
      . "${__wmui_cache_home}/02-templates/02-post-setup/${1}/01-set-env-defaults.sh"
    else
      pu_log_w "WMUI|47| 01-set-env-defaults.sh not found, no defaults considered!"
    fi

  ## Part 02 - prerequisites
    if wmui_hunt_for_file "02-templates/02-post-setup/${1}" "02-check-prerequisites.sh" ; then
      pu_log_d "WMUI|47| 02-check-prerequisites.sh found, calling..."
      # shellcheck disable=SC1090
      . "${__wmui_cache_home}/02-templates/02-post-setup/${1}/02-check-prerequisites.sh"
    else
      pu_log_w "WMUI|47| 02-check-prerequisites.sh not found, no prerequisites considered!"
    fi

  ## Part 03 - apply
    if ! wmui_hunt_for_file "02-templates/02-post-setup/${1}" "03-apply.sh" ; then
      pu_log_e "WMUI|61| File ${__wmui_cache_home}/02-templates/02-post-setup/${1}/03-apply.sh not found!"
      return 1
    fi

    pu_log_i "WMUI|61| Applying post-setup template ${1}"
    # shellcheck disable=SC1090
    if ! . "${__wmui_cache_home}/02-templates/02-post-setup/${1}/03-apply.sh" ; then
      pu_log_e "WMUI|61| Application of post-setup template ${1} failed, code $?"
      return 3
    fi
    pu_log_i "WMUI|61| Post setup template ${1} applied successfully"
    return 0
}

pu_log_d "WMUI|--| wmui-functions.sh initialized"
pu_log_d "WMUI|--| Using posix utils audit folder __2__audit_session_dir=${__2__audit_session_dir}"
