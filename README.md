# IBM webMethods Unattended Installation Assets

- [IBM webMethods Unattended Installation Assets](#ibm-webmethods-unattended-installation-assets)
  - [Quick Start](#quick-start)
  - [Folders](#folders)
    - [01.scripts](#01scripts)
    - [02.templates](#02templates)
      - [02.templates.01.setup](#02templates01setup)
      - [02.templates.02.post-setup](#02templates02post-setup)
    - [03.test](#03test)
    - [09.utils](#09utils)
  - [Acknowledgements](#acknowledgements)

Collection of scripts to be "curled" during unattended cloud installations for IBM webMethods products.

## Quick Start

**Important**: All files MUST have unix style end lines even when using docker desktop for Windows. Before cloning, ensure that the clone command will preserve the unix end lines even if you ar cloning from Windows:

```bat
git config --global core.autocrlf input
```

After cloning, depending on the the user situation and inbound file properties, the files might not have the desired properties.

In order to set properties, for example the executable flag on .sh files, look at the utility `09.utils/alpine-set-executable-4-sh`.

For a more specific example, where `jcode.sh` Integration Server compiling tool must have access to package folders, see the instructions [here](https://github.com/ibm-webmethods-continuous-delivery/5s-pub-sub-with-mon-01/blob/main/02.build/README.md#procedures) and eventually adapt for your specific situation.

Then, the user may immediately obtain the installation and patching binary files by using one of the test harnesses in `03.test\framework\assureBinaries`, for example  `03.test\framework\assureBinaries\alpine`.

According to the user purpose, the next step is about downloading the product binaries. Use tha harnesses in folder `03.test/framework/BuildZipImages` to download the necessary images, according to the templates of interest. 

## Folders

### 01.scripts

Contain the scripting assets for this repository. This is the core of the overall project.

### 02.templates

Contains templates for installations which leverage the core functions in the scripting assets. These are further divided in

#### 02.templates.01.setup

Setup templates are organized in a hierarchical folder structure under [02.templates/01.setup](02.templates/01.setup). Each template is identified by its relative path from this base directory and must contain a [`template.wmscript`](02.templates/01.setup/APIGateway/1101/wpm-e2e-cu-postgres/template.wmscript) file.

**Template Structure:**
- **Template ID**: The relative path from `02.templates/01.setup/` to the folder containing `template.wmscript`
- **Template Files**: Each template folder contains:
  - `template.wmscript` - Core installation script (required)
  - `ProductsLatestList.txt` or `ProductsVersionedList.txt` - Product lists (required)
  - `setEnvDefaults.sh` - Default environment variables (optional)
  - `checkPrerequisites.sh` - Prerequisites validation script (optional)
  - Installer view files - Configuration for installer interface (optional)

**Examples:**
- Template ID: `APIGateway/1101/default` → Located at `02.templates/01.setup/APIGateway/1101/default/template.wmscript`
- Template ID: `APIGateway/1101/wpm-e2e-cu-postgres` → Located at `02.templates/01.setup/APIGateway/1101/wpm-e2e-cu-postgres/template.wmscript`
- Template ID: `DBC/1101/full` → Located at `02.templates/01.setup/DBC/1101/full/template.wmscript`

#### 02.templates.02.post-setup

Post-setup templates for additional configuration after initial installation.

### 03.test

Contains test harnesses for validating scripts and templates. Test harnesses are organized to mirror the template structure.

**Test Harness Naming Convention:**
- Each template can have multiple test harnesses
- Test harnesses are located under `03.test/<template-path>/`
- Naming pattern: `wmui-<product>-<version>-test-<number>`

**Examples:**
- Template `APIGateway/1101/default` has test harness: `03.test/APIGateway/1101/default/wmui-agw-1101-test-01/`
- Template `DBC/1101/full` has test harness: `03.test/DBC/wmui-dbc-1101-test-01/`

Each test harness typically contains:
- `docker-compose.yml` - Container orchestration for the test
- `.env` - Environment variables for the test
- `scripts/` - Test-specific scripts and entry points

### 09.utils

Utilities supporting the considered use cases, e.g. a kernel properties setter for Elasticsearch.

## Acknowledgements

This repository is using some other libraries under the hood. These are not copied directly, but may be downloaded on demand at runtime.

These libraries include:

- [shunit2](https://github.com/kward/shunit2) - Apache 2 license [here](https://github.com/kward/shunit2/blob/master/LICENSE)

------------------------------

These tools are provided as-is and without warranty or support. They do not constitute part of the webMethods product suite. Users are free to use, fork and modify them, subject to the license agreement. While we welcome contributions, we cannot guarantee to include every contribution in the master project.

