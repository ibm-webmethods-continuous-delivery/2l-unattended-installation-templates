#!/bin/sh

export WMUI_CACHE_HOME="${WMUI_CACHE_HOME:-/tmp/WMUI_CACHE}"
export WMUI_INSTALL_INSTALL_DIR="${WMUI_INSTALL_INSTALL_DIR:-/opt/webmethods/products}"
# 0 means DB was not created, thus create now
export WMUI_DATABASE_ALREADY_CREATED="${WMUI_DATABASE_ALREADY_CREATED:-0}"
export WMUI_DBSERVER_PORT="${WMUI_DBSERVER_PORT:-1521}"
# By default create all components
export WMUI_DBC_COMPONENT_NAME="${WMUI_DBC_COMPONENT_NAME:-All}"
# By default create the latest version
export WMUI_DBC_COMPONENT_VERSION="${WMUI_DBC_COMPONENT_VERSION:-latest}"
# By default uses WEBMDATA for data tablespace
export WMUI_DBC_COMPONENT_TSDATA="${WMUI_DBC_COMPONENT_TSDATA:-WEBMDATA}"
# By default uses WEBMINDX for index tablespace
export WMUI_DBC_COMPONENT_TSINDEX="${WMUI_DBC_COMPONENT_TSINDEX:-WEBMINDX}"
