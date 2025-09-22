#!/bin/sh

# shellcheck source-path=SCRIPTDIR/../../../../..
# shellcheck disable=SC2153,SC2046,SC3043

# This scripts sets up the local installation if it doesn't already exist
export WMUI_TEST_HARNESS_FOLDER="03.test/APIGateway/1015/ApiGw-1015-default-test-1"
export lLOG_PREFIX="$WMUI_TEST_HARNESS_FOLDER/containerEntrypoint.sh - "

if [ ! -d "${WMUI_HOME}" ]; then
  echo "[$lLOG_PREFIX] - FATAL - WMUI_HOME variable MUST point to an existing local folder! Current value is ${WMUI_HOME}"
  exit 1
fi

# Source framework functions
. "${WMUI_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${WMUI_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5


# our configuration takes precedence in front of framework defaults, set it before sourcing the framework functions
if [ ! -d "${WMUI_LOCAL_SCRIPTS_HOME}" ]; then
    logE "[$lLOG_PREFIX] - Scripts folder not found: ${WMUI_LOCAL_SCRIPTS_HOME}"
    exit 2
fi

checkEnvVariables() {

  if [ -z "${WMUI_INSTALL_INSTALL_DIR+x}" ]; then
    logE "[$lLOG_PREFIX:checkEnvVariables()] - Variable WMUI_INSTALL_INSTALL_DIR was not set!"
    return 103
  fi

  if [ ! -d "${WMUI_INSTALL_INSTALL_DIR}" ]; then
    logE "[$lLOG_PREFIX:checkEnvVariables()] - Installation folder does not exist, but for this test it must be a mounted volume: ${WMUI_INSTALL_INSTALL_DIR}"
    return 104
  fi

  if [ ! -f "${WMUI_INSTALL_INSTALLER_BIN_MOUNT_POINT}" ]; then
    logE "[$lLOG_PREFIX:checkEnvVariables()] - ${WMUI_INSTALL_INSTALLER_BIN_MOUNT_POINT} is not a file, cannot continue"
    return 105
  fi

  if [ ! -f "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN_MOUNT_POINT}" ]; then
    logE "[$lLOG_PREFIX:checkEnvVariables()] - ${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN_MOUNT_POINT} is not a file, cannot continue"
    return 106
  fi
}

checkEnvVariables || exit $?

mkdir -p "${WMUI_WORK_DIR}"

cp "${WMUI_INSTALL_INSTALLER_BIN_MOUNT_POINT}" "${WMUI_INSTALL_INSTALLER_BIN}"
logI "copy ${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN_MOUNT_POINT} to ${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}"
cp "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN_MOUNT_POINT}" "${WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN}"

logI "Result code $?"

checkSetupTemplateBasicPrerequisites || exit $?

# If the installation is not present, do it now
if [ ! -d "${WMUI_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
  logI "[$lLOG_PREFIX] - Starting up for the first time, setting up ..."

  # Parameters - applySetupTemplate
  # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
  applySetupTemplate "APIGateway/1101/default" || exit 6

  ## Extra step: tell Elasticsearch to accept CORS from elasticvue
  logI "[$lLOG_PREFIX] - Telling Elasticsearch to accept CORS from elasticvue"
  
  echo \
    'http.cors.enabled: true' \
    >> "$WMUI_INSTALL_INSTALL_DIR/InternalDataStore/config/elasticsearch.yml"

  echo \
    'http.cors.allow-origin: "'"http://host.docker.internal:${H_WMUI_PORT_PREFIX}80"'"' \
    >> "$WMUI_INSTALL_INSTALL_DIR/InternalDataStore/config/elasticsearch.yml"

  logI "[$lLOG_PREFIX] - printing Elasticsearch configuration for debug ..."
  cat "$WMUI_INSTALL_INSTALL_DIR/InternalDataStore/config/elasticsearch.yml"
fi

onInterrupt(){
	logI "[$lLOG_PREFIX:onInterrupt()] - Interrupted! Shutting down API Gateway"

	logI "[$lLOG_PREFIX:onInterrupt()] - Shutting down Integration server ..."
    cd "${WMUI_INSTALL_INSTALL_DIR}/profiles/IS_default/bin" || exit 111
    ./shutdown.sh
	logI "[$lLOG_PREFIX:onInterrupt()] - Shutting down Platform manager ..."
    cd "${WMUI_INSTALL_INSTALL_DIR}/profiles/SPM/bin" || exit 112
    ./shutdown.sh
	logI "[$lLOG_PREFIX:onInterrupt()] - Shutting down Elasticsearch ..."
    cd "${WMUI_INSTALL_INSTALL_DIR}/InternalDataStore/bin" || exit 113
    ./shutdown.sh

	exit 0 # managed expected exit
}

checkPrerequisites(){
    local c1=262144 # p1 -> vm.max_map_count
    local p1
    p1=$(sysctl "vm.max_map_count" | cut -d " " -f 3)
    # shellcheck disable=SC2086
    if [ ! $p1 -lt $c1 ]; then
        logI "[$lLOG_PREFIX:checkPrerequisites()] - vm.max_map_count is adequate ($p1)"
    else
        logE "[$lLOG_PREFIX:checkPrerequisites()] - vm.max_map_count is NOT adequate ($p1), container will exit now"
		return 1
    fi
} 

beforeStartConfig(){
  logI "[$lLOG_PREFIX:beforeStartConfig()] - Before Start Configuration"
}

afterStartConfig(){
    logI "Applying afterStartConfig"
    # applyPostSetupTemplate ApiGateway/1005/ChangeAdministratorPassword
    # applyPostSetupTemplate ApiGateway/1005/SetLoadBalancerConfiguration
    # applyPostSetupTemplate ApiGateway/1005/PutSettings
}

trap "onInterrupt" INT TERM

logI "[$lLOG_PREFIX] - Starting up API Gateway server"
logI "[$lLOG_PREFIX] - Checking prerequisites ..."

checkPrerequisites || exit 7
crtPath=$(pwd)


beforeStartConfig

logI "[$lLOG_PREFIX] - Starting Elasticsearch ..."
cd "${WMUI_INSTALL_INSTALL_DIR}/InternalDataStore/bin" || exit 104
./startup.sh
logI "[$lLOG_PREFIX] - Starting Integration Server"
cd "${WMUI_INSTALL_INSTALL_DIR}/profiles/IS_default/bin" || exit 105
./console.sh & 

WPID=$!

while ! portIsReachable2 localhost 9072; do
  logI "Waiting for API Gateway to come up, sleeping 5..."
  sleep 5
done

afterStartConfig

wait ${WPID}

cd "$crtPath" || exit 106
