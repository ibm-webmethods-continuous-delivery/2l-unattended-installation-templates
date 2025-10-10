#!/bin/sh

if [ ! "`type -t urlencode`X" == "functionX" ]; then
    if [ ! -f "${WMUI_CACHE_HOME}/installationScripts/commonFunctions.sh" ]; then
        echo "Panic, common functions not sourced and not present locally! Cannot continue"
        exit 500
    fi
    . "$WMUI_CACHE_HOME/installationScripts/commonFunctions.sh"
fi

########### Section 1 - the caller MUST provide
## Framework - Install
export WMUI_INSTALL_INSTALLER_BIN=${WMUI_INSTALL_INSTALLER_BIN:-"/path/to/installer.bin"}
export WMUI_INSTALL_IMAGE_FILE=${WMUI_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}

## Framework - Patch
export WMUI_PATCH_SUM_BOOTSTRAP_BIN=${WMUI_PATCH_SUM_BOOTSTRAP_BIN:-"/path/to/sum-boostrap.bin"}
export WMUI_PATCH_FIXES_IMAGE_FILE=${WMUI_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

# Licenses
WMUI_SETUP_TEMPLATE_IS_LICENSE_FILE=${WMUI_SETUP_TEMPLATE_IS_LICENSE_FILE:-'No Is License File Provided'}
export WMUI_WMSCRIPT_integrationServerLicenseFiletext=$(urlencode ${WMUI_SETUP_TEMPLATE_IS_LICENSE_FILE})

WMUI_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE=${WMUI_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE:-'No Active Transfer License File Provided'}
export WMUI_WMSCRIPT_MFTLicenseFile=$(urlencode ${WMUI_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE})

# Integration server "Internal" DB connection
export WMUI_WMSCRIPT_IntegrationServerDBPassName=${WMUI_WMSCRIPT_IntegrationServerDBPassName:-'isDbPass'}
export WMUI_WMSCRIPT_IntegrationServerDBUserName=${WMUI_WMSCRIPT_IntegrationServerDBUserName:-'isDbUser'}
export WMUI_WMSCRIPT_IntegrationServerPoolName=${WMUI_WMSCRIPT_IntegrationServerPoolName:-'isDbConnPool'}
export WMUI_WMSCRIPT_IS_JDBC_CONN_STRING=${WMUI_WMSCRIPT_IS_JDBC_CONN_STRING:-'jdbc:wm:postgresql://postgres-server-is:5432;databaseName=isDbName'}
export WMUI_WMSCRIPT_IntegrationServerDBURLName=$(urlencode ${WMUI_WMSCRIPT_IS_JDBC_CONN_STRING})

# Active Transfer DB connection
export WMUI_WMSCRIPT_ActiveServerPasswordName=${WMUI_WMSCRIPT_ActiveServerPasswordName:-'atsDbPass'}
export WMUI_WMSCRIPT_ActiveServerPoolName=${WMUI_WMSCRIPT_ActiveServerPoolName:-'atsDbConnPool'}
export WMUI_WMSCRIPT_ActiveServerUserName=${WMUI_WMSCRIPT_ActiveServerUserName:-'atsDbUser'}
export WMUI_WMSCRIPT_ATS_JDBC_CONN_STRING=${WMUI_WMSCRIPT_ATS_JDBC_CONN_STRING:-'jdbc:wm:postgresql://postgres-server-ats:5432;databaseName=atsDbName'}
export WMUI_WMSCRIPT_ActiveServerUrlName=$(urlencode ${WMUI_WMSCRIPT_ATS_JDBC_CONN_STRING})

# Central Directory Services Connection
export WMUI_WMSCRIPT_CDSConnectionName=${WMUI_WMSCRIPT_CDSConnectionName:-'cdsConnection'}
export WMUI_WMSCRIPT_CDSPasswordName=${WMUI_WMSCRIPT_CDSPasswordName:-'cdsPassword'}
export WMUI_WMSCRIPT_CDSUserName=${WMUI_WMSCRIPT_CDSUserName:-'cdsUser'}
export WMUI_WMSCRIPT_CDS_JDBC_CONN_STRING=${WMUI_WMSCRIPT_CDS_JDBC_CONN_STRING:-'jdbc:wm:postgresql://postgres-server-cds:5432;databaseName=cdsDbName'}
export WMUI_WMSCRIPT_CDSUrlName=$(urlencode ${WMUI_WMSCRIPT_CDS_JDBC_CONN_STRING})
########### Section 1 END - the caller MUST provide

########### Section 2 - the caller MAY provide
## Framework - Install
export WMUI_INSTALL_INSTALL_DIR=${WMUI_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export WMUI_INSTALL_DECLARED_HOSTNAME=${WMUI_INSTALL_DECLARED_HOSTNAME:-"localhost"}
## Framework - Patch
export WMUI_SUM_HOME=${WMUI_SUM_HOME:-"/opt/sag/sum"}

# Integration Server Administrator password
export WMUI_WMSCRIPT_adminPassword=${WMUI_WMSCRIPT_adminPassword:-'manage01'}

# Integration Server Ports
export WMUI_WMSCRIPT_IntegrationServerdiagnosticPort=${WMUI_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}
export WMUI_WMSCRIPT_IntegrationServerPort=${WMUI_WMSCRIPT_IntegrationServerPort:-5555}
export WMUI_WMSCRIPT_IntegrationServersecurePort=${WMUI_WMSCRIPT_IntegrationServersecurePort:-5543}

# SPM Ports
export WMUI_WMSCRIPT_SPMHttpPort=${WMUI_WMSCRIPT_SPMHttpPort:-8092}
export WMUI_WMSCRIPT_SPMHttpsPort=${WMUI_WMSCRIPT_SPMHttpsPort:-8093}

# Active Transfer Port
export WMUI_WMSCRIPT_mftGWPortField=${WMUI_WMSCRIPT_mftGWPortField:-8500}
########### Section 2 END - the caller MAY provide

logI "Template environment sourced successfully"
logEnv4Debug
