#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#

# shellcheck disable=SC3043

if ! command -V "pu_log_i" 2>/dev/null | grep function >/dev/null; then
  echo "[/dbc/1101/postgresql-create/check-prerequisites] FATAL: function pu_log_i not found, you must initialize posix utils fundamental and audit functions before running this"
  exit 1
fi

_check_env_dependencies(){
  local l_errors=0

  if ! command -V "pu_audited_exec" 2>/dev/null | grep function >/dev/null; then
    pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] function pu_audited_exec not found, you must initialize posix utils functions before running this"
    l_errors=$((l_errors + 1))
  fi

  if ! command -V "pu_port_is_reachable" 2>/dev/null | grep function >/dev/null; then
    pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] function pu_port_is_reachable not found, you must initialize posix utils networking functions before running this"
    l_errors=$((l_errors + 1))
  fi

  if ! command -V "wmui_hunt_for_file" 2>/dev/null | grep function >/dev/null; then
    pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] function wmui_hunt_for_file not found, you must source WMUI functions before running this"
    l_errors=$((l_errors + 1))
  fi

  if [ -z "${WMUI_PST_DB_SERVER_HOSTNAME+x}" ] ; then
    pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] environment variable WMUI_PST_DB_SERVER_HOSTNAME MUST be set!"
    l_errors=$((l_errors + 1))
  fi

  if [ -z "${WMUI_PST_DB_SERVER_PORT+x}" ] ; then
    pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] environment variable WMUI_PST_DB_SERVER_PORT MUST be set!"
    l_errors=$((l_errors + 1))
  fi

  if [ -z "${WMUI_PST_DB_SERVER_DATABASE_NAME+x}" ] ; then
    pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] environment variable WMUI_PST_DB_SERVER_DATABASE_NAME MUST be set!"
    l_errors=$((l_errors + 1))
  fi

  if [ -z "${WMUI_PST_DB_SERVER_USER_NAME+x}" ] ; then
    pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] environment variable WMUI_PST_DB_SERVER_USER_NAME MUST be set!"
    l_errors=$((l_errors + 1))
  fi

  if [ -z "${WMUI_PST_DB_SERVER_PASSWORD+x}" ] ; then
    pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] environment variable WMUI_PST_DB_SERVER_PASSWORD MUST be set!"
    l_errors=$((l_errors + 1))
  fi

  # This template relies on an existing installation of the database configurator
  if [ -z "${WMUI_WMSCRIPT_InstallDir+x}" ] ; then
    pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] environment variable WMUI_WMSCRIPT_InstallDir MUST be set!"
    l_errors=$((l_errors + 1))
  fi

  if [ ! -x "${WMUI_WMSCRIPT_InstallDir}/common/db/bin/dbConfigurator.sh" ] ; then
    pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] ${WMUI_WMSCRIPT_InstallDir}/common/db/bin/dbConfigurator.sh MUST exist and be an executable file!"
    l_errors=$((l_errors + 1))
  fi

  return ${l_errors}
}

_check_service_dependencies(){
  local l_errors=0
  if ! pu_port_is_reachable "${WMUI_PST_DB_SERVER_HOSTNAME}" "${WMUI_PST_DB_SERVER_PORT}"; then
    pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] Cannot reach socket ${WMUI_PST_DB_SERVER_HOSTNAME}:${WMUI_PST_DB_SERVER_PORT}, database initialization failed!"
    l_errors=$((l_errors + 1))
  fi
  return ${l_errors}
}

if ! _check_env_dependencies; then
  pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] Prerequisites check failed ($? environment prerequisites errors)"
  exit 2
fi

if ! _check_service_dependencies; then
  pu_log_e "[/dbc/1101/postgresql-create/check-prerequisites] Prerequisites check failed ($? prerequisite services errors)"
  exit 3
fi