#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#
# This scripts apply the post-setup configuration for the current template

# shellcheck disable=SC3043

##############
_create_db_assets(){

  local _l_cmd_catalog _l_dbc_sh _l_dbc_db_url _l_db_init_cmd

  _l_dbc_db_url="jdbc:wm:oracle://${WMUI_DBSERVER_HOSTNAME}:${WMUI_DBSERVER_PORT};serviceName=${WMUI_DBSERVER_DATABASE_NAME}"
  _l_dbc_sh="${WMUI_INSTALL_INSTALL_DIR}/common/db/bin/dbConfigurator.sh"

  _l_cmd_catalog="${_l_dbc_sh} --action catalog"
  _l_cmd_catalog="${_l_cmd_catalog} --dbms oracle"
  _l_cmd_catalog="${_l_cmd_catalog} --url '${_l_dbc_db_url}'"
  _l_cmd_catalog="${_l_cmd_catalog} --user '${WMUI_DBSERVER_USER_NAME}'"
  _l_cmd_catalog="${_l_cmd_catalog} --password '${WMUI_DBSERVER_PASSWORD}'"
  
  pu_log_i "[/dbc/1101/oracle-create/apply] Checking if product database exists"
  pu_audited_exec "${_l_cmd_catalog}" "CatalogDatabase_${WMUI_DBSERVER_DATABASE_NAME}"

  local resCmdCatalog=$?
  if [ ! "${resCmdCatalog}" -eq 0 ];then
    pu_log_e "[/dbc/1101/oracle-create/apply] Database not reachable! Result: ${resCmdCatalog}"
    pu_log_d "[/dbc/1101/oracle-create/apply] Command was ${_l_cmd_catalog}"
    return 1
  fi
  # for now this test counts as connectivity. TODO: find out a way to render the "create" idempotent

  pu_log_i "[/dbc/1101/oracle-create/apply] Initializing database ${WMUI_DBSERVER_DATABASE_NAME} on server ${WMUI_DBSERVER_HOSTNAME}:${WMUI_DBSERVER_PORT} ..."

  _l_db_init_cmd="${_l_dbc_sh} --action create"
  _l_db_init_cmd="${_l_db_init_cmd} --dbms oracle"
  _l_db_init_cmd="${_l_db_init_cmd} --component ${WMUI_DBC_COMPONENT_NAME}"
  _l_db_init_cmd="${_l_db_init_cmd} --version ${WMUI_DBC_COMPONENT_VERSION}"
  _l_db_init_cmd="${_l_db_init_cmd} --tablespacefordata ${WMUI_DBC_COMPONENT_TSDATA}"
  _l_db_init_cmd="${_l_db_init_cmd} --tablespaceforindex ${WMUI_DBC_COMPONENT_TSINDEX}"
  _l_db_init_cmd="${_l_db_init_cmd} --url '${_l_dbc_db_url}'"
  _l_db_init_cmd="${_l_db_init_cmd} --user '${WMUI_DBSERVER_USER_NAME}'"
  _l_db_init_cmd="${_l_db_init_cmd} --password '${WMUI_DBSERVER_PASSWORD}'"
  _l_db_init_cmd="${_l_db_init_cmd} --printActions"

  pu_audited_exec "${_l_db_init_cmd}" "InitializeDatabase_${WMUI_DBSERVER_DATABASE_NAME}"

  local resInitDb=$?
  if [ "${resInitDb}" -ne 0 ];then
    pu_log_e "[/dbc/1101/oracle-create/apply] Database initialization failed! Result: ${resInitDb}"
    pu_log_d "[/dbc/1101/oracle-create/apply] Executed command was: ${_l_db_init_cmd}"
    return 2
  fi
}

_create_db_assets || exit $?
