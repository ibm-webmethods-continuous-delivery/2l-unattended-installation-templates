#!/bin/sh

## User MUST provide
## Note: this assumes Update Manager v11 is already installed
export WMUI_SUM_HOME=${WMUI_SUM_HOME:-"/opt/sag/sum"}
# diagnoserKey e.g. 5437713_PIE-68082_5
export WMUI_ENG_PATCH_DIAGS_KEY=${WMUI_ENG_PATCH_DIAGS_KEY:-"please_provide_WMUI_ENG_PATCH_DIAGS_KEY"}
# fixesId e.g. 5437713_PIE-68082_1.0.0.0005-0001
export WMUI_ENG_PATCH_FIX_ID_LIST=${WMUI_ENG_PATCH_FIX_ID_LIST:-"please_provide_WMUI_ENG_PATCH_FIX_ID"}         # example 

## User MAY provide
## the commonsFunctions.sh must be present
export WMUI_CACHE_HOME=${WMUI_CACHE_HOME:-"/tmp/suifCacheHome"}
export WMUI_INSTALL_INSTALL_DIR=${WMUI_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
