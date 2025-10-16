#!/bin/sh

## User MUST provide
export WMUI_SQLSERVER_HOSTNAME=${WMUI_SQLSERVER_HOSTNAME-:"ProvideDBHostName!"}
export WMUI_SQLSERVER_DATABASE_NAME=${WMUI_SQLSERVER_DATABASE_NAME-:"ProvideDatabaseName!"}
export WMUI_SQLSERVER_USER_NAME=${WMUI_SQLSERVER_USER_NAME-:"ProvideUserName!"}
export WMUI_SQLSERVER_PASSWORD=${WMUI_SQLSERVER_PASSWORD-:"ProvideUserPAssowrd!"}

## User MUST provide only IF WMUI_DATABASE_ALREADY_CREATED is not 0
export WMUI_SQLSERVER_SA_PASSWORD=${WMUI_SQLSERVER_SA_PASSWORD-:"ProvideSaPassword!"}


## User MAY provide
export WMUI_CACHE_HOME=${WMUI_CACHE_HOME:-"/tmp/WMUI_CACHE"}
export WMUI_INSTALL_InstallDir=${WMUI_INSTALL_InstallDir-:"/opt/sag/products"}
# 0 means DB was not created, thus create now
export WMUI_DATABASE_ALREADY_CREATED=${WMUI_DATABASE_ALREADY_CREATED:-"0"}
export WMUI_SQLSERVER_PORT=${WMUI_SQLSERVER_PORT:-"1433"}
# By default create all components
export WMUI_DBC_COMPONENT_NAME=${WMUI_DBC_COMPONENT_NAME:-"All"}
# By default create the latest version
export WMUI_DBC_COMPONENT_VERSION=${WMUI_DBC_COMPONENT_VERSION:-"latest"}
