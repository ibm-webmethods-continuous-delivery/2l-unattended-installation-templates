#!/bin/sh

# MSR Container Entrypoint for test-499
# This script sets up and starts MicroServices Runtime with TaskEngine support

# shellcheck disable=SC3043

# Validate WMUI_HOME
# shellcheck disable=SC2153
if [ ! -d "${WMUI_HOME}" ]; then
  echo "WMUI_HOME variable MUST point to an existing local folder! Current value is ${WMUI_HOME}"
  exit 1
fi

## 01 Source framework libraries
  # shellcheck source=../../../../../../2l-posix-shell-utils/code/1.init.sh
  . "${PU_HOME}/code/1.init.sh"

  # shellcheck source=../../../../../../2l-posix-shell-utils/code/5.network.sh
  . "${PU_HOME}/code/5.network.sh"

  # shellcheck source=../../../../../../2l-posix-shell-utils/code/7.data.sh
  . "${PU_HOME}/code/7.data.sh"

  # shellcheck source=../../../../../01-scripts/wmui-functions.sh
  . "${WMUI_HOME}/01-scripts/wmui-functions.sh"

## 02 Wait for database to be available
  pu_log_i "[test-499-msr] Waiting for database to be available..."
  if ! pu_wait_for_port "${WMUI_TEST_DB_HOSTNAME}" "${WMUI_TEST_DB_PORT}" 60 5; then
      pu_log_e "[test-499-msr] Database did not become available after waiting"
      exit 1
  fi

## 03 Install MSR if not present
  if [ ! -f "${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/bin/server.sh" ]; then
    pu_log_i "[test-499-msr] MSR is not present, setting up..."

    ## 03.1 Bootstrap Update Manager if not already present
      # Parameters - wmui_bootstrap_umgr
      # $1 - Update Manager Bootstrap file
      # $2 - Fixes image file, mandatory for offline mode
      # $3 - OPTIONAL Where to install (webMethods Update Manager Home), default ${__wmui_default_umgr_home}
      if ! wmui_bootstrap_umgr \
              "${WMUI_TEST_UMGR_BOOTSTRAP_BIN}" \
              "${WMUI_TEST_MSR_FIXES_IMAGE_FILE}" \
              "${WMUI_TEST_UMGR_HOME_DIR}" ; then
        pu_log_e "[test-499-msr] Cannot bootstrap update manager, cannot continue (code $?)"
        exit 2
      fi

    ## 03.2 Install MSR
      # Parameters - wmui_install_template_products
      # $1 - Template id
      # $2 - OPTIONAL: use latest versions (default passthrough to wmui_install_template_products)
      # $3 - OPTIONAL: Installer binary location, default passthrough to wmui_install_template_products
    # Parameters - wmui_setup_products_and_fixes_from_template
    # $1 - Template id
    # $2 - OPTIONAL: use latest versions (default passthrough to wmui_install_template_products)
    # $3 - OPTIONAL: Installer binary location, default passthrough to wmui_install_template_products
    # $4 - OPTIONAL: debugLevel for installer, default verbose
    # $5 - OPTIONAL: fixes file image. Absent means skip patching
    # $6 - OPTIONAL: Update manager home, default ${__wmui_default_umgr_home}
    if ! wmui_setup_products_and_fixes_from_template \
            "msr/1101/sel-25924" \
            "" \
            "${WMUI_TEST_INSTALLER_BIN}" \
            "" \
            "${WMUI_TEST_MSR_FIXES_IMAGE_FILE}" \
            "${WMUI_TEST_UMGR_HOME_DIR}" ; then
      pu_log_e "[test-499-msr] Failed to setup products and fixes from template"
      exit 3
    fi
  else
    pu_log_i "[test-499-msr] MSR installation found, skipping setup"
  fi

## 04 Refresh packages
  # Note: cannot mount directly the packages because this is not an MSR image, but an installation

  if [ -f "${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/bin/.lock" ]; then
    pu_log_w "[test-499-msr] IS Lock file present, shutdown was probably forced!"
    rm -rf  "${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/bin/.lock"
  fi

  if [ "${WMUI_TEST_ESB_COPY_PUB_SUB_MON_PACKAGES}" = "true" ]; then
    pu_log_i "[test-499-msr] refreshPubSubMonPackages()] - Refreshing packages from the publish subscribe with monitoring service development template..."
    _l__src_packages_home="${WMUI_TEST_PUB_SUB_MON_01_REPO_MOUNT_POINT}/01.code/is-packages"
    if [ ! -d "${_l__src_packages_home}" ]; then
      pu_log_e "[test-499-msr] refreshPubSubMonPackages()] - Folder does not exist: ${_l__src_packages_home}!"
      pu_log_e "[test-499-msr] refreshPubSubMonPackages()] - Is the repository 5s-pub-sub-with-mon-01 correctly mounted?"
      exit 6
    fi
    _l__packages_home="${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/packages"
    rm -\
      "{_l__packages_home}/Canonicals" \
      "{_l__packages_home}/CommonUtils" \
      "{_l__packages_home}/PublisherExample" \
      "{_l__packages_home}/ServiceMockup" \
      "{_l__packages_home}/SubscriberExample"

    ln -s "${_l__src_packages_home}"/Canonicals "${_l__packages_home}"/Canonicals
    cp -r "${_l__src_packages_home}"/CommonUtils "${_l__packages_home}"/CommonUtils
    cp -r "${_l__src_packages_home}"/PublisherExample "${_l__packages_home}"/PublisherExample
    cp -r "${_l__src_packages_home}"/ServiceMockup "${_l__packages_home}"/ServiceMockup
    cp -r "${_l__src_packages_home}"/SubscriberExample "${_l__packages_home}"/SubscriberExample
  fi

## 05 Start Integration Server

  cd "${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/bin" || exit 4
  nohup ./server.sh &
  __service_pid=$!

## 06 Display access information
  pu_log_i "[test-499-msr] =================================================="
  pu_log_i "[test-499-msr] MSR Test Harness"
  pu_log_i "[test-499-msr] =================================================="
  pu_log_i "[test-499-msr] Integration Server Admin: http://host.docker.internal:${WMUI_TEST_PORT_PREFIX}65"
  pu_log_i "[test-499-msr] Integration Server HTTPS: https://host.docker.internal:${WMUI_TEST_PORT_PREFIX}63"
  pu_log_i "[test-499-msr] Diagnostic Port: http://host.docker.internal:${WMUI_TEST_PORT_PREFIX}69"
  pu_log_i "[test-499-msr] =================================================="
  pu_log_i "[test-499-msr] Database: ${WMUI_TEST_DB_HOSTNAME}:${WMUI_TEST_DB_PORT}/${WMUI_WM_DB_NAME}"
  pu_log_i "[test-499-msr] User: ${WMUI_WM_DB_USER_NAME}"
  pu_log_i "[test-499-msr] =================================================="

wait ${__service_pid}

# echo "Forced sleep infinity for dev purpose"
# sleep infinity

# Made with Bob