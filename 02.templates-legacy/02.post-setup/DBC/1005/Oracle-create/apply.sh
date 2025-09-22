#!/bin/sh

# shellcheck disable=SC3043

# This scripts apply the post-setup configuration for the current template
thisFolder="02.templates/02.post-setup/DBC/1005/Oracle-create"

# Dependency 1
if ! commonFunctionsSourced 2>/dev/null; then
  if [ ! -f "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
    echo "[${thisFolder}/apply.sh] - Panic, common functions not sourced and not present locally! Cannot continue"
    exit 254
  fi
  echo "[${thisFolder}/apply.sh] - commonFunctions.sh not sourced, sourcing (again) ..."
  # shellcheck source=/dev/null
  . "$WMUI_CACHE_HOME/01.scripts/commonFunctions.sh"
fi

assureExportedVariables(){
  # TODO: complete
  if [ -z "${WMUI_DBSERVER_HOSTNAME+x}" ]; then
    logE "[${thisFolder}/apply.sh:assureExportedVariables()] - Variable WMUI_DBSERVER_HOSTNAME not courced!"
  fi

  # Default values
  export WMUI_INSTALL_InstallDir="${WMUI_INSTALL_InstallDir:-/opt/softwareag}"
  export WMUI_DBSERVER_PORT="${WMUI_DBSERVER_PORT:-1251}"
}

assureFiles(){
  huntForSuifFile "${thisFolder}" "setEnvDefaults.sh"

  if [ ! -f "${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" ]; then
    logE "[${thisFolder}/apply.sh:assureFiles()] - File not found: ${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
    exit 100
  fi

  chmod u+x "${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
}

########## CLI wrappers - BEGIN
# assume we are in the DBC bin folder and the following local vars are declared in the calling function
# - the lDbcSh var points to the command script file
# - 
# 21
checkSysCatalog(){
  local lCmdChkMaster="${lDbcSh} "' \
    --action catalog  \
    --dbms oracle  \
    --user '"'sys'"'  \
    --password '"'${WMUI_DBSERVER_SA_PASSWORD}'"' \
    --url '"'${lDBC_DB_URL_M}'"

  if [ "${WMUI_DEBUG_ON}" -ne 0 ]; then
    local lCmdChkMasterToLog="${lDbcSh} "' \
    --action catalog  \
    --dbms oracle  \
    --user '"'sys'"'  \
    --password '"'****'"' \
    --url '"'${lDBC_DB_URL_M}'"
    logD "[${thisFolder}/apply.sh:checkSysCatalog()] - Command to execute is ${lCmdChkMasterToLog}"
  fi

  logI "[${thisFolder}/apply.sh:checkSysCatalog()] - Checking if database service is reachable by dbConfigurator..."
  controlledExec "${lCmdChkMaster}" "$(date +%s).CheckMasterReachable"

  local resChkMaster=$?
  if [ "${resChkMaster}" -ne 0 ]; then
    logE "[${thisFolder}/apply.sh:checkSysCatalog()] - Database [${lDBC_DB_URL_M}] cannot be reached, dbConfigurator code ${resChkMaster}. Cannot continue!"
    logD "[${thisFolder}/apply.sh:checkSysCatalog()] - Command was: ${lCmdChkMaster}"
    return 211
  fi
}

# 22
checkStorageAlreadyExists(){
  local lCmdChkAlreadyCreated="${lDbcSh}"' \
    --action catalog \
    --dbms oracle \
    --user '"'${WMUI_DBSERVER_USER_NAME}'"' \
    --password '"'${WMUI_DBSERVER_PASSWORD}'"' \
    --url '"'${lDBC_DB_URL}'"

  if [ "${WMUI_DEBUG_ON}" -ne 0 ]; then
    local lCmdChkAlreadyCreatedToLog="${lDbcSh}"' \
    --action catalog \
    --dbms oracle \
    --user '"'${WMUI_DBSERVER_USER_NAME}'"' \
    --password '"'****'"' \
    --url '"'${lDBC_DB_URL}'"
    logD "[${thisFolder}/apply.sh:checkStorageAlreadyExists()] - Command to execute is ${lCmdChkAlreadyCreatedToLog}"
  fi

  logI "[${thisFolder}/apply.sh:checkStorageAlreadyExists()] - Checking if product database exists"
  controlledExec "${lCmdChkAlreadyCreated}" "$(date +%s).CheckDatabaseExists"

  local resChkAlreadyCreated=$?
  if [ "${resChkAlreadyCreated}" -eq 0 ]; then
    logI "[${thisFolder}/apply.sh:checkStorageAlreadyExists()] - Schema ${WMUI_DBSERVER_USER_NAME} already exists, continuing..."
  else
    logI "[${thisFolder}/apply.sh:checkStorageAlreadyExists()] - Schema ${WMUI_DBSERVER_USER_NAME} does not exist or not reachable, code ${resChkAlreadyCreated}"
    return 221
  fi
}

# 23
createStorage(){
  logI  "[${thisFolder}/apply.sh:createStorage()] - Creating a new schema named ${WMUI_DBSERVER_USER_NAME}"\
        "on server ${WMUI_DBSERVER_HOSTNAME}:${WMUI_DBSERVER_PORT}, service ${WMUI_DBSERVER_SERVICE_NAME}"

  local lDbCreateCmd="${lDbcSh} --action create "'\
    --dbms oracle \
    --component storage \
    --version latest \
    --url '"'${lDBC_DB_URL_M}'"' \
    -au sys \
    -ap '"'${WMUI_DBSERVER_SA_PASSWORD}'"' \
    -u '"'${WMUI_DBSERVER_USER_NAME}'"' \
    -p '"'${WMUI_DBSERVER_PASSWORD}'"' \
    -t '"'${WMUI_ORACLE_STORAGE_TABLESPACE_DIR}'"
    # --printActions

    # example from documentation
    # ./bin/dbConfigurator.sh
    # --component "ISI" --action "drop" --version latest
    # --url "jdbc:wm:oracle://host:port;serviceName=name"
    # --user "user" --password "password"
    # --admin_user "admin_user" --admin_password "admin_password"
    # --dbms Oracle --dbname "name" --tablespacedir "c:\\app\\test"
    # unclear if --tablespacedir must be provided. Deeper topic, study deferred

  controlledExec "${lDbCreateCmd}" "CreateDatabase_${WMUI_DBSERVER_DATABASE_NAME}"

  local resCreateDb=$?
  if [ "${resCreateDb}" -ne 0 ]; then
    logE "[${thisFolder}/apply.sh:createStorage()] - Database creation failed! Result: ${resCreateDb}"
    logD "[${thisFolder}/apply.sh:createStorage()] - Executed command was: ${lDbCreateCmd}"
    return 207
  fi
}

# 24
createAssets(){
  # Note: the create operation is idempotent and also incorporates an eventual upgrade of the DDL ( not data/DML ! )
  logI "[${thisFolder}/apply.sh:createAssets()] - Initializing database ${WMUI_DBSERVER_DATABASE_NAME} on server ${WMUI_DBSERVER_HOSTNAME}:${WMUI_DBSERVER_PORT} ..."

  local lDbInitCmd="${lDbcSh} --action create"' \
    --dbms oracle \
    --component '"${WMUI_DBC_COMPONENT_NAME}"' \
    --version '"${WMUI_DBC_COMPONENT_VERSION}"' \
    --url '"'${lDBC_DB_URL}'"' \
    --user '"'${WMUI_DBSERVER_USER_NAME}'"' \
    --password '"'${WMUI_DBSERVER_PASSWORD}'"
  # local lDbInitCmd="${lDbInitCmd} --printActions"

  controlledExec "${lDbInitCmd}" "InitializeDatabase_${WMUI_DBSERVER_DATABASE_NAME}"

  local resInitDb=$?
  if [ "${resInitDb}" -ne 0 ]; then
    logE "[${thisFolder}/apply.sh:createAssets()] - Database initialization failed! Result: ${resInitDb}"
    logD "[${thisFolder}/apply.sh:createAssets()] - Executed command was: ${lDbInitCmd}"
    return 241
  fi
}
########## CLI wrappers - END

eventuallyInitializeDB(){

  logI "[${thisFolder}/apply.sh:eventuallyInitializeDB()] - Sourcing variables from ${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
  # shellcheck source=/dev/null
  . "${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" || return 100

  assureExportedVariables
  assureFiles

  # Check if DB port is reachable...
  if ! portIsReachable2 "${WMUI_DBSERVER_HOSTNAME}" "${WMUI_DBSERVER_PORT}" ; then
    logE "[${thisFolder}/apply.sh:eventuallyInitializeDB()] - Cannot reach socket ${WMUI_DBSERVER_HOSTNAME}:${WMUI_DBSERVER_PORT}, database initialization failed!"
    return 101
  fi

  local crtDir
  crtDir=$(pwd)

  cd "${WMUI_INSTALL_InstallDir}/common/db/bin" || return 102

  local lDbcSh="./dbConfigurator.sh"
  local lDBC_DB_URL_M="jdbc:wm:oracle://${WMUI_DBSERVER_HOSTNAME}:${WMUI_DBSERVER_PORT};serviceName=${WMUI_DBSERVER_SERVICE_NAME};sysLoginRole=sysdba"
  local lDBC_DB_URL="jdbc:wm:oracle://${WMUI_DBSERVER_HOSTNAME}:${WMUI_DBSERVER_PORT};serviceName=${WMUI_DBSERVER_SERVICE_NAME}"

  checkStorageAlreadyExists
  local nStorageExists=$? # 0 means it exists...
  local returnCode=0

  if [ ${nStorageExists} -ne 0 ]; then
    if [ "${WMUI_DATABASE_ALREADY_CREATED}" -ne 0 ]; then
      logE "[${thisFolder}/apply.sh:eventuallyInitializeDB()] - Storage does not exist or is not reachable and WMUI_DATABASE_ALREADY_CREATED is not zero (=${WMUI_DATABASE_ALREADY_CREATED})"
      logE "[${thisFolder}/apply.sh:eventuallyInitializeDB()] - Inconsistent configuration or database not reachable! Cannot continue"

      cd "${crtDir}" || return 103
      return 104
    fi
    logI "[${thisFolder}/apply.sh:eventuallyInitializeDB()] - Storage does not exist or is not reachable. Attempting to create now"
    checkSysCatalog || returnCode=$?
    if [ ${returnCode} -eq 0 ] ; then
      createStorage || returnCode=$?
    fi
  fi

  if [ ${returnCode} -eq 0 ] ; then
    createAssets || returnCode=$?
  fi

  cd "${crtDir}" || return 106
  return ${returnCode}
}

eventuallyInitializeDB || exit $?