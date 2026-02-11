#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2026
# SPDX-License-Identifier: Apache-2.0
#

# shellcheck disable=SC3043

if ! command -V "pu_log_i" 2>/dev/null | grep function >/dev/null; then
  echo "[/agw/1101/cds-e2e/02-check-prerequisites] FATAL: function pu_log_i not found, you must initialize posix utils fundamental and audit functions before running this"
  exit 1
fi

_check_env_dependencies(){
  local l_errors=0

  if [ -z "${WMUI_WMSCRIPT_InstallDir+x}" ] ; then
    pu_log_e "[/agw/1101/cds-e2e/02-check-prerequisites] environment variable WMUI_WMSCRIPT_InstallDir MUST be set!"
    l_errors=$((l_errors + 1))
  fi

  if [ -z "${WMUI_WMSCRIPT_TaskEngineRuntimeUrlName+x}" ] ; then
    pu_log_e "[/agw/1101/cds-e2e/02-check-prerequisites] environment variable WMUI_WMSCRIPT_TaskEngineRuntimeUrlName MUST be set!"
    pu_log_i "[/agw/1101/cds-e2e/02-check-prerequisites] Example value: jdbc%3Awm%3Apostgresql%3A%2F%2F%3Cserver%3E%3A%3C5432%7Cport%3E%3BDatabaseName%3D%3Cdatabase%3E"
    l_errors=$((l_errors + 1))
  fi

  if [ -z "${WMUI_WMSCRIPT_TaskEngineRuntimeUserName+x}" ] ; then
    pu_log_e "[/agw/1101/cds-e2e/02-check-prerequisites] environment variable WMUI_WMSCRIPT_TaskEngineRuntimeUserName MUST be set!"
    l_errors=$((l_errors + 1))
  fi

  if [ -z "${WMUI_WMSCRIPT_TaskEngineRuntimePasswordName+x}" ] ; then
    pu_log_e "[/agw/1101/cds-e2e/02-check-prerequisites] environment variable WMUI_WMSCRIPT_TaskEngineRuntimePasswordName MUST be set!"
    l_errors=$((l_errors + 1))
  fi

  if [ -z "${WMUI_WMSCRIPT_TaskEngineRuntimeDriverName+x}" ] ; then
    pu_log_e "[/agw/1101/cds-e2e/02-check-prerequisites] environment variable WMUI_WMSCRIPT_TaskEngineRuntimeDriverName MUST be set!"
    l_errors=$((l_errors + 1))
  fi

  return ${l_errors}
}

if ! _check_env_dependencies; then
  pu_log_e "[/agw/1101/cds-e2e/02-check-prerequisites] Prerequisites check failed ($? environment prerequisites errors)"
  exit 2
fi

# Made with Bob
