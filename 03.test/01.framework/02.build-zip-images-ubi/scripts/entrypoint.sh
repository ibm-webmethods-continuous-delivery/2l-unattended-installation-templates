#!/bin/sh

# shellcheck disable=SC3043

## Prerequisite libraries

  # shellcheck source=../../../../../2l-posix-shell-utils/code/1.init.sh
  . "${PU_HOME}/code/1.init.sh"

  # shellcheck source=../../../../../2l-posix-shell-utils/code/3.ingester.sh
  . "${PU_HOME}/code/3.ingester.sh"

  # shellcheck source=../../../../../2l-posix-shell-utils/code/6.string.sh
  . "${PU_HOME}/code/6.string.sh"

  # shellcheck source=../../../../../2l-posix-shell-utils/code/7.data.sh
  . "${PU_HOME}/code/7.data.sh"

  # shellcheck source=../../../..//01.scripts/wmui-functions.sh
  . "${WMUI_HOME}/01.scripts/wmui-functions.sh"

## Test base resources
  __err_no=0
  __epoch=$(date '+%s')
  __work_dir=/tmp/wmui/test/${__epoch}

  mkdir -p "${__work_dir}"
  cd "${__work_dir}" || exit 1

  if ! wmui_assure_default_installer "${WMUI_TEST_INSTALLER_BIN}" ; then
    pu_log_w "Default installer not assured! Eventually clean the output folder."
    __err_no=$((__err_no+1))
  fi

  if ! wmui_assure_default_umgr_bin "${WMUI_TEST_UMGR_BOOTSTRAP_BIN}" ; then
    pu_log_w "Default Update Manager Bootstrap not assured! Eventually clean the output folder."
    __err_no=$((__err_no+1))
  fi

pu_log_i "Installing Update Manager..."

  cp "${WMUI_TEST_UMGR_BOOTSTRAP_BIN}" "${__work_dir}/umgr-boot.bin"
  chmod u+x "${__work_dir}/umgr-boot.bin"
  if ! wmui_bootstrap_umgr \
    "${__work_dir}/umgr-boot.bin" \
    "" \
    "${WMUI_TEST_UMGR_HOME_DIR}"; then
    pu_log_e "Update Manager bootstrap failed with code $?, stopping for debug. CTRL-C for the next instructions"
    __err_no=$((__err_no+1))
  fi
  rm "${__work_dir}/umgr-boot.bin"

## Collected prerequisites errors check
  if [ $__err_no -gt 0 ]; then
    pu_log_e "Some tests failed, stopping for debug. Stopping. CTRL-C for the next instructions"
    sleep infinity
  fi

_make_images() {
  # Use Function 28 for orchestrated zip generation
  # shellcheck disable=SC2154
  pu_log_i "Test|ZipImages Starting zip generation for templates: ${WMUI_TEST_Templates}"

  # Set default directories if not provided
  local l_products_base_dir="${WMUI_PRODUCT_IMAGES_SHARED_DIRECTORY:-/mnt/artifacts/products}"
  local l_fixes_base_dir="${WMUI_FIX_IMAGES_SHARED_DIRECTORY:-/mnt/artifacts/fixes}"

  # Parameters for wmui_generate_all_zips_for_templates_list:
  # $1 -> templates list (space-separated)
  # $2 -> OPTIONAL - installer binary location
  # $3 -> OPTIONAL - global output directory (for merged zips)
  # $4 -> OPTIONAL - per-template products output directory
  # $5 -> OPTIONAL - per-template fixes output directory
  # $6 -> OPTIONAL - platform string
  # $7 -> OPTIONAL - fixes date tag
  # $8 -> OPTIONAL - update manager home
  # $9 -> OPTIONAL - update manager bootstrap binary
  # $10 -> OPTIONAL - useLatest flag

  wmui_generate_all_zips_for_templates_list \
    "${WMUI_TEST_Templates}" \
    "${WMUI_TEST_INSTALLER_BIN}" \
    "${WMUI_TEST_ALL_PRODUCTS_OUTPUT_DIR}" \
    "${l_products_base_dir}" \
    "${l_fixes_base_dir}" \
    "${WMUI_PRODUCT_IMAGES_PLATFORM}" \
    "${WMUI_FIXES_DATE_TAG}" \
    "${WMUI_TEST_UMGR_HOME_DIR}" \
    "${WMUI_TEST_UMGR_BOOTSTRAP_BIN}" \
    "${TEST_USE_LATEST_PRODUCTS_LIST}"

  local l_result=$?

  if [ ${l_result} -eq 0 ]; then
    pu_log_i "Test|ZipImages Successfully generated all zip files"
  else
    pu_log_e "Test|ZipImages Failed to generate zip files, error code: ${l_result}"
  fi

  return ${l_result}
}

_make_images || exit $?
