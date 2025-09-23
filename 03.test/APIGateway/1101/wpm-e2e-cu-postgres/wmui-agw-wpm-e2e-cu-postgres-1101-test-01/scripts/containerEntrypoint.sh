#!/bin/sh

# shellcheck source-path=SCRIPTDIR/../../../../../../
# shellcheck disable=SC2153,SC2046,SC3043

# This scripts sets up the local installation with API Gateway and CDS on PostgreSQL
export WMUI_TEST_HARNESS_FOLDER="03.test/APIGateway/1101/wpm-e2e-cu-postgres/wmui-agw-wpm-e2e-cu-postgres-1101-test-01"
export lLOG_PREFIX="$WMUI_TEST_HARNESS_FOLDER/containerEntrypoint.sh - "

if [ ! -d "${WMUI_HOME}" ]; then
  echo "[$lLOG_PREFIX] - FATAL - WMUI_HOME variable MUST point to an existing local folder! Current value is ${WMUI_HOME}"
  exit 1
fi

# Source framework functions
. "${WMUI_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${WMUI_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

checkEnvVariables() {

  if [ -z "${WMUI_INSTALL_INSTALL_DIR+x}" ]; then
    logE "[$lLOG_PREFIX:checkEnvVariables()] - Variable WMUI_INSTALL_INSTALL_DIR was not set!"
    return 13
  fi

  if [ ! -d "${WMUI_INSTALL_INSTALL_DIR}" ]; then
    logE "[$lLOG_PREFIX:checkEnvVariables()] - Installation folder does not exist, but for this test it must be a mounted volume: ${WMUI_INSTALL_INSTALL_DIR}"
    return 14
  fi

  if [ ! -f "${WMUI_INSTALL_INSTALLER_BIN_MOUNT_POINT}" ]; then
    logE "[$lLOG_PREFIX:checkEnvVariables()] - ${WMUI_INSTALL_INSTALLER_BIN_MOUNT_POINT} is not a file, cannot continue"
    return 15
  fi

  if [ ! -f "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN_MOUNT_POINT}" ]; then
    logE "[$lLOG_PREFIX:checkEnvVariables()] - ${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN_MOUNT_POINT} is not a file, cannot continue"
    return 16
  fi
}

checkEnvVariables || exit $?

setupPrerequisites() {
  logI "[$lLOG_PREFIX:setupPrerequisites()] - Making installer binaries executable..."

  mkdir -p "${WMUI_WORK_DIR}"
  
  cp "${WMUI_INSTALL_INSTALLER_BIN_MOUNT_POINT}" "${WMUI_INSTALL_INSTALLER_BIN}" || exit 21
  chmod u+x "${WMUI_INSTALL_INSTALLER_BIN}" || exit 22

  cp "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN_MOUNT_POINT}" "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}" || exit 23
  chmod u+x "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}" || exit 24

  # Other prerequisites can be added here as needed
}

setupAPIGateway() {
  logI "[$lLOG_PREFIX:setupAPIGateway()] - Checking if API Gateway is already installed..."
  
  # Check if API Gateway is already installed
  if [ ! -f "${WMUI_INSTALL_INSTALL_DIR}/IntegrationServer/bin/startup.sh" ]; then
    logI "[$lLOG_PREFIX:setupAPIGateway()] - API Gateway is not present, setting up..."
    
    # Wait for database to be available
    logI "[$lLOG_PREFIX:setupAPIGateway()] - Waiting for database to be available..."
    while ! portIsReachable2 "${WMUI_DBSERVER_HOSTNAME}" "${WMUI_DBSERVER_PORT}"; do
        logI "[$lLOG_PREFIX:setupAPIGateway()] - Waiting for the database to come up, sleeping 5..."
        sleep 5
        # TODO: add a maximum retry number
    done
    sleep 5 # allow some time to the DB in any case...
       
    # Apply the setup template for API Gateway with PostgreSQL CDS
    applySetupTemplate "APIGateway/1101/wpm-e2e-cu-postgres" || exit 31
  else
    logI "[$lLOG_PREFIX:setupAPIGateway()] - API Gateway installation found, skipping setup."
  fi
}

startAPIGateway() {
  logI "[$lLOG_PREFIX:startAPIGateway()] - Starting API Gateway..."
  
  # Start Integration Server / API Gateway
  "${WMUI_INSTALL_INSTALL_DIR}/IntegrationServer/bin/startup.sh" &
  
  # Wait for API Gateway to be ready
  local retries=0
  local max_retries=200
  while [ $retries -lt $max_retries ]; do
    if curl --write-out 'HTTP %{http_code}' --fail --silent --output /dev/null http://localhost:5555/rest/apigateway/health 2>/dev/null; then
      logI "[$lLOG_PREFIX:startAPIGateway()] - API Gateway is ready!"
      break
    fi
    logI "[$lLOG_PREFIX:startAPIGateway()] - Waiting for API Gateway to start... (attempt $((retries + 1))/$max_retries)"
    sleep 10
    retries=$((retries + 1))
  done
  
  if [ $retries -eq $max_retries ]; then
    logE "[$lLOG_PREFIX:startAPIGateway()] - API Gateway failed to start within expected time!"
    return 32
  fi
}

showAccessInfo() {
  logI "[$lLOG_PREFIX:showAccessInfo()] - ==================================================="
  logI "[$lLOG_PREFIX:showAccessInfo()] - API Gateway with CDS on PostgreSQL Test Harness"
  logI "[$lLOG_PREFIX:showAccessInfo()] - ==================================================="
  logI "[$lLOG_PREFIX:showAccessInfo()] - API Gateway Admin UI: http://host.docker.internal:${H_WMUI_PORT_PREFIX}55"
  logI "[$lLOG_PREFIX:showAccessInfo()] - API Gateway REST Port: http://host.docker.internal:${H_WMUI_PORT_PREFIX}72"
  logI "[$lLOG_PREFIX:showAccessInfo()] - API Gateway HTTPS Port: https://host.docker.internal:${H_WMUI_PORT_PREFIX}73"
  logI "[$lLOG_PREFIX:showAccessInfo()] - Database Admin (Adminer): http://host.docker.internal:${H_WMUI_PORT_PREFIX}80"
  logI "[$lLOG_PREFIX:showAccessInfo()] - Elasticsearch: http://host.docker.internal:${H_WMUI_PORT_PREFIX}20"
  logI "[$lLOG_PREFIX:showAccessInfo()] - Elasticvue: http://host.docker.internal:${H_WMUI_PORT_PREFIX}81"
  logI "[$lLOG_PREFIX:showAccessInfo()] - Kibana: http://host.docker.internal:${H_WMUI_PORT_PREFIX}56"
  logI "[$lLOG_PREFIX:showAccessInfo()] - ==================================================="
  logI "[$lLOG_PREFIX:showAccessInfo()] - Database connection details:"
  logI "[$lLOG_PREFIX:showAccessInfo()] - Host: ${WMUI_DBSERVER_HOSTNAME}"
  logI "[$lLOG_PREFIX:showAccessInfo()] - Database: ${WMUI_DBSERVER_DATABASE_NAME}"
  logI "[$lLOG_PREFIX:showAccessInfo()] - User: ${WMUI_DBSERVER_USER_NAME}"
  logI "[$lLOG_PREFIX:showAccessInfo()] - Password: ${WMUI_DBSERVER_PASSWORD}"
  logI "[$lLOG_PREFIX:showAccessInfo()] - ==================================================="
  logI "[$lLOG_PREFIX:showAccessInfo()] - Issue 'docker-compose down -t 20' to close this project!"
  logI "[$lLOG_PREFIX:showAccessInfo()] - ==================================================="
}

# Main execution flow
main() {
  logI "[$lLOG_PREFIX:main()] - Starting API Gateway with CDS setup..."
  
  setupPrerequisites || exit $?
  setupAPIGateway || exit $?
  startAPIGateway || exit $?
  showAccessInfo
  
  # Keep container running
  tail -f /dev/null
}

main "$@"