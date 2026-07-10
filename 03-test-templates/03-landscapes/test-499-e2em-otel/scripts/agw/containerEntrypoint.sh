#!/bin/sh

# API Gateway Container Entrypoint for test-499
# This script sets up and starts API Gateway with CDS and OpenTelemetry support

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
  pu_log_i "[test-499-agw] Waiting for database to be available..."
  if ! pu_wait_for_port "${WMUI_TEST_DB_HOSTNAME}" "${WMUI_TEST_DB_PORT}" 60 5; then
      pu_log_e "[test-499-agw] Database did not become available after waiting"
      exit 1
  fi


## 03 Install API Gateway if not present
  if [ ! -f "${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/bin/server.sh" ]; then

    pu_log_i "[test-499-agw] API Gateway is not present, setting up..."
    ## 03.1 Bootstrap Update Manager if not already present
      # Parameters - wmui_bootstrap_umgr
      # $1 - Update Manager Bootstrap file
      # $2 - Fixes image file, mandatory for offline mode
      # $3 - OPTIONAL Where to install (webMethods Update Manager Home), default ${__wmui_default_umgr_home}
      if ! wmui_bootstrap_umgr \
              "${WMUI_TEST_UMGR_BOOTSTRAP_BIN}" \
              "${WMUI_TEST_AGW_FIXES_IMAGE_FILE}" \
              "${WMUI_TEST_UMGR_HOME_DIR}" ; then
        pu_log_e "[test-499-agw] Cannot bootstrap update manager, cannot continue (code $?)"
        exit 2
      fi


    ## 03.2 Setting up api gateway
    # Parameters - wmui_setup_products_and_fixes_from_template
    # $1 - Template id
    # $2 - OPTIONAL: use latest versions (default passthrough to wmui_install_template_products)
    # $3 - OPTIONAL: Installer binary location, default passthrough to wmui_install_template_products
    # $4 - OPTIONAL: debugLevel for installer, default verbose
    # $5 - OPTIONAL: fixes file image. Absent means skip patching
    # $6 - OPTIONAL: Update manager home, default ${__wmui_default_umgr_home}
    if ! wmui_setup_products_and_fixes_from_template \
            "agw/1101/cds-e2e" \
            "" \
            "${WMUI_TEST_INSTALLER_BIN}" \
            "" \
            "${WMUI_TEST_AGW_FIXES_IMAGE_FILE}" \
            "${WMUI_TEST_UMGR_HOME_DIR}" ; then
      pu_log_e "[test-499-agw] Failed to setup products and fixes from template"
      exit 3
    fi
  else
    pu_log_i "[test-499-agw] API Gateway installation found, skipping setup"
  fi

## 05 Start Integration Server

  if [ -f "${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/bin/.lock" ]; then
    pu_log_w "[test-499-msr] IS Lock file present, shutdown was probably forced!"
    rm -rf  "${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/bin/.lock"
  fi

  cd "${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/bin" || exit 4
  nohup ./server.sh &
  __service_pid=$!

## 06 Display access information
  pu_log_i "[test-499-agw] =================================================="
  pu_log_i "[test-499-agw] API Gateway with CDS Test Harness"
  pu_log_i "[test-499-agw] =================================================="
  pu_log_i "[test-499-agw] Integration Server Admin: http://host.docker.internal:${WMUI_TEST_PORT_PREFIX}55"
  pu_log_i "[test-499-agw] API Gateway HTTP: http://host.docker.internal:${WMUI_TEST_PORT_PREFIX}72"
  pu_log_i "[test-499-agw] API Gateway HTTPS: https://host.docker.internal:${WMUI_TEST_PORT_PREFIX}73"
  pu_log_i "[test-499-agw] Elasticsearch: http://host.docker.internal:${WMUI_TEST_PORT_PREFIX}20"
  pu_log_i "[test-499-agw] Kibana: http://host.docker.internal:${WMUI_TEST_PORT_PREFIX}56"
  pu_log_i "[test-499-agw] Elasticvue: http://host.docker.internal:${WMUI_TEST_PORT_PREFIX}80"
  pu_log_i "[test-499-agw] =================================================="
  pu_log_i "[test-499-agw] Database: ${WMUI_TEST_DB_HOSTNAME}:${WMUI_TEST_DB_PORT}/${WMUI_WM_DB_NAME}"
  pu_log_i "[test-499-agw] User: ${WMUI_WM_DB_USER_NAME}"
  pu_log_i "[test-499-agw] =================================================="


## TODO 06 add the API if it does not exists yet. Swagger file in the same folder

wait ${__service_pid}

# echo "Forced sleep infinity for dev purpose"
# sleep infinity

# Made with Bob