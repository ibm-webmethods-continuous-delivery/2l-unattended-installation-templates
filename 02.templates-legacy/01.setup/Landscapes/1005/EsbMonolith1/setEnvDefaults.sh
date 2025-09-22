#!/bin/sh

# Section 0 - Framework Import

if ! commonFunctionsSourced 2>/dev/null; then
	if [ ! -f "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
		echo "Panic, common functions not sourced and not present locally! Cannot continue"
		exit 254
	fi
	# shellcheck source=/dev/null
	. "$WMUI_CACHE_HOME/01.scripts/commonFunctions.sh"
fi

if ! setupFunctionsSourced 2>/dev/null; then
	if [ ! -f "${WMUI_CACHE_HOME}/01.scripts/installation/setupFunctions.sh" ]; then
		echo "Panic, setup functions not sourced and not present locally! Cannot continue"
		exit 253
	fi
	# shellcheck source=/dev/null
	. "$WMUI_CACHE_HOME/01.scripts/installation/setupFunctions.sh"
fi

checkSetupTemplateBasicPrerequisites || exit $?

# Section 1 - the caller MUST provide License files

#NUMRealmServer.LicenseFile.text=__VERSION1__,${WMUI_WMSCRIPT_NUMRealmServer_LicenseFile_text_UrlEncoded}
#PrestoLicenseChooser=__VERSION1__,${WMUI_WMSCRIPT_PrestoLicenseChooser_UrlEncoded}

if [ -z "${WMUI_WMSCRIPT_BRMS_LICENSE_FILE+x}" ]; then
	logE "User must provide a variable called WMUI_WMSCRIPT_BRMS_LICENSE_FILE pointing to a valid Business Rules Engine license file local path"
	exit 21
fi
if [ ! -f "${WMUI_WMSCRIPT_BRMS_LICENSE_FILE}" ]; then
	logE "WMUI_WMSCRIPT_BRMS_LICENSE_FILE points to inexistent file ${WMUI_WMSCRIPT_BRMS_LICENSE_FILE}"
	exit 22
fi

if [ -z "${WMUI_WMSCRIPT_integrationServer_LicenseFile+x}" ]; then
	logE "User must provide a variable called WMUI_WMSCRIPT_integrationServer_LicenseFile pointing to a valid IS/MSR license file local path"
	exit 23
fi
if [ ! -f "${WMUI_WMSCRIPT_integrationServer_LicenseFile}" ]; then
	logE "WMUI_WMSCRIPT_integrationServer_LicenseFile points to inexistent file ${WMUI_WMSCRIPT_integrationServer_LicenseFile}"
	exit 24
fi

if [ -z "${WMUI_WMSCRIPT_NUMRealmServer_LicenseFile+x}" ]; then
	logE "User must provide a variable called WMUI_WMSCRIPT_NUMRealmServer_LicenseFile pointing to a valid Universal Messaging license file local path"
	exit 25
fi
if [ ! -f "${WMUI_WMSCRIPT_NUMRealmServer_LicenseFile}" ]; then
	logE "WMUI_WMSCRIPT_NUMRealmServer_LicenseFile points to inexistent file ${WMUI_WMSCRIPT_NUMRealmServer_LicenseFile}"
	exit 26
fi

if [ -z "${WMUI_WMSCRIPT_PrestoLicenseChooser_LICENSE_FILE+x}" ]; then
	logE "User must provide a variable called WMUI_WMSCRIPT_PrestoLicenseChooser_LICENSE_FILE pointing to a valid Presto license file local path"
	exit 27
fi
if [ ! -f "${WMUI_WMSCRIPT_PrestoLicenseChooser_LICENSE_FILE}" ]; then
	logE "WMUI_WMSCRIPT_PrestoLicenseChooser_LICENSE_FILE points to inexistent file ${WMUI_WMSCRIPT_PrestoLicenseChooser_LICENSE_FILE}"
	exit 28
fi

WMUI_WMSCRIPT_BRMS_LICENSE_UrlEncoded=$(urlencode "${WMUI_WMSCRIPT_BRMS_LICENSE_FILE}")
export WMUI_WMSCRIPT_BRMS_LICENSE_UrlEncoded
WMUI_WMSCRIPT_integrationServer_LicenseFile_text_UrlEncoded=$(urlencode "${WMUI_WMSCRIPT_integrationServer_LicenseFile}")
export WMUI_WMSCRIPT_integrationServer_LicenseFile_text_UrlEncoded
WMUI_WMSCRIPT_NUMRealmServer_LicenseFile_text_UrlEncoded=$(urlencode "${WMUI_WMSCRIPT_NUMRealmServer_LicenseFile}")
export WMUI_WMSCRIPT_NUMRealmServer_LicenseFile_text_UrlEncoded
WMUI_WMSCRIPT_PrestoLicenseChooser_UrlEncoded=$(urlencode "${WMUI_WMSCRIPT_PrestoLicenseChooser_LICENSE_FILE}")
export WMUI_WMSCRIPT_PrestoLicenseChooser_UrlEncoded

# Section 2 - the caller SHOULD provide database coordinates for IS Core DB
# If not passed, the jdbc pool is initialized with default values and would most probably not work

export WMUI_WMSCRIPT_IntegrationServerDBUser_Name="${WMUI_WMSCRIPT_IntegrationServerDBUser_Name:-webm}"
export WMUI_WMSCRIPT_IntegrationServerDBPass_Name="${WMUI_WMSCRIPT_IntegrationServerDBPass_Name:-webm}"
export WMUI_WMSCRIPT_IntegrationServerPool_Name="${WMUI_WMSCRIPT_IntegrationServerPool_Name:-iscore}"

# composite WMUI_WMSCRIPT_IntegrationServerDBURL_Name_UrlEncoded
# e.g. jdbc:wm:oracle://​<server>:<1521|port>;​serviceName=<value>[;<option>=<value>...]
DB_SERVER_FQDN=${WMUI_SETUP_ISCORE_DB_SERVER_FQDN:-oracle-db-server}
DB_SERVER_PORT=${WMUI_SETUP_ISCORE_DB_SERVER_PORT:-1521}
DB_SERVICE_NAME=${WMUI_SETUP_ISCORE_DB_SERVICE_NAME:-oradbservicename}
DB_CONN_EXTRA_PARAMS=${WMUI_SETUP_ISCORE_DB_CONN_EXTRA_PARAMS:-";"}

WMUI_WMSCRIPT_IntegrationServerDBURL_Name_UrlEncoded=\
$(urlencode \
"jdbc:wm:oracle://${DB_SERVER_FQDN}:${DB_SERVER_PORT};serviceName=${DB_SERVICE_NAME}${DB_CONN_EXTRA_PARAMS}")
export WMUI_WMSCRIPT_IntegrationServerDBURL_Name_UrlEncoded
logD "WMUI_WMSCRIPT_IntegrationServerDBURL_Name_UrlEncoded=||${WMUI_WMSCRIPT_IntegrationServerDBURL_Name_UrlEncoded}||"

# Section 3 - the caller SHOULD provide database coordinates for Central Users DB
# If not passed, the jdbc pool is initialized with default values and would most probably not work

export WMUI_WMSCRIPT_mwsDBUserField="${WMUI_WMSCRIPT_mwsDBUserField:-webm}"
export WMUI_WMSCRIPT_mwsDBPwdField="${WMUI_WMSCRIPT_mwsDBPwdField:-webm}"
export WMUI_WMSCRIPT_mwsNameField="${WMUI_WMSCRIPT_mwsNameField:-mws}"

# composite WMUI_WMSCRIPT_mwsDBURLField_UrlEncoded
# e.g. jdbc:wm:oracle://​<server>:<1521|port>;​serviceName=<value>[;<option>=<value>...]
DB_SERVER_FQDN=${WMUI_SETUP_MWS_DB_SERVER_FQDN:-oracle-db-server}
DB_SERVER_PORT=${WMUI_SETUP_MWS_DB_SERVER_PORT:-1521}
DB_SERVICE_NAME=${WMUI_SETUP_MWS_DB_SERVICE_NAME:-oradbservicename}
DB_CONN_EXTRA_PARAMS=${WMUI_SETUP_MWS_DB_CONN_EXTRA_PARAMS:-";"}

WMUI_WMSCRIPT_mwsDBURLField_UrlEncoded=\
$(urlencode \
"jdbc:wm:oracle://${DB_SERVER_FQDN}:${DB_SERVER_PORT};serviceName=${DB_SERVICE_NAME}${DB_CONN_EXTRA_PARAMS}")
export WMUI_WMSCRIPT_mwsDBURLField_UrlEncoded

logD "WMUI_WMSCRIPT_mwsDBURLField_UrlEncoded=||${WMUI_WMSCRIPT_mwsDBURLField_UrlEncoded}||"

# Section 4 - the caller MAY provide UM Realm Parameters
export WMUI_WMSCRIPT_NUM_Realm_Server_Name_ID="${WMUI_WMSCRIPT_NUM_Realm_Server_Name_ID:-umserver}"
WMUI_WMSCRIPT_NUM_Data_Dir_ID=\
"${WMUI_WMSCRIPT_NUM_Data_Dir_ID:-${WMUI_INSTALL_INSTALL_DIR}/UniversalMessaging/server/umserver}"
WMUI_WMSCRIPT_NUM_Data_Dir_ID_UrlEncoded=$(urlencode \ "${WMUI_WMSCRIPT_NUM_Data_Dir_ID}")
export WMUI_WMSCRIPT_NUM_Data_Dir_ID_UrlEncoded

# Section 5 - the caller MAY provide PORTS

## IS/MSR related
export WMUI_WMSCRIPT_IntegrationServerPort="${WMUI_WMSCRIPT_IntegrationServerPort:-5555}"
export WMUI_WMSCRIPT_IntegrationServerdiagnosticPort="${WMUI_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}"
export WMUI_WMSCRIPT_mwsPortField="${WMUI_WMSCRIPT_mwsPortField:-8585}"
export WMUI_WMSCRIPT_NUM_Interface_Port_ID="${WMUI_WMSCRIPT_NUM_Interface_Port_ID:-9000}"
export WMUI_WMSCRIPT_PrestoHTTPPort="${WMUI_WMSCRIPT_PrestoHTTPPort:-8080}"
export WMUI_WMSCRIPT_PrestoShutdownPort="${WMUI_WMSCRIPT_PrestoShutdownPort:-8005}"
export WMUI_WMSCRIPT_SPMHttpPort="${WMUI_WMSCRIPT_SPMHttpPort:-9082}"
export WMUI_WMSCRIPT_SPMHttpsPort="${WMUI_WMSCRIPT_SPMHttpsPort:-9083}"

# Section 6 - Constants

export WMUI_CURRENT_SETUP_TEMPLATE_PATH="Labs/1005/EsbMonolith1"

logI "Template environment sourced successfully"
logEnv4Debug
