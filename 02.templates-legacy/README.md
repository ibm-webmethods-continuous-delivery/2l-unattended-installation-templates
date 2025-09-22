# Templates for Unattended Installations

## Convention

Products version here is always four digits MMmm:

10.5 -> 1005
11.1 -> 1101

### Framework Base Variables and Initialization

The variables specified in this section are always used in every template and managed by the framework "init" function.

The following environment variables will always have to be provided by the caller.

|Environment Variable|Notes|
|-|-|
|WMUI_INSTALL_INSTALLER_BIN|Installer binary|
|WMUI_INSTALL_IMAGE_FILE|Installer products image file|
|WMUI_PATCH_AVAILABLE|0 if post-install are not available or not applicable|
|WMUI_PATCH_SUM_BOOTSTRAP_BIN|Software AG Update Manager bootstrap binary|
|WMUI_PATCH_FIXES_IMAGE_FILE|Fixes image file|

The following environment variables may to be provided by the caller, otherwise the framework will use default values.

|Environment Variable|Default Value|Notes|
|-|-|-|
|WMUI_AUDIT_BASE_DIR|/tmp|Audit folder for the framework -> the framework will put here logs and introspection output|
|WMUI_INSTALL_INSTALL_DIR|/opt/sag/products|Where to install the products|
|WMUI_INSTALL_DECLARED_HOSTNAME|localhost|the host name passed during the installation process|
|WMUI_SUM_HOME|/opt/sag/sum|Installation folder for Software AG Update Manager, must be different than the products intallation folder|
|WMUI_INSTALL_SPM_HTTPS_PORT|9083|Although not always used, it is used frequently, thus initialized by the framework|
|WMUI_INSTALL_SPM_HTTP_PORT|9082|Although not always used, it is used frequently, thus initialized by the framework|

The following variables MUST always be set by the template accordingly

|Environment Variable|Notes|
|-|-|
|WMUI_CURRENT_SETUP_TEMPLATE_PATH|the template relative path of the current template (e.g. AT/1005%default)|