#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#

# false means DB was not created, thus create now
export WMUI_PST_DATABASE_ALREADY_CREATED="${WMUI_PST_DATABASE_ALREADY_CREATED:-false}"
export WMUI_PST_DB_SERVER_PORT="${WMUI_PST_DB_SERVER_PORT:-5432}"
# By default create all components
export WMUI_PST_DBC_COMPONENT_NAME="${WMUI_PST_DBC_COMPONENT_NAME:-All}"
# By default create the latest version
export WMUI_PST_DBC_COMPONENT_VERSION="${WMUI_PST_DBC_COMPONENT_VERSION:-latest}"
