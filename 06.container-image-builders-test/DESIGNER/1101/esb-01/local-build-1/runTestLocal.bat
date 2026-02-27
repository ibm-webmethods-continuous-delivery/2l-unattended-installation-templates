@echo off

call .\setEnv.bat

md build_context
md build_context\plugins

copy ..\..\..\..\..\05.container-image-builders\%INSTALL_TEMPLATE_win%\ubi-min\Dockerfile build_context\
copy ..\..\..\..\..\05.container-image-builders\%INSTALL_TEMPLATE_win%\ubi-min\*.sh build_context\

COPY "%INSTALLER_BIN%" build_context\installer.bin
COPY "%SUM_BOOTSTRAP_BIN%" build_context\upd-mgr-bootstrap.bin
COPY "%PRODUCTS_ZIP%" build_context\products.zip
COPY "%FIXES_ZIP%" build_context\fixes.zip
COPY "%PLUGINS_PATH%"\* build_context\plugins\

cd build_context

dir

docker buildx build --build-arg __wm_install_template=%INSTALL_TEMPLATE% --build-arg __wmui_tag=%WMUI_TAG% -t %CONTAINER_IMAGE% .

cd ..

del /q build_context\plugins\*
rd /q build_context\plugins

del /q build_context\*
rd /q build_context
