#!/bin/sh

# shellcheck source-path=SCRIPTDIR/../../../../../../
# shellcheck disable=SC2153,SC2046,SC3043

# This script initializes the database with webMethods schemas for API Gateway CDS
export WMUI_TEST_HARNESS_FOLDER="03.test/APIGateway/1101/wpm-e2e-cu-postgres/wmui-agw-wpm-e2e-cu-postgres-1101-test-01"
export lLOG_PREFIX="$WMUI_TEST_HARNESS_FOLDER/dbInitEntrypoint.sh - "

if [ ! -d "${WMUI_HOME}" ]; then
  echo "[$lLOG_PREFIX] - FATAL - WMUI_HOME variable MUST point to an existing local folder! Current value is ${WMUI_HOME}"
  exit 1
fi

# Source framework functions
. "${WMUI_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${WMUI_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

# our configuration takes precedence in front of framework defaults, set it before sourcing the framework functions
if [ ! -d "${WMUI_TEST_LOCAL_SCRIPTS_DIR}" ]; then
    logE "[$lLOG_PREFIX] - Scripts folder not found: ${WMUI_TEST_LOCAL_SCRIPTS_DIR}"
    exit 2
fi

setupPrerequisites() {
  logI "[$lLOG_PREFIX:setupPrerequisites()] - Making installer binaries executable..."
  
  mkdir -p "${WMUI_WORK_DIR}"

  cp "${WMUI_INSTALL_INSTALLER_BIN_MOUNT_POINT}" "${WMUI_INSTALL_INSTALLER_BIN}" || exit 21
  chmod u+x "${WMUI_INSTALL_INSTALLER_BIN}" || exit 22

  cp "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN_MOUNT_POINT}" "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}" || exit 23
  chmod u+x "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}" || exit 24
}

installDBC() {
  logI "[$lLOG_PREFIX:installDBC()] - Checking if Database Configurator is already installed..."
  
  # Check if DBC is already installed
  if [ ! -f "${WMUI_INSTALL_INSTALL_DIR}/common/db/bin/dbConfigurator.sh" ]; then
    logI "[$lLOG_PREFIX:installDBC()] - Database configurator is not present, setting up ..."
    # Install DBC tools
    applySetupTemplate "DBC/1101/full" || exit 31
  else
    logI "[$lLOG_PREFIX:installDBC()] - Database configurator already installed, skipping setup."
  fi
}

initializeDatabase() {
  logI "[$lLOG_PREFIX:initializeDatabase()] - Initializing database schemas..."
  
  # Wait for database to be available
  logI "[$lLOG_PREFIX:initializeDatabase()] - Waiting for database to be available..."
  while ! portIsReachable2 "${WMUI_DBSERVER_HOSTNAME}" "${WMUI_DBSERVER_PORT}"; do
    logI "[$lLOG_PREFIX:initializeDatabase()] - Waiting for the database to come up, sleeping 5..."
    sleep 5
  done
  sleep 5 # allow some time to the DB in any case...

  logI "[$lLOG_PREFIX:initializeDatabase()] - Creating database schemas for webMethods components..."
  
  # Create database components using the post-setup template
  # This template includes its own checks for existing schemas
  applyPostSetupTemplate "DBC/1101/postgresql-create" || exit 32
  
  logI "[$lLOG_PREFIX:initializeDatabase()] - Database initialization completed successfully!"
}

showInitInfo() {
  logI "[$lLOG_PREFIX:showInitInfo()] - ==================================================="
  logI "[$lLOG_PREFIX:showInitInfo()] - Database Initialization Complete"
  logI "[$lLOG_PREFIX:showInitInfo()] - ==================================================="
  logI "[$lLOG_PREFIX:showInitInfo()] - Database Admin (Adminer): http://host.docker.internal:${H_WMUI_PORT_PREFIX}80"
  logI "[$lLOG_PREFIX:showInitInfo()] - Database (PostgreSQL): host.docker.internal:${H_WMUI_PORT_PREFIX}32"
  logI "[$lLOG_PREFIX:showInitInfo()] - ==================================================="
  logI "[$lLOG_PREFIX:showInitInfo()] - Database connection details:"
  logI "[$lLOG_PREFIX:showInitInfo()] - Host: ${WMUI_DBSERVER_HOSTNAME}"
  logI "[$lLOG_PREFIX:showInitInfo()] - Database: ${WMUI_DBSERVER_DATABASE_NAME}"
  logI "[$lLOG_PREFIX:showInitInfo()] - User: ${WMUI_DBSERVER_USER_NAME}"
  logI "[$lLOG_PREFIX:showInitInfo()] - Password: ${WMUI_DBSERVER_PASSWORD}"
  logI "[$lLOG_PREFIX:showInitInfo()] - ==================================================="
  logI "[$lLOG_PREFIX:showInitInfo()] - Next steps:"
  logI "[$lLOG_PREFIX:showInitInfo()] - 1. Stop this initialization: docker-compose -f docker-compose-init.yml down"
  logI "[$lLOG_PREFIX:showInitInfo()] - 2. Start main application: docker-compose up -d"
  logI "[$lLOG_PREFIX:showInitInfo()] - ==================================================="
}

# Main execution flow
main() {
  logI "[$lLOG_PREFIX:main()] - Starting database initialization for API Gateway CDS..."
  
  local exit_code=0
  
  setupPrerequisites || exit_code=$?
  if [ $exit_code -ne 0 ]; then
    logE "[$lLOG_PREFIX:main()] - setupPrerequisites failed with exit code $exit_code"
  else
    installDBC || exit_code=$?
    if [ $exit_code -ne 0 ]; then
      logE "[$lLOG_PREFIX:main()] - installDBC failed with exit code $exit_code"
    else
      initializeDatabase || exit_code=$?
      if [ $exit_code -ne 0 ]; then
        logE "[$lLOG_PREFIX:main()] - initializeDatabase failed with exit code $exit_code"
      else
        showInitInfo
        logI "[$lLOG_PREFIX:main()] - Database initialization completed successfully!"
      fi
    fi
  fi
  
  # Only stay running in debug mode, otherwise always exit for batch operations
  if [ "${WMUI_DEBUG_ON}" = "1" ]; then
    if [ $exit_code -eq 0 ]; then
      logI "[$lLOG_PREFIX:main()] - Database initialization complete. Debug mode enabled - keeping container running."
    else
      logE "[$lLOG_PREFIX:main()] - Database initialization failed (exit code: $exit_code). Debug mode enabled - keeping container running for troubleshooting."
    fi
    logI "[$lLOG_PREFIX:main()] - Use 'docker-compose -f docker-compose-init.yml down' to stop this container."
    tail -f /dev/null
  else
    if [ $exit_code -eq 0 ]; then
      logI "[$lLOG_PREFIX:main()] - Database initialization complete. Container will exit now."
    else
      logE "[$lLOG_PREFIX:main()] - Database initialization failed. Container will exit with code $exit_code."
    fi
    exit $exit_code
  fi
}

main "$@"