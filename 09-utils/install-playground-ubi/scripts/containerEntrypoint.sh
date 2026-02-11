#!/bin/bash

cp "${WMUI_TEST_INSTALLER_BIN}" /tmp/installer.bin
chmod u+x /tmp/installer.bin

echo "Just stopping, open a shell :)"

echo "Quick run command is"
# shellcheck disable=SC2016
echo '/tmp/installer.bin \
-installDir ${WMUI_WMSCRIPT_InstallDir} \
-writeScript ${WMUI_TEST_ARTIFACTS_DIR}/some/path/yourTemplateNameHere.wmscript'

tail -f /dev/null