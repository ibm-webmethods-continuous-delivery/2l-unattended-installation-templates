#!/bin/sh
WMUI_WMSCRIPT_HostName=${WMUI_WMSCRIPT_HostName:--localhost}
WMUI_WMSCRIPT_InstallDir=${WMUI_WMSCRIPT_InstallDir:-/opt/webmethods}
pu_log_i "[/dbc/1101/full/01-set-env-defaults] Template environment sourced successfully, environment below"
wmui_log_wmscript_env