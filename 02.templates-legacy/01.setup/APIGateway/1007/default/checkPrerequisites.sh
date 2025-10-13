#!/bin/sh

if ! command -V "logI" 2>/dev/null | grep function >/dev/null; then 
    echo "sourcing commonFunctions.sh again (lost?)"
    if [ ! -f "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue!"
        exit 151
    fi
    . "${WMUI_CACHE_HOME}/01.scripts/commonFunctions.sh"
fi

logI "Checking prerequisites for Elasticsearch installation..."

checkVmMaxMapCount(){
    ## constants 
    local c1=262144 # p1 -> vm.max_map_count

    local p1=$(sysctl "vm.max_map_count" | cut -d " " -f 3)
    if [[ ! $p1 -lt $c1 ]]; then
        logI "vm.max_map_count is adequate ($p1)"
    else
        logE "vm.max_map_count is NOT adequate ($p1)"
        return 1
    fi
}

checkVmMaxMapCount || exit 1 
