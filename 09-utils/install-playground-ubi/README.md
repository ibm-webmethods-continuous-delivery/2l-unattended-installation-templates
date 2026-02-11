# Installer Playground Helper based on UBI image

This project is provided to help the user create new setup templates, specifically for generating the scripts for installation.

## Usage

- Copy `EXAMPLE.env` into `.env` and provide the required variables
- Start an instance by issuing:

```sh
docker-compose up
```

- Start a separate shell in the container:

```sh
docker exec -ti install-playground-ubi bash
```


- Launch the installer and pick your desired configuration

```sh
/tmp/installer.bin \
-installDir ${WMUI_WMSCRIPT_InstallDir} \
-writeScript ${WMUI_TEST_ARTIFACTS_DIR}/some/path/yourTemplateNameHere.wmscript
```

- After all choices are made and immediately before the actual installation, installer writes the script file. Watch for the destination, when the file is created exit the installer. This moment may also be identified with the wizard step where you can see 

```sh
The products listed below are ready to be saved to script ${WMUI_TEST_ARTIFACTS_DIR}/some/path/yourTemplateNameHere.wmscript and installed.
```

- This procedure is supposed to be run online.

- Continue with the authoring of the output file by moving the lines containing variables from their original position to the bottom of the file and substituting the actual values with variable names. Example

```sh
#Template variables
imageFile=${WMUI_WMSCRIPT_imageFile}
InstallDir=${WMUI_WMSCRIPT_InstallDir}
```

Installer also accepts a "LATEST" version of the components. To achieve this, run:

```sh
cd ${WMUI_TEST_SCRIPTS_DIR}/
./setLatestVerForProducts.sh # implicit file is /mnt/output/yourTemplateNameHere.wmscript
# or
./setLatestVerForProducts.sh /path/to/install.wmscript
```
