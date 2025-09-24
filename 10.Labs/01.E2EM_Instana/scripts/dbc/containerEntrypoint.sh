#!/bin/sh
# shellcheck disable=SC3043

# This script creates all webmethods DB components
WM_HOME=${WM_HOME:-/opt/webmethods/1101/dbc}

createDbAssets(){

    local logPfx="WMUI_LAB10::createDbAssets()"

    if ! nc -z "${WMUI_LAB10_DBSERVER_HOSTNAME}" "${WMUI_LAB10_DBSERVER_PORT}"; then
        echo "$logPfx - Cannot reach socket ${WMUI_LAB10_DBSERVER_HOSTNAME}:${WMUI_LAB10_DBSERVER_PORT}, database initialization failed!"
        return 1
    fi

    local lDBC_DB_URL="jdbc:wm:postgresql://${WMUI_LAB10_DBSERVER_HOSTNAME}:${WMUI_LAB10_DBSERVER_PORT};databaseName=${WMUI_LAB10_DBSERVER_DATABASE_NAME}"
    local lDbcSh="${WM_HOME}/common/db/bin/dbConfigurator.sh"

    local lCmdCatalog="${lDbcSh} --action catalog"
    local lCmdCatalog="${lCmdCatalog} --dbms pgsql"
    local lCmdCatalog="${lCmdCatalog} --user '${WMUI_LAB10_DBSERVER_USER_NAME}'"
    local lCmdCatalog="${lCmdCatalog} --password '${WMUI_LAB10_DBSERVER_PASSWORD}'"
    local lCmdCatalog="${lCmdCatalog} --url '${lDBC_DB_URL}'"

    echo "$logPfx - Checking if product database exists"
    eval "${lCmdCatalog}"

    local resCmdCatalog=$?
    if [ ! "${resCmdCatalog}" -eq 0 ];then
        echo "$logPfx - ERROR - Database not reachable! Result: ${resCmdCatalog}"
        echo "$logPfx - Command was ${lCmdCatalog}"
        return 2
    fi
    # for now this test counts as connectivity.
    # As per product's properties, we consider the "create" action as idempotent

    echo "$logPfx - Initializing database ${WMUI_LAB10_DBSERVER_DATABASE_NAME} on server ${WMUI_LAB10_DBSERVER_HOSTNAME}:${WMUI_LAB10_DBSERVER_PORT} ..."

    local lDbInitCmd="${lDbcSh} --action create"
    local lDbInitCmd="${lDbInitCmd} --dbms pgsql"
    local lDbInitCmd="${lDbInitCmd} --component ${WMUI_LAB10_DBC_COMPONENT_NAME}"
    local lDbInitCmd="${lDbInitCmd} --version ${WMUI_LAB10_DBC_COMPONENT_VERSION}"
    local lDbInitCmd="${lDbInitCmd} --url '${lDBC_DB_URL}'"
    local lDbInitCmd="${lDbInitCmd} --user '${WMUI_LAB10_DBSERVER_USER_NAME}'"
    local lDbInitCmd="${lDbInitCmd} --password '${WMUI_LAB10_DBSERVER_PASSWORD}'"
    local lDbInitCmd="${lDbInitCmd} --printActions"

    eval "${lDbInitCmd}"

    local resInitDb=$?
    if [ "${resInitDb}" -ne 0 ];then
        echo "$logPfx - ERROR - Database initialization failed! Result: ${resInitDb}"
        echo "$logPfx - Executed command was: ${lDbInitCmd}"
        return 3
    fi
}
createDbAssets


echo "Go to http://host.docker.internal:${WMUI_LAB10_PORT_PREFIX}80 and check the database content!. Look at the .env file for details!"
