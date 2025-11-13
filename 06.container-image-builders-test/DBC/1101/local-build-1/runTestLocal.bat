@echo off

call .\setEnv.bat

md build_context

copy ..\..\..\..\05.container-image-builders\%CONTAINER_BUILDER_TEMPLATE%\alpine\Dockerfile build_context\
copy ..\..\..\..\05.container-image-builders\%CONTAINER_BUILDER_TEMPLATE%\alpine\*.sh build_context\

COPY "%INSTALLER_BIN%" build_context\installer.bin
COPY "%SUM_BOOTSTRAP_BIN%" build_context\upd-mgr-bootstrap.bin
COPY "%PRODUCTS_ZIP%" build_context\products.zip
COPY "%FIXES_ZIP%" build_context\fixes.zip

cd build_context

dir

docker buildx build ^
--build-arg __wm_install_template=%INSTALL_TEMPLATE% ^
--build-arg __wmui_tag=%WMUI_TAG% ^
-t %CONTAINER_IMAGE% .

cd ..

del /q build_context\*

rd /q build_context
