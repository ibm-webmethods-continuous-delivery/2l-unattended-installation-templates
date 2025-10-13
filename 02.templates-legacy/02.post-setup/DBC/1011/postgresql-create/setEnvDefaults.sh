#!/bin/sh

## User MUST provide
export WMUI_DBSERVER_HOSTNAME=${WMUI_DBSERVER_HOSTNAME-:"ProvideDBHostName!"}
export WMUI_DBSERVER_DATABASE_NAME=${WMUI_DBSERVER_DATABASE_NAME-:"ProvideDatabaseName!"}
export WMUI_DBSERVER_USER_NAME=${WMUI_DBSERVER_USER_NAME-:"ProvideUserName!"}
export WMUI_DBSERVER_PASSWORD=${WMUI_DBSERVER_PASSWORD-:"ProvideUserPAssowrd!"}

## User MAY provide
export WMUI_CACHE_HOME=${WMUI_CACHE_HOME:-"/tmp/WMUI_CACHE"}
export WMUI_INSTALL_INSTALL_DIR=${WMUI_INSTALL_INSTALL_DIR-:"/opt/sag/products"}
# 0 means DB was not created, thus create now
export WMUI_DATABASE_ALREADY_CREATED=${WMUI_DATABASE_ALREADY_CREATED:-"0"}
export WMUI_DBSERVER_PORT=${WMUI_DBSERVER_PORT:-"5432"}
# By default create all components
export WMUI_DBC_COMPONENT_NAME=${WMUI_DBC_COMPONENT_NAME:-"All"}
# By default create the latest version
export WMUI_DBC_COMPONENT_VERSION=${WMUI_DBC_COMPONENT_VERSION:-"latest"}
