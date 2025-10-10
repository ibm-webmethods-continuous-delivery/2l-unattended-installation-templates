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
thisFolder="02.templates/02.post-setup/DBC/1005/Sql-server-create"

huntForSuifFile "${thisFolder}" "setEnvDefaults.sh"

if [ ! -f "${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" ]; then
    logE "File not found: ${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
    exit 100
fi

chmod u+x "${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" 

logI "Sourcing variables from ${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
. "${WMUI_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"

##############
createDbAndAssets(){

    if [ `portIsReachable ${WMUI_SQLSERVER_HOSTNAME} ${WMUI_SQLSERVER_PORT}` ]; then

        local lDBC_DB_URL_M="jdbc:wm:sqlserver://${WMUI_SQLSERVER_HOSTNAME}:${WMUI_SQLSERVER_PORT};databaseName=master" 
        local lDBC_DB_URL="jdbc:wm:sqlserver://${WMUI_SQLSERVER_HOSTNAME}:${WMUI_SQLSERVER_PORT};databaseName=${WMUI_SQLSERVER_DATABASE_NAME}"
        local lDbcSh="${WMUI_INSTALL_InstallDir}/common/db/bin/dbConfigurator.sh"

        #1 Check if master can be reached
        local lCmdChkMaster="${lDbcSh} --action catalog"
        local lCmdChkMaster="${lCmdChkMaster} --dbms sqlserver"
        local lCmdChkMaster="${lCmdChkMaster} --user 'sa'"
        local lCmdChkMaster="${lCmdChkMaster} --password '${WMUI_SQLSERVER_SA_PASSWORD}'"
        local lCmdChkMaster="${lCmdChkMaster} --url '${lDBC_DB_URL_M}'"

        logI "Checking if master database is reachable"
        controlledExec "${lCmdChkMaster}" `date +%s`.CheckMasterReachable

        local resChkMaster=$?
        if [ "${resChkMaster}" -ne 0 ];then
            logE "Master database [${lDBC_DB_URL_M}] cannot be reached, dbConfigurator code ${resChkMaster}. Cannot continue!"
            return 2
        fi

        local lCmd="${WMUI_INSTALL_InstallDir}/common/db/bin/dbConfigurator.sh"
        if [ "${WMUI_DATABASE_ALREADY_CREATED}" -eq 0 ]; then
            # Check if database was already created (idempotence)

            local lCmdChkAlreadyCreated="${lDbcSh} --action catalog"
            local lCmdChkAlreadyCreated="${lCmdChkAlreadyCreated} --dbms sqlserver"
            local lCmdChkAlreadyCreated="${lCmdChkAlreadyCreated} --user '${WMUI_SQLSERVER_USER_NAME}'"
            local lCmdChkAlreadyCreated="${lCmdChkAlreadyCreated} --password '${WMUI_SQLSERVER_PASSWORD}'"
            local lCmdChkAlreadyCreated="${lCmdChkAlreadyCreated} --url '${lDBC_DB_URL}'"

            logI "Checking if product database exists"
            controlledExec "${lCmdChkAlreadyCreated}" `date +%s`.CheckDatabaseExists

            local resChkAlreadyCreated=$?
            if [ "${resChkAlreadyCreated}" -eq 0 ];then
                logI "Database ${lDBC_DB_URL} already exists, continuing..."
            else
                logI "Product database [${lDBC_DB_URL}] cannot be reached, dbConfigurator code ${resChkAlreadyCreated}. Attempting creation now..."
                logI "Creating a new database named ${WMUI_SQLSERVER_DATABASE_NAME} on server ${WMUI_SQLSERVER_HOSTNAME}:${WMUI_SQLSERVER_PORT}"

                local lDbCreateCmd="${lDbcSh} --action create"
                local lDbCreateCmd="${lDbCreateCmd} --dbms sqlserver"
                local lDbCreateCmd="${lDbCreateCmd} --component storage"
                local lDbCreateCmd="${lDbCreateCmd} --version latest"
                local lDbCreateCmd="${lDbCreateCmd} --url '${lDBC_DB_URL_M}'"
                local lDbCreateCmd="${lDbCreateCmd} --user '${WMUI_SQLSERVER_USER_NAME}'"
                local lDbCreateCmd="${lDbCreateCmd} --password '${WMUI_SQLSERVER_PASSWORD}'"
                local lDbCreateCmd="${lDbCreateCmd} -au sa"
                local lDbCreateCmd="${lDbCreateCmd} -ap '${WMUI_SQLSERVER_SA_PASSWORD}'"
                local lDbCreateCmd="${lDbCreateCmd} -n '${WMUI_SQLSERVER_DATABASE_NAME}'"
                local lDbCreateCmd="${lDbCreateCmd} --printActions"

                controlledExec "${lDbCreateCmd}" "CreateDatabase_${WMUI_SQLSERVER_DATABASE_NAME}"

                local resCreateDb=$?
                if [ "${resCreateDb}" -ne 0 ];then
                    logE "Database creation failed! Result: ${resCreateDb}"
                    return 3
                fi
            fi
        fi

        logI "Initializing database ${WMUI_SQLSERVER_DATABASE_NAME} on server ${WMUI_SQLSERVER_HOSTNAME}:${WMUI_SQLSERVER_PORT} ..."

        local lDbInitCmd="${lDbcSh} --action create"
        local lDbInitCmd="${lDbInitCmd} --dbms sqlserver"
        local lDbInitCmd="${lDbInitCmd} --component ${WMUI_DBC_COMPONENT_NAME}"
        local lDbInitCmd="${lDbInitCmd} --version ${WMUI_DBC_COMPONENT_VERSION}"
        local lDbInitCmd="${lDbInitCmd} --url '${lDBC_DB_URL}'"
        local lDbInitCmd="${lDbInitCmd} --user '${WMUI_SQLSERVER_USER_NAME}'"
        local lDbInitCmd="${lDbInitCmd} --password '${WMUI_SQLSERVER_PASSWORD}'"
        local lDbInitCmd="${lDbInitCmd} --printActions"

        controlledExec "${lDbInitCmd}" "InitializeDatabase_${WMUI_SQLSERVER_DATABASE_NAME}"

        local resInitDb=$?
        if [ "${resInitDb}" -ne 0 ];then
            logE "Database initialization failed! Result: ${resInitDb}"
            logD "Executed command was: ${lDbInitCmd}"
            return 4
        fi

    else
        logE "Cannot reach socket ${WMUI_SQLSERVER_HOSTNAME}:${WMUI_SQLSERVER_PORT}, database initialization failed!"
        return 1
    fi
}

createDbAndAssets
