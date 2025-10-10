#!/bin/bash


cp "${WMUI_INSTALL_INSTALLER_ARTIFACT}" "${WMUI_INSTALL_INSTALLER_BIN}"
chmod u+x "${WMUI_INSTALL_INSTALLER_BIN}"
echo "Just stopping, open a shell :)"
tail -f /dev/null