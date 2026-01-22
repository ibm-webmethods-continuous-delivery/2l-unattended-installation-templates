#!/bin/sh

# shellcheck disable=SC3043

# BREAKING CHANGE: Now requires posix-shell-utils
# IMPORTANT: PU_* variables must be set BEFORE sourcing PU (they are constants)

# Set up PU_HOME
PU_HOME="${PU_HOME:-${WMUI_HOME}/../../2l-posix-shell-utils}"
export PU_HOME

if [ ! -f "${PU_HOME}/code/1.init.sh" ]; then
  echo "ERROR: posix-shell-utils not found at ${PU_HOME}/code/1.init.sh"
  echo "Please set PU_HOME environment variable"
  exit 1
fi

# Configure PU (only if not already set - PU_* are constants)
PU_ONLINE_MODE="${PU_ONLINE_MODE:-true}"
export PU_ONLINE_MODE
PU_DEBUG_MODE="${PU_DEBUG_MODE:-false}"
export PU_DEBUG_MODE
PU_COLORED_MODE="${PU_COLORED_MODE:-false}"
export PU_COLORED_MODE
PU_INIT_COMMON="${PU_INIT_COMMON:-true}"
export PU_INIT_COMMON
PU_INIT_NETWORK="${PU_INIT_NETWORK:-true}"
export PU_INIT_NETWORK
PU_INIT_STRING="${PU_INIT_STRING:-true}"
export PU_INIT_STRING

# Source posix-shell-utils (reads PU_* constants)
# shellcheck source=/dev/null
. "${PU_HOME}/code/1.init.sh"

# Now source commonFunctions.sh
if [ ! -f "${WMUI_HOME}/01.scripts/commonFunctions.sh" ]; then
  echo "ERROR: commonFunctions.sh not found at ${WMUI_HOME}/01.scripts/commonFunctions.sh"
  exit 1
fi

# shellcheck source=SCRIPTDIR/../commonFunctions.sh
. "${WMUI_HOME}/01.scripts/commonFunctions.sh"

localTestDir=${WMUI_TEST_DIR:-/tmp/WMUI_TESTS}

if [ ! -f "${localTestDir}/shunit2" ]; then
  mkdir -p "${localTestDir}"
  curl https://raw.githubusercontent.com/kward/shunit2/master/shunit2 -o "${localTestDir}"/shunit2
fi

testUrlEncode1(){
  str='a/c'
  encstr=$(urlencode "$str")
  assertEquals "$encstr" 'a%2fc'
}

# shellcheck source=/dev/null
. "${localTestDir}"/shunit2