#!/bin/sh

# This script sets up the API Gateway installation with CDS on PostgreSQL

# shellcheck disable=SC3043

# Validate WMUI_HOME
# shellcheck disable=SC2153
if [ ! -d "${WMUI_HOME}" ]; then
    echo "WMUI_HOME variable MUST point to an existing local folder! Current value is ${WMUI_HOME}"
    exit 1
fi

## 01 Prerequisite libraries
  # shellcheck source=../../../../../2l-posix-shell-utils/code/1.init.sh
  . "${PU_HOME}/code/1.init.sh"

  # shellcheck source=../../../../../2l-posix-shell-utils/code/5.network.sh
  . "${PU_HOME}/code/5.network.sh"

  # shellcheck source=../../../../../2l-posix-shell-utils/code/7.data.sh
  . "${PU_HOME}/code/7.data.sh"

  # shellcheck source=../../../../01-scripts/wmui-functions.sh
  . "${WMUI_HOME}/01-scripts/wmui-functions.sh"

## 02 Wait for database to be available
    pu_log_i "[test-404-agw/containerEntrypoint] Waiting for database to be available..."
    while ! pu_port_is_reachable "${WMUI_TEST_DB_HOSTNAME}" "${WMUI_TEST_DB_PORT}"; do
        pu_log_i "[test-404-agw/containerEntrypoint] Waiting for the database to come up, sleeping 5..."
        sleep 5
    done
    sleep 5 # allow some time to the DB in any case...
    pu_log_i "[test-404-agw/containerEntrypoint] Database is available!"

## 03 Bootstrap UMGR if not already present
    # Parameters - wmui_bootstrap_umgr
    # $1 - Update Manager Bootstrap file
    # $2 - Fixes image file, mandatory for offline mode
    # $3 - OPTIONAL Where to install (webMethods Update Manager Home), default ${__wmui_default_umgr_home}
    if ! wmui_bootstrap_umgr \
            "${WMUI_TEST_UMGR_BOOTSTRAP_BIN}" \
            "${WMUI_TEST_FIXES_IMAGE_FILE}" \
            "${WMUI_TEST_UMGR_HOME_DIR}" ; then
      pu_log_e "[test-404-agw/containerEntrypoint] Cannot bootstrap update manager, cannot continue (code $?)!"
      exit 2
    fi

## 04 Install API Gateway if not already present
  # Apply setup template if not present
  if [ ! -f "${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/bin/server.sh" ]; then
    pu_log_i "[test-404-agw/containerEntrypoint] API Gateway is not present, setting up ..."
    # Parameters
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
            "${WMUI_TEST_FIXES_IMAGE_FILE}" \
            "${WMUI_TEST_UMGR_HOME_DIR}" ; then
      pu_log_e "[test-404-agw/containerEntrypoint] Failed to setup products and fixes from template"
      exit 3
    fi
  else
    pu_log_i "[test-404-agw/containerEntrypoint] API Gateway installation found, skipping setup."
  fi

## 05 Startup server
  cd "${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/bin" || exit 4
  nohup ./server.sh &
  __agw_pid=$!

  pu_log_i "[test-404-agw/containerEntrypoint] =================================================="
  pu_log_i "[test-404-agw/containerEntrypoint] API Gateway with CDS Test Harness"
  pu_log_i "[test-404-agw/containerEntrypoint] =================================================="
  pu_log_i "[test-404-agw/containerEntrypoint] Integration Server Admin: http://host.docker.internal:${WMUI_TEST_PORT_PREFIX}55"
  pu_log_i "[test-404-agw/containerEntrypoint] API Gateway HTTP: http://host.docker.internal:${WMUI_TEST_PORT_PREFIX}72"
  pu_log_i "[test-404-agw/containerEntrypoint] API Gateway HTTPS: https://host.docker.internal:${WMUI_TEST_PORT_PREFIX}73"
  pu_log_i "[test-404-agw/containerEntrypoint] Database Admin (Adminer): http://host.docker.internal:${WMUI_TEST_PORT_PREFIX}80"
  pu_log_i "[test-404-agw/containerEntrypoint] =================================================="
  pu_log_i "[test-404-agw/containerEntrypoint] Database: ${WMUI_TEST_DB_HOSTNAME}:${WMUI_TEST_DB_PORT}/${WMUI_TEST_DB_NAME}"
  pu_log_i "[test-404-agw/containerEntrypoint] User: ${WMUI_WM_DB_USER_NAME}"
  pu_log_i "[test-404-agw/containerEntrypoint] =================================================="

  wait ${__agw_pid}

echo "Forced sleep infinity for dev purpose"
sleep infinity

# Made with Bob
