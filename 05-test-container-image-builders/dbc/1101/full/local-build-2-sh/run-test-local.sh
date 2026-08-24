#!/bin/sh

# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0

. ./set-env.sh

mkdir -p build_context

cp "../../../../../04-container-image-builders/${CONTAINER_BUILDER_TEMPLATE}/alpine/Dockerfile" build_context/
cp "../../../../../01-scripts/local-install.sh" build_context/local-install.sh

cp "${INSTALLER_BIN}"     build_context/installer.bin
cp "${SUM_BOOTSTRAP_BIN}" build_context/upd-mgr-bootstrap.bin
cp "${PRODUCTS_ZIP}"      build_context/products.zip
cp "${FIXES_ZIP}"         build_context/fixes.zip

cd build_context || exit 1

ls -la

docker buildx build \
  --platform linux/amd64 \
  --build-arg __wm_install_template="${INSTALL_TEMPLATE}" \
  --build-arg __pu_tag="${PU_TAG}" \
  --build-arg __wmui_tag="${WMUI_TAG}" \
  -t "${CONTAINER_IMAGE}" .

cd ..

rm -f build_context/*
rmdir build_context
