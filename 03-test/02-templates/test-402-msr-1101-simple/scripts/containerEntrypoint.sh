#!/bin/sh

# This script sets up the DBC installation and creates database components

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

## 02 Bootstrap UMGR if not already present
    # Parameters - wmui_bootstrap_umgr
    # $1 - Update Manager Bootstrap file
    # $2 - Fixes image file, mandatory for offline mode
    # $3 - OPTIONAL Where to install (webMethods Update Manager Home), default ${__wmui_default_umgr_home}
    if ! wmui_bootstrap_umgr \
            "${WMUI_TEST_UMGR_BOOTSTRAP_BIN}" \
            "${WMUI_TEST_FIXES_IMAGE_FILE}" \
            "${WMUI_TEST_UMGR_HOME_DIR}" ; then
      pu_log_e "Cannot bootstrap update manager, cannot continue (code $?)!"
      exit 2
    fi
## 03 Install dbc if not already present
  # Apply setup template if not present
  if [ ! -f "${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/bin/server.sh" ]; then
    pu_log_i "MSR is not present, setting up ..."
    # Parameters
    # $1 - Template id
    # $2 - OPTIONAL: use latest versions (default passthrough to wmui_install_template_products)
    # $3 - OPTIONAL: Installer binary location, default passthrough to wmui_install_template_products
    # $4 - OPTIONAL: debugLevel for installer, default verbose
    # $5 - OPTIONAL: fixes file image. Absent means skip patching
    # $6 - OPTIONAL: Update manager home, default ${__wmui_default_umgr_home}
    if ! wmui_setup_products_and_fixes_from_template \
            "msr/1101/simple" \
            "" \
            "${WMUI_TEST_INSTALLER_BIN}" \
            "" \
            "${WMUI_TEST_FIXES_IMAGE_FILE}" \
            "${WMUI_TEST_UMGR_HOME_DIR}" ; then
      pu_log_e "Failed to setup products and fixes from template"
      exit 3
    fi
  fi

## 04 Startup server
  # Map test harness variables to post-setup template variables
  # This construct is done on purpose to showcase how post setup templates receive variables
  # WIP
  cd "${WMUI_WMSCRIPT_InstallDir}/IntegrationServer/bin" || exit 3
  nohup ./server.sh &
  __msr_pid=$!
  pu_log_i "Go to http://host.docker.internal:${WMUI_TEST_PORT_PREFIX}55 and check the database content! Look at the .env file for details!"
  wait ${__msr_pid}

echo "Forced sleep infinity for dev purpose"
sleep infinity

