#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#
# WARNING: POSIX compatibility is pursued, but this is not a strict POSIX script.
# The following exceptions apply
# - local variables for functions
# shellcheck disable=SC3043

# This file is a collection of functions used by all the other scripts

## Framework variables
# Convention: all variables from this framework are prefixed with WMUI_
# Variables defaults are specified in the init function
# client projects should source their variables with en .env file

init() {
  # BREAKING CHANGE: This file now requires posix-shell-utils (2.audit.sh) to be sourced first
  # Verify that PU audit is loaded
  if [ -z "${__2__audit_session_dir}" ]; then
    echo "FATAL: commonFunctions.sh requires posix-shell-utils (2.audit.sh) to be sourced first!"
    echo "Please source 2l-posix-shell-utils/code/2.audit.sh before sourcing commonFunctions.sh"
    return 201
  fi

  # Map PU audit session to WMUI variables for compatibility
  export WMUI_AUDIT_SESSION_DIR="${__2__audit_session_dir}"

  # WMUI-specific configuration
  export WMUI_DEBUG_ON="${WMUI_DEBUG_ON:-0}"
  export WMUI_LOG_TOKEN="${WMUI_LOG_TOKEN:-WMUI}"

  # Online/offline mode: 1=online (default), 0=offline
  export WMUI_ONLINE_MODE="${WMUI_ONLINE_MODE:-1}"

  if [ "${WMUI_ONLINE_MODE}" -eq 0 ]; then
    # Offline mode: caller MUST provide WMUI_HOME
    if [ ! -f "${WMUI_HOME}/01.scripts/commonFunctions.sh" ]; then
      pu_log_e "FATAL - ${WMUI_HOME}/01.scripts/commonFunctions.sh not found in offline mode!"
      pu_log_e "HINT  - Set WMUI_HOME variable (current value=${WMUI_HOME})"
      return 104
    fi
    export WMUI_CACHE_HOME="${WMUI_HOME}"
  else
    # Online mode: use GitHub repository
    export WMUI_HOME_URL="${WMUI_HOME_URL:-"https://raw.githubusercontent.com/SoftwareAG/sag-unattended-installations/main"}"
    export WMUI_CACHE_HOME="${WMUI_CACHE_HOME:-"/tmp/wmuiCacheHome"}"
    mkdir -p "${WMUI_CACHE_HOME}"
  fi

  # SUPPRESS_STDOUT: 1=suppress stdout, 0=show stdout (default)
  export WMUI_SUPPRESS_STDOUT="${WMUI_SUPPRESS_STDOUT:-0}"
}

init || exit $?

pu_log_i "WMUI commonFunctions.sh initialized - WMUI_AUDIT_SESSION_DIR=${WMUI_AUDIT_SESSION_DIR}"

# Convention:
# f() function creates a RESULT_f variable for the outcome
# if not otherwise specified, 0 means success

# controlledExec has been moved to posix-shell-utils
# Use pu_audited_exec instead

# portIsReachable() {
#   # Params: $1 -> host $2 -> port
#   if [ -f /usr/bin/nc ]; then
#     nc -z "${1}" "${2}" # alpine image
#   else
#     # shellcheck disable=SC2006,SC2086,SC3025,SC2034
#     temp=$( (echo >/dev/tcp/${1}/${2}) >/dev/null 2>&1) # centos image
#   fi
#   # shellcheck disable=SC2181
#   if [ $? -eq 0 ]; then echo 1; else echo 0; fi
# }

# Network functions have been moved to posix-shell-utils
# Use pu_port_is_reachable and pu_wait_for_port instead

# URL encoding functions have been moved to posix-shell-utils
# Use pu_urlencode instead

# deprecated, not POSIX portable
urldecode() {
  # urldecode <string>
  # usage A=$(urldecode ${A_ENC})

  # shellcheck disable=SC3060
  local url_encoded="${1//+/ }"
  # shellcheck disable=SC3060
  printf '%b' "${url_encoded//%/\\x}"
}

# Parameters - huntForWmuiFile
# $1 - relative Path to WMUI_CACHE_HOME
# $2 - filename
huntForWmuiFile() {
  if [ ! -f "${WMUI_CACHE_HOME}/${1}/${2}" ]; then
    if [ "${WMUI_ONLINE_MODE}" -eq 0 ]; then
      pu_log_e "[commonFunctions.sh:huntForWmuiFile()] - File ${WMUI_CACHE_HOME}/${1}/${2} not found! Will not attempt download, as we are working offline!"
      return 1 # File should exist, but it does not
    fi
    pu_log_i "[commonFunctions.sh:huntForWmuiFile()] - File ${WMUI_CACHE_HOME}/${1}/${2} not found in local cache, attempting download"
    mkdir -p "${WMUI_CACHE_HOME}/${1}"
    pu_log_i "[commonFunctions.sh:huntForWmuiFile()] - Downloading from ${WMUI_HOME_URL}/${1}/${2} ..."
    curl "${WMUI_HOME_URL}/${1}/${2}" --silent -o "${WMUI_CACHE_HOME}/${1}/${2}"
    local RESULT_curl=$?
    if [ ${RESULT_curl} -ne 0 ]; then
      pu_log_e "[commonFunctions.sh:huntForWmuiFile()] - curl failed, code ${RESULT_curl}"
      return 2
    fi
    pu_log_i "[commonFunctions.sh:huntForWmuiFile()] - File ${WMUI_CACHE_HOME}/${1}/${2} downloaded successfully"
  fi
}

# Parameters - applyPostSetupTemplate
# $1 - Setup template directory, relative to <repo_home>/02.templates/02.post-setup
applyPostSetupTemplate() {
  pu_log_i "[commonFunctions.sh:applyPostSetupTemplate()] - Applying post-setup template ${1}"
  huntForWmuiFile "02.templates/02.post-setup/${1}" "apply.sh"
  local RESULT_huntForWmuiFile=$?
  if [ ${RESULT_huntForWmuiFile} -ne 0 ]; then
    pu_log_e "[commonFunctions.sh:applyPostSetupTemplate()] - File ${WMUI_CACHE_HOME}/02.templates/02.post-setup/${1}/apply.sh not found!"
    return 1
  fi
  chmod u+x "${WMUI_CACHE_HOME}/02.templates/02.post-setup/${1}/apply.sh"
  local RESULT_chmod=$?
  if [ ${RESULT_chmod} -ne 0 ]; then
    pu_log_w "[commonFunctions.sh:applyPostSetupTemplate()] - chmod command for apply.sh failed. This is not always a problem, continuing"
  fi
  pu_log_i "[commonFunctions.sh:applyPostSetupTemplate()] - Calling apply.sh for template ${1}"
  #controlledExec "${WMUI_CACHE_HOME}/02.templates/02.post-setup/${1}/apply.sh" "PostSetupTemplateApply"
  "${WMUI_CACHE_HOME}/02.templates/02.post-setup/${1}/apply.sh"
  local RESULT_apply=$?
  if [ ${RESULT_apply} -ne 0 ]; then
    pu_log_e "[commonFunctions.sh:applyPostSetupTemplate()] - Application of post-setup template ${1} failed, code ${RESULT_apply}"
    return 3
  fi
  pu_log_i "[commonFunctions.sh:applyPostSetupTemplate()] - Post setup template ${1} applied successfully"
}

# Common utility functions have been moved to posix-shell-utils
# Use pu_log_env_filtered, pu_debug_suspend, pu_read_secret_from_user, pu_str_substitute instead

commonFunctionsSourced() {
  return 0
}

# Note: Logging functions have been moved to posix-shell-utils
# The framework now uses pu_log_* functions

# parse_yaml - Function to load env variables from a yaml file
# Parameters
# $1 - file to parse
# $2 - OPTIONAL - PREFIX
# Credits: https://gist.github.com/pkuczynski/8665367
parse_yaml() {

  local prefix="$2"
  local s='[[:space:]]*'
  local w='[a-zA-Z0-9_]*'
  local fs
  fs="$(echo @|tr @ '\034')"

  # shellcheck disable=SC2086
  sed "h;s/^[^:]*//;x;s/:.*$//;y/-/_/;G;s/\n//" $1 |
  sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" |
  awk -F"$fs" '{
    indent = length($1)/2;
    vname[indent] = $2;

    for (i in vname) {if (i > indent) {delete vname[i]}}
    if (length($3) > 0) {
        vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
        printf("export %s%s%s=\"%s\"\n", "'"$prefix"'",vn, $2, $3);
    }
  }'
}

# Function to load WMUI environment variables from a yaml file
# Parameters
# $1 - yaml file containing WMUI variables
load_env_from_yaml(){
  # shellcheck disable=SC2046
  eval $(parse_yaml "${1}" WMUI_)
}

# Parameters
# $1 - a csv string
# $2 - comma character, default is ","
csvStringToLines(){
  local commaChar="${2:-,}"
  echo "$1" | tr "$commaChar" '\n'
}

# Parameters
# $1 - a text file containing lines
# $2 - comma character, default is ","
linesFileToCsvString(){
  if [ ! -f "$1" ]; then
    pu_log_e "[commonFunctions.sh::linesFileToCsvString()] - File not found: \"$1\""
  fi
  local commaChar="${2:-,}"
  local firstLine=1
  while read -r in; do
    if [ $firstLine -eq 1 ]; then
      firstLine=0
    else
      printf '%s' "$commaChar"
    fi
    printf '%s' "$in"
  done < "$1"
}