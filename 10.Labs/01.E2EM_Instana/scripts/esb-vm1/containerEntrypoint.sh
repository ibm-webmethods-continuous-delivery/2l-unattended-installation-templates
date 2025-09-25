#!/bin/sh

# shellcheck source-path=SCRIPTDIR/../../../../
# shellcheck disable=SC2153,SC2046,SC3043

# This scripts sets up the local installation with MSR and CDS on PostgreSQL
export WMUI_TEST_HARNESS_ID="E2EM_Instana_Lab_01"

export lLOG_PREFIX="$WMUI_TEST_HARNESS_ID/containerEntrypoint.sh - "

if [ ! -d "${WMUI_HOME}" ]; then
  echo "[${lLOG_PREFIX}] - FATAL - WMUI_HOME variable MUST point to an existing local folder! Current value is ${WMUI_HOME}"
  exit 1
fi

# Source framework functions
. "${WMUI_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${WMUI_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

checkEnvVariables() {

  __check_env_err_count=0

  if [ -z "${WMUI_INSTALL_INSTALL_DIR+x}" ]; then
    logE "[${lLOG_PREFIX}:checkEnvVariables()] - Variable WMUI_INSTALL_INSTALL_DIR was not set!"
    __check_env_err_count=$((__check_env_err_count + 1))
  fi

  if [ ! -d "${WMUI_INSTALL_INSTALL_DIR}" ]; then
    logE "[${lLOG_PREFIX}:checkEnvVariables()] - Installation folder does not exist, but for this test it must be a mounted volume: ${WMUI_INSTALL_INSTALL_DIR}"
    __check_env_err_count=$((__check_env_err_count + 1))
  fi

  if [ ! -f "${WMUI_INSTALL_INSTALLER_BIN_MOUNT_POINT}" ]; then
    logE "[${lLOG_PREFIX}:checkEnvVariables()] - ${WMUI_INSTALL_INSTALLER_BIN_MOUNT_POINT} is not a file, cannot continue"
    __check_env_err_count=$((__check_env_err_count + 1))
  fi

  if [ ! -f "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN_MOUNT_POINT}" ]; then
    logE "[${lLOG_PREFIX}:checkEnvVariables()] - ${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN_MOUNT_POINT} is not a file, cannot continue"
    __check_env_err_count=$((__check_env_err_count + 1))
  fi

  if [ "${__check_env_err_count}" -ne 0 ]; then
    logE "[${lLOG_PREFIX}:checkEnvVariables()] - ${__check_env_err_count} errors found"
    unset __check_env_err_count
    return 1
  fi
  unset __check_env_err_count
}

checkEnvVariables || exit $?

setupPrerequisites() {
  logI "[${lLOG_PREFIX}:setupPrerequisites()] - Making installer binaries executable..."

  mkdir -p "${WMUI_WORK_DIR}"
  
  cp "${WMUI_INSTALL_INSTALLER_BIN_MOUNT_POINT}" "${WMUI_INSTALL_INSTALLER_BIN}" || exit 21
  chmod u+x "${WMUI_INSTALL_INSTALLER_BIN}" || exit 22

  cp "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN_MOUNT_POINT}" "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}" || exit 23
  chmod u+x "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}" || exit 24

  # Other prerequisites can be added here as needed
}

onInterrupt(){
	logI "[$lLOG_PREFIX:onInterrupt()] - Interrupted! Shutting down MSR"

	logI "[$lLOG_PREFIX:onInterrupt()] - Shutting down Integration server ..."
    cd "${WMUI_INSTALL_INSTALL_DIR}/IntegrationServer/bin" || exit 111
    ./shutdown.sh

	exit 0 # managed expected exit
}

setupMSR() {
  logI "[${lLOG_PREFIX}:setupMSR()] - Checking if MSR is already installed..."
  
  # Check if MSR is already installed__err_count
  if [ ! -f "${WMUI_INSTALL_INSTALL_DIR}/IntegrationServer/bin/startup.sh" ]; then
    logI "[${lLOG_PREFIX}:setupMSR()] - MSR is not present, setting up..."
    
    # Wait for database to be available
    logI "[${lLOG_PREFIX}:setupMSR()] - Waiting for database to be available -> ${WMUI_LAB10_DBSERVER_HOSTNAME}:${WMUI_LAB10_DBSERVER_PORT}..."
    while ! portIsReachable2 "${WMUI_LAB10_DBSERVER_HOSTNAME}" "${WMUI_LAB10_DBSERVER_PORT}"; do
        logI "[${lLOG_PREFIX}:setupMSR()] - Waiting for the database to come up, sleeping 5..."
        sleep 5
        # TODO: add a maximum retry number
    done
    sleep 5 # allow some time to the DB in any case...
       
    # Apply the setup template for MSR with PostgreSQL CDS
    applySetupTemplate "MSR/1101/selection-20250924" || exit 31

    ## Work around for CDS BUG ?
    ## TODO: Investigate injection variables for unattended setup
    cp -r \
      "${WMUI_INSTALL_INSTALL_DIR}/IntegrationServer/instances/default/config/jdbc/properties" \
      "${WMUI_INSTALL_INSTALL_DIR}/IntegrationServer/config/jdbc/properties"

    ## Set Up E2EM, see https://www.ibm.com/docs/en/wm-end-to-end-monitoring?topic=installer-webmethods-microservices-runtime
    mv \
      "${WMUI_INSTALL_INSTALL_DIR}/E2EMonitoring/agent/plugins/uha-onpremise-is-plugin.jar" \
      "${WMUI_INSTALL_INSTALL_DIR}/IntegrationServer/lib/jars/"

    mv \
      "${WMUI_INSTALL_INSTALL_DIR}/E2EMonitoring/agent/config/e2ecustomlogback.xml" \
      "${WMUI_INSTALL_INSTALL_DIR}/IntegrationServer/"

    {
      echo "JAVA_UHA_OPTS=\"-javaagent:../E2EMonitoring/agent/uha-apm-agent.jar=logging.dir=./logs/ -Xbootclasspath/a:../E2EMonitoring/agent/uha-apm-agent.jar\""
      echo "JAVA_CUSTOM_OPTS=\"${JAVA_CUSTOM_OPTS} ${JAVA_UHA_OPTS}\""
      echo "JAVA_CUSTOM_OPTS=\"${JAVA_CUSTOM_OPTS} -Dlogback.configurationFile=./e2ecustomlogback.xml\""
    } >> "${WMUI_INSTALL_INSTALL_DIR}/IntegrationServer/bin/setenv.sh"

  else
    logI "[${lLOG_PREFIX}:setupMSR()] - MSR installation found, skipping setup."
  fi
}

startMSR() {
  logI "[${lLOG_PREFIX}:startMSR()] - Starting MSR..."
  
  # Start Integration Server / MSR
  #"${WMUI_INSTALL_INSTALL_DIR}/IntegrationServer/bin/startup.sh" &

  cd "${WMUI_INSTALL_INSTALL_DIR}/IntegrationServer/bin" || return 1
  nohup ./server.sh &

  MSR_PID=$!
  
  # Wait for MSR to be ready
  local retries=0
  local max_retries=200
  while [ $retries -lt $max_retries ]; do
    if curl -u "Administrator:manage" --write-out 'HTTP %{http_code}' --fail --silent --output /dev/null http://localhost:5555/invoke/wm.server/ping 2>/dev/null; then
      logI "[${lLOG_PREFIX}:startMSR()] - MSR is ready!"
      break
    fi
    logI "[${lLOG_PREFIX}:startMSR()] - Waiting for MSR to start... (attempt $((retries + 1))/$max_retries)"
    sleep 10
    retries=$((retries + 1))
  done
  
  if [ $retries -eq $max_retries ]; then
    logE "[${lLOG_PREFIX}:startMSR()] - MSR failed to start within expected time!"
    return 32
  fi
}

showAccessInfo() {
  logI "[${lLOG_PREFIX}:showAccessInfo()] - ==================================================="
  logI "[${lLOG_PREFIX}:showAccessInfo()] - Lab 10 - E2E Monitoring with Instana"
  logI "[${lLOG_PREFIX}:showAccessInfo()] - ==================================================="
  logI "[${lLOG_PREFIX}:showAccessInfo()] - MSR Admin UI: http://${WMUI_LAB10_HOST_NAME}:${WMUI_LAB10_PORT_PREFIX}55"
  logI "[${lLOG_PREFIX}:showAccessInfo()] - Database Admin (Adminer): http://${WMUI_LAB10_HOST_NAME}:${WMUI_LAB10_PORT_PREFIX}80"
  logI "[${lLOG_PREFIX}:showAccessInfo()] - ==================================================="
  logI "[${lLOG_PREFIX}:showAccessInfo()] - Database connection details:"
  logI "[${lLOG_PREFIX}:showAccessInfo()] - Host: ${WMUI_DBSERVER_HOSTNAME}"
  logI "[${lLOG_PREFIX}:showAccessInfo()] - Database: ${WMUI_DBSERVER_DATABASE_NAME}"
  logI "[${lLOG_PREFIX}:showAccessInfo()] - User: ${WMUI_DBSERVER_USER_NAME}"
  logI "[${lLOG_PREFIX}:showAccessInfo()] - Password: ${WMUI_DBSERVER_PASSWORD}"
  logI "[${lLOG_PREFIX}:showAccessInfo()] - ==================================================="
  logI "[${lLOG_PREFIX}:showAccessInfo()] - Issue 'docker-compose down -t 80' to close this project!"
  logI "[${lLOG_PREFIX}:showAccessInfo()] - ==================================================="
}

# Main execution flow
main() {
  logI "[${lLOG_PREFIX}:main()] - Starting MSR selection 20250924 setup..."
  
  setupPrerequisites || exit $?

  trap "onInterrupt" INT TERM

  setupMSR || exit $?
  startMSR || exit $?
  showAccessInfo
  
  # Keep container running by waiting on the MSR process
  logI "[${lLOG_PREFIX}:main()] - Waiting on MSR process (PID: ${MSR_PID})..."
  wait "${MSR_PID}"
}

main "$@"