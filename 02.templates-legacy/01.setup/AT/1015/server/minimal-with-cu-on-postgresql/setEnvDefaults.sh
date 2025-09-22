#!/bin/sh

if ! command -V "urlencode" 2>/dev/null | grep function >/dev/null; then
  echo "sourcing commonFunctions.sh again (lost?)"
  if [ ! -f "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
    echo "[checkPrerequisites.sh] - Panic, framework issue!"
    exit 151
  fi
  # shellcheck source=SCRIPTDIR/../../../../../01.scripts/commonFunctions.sh
  . "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh"
fi

########### Section 1 - the caller MUST provide

# Licenses
WMUI_WMSCRIPT_integrationServerLicenseFiletext=$(urlencode "${WMUI_SETUP_TEMPLATE_IS_LICENSE_FILE}")
export WMUI_WMSCRIPT_integrationServerLicenseFiletext

WMUI_WMSCRIPT_MFTLicenseFile=$(urlencode "${WMUI_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE}")
export WMUI_WMSCRIPT_MFTLicenseFile

# Integration server "Internal" DB connection
export WMUI_WMSCRIPT_IntegrationServerDBPassName="${WMUI_WMSCRIPT_IntegrationServerDBPassName:-isDbPass}"
export WMUI_WMSCRIPT_IntegrationServerDBUserName="${WMUI_WMSCRIPT_IntegrationServerDBUserName:-isDbUser}"
export WMUI_WMSCRIPT_IntegrationServerPoolName="${WMUI_WMSCRIPT_IntegrationServerPoolName:-isDbConnPool}"
export WMUI_WMSCRIPT_IS_JDBC_CONN_STRING="${WMUI_WMSCRIPT_IS_JDBC_CONN_STRING:-jdbc:wm:postgresql://postgres-server-is:5432;databaseName=isDbName}"
WMUI_WMSCRIPT_IntegrationServerDBURLName=$(urlencode "${WMUI_WMSCRIPT_IS_JDBC_CONN_STRING}")
export WMUI_WMSCRIPT_IntegrationServerDBURLName

# Active Transfer DB connection
export WMUI_WMSCRIPT_ActiveServerPasswordName="${WMUI_WMSCRIPT_ActiveServerPasswordName:-atsDbPass}"
export WMUI_WMSCRIPT_ActiveServerPoolName="${WMUI_WMSCRIPT_ActiveServerPoolName:-atsDbConnPool}"
export WMUI_WMSCRIPT_ActiveServerUserName="${WMUI_WMSCRIPT_ActiveServerUserName:-atsDbUser}"
export WMUI_WMSCRIPT_ATS_JDBC_CONN_STRING="${WMUI_WMSCRIPT_ATS_JDBC_CONN_STRING:-jdbc:wm:postgresql://postgres-server-ats:5432;databaseName=atsDbName}"
WMUI_WMSCRIPT_ActiveServerUrlName=$(urlencode "${WMUI_WMSCRIPT_ATS_JDBC_CONN_STRING}")
export WMUI_WMSCRIPT_ActiveServerUrlName

# Central Directory Services Connection
export WMUI_WMSCRIPT_CDSConnectionName="${WMUI_WMSCRIPT_CDSConnectionName:-cdsConnection}"
export WMUI_WMSCRIPT_CDSPasswordName="${WMUI_WMSCRIPT_CDSPasswordName:-cdsPassword}"
export WMUI_WMSCRIPT_CDSUserName="${WMUI_WMSCRIPT_CDSUserName:-cdsUser}"
export WMUI_WMSCRIPT_CDS_JDBC_CONN_STRING="${WMUI_WMSCRIPT_CDS_JDBC_CONN_STRING:-jdbc:wm:postgresql://postgres-server-cds:5432;databaseName=cdsDbName}"
WMUI_WMSCRIPT_CDSUrlName=$(urlencode "${WMUI_WMSCRIPT_CDS_JDBC_CONN_STRING}")
export WMUI_WMSCRIPT_CDSUrlName=
########### Section 1 END - the caller MUST provide

########### Section 2 - the caller MAY provide
## Framework - Install
export WMUI_INSTALL_INSTALL_DIR="${WMUI_INSTALL_INSTALL_DIR:-/opt/sag/products}"
export WMUI_INSTALL_DECLARED_HOSTNAME="${WMUI_INSTALL_DECLARED_HOSTNAME:-localhost}"
## Framework - Patch
export WMUI_SUM_HOME="${WMUI_SUM_HOME:-/opt/sag/sum}"

# Integration Server Administrator password
export WMUI_WMSCRIPT_adminPassword="${WMUI_WMSCRIPT_adminPassword:-Manage01}"

# Integration Server Ports
export WMUI_WMSCRIPT_IntegrationServerdiagnosticPort="${WMUI_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}"
export WMUI_WMSCRIPT_IntegrationServerPort="${WMUI_WMSCRIPT_IntegrationServerPort:-5555}"
export WMUI_WMSCRIPT_IntegrationServersecurePort="${WMUI_WMSCRIPT_IntegrationServersecurePort:-5543}"

# SPM Ports
export WMUI_WMSCRIPT_SPMHttpPort="${WMUI_WMSCRIPT_SPMHttpPort:-8092}"
export WMUI_WMSCRIPT_SPMHttpsPort="${WMUI_WMSCRIPT_SPMHttpsPort:-8093}"

# Active Transfer Port
export WMUI_WMSCRIPT_mftGWPortField="${WMUI_WMSCRIPT_mftGWPortField:-8500}"
########### Section 2 END - the caller MAY provide

logI "Template environment sourced successfully"
logEnv4Debug
