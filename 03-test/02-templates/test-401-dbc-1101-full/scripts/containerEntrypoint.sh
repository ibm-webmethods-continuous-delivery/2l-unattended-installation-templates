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
  if [ ! -f "${WMUI_WMSCRIPT_InstallDir}/common/db/bin/dbConfigurator.sh" ]; then
    pu_log_i "Database configurator is not present, setting up ..."
    # Parameters
    # $1 - Template id
    # $2 - OPTIONAL: use latest versions (default passthrough to wmui_install_template_products)
    # $3 - OPTIONAL: Installer binary location, default passthrough to wmui_install_template_products
    # $4 - OPTIONAL: debugLevel for installer, default verbose
    # $5 - OPTIONAL: fixes file image. Absent means skip patching
    # $6 - OPTIONAL: Update manager home, default ${__wmui_default_umgr_home}
    if ! wmui_setup_products_and_fixes_from_template \
            "dbc/1101/full" \
            "" \
            "${WMUI_TEST_INSTALLER_BIN}" \
            "" \
            "${WMUI_TEST_FIXES_IMAGE_FILE}" \
            "${WMUI_TEST_UMGR_HOME_DIR}" ; then
      pu_log_e "Failed to setup products and fixes from template"
      exit 3
    fi
  fi

## 04 Create the database component
  # Map test harness variables to post-setup template variables
  # This construct is done on purpose to showcase how post setup templates receive variables
  export WMUI_PST_DB_SERVER_HOSTNAME="${WMUI_TEST_DB_SERVER_HOSTNAME}"
  export WMUI_PST_DB_SERVER_PORT="${WMUI_TEST_DB_SERVER_PORT}"
  export WMUI_PST_DB_SERVER_DATABASE_NAME="${WMUI_TEST_DB_SERVER_DATABASE_NAME}"
  export WMUI_PST_DB_SERVER_USER_NAME="${WMUI_TEST_DB_SERVER_USER_NAME}"
  export WMUI_PST_DB_SERVER_PASSWORD="${WMUI_TEST_DB_SERVER_PASSWORD}"
  export WMUI_PST_DBC_COMPONENT_NAME="${WMUI_TEST_DBC_COMPONENT_NAME}"
  export WMUI_PST_DBC_COMPONENT_VERSION="${WMUI_TEST_DBC_COMPONENT_VERSION}"

  if ! wmui_apply_post_setup_template dbc/1101/postgresql-create ; then
    pu_log_e "Failed to apply post setup template"
    exit 4
  fi

pu_log_i "Go to http://host.docker.internal:${WMUI_TEST_PORT_PREFIX}80 and check the database content! Look at the .env file for details!"
