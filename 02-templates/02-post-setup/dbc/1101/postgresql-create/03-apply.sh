#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#
# This scripts apply the post-setup configuration for the current template

# shellcheck disable=SC3043

##############
_create_db_assets(){

  local l_db_url="jdbc:wm:postgresql://${WMUI_PST_DB_SERVER_HOSTNAME}:${WMUI_PST_DB_SERVER_PORT};databaseName=${WMUI_PST_DB_SERVER_DATABASE_NAME}"
  # shellcheck disable=SC2154
  local l_dbc_sh="${WMUI_WMSCRIPT_InstallDir}/common/db/bin/dbConfigurator.sh"

  local l_cmd_catalog
  l_cmd_catalog="${l_dbc_sh} --action catalog"
  l_cmd_catalog="${l_cmd_catalog} --dbms pgsql"
  l_cmd_catalog="${l_cmd_catalog} --url '${l_db_url}'"
  l_cmd_catalog="${l_cmd_catalog} --user '${WMUI_PST_DB_SERVER_USER_NAME}'"
  l_cmd_catalog="${l_cmd_catalog} --password '${WMUI_PST_DB_SERVER_PASSWORD}'"
  local l_cmd_catalog_audit="${l_cmd_catalog} --password ***"

  pu_log_i "[/dbc/1101/postgresql-create/apply] Checking if product database exists"
  pu_log_d "[/dbc/1101/postgresql-create/apply] Catalog command is: ${l_cmd_catalog_audit}"
  if ! pu_audited_exec "${l_cmd_catalog}" "CatalogDatabase" ; then
    pu_log_e "[/dbc/1101/postgresql-create/apply] Database catalog failed! Result: $?"
    return 2
  fi
  # for now this test counts as connectivity. TODO: find out a way to render the "create" idempotent

  pu_log_i "[/dbc/1101/postgresql-create/apply] Initializing database ${WMUI_PST_DB_SERVER_DATABASE_NAME} on server ${WMUI_PST_DB_SERVER_HOSTNAME}:${WMUI_PST_DB_SERVER_PORT} ..."

  local l_db_init_cmd
  l_db_init_cmd="${l_dbc_sh} --action create"
  l_db_init_cmd="${l_db_init_cmd} --dbms pgsql"
  l_db_init_cmd="${l_db_init_cmd} --component ${WMUI_PST_DBC_COMPONENT_NAME}"
  l_db_init_cmd="${l_db_init_cmd} --version ${WMUI_PST_DBC_COMPONENT_VERSION}"
  l_db_init_cmd="${l_db_init_cmd} --url '${l_db_url}'"
  l_db_init_cmd="${l_db_init_cmd} --printActions"
  l_db_init_cmd="${l_db_init_cmd} --user '${WMUI_PST_DB_SERVER_USER_NAME}'"
  l_db_init_cmd="${l_db_init_cmd} --password '${WMUI_PST_DB_SERVER_PASSWORD}'"
  local l_db_init_cmd_audit="${l_db_init_cmd} --password ***"

  pu_log_d "[/dbc/1101/postgresql-create/apply] db initialization command is: ${l_db_init_cmd_audit}"

  if ! pu_audited_exec "${l_db_init_cmd}" "InitializeDatabase_${WMUI_PST_DB_SERVER_DATABASE_NAME}" ; then
    pu_log_e "[/dbc/1101/postgresql-create/apply] Database initialization failed! Result: $?"
    return 3
  fi
}

_create_db_assets || exit $?
