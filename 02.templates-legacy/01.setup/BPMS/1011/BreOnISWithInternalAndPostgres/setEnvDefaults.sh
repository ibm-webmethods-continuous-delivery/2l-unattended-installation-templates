#!/bin/sh

## Installation Directory
export WMUI_WMSCRIPT_InstallDir=${WMUI_WMSCRIPT_InstallDir:-/app/sag/version/products}

## Default install time password
export WMUI_WMSCRIPT_adminPassword=${WMUI_WMSCRIPT_adminPassword:-manage1}

## SPM
export WMUI_WMSCRIPT_SPMHttpPort=${WMUI_WMSCRIPT_SPMHttpPort:-8092}
export WMUI_WMSCRIPT_SPMHttpsPort=${WMUI_WMSCRIPT_SPMHttpsPort:-8093}

## IS Ports
export WMUI_WMSCRIPT_IntegrationServersecurePort=${WMUI_WMSCRIPT_IntegrationServersecurePort:-5543}
export WMUI_WMSCRIPT_IntegrationServerdiagnosticPort=${WMUI_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}
export WMUI_WMSCRIPT_IntegrationServerPort=${WMUI_WMSCRIPT_IntegrationServerPort:-5555}

## BPM / TE DB, wired on Postgres
export WMUI_WMSCRIPT_TaskEngineRuntimeConnectionName=${WMUI_WMSCRIPT_TaskEngineRuntimeConnectionName:-postgresConnectionNameHere}
# jdbc:wm:postgresql://s-db:5432;DatabaseName=dbNameHere
export WMUI_WMSCRIPT_TaskEngineDatabaseUrl=${WMUI_WMSCRIPT_TaskEngineDatabaseUrl:-'jdbc:wm:postgresql://s-db:5432;DatabaseName=dbNameHere'}
export WMUI_WMSCRIPT_TaskEngineRuntimeUrlName=$(urlencode ${WMUI_WMSCRIPT_TaskEngineDatabaseUrl})
export WMUI_WMSCRIPT_TaskEngineRuntimeUserName=${WMUI_WMSCRIPT_TaskEngineRuntimeUserName:-db-user-name-here}
export WMUI_WMSCRIPT_TaskEngineRuntimePasswordName=${WMUI_WMSCRIPT_TaskEngineRuntimePasswordName:-db-pass-here}

## License files
# /tmp/BusinessRules_1011.xml
export WMUI_WMSCRIPT_BRMS_license_file=${WMUI_WMSCRIPT_BRMS_license_file:-/tmp/BusinessRules_1011.xml}
export WMUI_WMSCRIPT_BRMS_license=$(urlencode ${WMUI_WMSCRIPT_BRMS_license_file})
# /tmp/MicroservicesRuntime_100.xml
export WMUI_WMSCRIPT_IS_LICENSE_FILE=${WMUI_WMSCRIPT_IS_LICENSE_FILE:-/tmp/MicroservicesRuntime_100.xml}
export WMUI_WMSCRIPT_integrationServer_LicenseFile_text=$(urlencode ${WMUI_WMSCRIPT_IS_LICENSE_FILE})
