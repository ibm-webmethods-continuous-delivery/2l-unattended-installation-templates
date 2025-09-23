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
  - [Important notes](#important-notes)
  - [Acknowledgements](#acknowledgements)

Collection of scripts to be "curled" during unattended cloud installations for IBM webMethods products.

## Quick Start

After cloning, the user may immediately obtain the installation and patching binary files by using the test harness `03.test\framework\assureBinaries\alpine`.

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

## Important notes

- All files must have unix style end lines even when using docker desktop for Windows. Clone accordingly!

## Acknowledgements

This repository is using some other libraries under the hood. These are not copied directly, but may be downloaded on demand at runtime.

These libraries include:

- [shunit2](https://github.com/kward/shunit2) - Apache 2 license [here](https://github.com/kward/shunit2/blob/master/LICENSE)

------------------------------

These tools are provided as-is and without warranty or support. They do not constitute part of the webMethods product suite. Users are free to use, fork and modify them, subject to the license agreement. While we welcome contributions, we cannot guarantee to include every contribution in the master project.

