#!/bin/sh

# This scripts apply the post-setup configuration for the current template

# Dependency 1
if [ ! "`type -t huntForSuifFile`X" == "functionX" ]; then
    echo "sourcing commonFunctions.sh again (lost?)"
    if [ ! -f "$WMUI_CACHE_HOME/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue!"
        exit 500
    fi
    . "$WMUI_CACHE_HOME/01.scripts/commonFunctions.sh"
fi
thisFolder="02.templates/02.post-setup/DBC/1011/postgresql-create"

huntForSuifFile "${thisFolder}" "setEnvDefaults.sh"

if [ ! -f "${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" ]; then
    logE "File not found: ${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
    exit 100
fi

chmod u+x "${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" 

logI "Sourcing variables from ${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
. "${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"

##############
createDbAssets(){

    if [ ! `portIsReachable ${WMUI_DBSERVER_HOSTNAME} ${WMUI_DBSERVER_PORT}` ]; then
        logE "Cannot reach socket ${WMUI_DBSERVER_HOSTNAME}:${WMUI_DBSERVER_PORT}, database initialization failed!"
        return 1
    fi

    local lDBC_DB_URL="jdbc:wm:postgresql://${WMUI_DBSERVER_HOSTNAME}:${WMUI_DBSERVER_PORT};databaseName=${WMUI_DBSERVER_DATABASE_NAME}"
    local lDbcSh="${WMUI_INSTALL_INSTALL_DIR}/common/db/bin/dbConfigurator.sh"

    local lCmdCatalog="${lDbcSh} --action catalog"
    local lCmdCatalog="${lCmdCatalog} --dbms pgsql"
    local lCmdCatalog="${lCmdCatalog} --user '${WMUI_DBSERVER_USER_NAME}'"
    local lCmdCatalog="${lCmdCatalog} --password '${WMUI_DBSERVER_PASSWORD}'"
    local lCmdCatalog="${lCmdCatalog} --url '${lDBC_DB_URL}'"

    logI "Checking if product database exists"
    controlledExec "${lCmdCatalog}" `date +%s`.CatalogDatabase

    local resCmdCatalog=$?
    if [ ! "${resCmdCatalog}" -eq 0 ];then
        logE "Database not reachable! Result: ${resCmdCatalog}"
        logD "Command was ${lCmdCatalog}"
        return 2
    fi
    # for now this test counts as connectivity. TODO: find out a way to render the "create" idempotent

    logI "Initializing database ${WMUI_DBSERVER_DATABASE_NAME} on server ${WMUI_DBSERVER_HOSTNAME}:${WMUI_DBSERVER_PORT} ..."

    local lDbInitCmd="${lDbcSh} --action create"
    local lDbInitCmd="${lDbInitCmd} --dbms pgsql"
    local lDbInitCmd="${lDbInitCmd} --component ${WMUI_DBC_COMPONENT_NAME}"
    local lDbInitCmd="${lDbInitCmd} --version ${WMUI_DBC_COMPONENT_VERSION}"
    local lDbInitCmd="${lDbInitCmd} --url '${lDBC_DB_URL}'"
    local lDbInitCmd="${lDbInitCmd} --user '${WMUI_DBSERVER_USER_NAME}'"
    local lDbInitCmd="${lDbInitCmd} --password '${WMUI_DBSERVER_PASSWORD}'"
    local lDbInitCmd="${lDbInitCmd} --printActions"

    controlledExec "${lDbInitCmd}" "InitializeDatabase_${WMUI_DBSERVER_DATABASE_NAME}"

    local resInitDb=$?
    if [ "${resInitDb}" -ne 0 ];then
        logE "Database initialization failed! Result: ${resInitDb}"
        logD "Executed command was: ${lDbInitCmd}"
        return 3
    fi
}

createDbAssets
