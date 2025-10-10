#!/bin/sh

## User MUST provide
## Note: this assumes Update Manager v11 is already installed
export WMUI_SUM_HOME=${WMUI_SUM_HOME:-"/opt/sag/sum"}
export WMUI_PATCH_FIXES_IMAGE_FILE=${WMUI_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

## User MAY provide
## the commonsFunctions.sh must be present
export WMUI_CACHE_HOME=${WMUI_CACHE_HOME:-"/tmp/suifCacheHome"}
export WMUI_INSTALL_INSTALL_DIR=${WMUI_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export WMUI_ENG_PATCH_MODE=${WMUI_ENG_PATCH_MODE:-"N"}

## USER MUST provide if WMUI_ENG_PATCH_MODE="Y"
export WMUI_ENG_PATCH_DIAGS_KEY=${WMUI_ENG_PATCH_DIAGS_KEY:-""}