#!/bin/sh

# Section 1 - the caller MUST provide

# Section 2 - the caller MAY provide
export WMUI_WMSCRIPT_adminPassword="${WMUI_WMSCRIPT_adminPassword:-manage}"
export WMUI_WMSCRIPT_HostName="${WMUI_WMSCRIPT_HostName:-localhost}"
export WMUI_WMSCRIPT_InstallDir="${WMUI_WMSCRIPT_InstallDir:-/opt/webmethods}"

## MSR related
export WMUI_WMSCRIPT_IntegrationServerPort="${WMUI_WMSCRIPT_IntegrationServerPort:-5555}"
export WMUI_WMSCRIPT_IntegrationServersecurePort="${WMUI_WMSCRIPT_IntegrationServersecurePort:-5553}"
export WMUI_WMSCRIPT_IntegrationServerdiagnosticPort="${WMUI_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}"

# Section 3 - Computed values

# Section 4 - Constants

export WMUI_CURRENT_SETUP_TEMPLATE_PATH="MSR/1101/simple"

pu_log_i "Template environment sourced successfully"
logEnv4Debug
