#!/bin/sh

# Section 1 - the caller MUST provide
# (Database connection variables are checked in 02-check-prerequisites.sh)

# Section 2 - the caller MAY provide
export WMUI_WMSCRIPT_HostName="${WMUI_WMSCRIPT_HostName:-localhost}"
export WMUI_WMSCRIPT_InstallDir="${WMUI_WMSCRIPT_InstallDir:-/opt/webmethods}"

export WMUI_WMSCRIPT_adminPassword="${WMUI_WMSCRIPT_adminPassword:-manage}"
export WMUI_WMSCRIPT_IntegrationServerdiagnosticPort="${WMUI_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}"
export WMUI_WMSCRIPT_IntegrationServerPort="${WMUI_WMSCRIPT_IntegrationServerPort:-5555}"
export WMUI_WMSCRIPT_IntegrationServersecurePort="${WMUI_WMSCRIPT_IntegrationServersecurePort:-5553}"
export WMUI_WMSCRIPT_YAIHttpPort="${WMUI_WMSCRIPT_YAIHttpPort:-9072}"
export WMUI_WMSCRIPT_YAIHttpsPort="${WMUI_WMSCRIPT_YAIHttpsPort:-9073}"

export TaskEngineRuntimeConnectionName="${TaskEngineRuntimeConnectionName:-CDS}"

WMUI_WMSCRIPT_TaskEngineRuntimeDriverName=${WMUI_WMSCRIPT_TaskEngineRuntimeDriverName:-6,0,1,2,3,4,5_,Oracle,SQL+Server,DB2+for+Linux%2C+UNIX%2C+Windows,MySQL+Community+Edition,MySQL+Enterprise+Edition,PostgreSQL}
# Example and default value for postgres
# 6,0,1,2,3,4,5_,Oracle,SQL+Server,DB2+for+Linux%2C+UNIX%2C+Windows,MySQL+Community+Edition,MySQL+Enterprise+Edition,PostgreSQL
# Example value for oracle
# 6,0_,1,2,3,4,5,Oracle,SQL+Server,DB2+for+Linux%2C+UNIX%2C+Windows,MySQL+Community+Edition,MySQL+Enterprise+Edition,PostgreSQL

# Section 3 - Computed values
# (none currently)

# Section 4 - Constants
export WMUI_CURRENT_SETUP_TEMPLATE_PATH="APIGateway/1101/cds-e2e"

pu_log_i "[/agw/1101/cds-e2e/01-set-env-defaults] Template environment sourced successfully, environment below"
wmui_log_wmscript_env

# Made with Bob
