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

# Almost everywhere /bin/sh is actually a symlink. This instruction gives us the actual shell
WMUI_CURRENT_SHELL=$(readlink /proc/$$/exe)
export WMUI_CURRENT_SHELL

## Framework variables
# Convention: all variables from this framework are prefixed with WMUI_
# Variables defaults are specified in the init function
# client projects should source their variables with en .env file

initAuditSession() {
  export WMUI_AUDIT_BASE_DIR="${WMUI_AUDIT_BASE_DIR:-/tmp}"
  WMUI_SESSION_TIMESTAMP="${WMUI_SESSION_TIMESTAMP:-$(date +%Y-%m-%dT%H.%M.%S_%3N)}"
  export WMUI_SESSION_TIMESTAMP
  export WMUI_AUDIT_SESSION_DIR="${WMUI_AUDIT_BASE_DIR}/${WMUI_SESSION_TIMESTAMP}"
  mkdir -p "${WMUI_AUDIT_SESSION_DIR}"
  return $?
}

init() {
  initAuditSession || return $?

  # For internal dependency checks,
  export WMUI_DEBUG_ON="${WMUI_DEBUG_ON:-0}"
  export WMUI_LOG_TOKEN="${WMUI_LOG_TOKEN:-WMUI}"
  # by default, we assume we are working connected to internet, put this on 0 for offline installations
  export WMUI_ONLINE_MODE="${WMUI_ONLINE_MODE:-1}"
  # enable colorized output on stdout, 0=no colors, 1=colors enabled
  export WMUI_COLORIZED_OUTPUT="${WMUI_COLORIZED_OUTPUT:-0}"

  if [ "${WMUI_ONLINE_MODE}" -eq 0 ]; then
    # in offline mode the caller MUST provide the home folder for WMUI in the env var WMUI_HOME
    if [ ! -f "${WMUI_HOME}/01.scripts/commonFunctions.sh" ]; then
      return 104
    else
      export WMUI_CACHE_HOME="${WMUI_HOME}" # we already have everything
    fi
  else
    # by default use master branch
    export WMUI_HOME_URL="${WMUI_HOME_URL:-"https://raw.githubusercontent.com/SoftwareAG/sag-unattended-installations/main"}"
    export WMUI_CACHE_HOME="${WMUI_CACHE_HOME:-"/tmp/wmuiCacheHome"}"
    mkdir -p "${WMUI_CACHE_HOME}"
  fi

  # SUPPRESS_STDOUT means we will not produce STD OUT LINES
  # Normally we want the see the output when we prepare scripts, and suppress it when we finished
  export WMUI_SUPPRESS_STDOUT="${WMUI_SUPPRESS_STDOUT:-0}"

  # Color constants for output (ANSI escape codes)
  if [ "${WMUI_COLORIZED_OUTPUT}" -ne 0 ]; then
    export WMUI_COLOR_RESET='\033[0m'
    export WMUI_COLOR_INFO='\033[0;36m'     # Cyan for INFO
    export WMUI_COLOR_WARN='\033[0;33m'     # Yellow for WARN
    export WMUI_COLOR_ERROR='\033[0;31m'    # Red for ERROR
    export WMUI_COLOR_DEBUG='\033[0;35m'    # Magenta for DEBUG
  else
    export WMUI_COLOR_RESET=''
    export WMUI_COLOR_INFO=''
    export WMUI_COLOR_WARN=''
    export WMUI_COLOR_ERROR=''
    export WMUI_COLOR_DEBUG=''
  fi
}

# all log functions receive 1 parameter
# $1 - Message to log

logI() {
  if [ "${WMUI_SUPPRESS_STDOUT}" -eq 0 ]; then 
    printf "%b%s%b\n" "${WMUI_COLOR_INFO}" "$(date +%H%M%S)|${WMUI_LOG_TOKEN}|I|${1}" "${WMUI_COLOR_RESET}"
  fi
  echo "$(date +%H%M%S)|${WMUI_LOG_TOKEN}|I|${1}" >>"${WMUI_AUDIT_SESSION_DIR}/session.log"
}

logW() {
  if [ "${WMUI_SUPPRESS_STDOUT}" -eq 0 ]; then 
    printf "%b%s%b\n" "${WMUI_COLOR_WARN}" "$(date +%H%M%S)|${WMUI_LOG_TOKEN}|W|${1}" "${WMUI_COLOR_RESET}"
  fi
  echo "$(date +%H%M%S)|${WMUI_LOG_TOKEN}|W|${1}" >>"${WMUI_AUDIT_SESSION_DIR}/session.log"
}

logE() {
  if [ "${WMUI_SUPPRESS_STDOUT}" -eq 0 ]; then 
    printf "%b%s%b\n" "${WMUI_COLOR_ERROR}" "$(date +%H%M%S)|${WMUI_LOG_TOKEN}|E|${1}" "${WMUI_COLOR_RESET}"
  fi
  echo "$(date +%H%M%S)|${WMUI_LOG_TOKEN}|E|${1}" >>"${WMUI_AUDIT_SESSION_DIR}/session.log"
}

logD() {
  if [ "${WMUI_DEBUG_ON}" -ne 0 ]; then
    if [ "${WMUI_SUPPRESS_STDOUT}" -eq 0 ]; then 
      printf "%b%s%b\n" "${WMUI_COLOR_DEBUG}" "$(date +%H%M%S)|${WMUI_LOG_TOKEN}|D|${1}" "${WMUI_COLOR_RESET}"
    fi
    echo "$(date +%H%M%S)|${WMUI_LOG_TOKEN}|D|${1}" >>"${WMUI_AUDIT_SESSION_DIR}/session.log"
  fi
}

logEnv() {
  if [ "${WMUI_DEBUG_ON}" -ne 0 ]; then
    if [ "${WMUI_SUPPRESS_STDOUT}" -eq 0 ]; then env | grep WMUI | sort; fi
    env | grep WMUI | sort >>"${WMUI_AUDIT_SESSION_DIR}/session.log"
  fi
}

logFullEnv() {
  if [ "${WMUI_DEBUG_ON}" -ne 0 ]; then
    if [ "${WMUI_SUPPRESS_STDOUT}" -eq 0 ]; then env | sort; fi
    env | grep WMUI | sort >>"${WMUI_AUDIT_SESSION_DIR}/session.log"
  fi
}

init || exit $?

logI "New Session initialized WMUI_AUDIT_SESSION_DIR=${WMUI_AUDIT_SESSION_DIR}"

# Convention:
# f() function creates a RESULT_f variable for the outcome
# if not otherwise specified, 0 means success

controlledExec() {
  # Param $1 - command to execute in a controlled manner
  # Param $2 - tag for trace files
  local lCrtEpoch
  lCrtEpoch="$(date +%s)"
  eval "${1}" >"${WMUI_AUDIT_SESSION_DIR}/controlledExec_${lCrtEpoch}_${2}.out" 2>"${WMUI_AUDIT_SESSION_DIR}/controlledExec_${lCrtEpoch}_${2}.err"
  return $?
}

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

portIsReachable2() {
  # Params: $1 -> host $2 -> port
  if [ -f /usr/bin/nc ]; then
    # shellcheck disable=SC2086
    nc -z ${1} ${2} # e.g. alpine image
  else
    # shellcheck disable=SC3025,SC2086
    (echo >/dev/tcp/${1}/${2}) >/dev/null 2>&1 # e.g. centos image
  fi
  return $?
}

# Wait for another service to open a certain port
# Params:
# $1 -> host
# $2 -> port
# $3 -> OPTIONAL - maximum trials number, default is 30
# $4 -> OPTIONAL - sleep time between retries, in seconds, default is 5
waitForExternalServicePort() {
  local count=0
  local maxCount="${3:-30}"
  local sleepSeconds="${4:-5}"
  until portIsReachable2 "$1" "$2"; do
    logI "Waiting for port $2 to be open on host $1 ..."
    sleep "$sleepSeconds"
    count=$((count + 1))
    if [ "$count" -ge "$maxCount" ]; then
      logW "The port $2 on host $1 is not reachable after the maximum number of retries of $maxCount"
      return 1
    fi
  done
}

# New urlencode approach, to render the script more portable
# Code taken from https://stackoverflow.com/questions/38015239/url-encoding-a-string-in-shell-script-in-a-portable-way
urlencodepipe() {
  local LANG=C
  local c
  while IFS= read -r c; do
    # shellcheck disable=SC2059
    case $c in [a-zA-Z0-9.~_-])
      printf "$c"
      continue
      ;;
    esac
    # shellcheck disable=SC2059
    printf "$c" | od -An -tx1 | tr ' ' % | tr -d '\n'
  done <<EOF
$(fold -w1)
EOF
  echo
}

# shellcheck disable=SC2059
urlencode() { printf "$*" | urlencodepipe; }

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
      logE "[commonFunctions.sh:huntForWmuiFile()] - File ${WMUI_CACHE_HOME}/${1}/${2} not found! Will not attempt download, as we are working offline!"
      return 1 # File should exist, but it does not
    fi
    logI "[commonFunctions.sh:huntForWmuiFile()] - File ${WMUI_CACHE_HOME}/${1}/${2} not found in local cache, attempting download"
    mkdir -p "${WMUI_CACHE_HOME}/${1}"
    logI "[commonFunctions.sh:huntForWmuiFile()] - Downloading from ${WMUI_HOME_URL}/${1}/${2} ..."
    curl "${WMUI_HOME_URL}/${1}/${2}" --silent -o "${WMUI_CACHE_HOME}/${1}/${2}"
    local RESULT_curl=$?
    if [ ${RESULT_curl} -ne 0 ]; then
      logE "[commonFunctions.sh:huntForWmuiFile()] - curl failed, code ${RESULT_curl}"
      return 2
    fi
    logI "[commonFunctions.sh:huntForWmuiFile()] - File ${WMUI_CACHE_HOME}/${1}/${2} downloaded successfully"
  fi
}

# Parameters - applyPostSetupTemplate
# $1 - Setup template directory, relative to <repo_home>/02.templates/02.post-setup
applyPostSetupTemplate() {
  logI "[commonFunctions.sh:applyPostSetupTemplate()] - Applying post-setup template ${1}"
  huntForWmuiFile "02.templates/02.post-setup/${1}" "apply.sh"
  local RESULT_huntForWmuiFile=$?
  if [ ${RESULT_huntForWmuiFile} -ne 0 ]; then
    logE "[commonFunctions.sh:applyPostSetupTemplate()] - File ${WMUI_CACHE_HOME}/02.templates/02.post-setup/${1}/apply.sh not found!"
    return 1
  fi
  chmod u+x "${WMUI_CACHE_HOME}/02.templates/02.post-setup/${1}/apply.sh"
  local RESULT_chmod=$?
  if [ ${RESULT_chmod} -ne 0 ]; then
    logW "[commonFunctions.sh:applyPostSetupTemplate()] - chmod command for apply.sh failed. This is not always a problem, continuing"
  fi
  logI "[commonFunctions.sh:applyPostSetupTemplate()] - Calling apply.sh for template ${1}"
  #controlledExec "${WMUI_CACHE_HOME}/02.templates/02.post-setup/${1}/apply.sh" "PostSetupTemplateApply"
  "${WMUI_CACHE_HOME}/02.templates/02.post-setup/${1}/apply.sh"
  local RESULT_apply=$?
  if [ ${RESULT_apply} -ne 0 ]; then
    logE "[commonFunctions.sh:applyPostSetupTemplate()] - Application of post-setup template ${1} failed, code ${RESULT_apply}"
    return 3
  fi
  logI "[commonFunctions.sh:applyPostSetupTemplate()] - Post setup template ${1} applied successfully"
}

logEnv4Debug() {
  logD "[commonFunctions.sh:logEnv4Debug()] - Dumping environment variables for debugging purposes"

  if [ "${WMUI_DEBUG_ON}" -ne 0 ]; then
    if [ "${WMUI_SUPPRESS_STDOUT}" -eq 0 ]; then
      env | grep WMUI_ | grep -v PASS | grep -vi password | grep -vi dbpass | sort
    fi
    echo env | grep WMUI_ | grep -v PASS | grep -vi password | grep -vi dbpass | sort >>"${WMUI_AUDIT_SESSION_DIR}/session.log"
  fi
}

debugSuspend() {
  if [ "${WMUI_DEBUG_ON}" -ne 0 ]; then
    logD "[commonFunctions.sh:debugSuspend()] - Suspending for debug"
    tail -f /dev/null
  fi
}

# Rewritten for portability
# code inspired from https://stackoverflow.com/questions/3980668/how-to-get-a-password-from-a-shell-script-without-echoing
readSecretFromUser() {
  stty -echo
  secret="0"
  local s1 s2
  while [ "${secret}" = "0" ]; do
    printf "Please input %s: " "${1}"
    read -r s1
    printf "\n"
    printf "Please input %s again: " "${1}"
    read -r s2
    printf "\n"
    if [ "${s1}" = "${s2}" ]; then
      secret=${s1}
    else
      echo "Input do not match, retry"
    fi
    unset s1 s2
  done
  stty echo
}

# POSIX string substitution
# Parameters
# $1 - original string
# $2 - charset what to substitute
# $3 - replacement charset
# ATTN: works char by char, not with substrings
strSubstPOSIX() {
  # shellcheck disable=SC2086
  printf '%s' "$1" | tr $2 $3
}

commonFunctionsSourced() {
  return 0
}

logI "[commonFunctions.sh] - SLS common framework functions initialized. Current shell is ${WMUI_CURRENT_SHELL}"

if [ ! "${WMUI_CURRENT_SHELL}" = "/usr/bin/bash" ]; then
  logW "[commonFunctions.sh] - This framework has not been tested with this shell. Scripts are not guaranteed to work as expected"
fi

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
    logE "[commonFunctions.sh::linesFileToCsvString()] - File not found: \"$1\""
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