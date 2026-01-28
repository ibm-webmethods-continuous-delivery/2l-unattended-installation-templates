# WMUI Functions Reference

## Overview

This document provides a comprehensive reference for all functions in `wmui-functions.sh`, including their parameters, return codes, and required environment variables.

## Table of Contents

- [Environment Variables](#environment-variables)
- [Initialization Functions](#initialization-functions)
- [Utility Functions](#utility-functions)
- [Image Generation Functions](#image-generation-functions)
- [Setup and Installation Functions](#setup-and-installation-functions)
- [Post-Setup Functions](#post-setup-functions)

---

## Environment Variables

### Required Environment Variables

These variables MUST be set by the calling environment before using WMUI functions:

#### Core Framework Variables

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `WMUI_HOME` | Path | WMUI repository home directory (required in offline mode) | None |
| `WMUI_HOME_URL` | URL | GitHub repository URL for online mode | `https://raw.githubusercontent.com/ibm-webmethods-continuous-delivery/2l-unattended-installation-templates/main` |
| `WMUI_ONLINE_MODE` | Boolean | Framework online/offline mode (`true`=online) | `true` |
| `WMUI_PRODUCT_ONLINE_MODE` | Boolean | Product download mode (`true`=online) | `true` |
| `WMUI_TEMP_FS_QUICK` | Path | Fast temporary filesystem (e.g., /dev/shm) | `/dev/shm` |

#### Installation Variables

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `WMUI_INSTALL_INSTALLER_BIN` | Path | Path to webMethods installer binary | `/tmp/WMUI/installer.bin` |
| `WMUI_INSTALL_IMAGE_FILE` | Path | Path to product installation image | None |

#### Patching Variables

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `WMUI_PATCH_AVAILABLE` | Boolean | Whether patches should be applied | `false` |
| `WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN` | Path | Path to Update Manager bootstrap binary | `/tmp/WMUI/umgr-bootstrap.bin` |
| `WMUI_PATCH_FIXES_IMAGE_FILE` | Path | Path to fixes image file | None |
| `WMUI_UPD_MGR_HOME` | Path | Update Manager installation directory | `/opt/wm-umgr` |

#### Credentials (for online operations)

| Variable | Type | Description | Required For |
|----------|------|-------------|--------------|
| `WMUI_DOWNLOAD_USER` | String | Download credentials username | Image generation, online patching |
| `WMUI_DOWNLOAD_PASSWORD` | String | Download credentials password | Image generation, online patching |

#### SDC Server URLs (for specific versions)

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `WMUI_SDC_SERVER_URL_1011` | URL | SDC server for version 10.11 | `https://sdc.webmethods.io/cgi-bin/dataservewebM1011.cgi` |
| `WMUI_SDC_SERVER_URL_1015` | URL | SDC server for version 10.15 | `https://sdc.webmethods.io/cgi-bin/dataservewebM1015.cgi` |
| `WMUI_SDC_SERVER_URL_1101` | URL | SDC server for version 11.01 | `https://sdc.webmethods.io/cgi-bin/dataservewebM111.cgi` |
| `WMUI_SDC_SERVER_URL_DEFAULT` | URL | Default SDC server | `https://sdc.webmethods.io/cgi-bin/dataservewebM111.cgi` |

### Template-Specific Variables

Template wmscript files use environment variables with the `WMUI_WMSCRIPT_` prefix. These are substituted using `envsubst`. Common examples:

| Variable | Description |
|----------|-------------|
| `WMUI_WMSCRIPT_InstallDir` | Installation directory |
| `WMUI_WMSCRIPT_LicenseAgree` | License agreement (Accept/Decline) |
| `WMUI_WMSCRIPT_imageFile` | Path to product image file |

### Internal Framework Variables

These are set by the framework and should not be modified externally:

| Variable | Description |
|----------|-------------|
| `__wmui_cache_home` | Local cache directory for downloaded files |
| `__wmui_online_mode` | Internal online mode flag |
| `__wmui_product_online_mode` | Internal product online mode flag |
| `__wmui_default_*` | Various default values for paths, URLs, and settings |

---

## Initialization Functions

### Function 01: `_init`

**Purpose**: Internal initialization function that sets up the WMUI framework.

**Visibility**: Private (internal use only)

**Parameters**: None

**Return Codes**:
- `0` - Success
- `101` - PU audit module not loaded (prerequisite failure)
- `102` - WMUI_HOME not set or invalid in offline mode

**Side Effects**:
- Sets all `__wmui_default_*` variables
- Exports `__wmui_online_mode`, `__wmui_product_online_mode`, `__wmui_cache_home`, `__wmui_home_url`, `__wmui_temp_fs_quick`
- Creates cache directory in online mode
- Validates WMUI_HOME in offline mode

**Dependencies**:
- Requires PU 2.audit.sh to be sourced first
- Checks for `__2__audit_session_dir` variable

**Notes**:
- Automatically called when wmui-functions.sh is sourced
- Exits the script if initialization fails

---

## Utility Functions

### Function 02: `wmui_hunt_for_file`

**Purpose**: Download a file from the repository if not present locally (online mode only).

**Parameters**:
- `$1` - Relative path to `__wmui_cache_home`
- `$2` - Filename

**Return Codes**:
- `0` - Success (file exists or downloaded successfully)
- `1` - File not found and offline mode (cannot download)
- `2` - curl download failed

**Behavior**:
- **Offline mode**: Returns error if file doesn't exist
- **Online mode**: Downloads file from `__wmui_home_url` if not in cache

**Example**:
```sh
wmui_hunt_for_file "02.templates/01.setup/APIGateway/1101/default" "template.wmscript"
```

---

### Function 03: `wmui_assure_default_installer`

**Purpose**: Ensure the default webMethods installer binary is available, downloading if necessary.

**Parameters**:
- `$1` - OPTIONAL: Installer binary location (default: `${WMUI_INSTALL_INSTALLER_BIN}` or `${__wmui_default_installer_bin}`)

**Return Codes**:
- `0` - Success (installer assured)
- `1` - Failed to assure installer

**Side Effects**:
- Downloads installer if not present (online mode)
- Sets executable permission on installer binary

**Dependencies**:
- Uses `pu_assure_downloadable_file` from PU library
- Validates SHA256 checksum

**Default Values**:
- URL: `https://delivery04.dhe.ibm.com/sar/CMA/OSA/0cx80/2/IBM_webMethods_Install_Linux_x64.bin`
- SHA256: `07ecdff4efe4036cb5ef6744e1a60b0a7e92befed1a00e83b5afe9cdfd6da8d3`

---

### Function 04: `wmui_assure_default_umgr_bin`

**Purpose**: Ensure the default Update Manager bootstrap binary is available.

**Parameters**:
- `$1` - OPTIONAL: Update Manager binary location (default: `${WMUI_INSTALL_INSTALLER_BIN}` or `${__wmui_default_umgr_bin}`)

**Return Codes**:
- `0` - Success (Update Manager binary assured)
- `1` - Failed to assure Update Manager binary

**Side Effects**:
- Downloads Update Manager bootstrap if not present (online mode)
- Sets executable permission on binary

**Default Values**:
- URL: `https://delivery04.dhe.ibm.com/sar/CMA/OSA/0crqw/0/IBM_webMethods_Update_Mnger_Linux_x64.bin`
- SHA256: `a997a690c00efbb4668323d434fa017a05795c6bf6064905b640fa99a170ff55`

---

### Function 05: `wmui_generate_inventory_from_products_list`

**Purpose**: Generate a JSON inventory file from a products list file for Update Manager.

**Parameters**:
- `$1` - Input file path (products list file)
- `$2` - Output file path (JSON inventory file)
- `$3` - OPTIONAL: webMethods Update Manager version string (default: `${__wmui_default_umgr_version_string}`)
- `$4` - OPTIONAL: Platform string (default: `${__wmui_default_platform_string}`)
- `$5` - OPTIONAL: Update Manager version (default: `${__wmui_default_umgr_version}`)
- `$6` - OPTIONAL: Platform group string (default: `${__wmui_default_platform_group_string}`)

**Return Codes**:
- `0` - Success
- `1` - Missing required parameters
- `2` - Input file does not exist
- `3` - No products found in input file
- `4` - No products could be parsed

**Input Format**:
Products list file should contain lines in format:
```
e2ei/27/PRODUCT_VERSION.LATEST/Category/ProductCode
```

**Output Format**:
Generates JSON inventory file compatible with Update Manager.

**Default Values**:
- webMethods Update Manager version: `27.1.0`
- Platform: `LNXAMD64`
- Update Manager version: `27.0.0.0000-0117`
- Platform group: `"UNX-ANY","LNX-ANY"`

---

### Function 05b: `wmui_get_product_list_of_template`

**Purpose**: Get the appropriate products list file for a template (latest or versioned).

**Parameters**:
- `$1` - Template name (relative to `02.templates/01.setup/`)
- `$2` - OPTIONAL: Use latest flag (default: `${__wmui_default_use_latest}`)

**Return Codes**:
- `0` - Success (prints file path to stdout)
- `1` - Products list file not found

**Output**:
- Prints full path to products list file on success
- Prints "not found" on failure

**Behavior**:
- If `$2` is `"true"`: Uses `ProductsLatestList.txt`
- Otherwise: Uses `ProductsVersionedList.txt`

---

## Image Generation Functions

### Function 21: `wmui_generate_products_zip_from_list`

**Purpose**: Generate a products.zip image file from a CSV list of products.

**Parameters**:
- `$1` - Product CSV list (comma-separated)
- `$2` - OPTIONAL: Installer binary location (default: `${__wmui_default_installer_bin}`)
- `$3` - OPTIONAL: Output folder (default: `${__wmui_default_output_folder}`)
- `$4` - OPTIONAL: Platform string (default: `${__wmui_default_platform_string}`)

**Return Codes**:
- `0` - Success (image created or already exists)
- `1` - Installer file not found
- `2` - No product CSV list provided
- Other - Installer execution failure

**Required Environment Variables**:
- `WMUI_DOWNLOAD_USER` - Download credentials username
- `WMUI_DOWNLOAD_PASSWORD` - Download credentials password

**Side Effects**:
- Creates permanent wmscript file in output folder
- Creates temporary volatile script with credentials
- Creates products.zip image file
- May create debug.log if debug mode enabled

**Notes**:
- Skips if products.zip already exists
- Uses appropriate SDC server URL based on version in path
- Supports existing images list for caching (`${__wmui_temp_fs_quick}/productsImagesList.txt`)

---

### Function 22: `wmui_generate_products_zip_from_template`

**Purpose**: Generate a products.zip image file for a specific template.

**Parameters**:
- `$1` - Setup template (relative to `02.templates/01.setup/`)
- `$2` - OPTIONAL: Installer binary location (default: `/tmp/installer.bin`)
- `$3` - OPTIONAL: Output folder (default: `/tmp/images`)
- `$4` - OPTIONAL: Platform string (default: `LNXAMD64`)
- `$5` - OPTIONAL: useLatest flag (default: `true`)

**Return Codes**:
- Same as `wmui_generate_products_zip_from_list`

**Behavior**:
- Retrieves products list file for template
- Converts products list to CSV
- Calls `wmui_generate_products_zip_from_list`

---

### Function 23: `wmui_generate_products_zip_from_templates_list`

**Purpose**: Generate a single products.zip for multiple templates.

**Status**: Not yet implemented

**Parameters**:
- `$1` - Setup templates list (space-separated)
- `$2` - OPTIONAL: Installer binary location
- `$3` - OPTIONAL: Output folder
- `$4` - OPTIONAL: Platform string
- `$5` - OPTIONAL: useLatest flag

---

### Function 26: `wmui_generate_fixes_zip_from_list_on_file`

**Purpose**: Generate a fixes.zip image file from a products list file.

**Parameters**:
- `$1` - File containing the product list
- `$2` - OPTIONAL: Output folder (default: `${__wmui_default_output_folder_fixes}`)
- `$3` - OPTIONAL: Fixes tag (default: current date `YY-MM-DD`)
- `$4` - OPTIONAL: Platform string (default: `${__wmui_default_platform_string}`)
- `$5` - OPTIONAL: Update Manager home (default: `${__wmui_default_umgr_home}`)
- `$6` - OPTIONAL: Update Manager bootstrap binary (default: `${__wmui_default_umgr_bin}`)
- `$7` - OPTIONAL: useLatest flag (default: `${__wmui_default_use_latest}`)

**Return Codes**:
- `0` - Success (fixes image created or already exists)
- `1` - No product list file provided
- `2` - Required template.wmscript not found
- `3` - Failed to change directory to Update Manager bin
- `4` - Failed to return to original directory
- `5` - Failed to return to original directory (after error)

**Required Environment Variables**:
- `WMUI_DOWNLOAD_USER` - Download credentials username
- `WMUI_DOWNLOAD_PASSWORD` - Download credentials password

**Side Effects**:
- Bootstraps Update Manager if not present
- Generates inventory JSON file
- Creates permanent wmscript file
- Creates fixes.zip image file
- On failure: Creates troubleshooting dump with logs

**Notes**:
- Automatically bootstraps Update Manager if needed
- Hides password in logs before archiving
- Creates dated subdirectories for troubleshooting dumps

---

### Function 27: `wmui_generate_fixes_zip_from_template`

**Purpose**: Generate a fixes.zip image file for a specific template.

**Parameters**:
- `$1` - Setup template (relative to `02.templates/01.setup/`)
- `$2` - OPTIONAL: Output folder (default: `${__wmui_default_output_folder_fixes}`)
- `$3` - OPTIONAL: Fixes tag (default: current date)
- `$4` - OPTIONAL: Platform string (default: `${__wmui_default_platform_string}`)
- `$5` - OPTIONAL: Update Manager home (default: `${__wmui_default_umgr_home}`)
- `$6` - OPTIONAL: Update Manager bootstrap binary (default: `${__wmui_default_umgr_bin}`)
- `$7` - OPTIONAL: useLatest flag (default: `${__wmui_default_use_latest}`)

**Return Codes**:
- Same as `wmui_generate_fixes_zip_from_list_on_file`

**Behavior**:
- Retrieves products list file for template
- Calls `wmui_generate_fixes_zip_from_list_on_file`

---

## Setup and Installation Functions

### Function 41: `wmui_bootstrap_umgr`

**Purpose**: Bootstrap webMethods Update Manager from binary file.

**Parameters**:
- `$1` - Update Manager bootstrap file
- `$2` - Fixes image file (mandatory for offline mode)
- `$3` - OPTIONAL: Installation directory (webMethods Update Manager Home) (default: `${__wmui_default_umgr_home}`)

**Return Codes**:
- `0` - Success (bootstrapped or already present and updated)
- `1` - Update Manager bootstrap file not found
- `2` - Fixes image file not found (offline mode)
- `3` - Bootstrap execution failed

**Behavior**:
- **If Update Manager already exists**: Attempts to update it and returns
- **Online mode**: Bootstraps without image file
- **Offline mode**: Requires fixes image file for bootstrap

**Side Effects**:
- Creates Update Manager installation in specified directory
- May call `wmui_patch_umgr` if Update Manager already exists

---

### Function 42: `wmui_patch_umgr`

**Purpose**: Patch an existing Update Manager installation from a fixes image.

**Parameters**:
- `$1` - Fixes image file
- `$2` - OPTIONAL: Update Manager home (default: `${__wmui_default_umgr_home}`)

**Return Codes**:
- `0` - Success (patched or skipped in online mode)
- `1` - Update Manager self-update failed
- `2` - Failed to change directory to Update Manager bin
- `3` - Failed to return to original directory

**Behavior**:
- Ignored in online mode (returns 0)
- Skips if Update Manager not present
- Executes Update Manager self-update command

---

### Function 43: `wmui_install_products`

**Purpose**: Install webMethods products using installer binary and script.

**Parameters**:
- `$1` - Installer binary file
- `$2` - Script file for installer (wmscript)
- `$3` - OPTIONAL: Debug level for installer (default: `${__wmui_default_debug_level}`)

**Return Codes**:
- `0` - Success
- `1` - Invalid installer file
- `2` - Invalid installer script file
- `3` - envsubst not installed
- `4` - Product installation failed
- `5` - Environment substitution failed

**Required Tools**:
- `envsubst` - For environment variable substitution

**Side Effects**:
- Applies environment variable substitution to script
- Creates temporary install script in `${__wmui_temp_fs_quick}`
- Creates debug log in audit session directory
- On failure: Copies script to audit directory (debug mode)
- Cleans up temporary script on success

**Debug Behavior**:
- If `__1__debug_mode` is `true`: Uses interactive error mode
- Otherwise: Uses non-interactive mode

---

### Function 44: `wmui_patch_installation`

**Purpose**: Apply fixes to an installed webMethods installation.

**Parameters**:
- `$1` - Fixes image file
- `$2` - OPTIONAL: Update Manager home (default: `${__wmui_default_umgr_home}`)
- `$3` - OPTIONAL: Installation home (default: `${__wmui_default_installation_home}`)
- `$4` - OPTIONAL: Engineering patch modifier (default: `${__wmui_default_epm}` = `N`)
- `$5` - OPTIONAL: Engineering patch diagnoser key (required if `$4=Y`)

**Return Codes**:
- `0` - Success
- `1` - Fixes image file not found
- `2` - Patch execution failed
- `3` - Failed to change directory to Update Manager bin
- `4` - Failed to return to original directory

**Side Effects**:
- Takes snapshot of fixes before patching
- Patches Update Manager itself if needed
- Applies fixes from image
- Takes snapshot of fixes after patching
- On failure: Copies Update Manager logs to audit directory (debug mode)
- Creates temporary fixes script

**Notes**:
- Supports engineering patches (diagnosers) if `$4=Y`
- Automatically patches Update Manager before applying fixes

---

### Function 45: `wmui_remove_diagnoser_patch`

**Purpose**: Remove a specific engineering patch (diagnoser) from installation.

**Parameters**:
- `$1` - Engineering patch diagnoser key (e.g., `"5437713_PIE-68082_5"`)
- `$2` - Engineering patch IDs list (e.g., `"5437713_PIE-68082_1.0.0.0005-0001"`)
- `$3` - OPTIONAL: Update Manager home (default: `${__wmui_default_umgr_home}`)
- `$4` - OPTIONAL: Installation home (default: `${__wmui_default_installation_home}`)

**Return Codes**:
- `0` - Success
- `1` - Update Manager not found
- `2` - Product installation folder missing
- `3` - Support patch removal failed
- `4` - Failed to change directory to Update Manager bin
- `5` - Failed to return to original directory

**Side Effects**:
- Takes snapshot of fixes before removal
- Removes specified support patch
- Takes snapshot of fixes after removal
- On failure: Copies Update Manager logs to audit directory (debug mode)

---

### Function 46: `wmui_setup_products_and_fixes`

**Purpose**: High-level function that orchestrates complete product installation and patching.

**Parameters**:
- `$1` - Installer binary file
- `$2` - Script file for installer
- `$3` - Patch available flag (default: `false`)
- `$4` - Update Manager bootstrap file (required if `$3=true`)
- `$5` - Fixes image file (required if `$3=true`)
- `$6` - OPTIONAL: Update Manager home (default: `${__wmui_default_umgr_home}`)
- `$7` - OPTIONAL: Debug level for installer

**Return Codes**:
- `0` - Success
- `1` - Installer binary file not found
- `2` - Installer script file not found
- `3` - Update Manager bootstrap binary not found (if patching enabled)
- `4` - Fixes image file not found (if patching enabled)
- `5` - envsubst not installed
- `6` - Product image file not found
- `7` - Cannot create installation directory
- `8` - Product installation failed
- `9` - Update Manager bootstrap failed
- `10` - Patch installation failed

**Workflow**:
1. Validates all required files
2. Applies environment substitution to script
3. Extracts and validates product image file path
4. Creates installation directory if needed
5. Installs products
6. If patching enabled:
   - Bootstraps Update Manager
   - Applies fixes

**Side Effects**:
- Creates temporary wmscript file
- Creates installation directory
- Warns if installation directory already exists and is not empty

---

### Function 47: `wmui_apply_setup_template`

**Purpose**: Apply a complete setup template including product installation and optional patching.

**Parameters**:
- `$1` - Setup template directory (relative to `02.templates/01.setup/`)
- `$2` - OPTIONAL: useLatest flag (default: `true`)

**Required Environment Variables**:
- `WMUI_INSTALL_INSTALLER_BIN` - Installer binary path
- `WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN` - Update Manager bootstrap path
- `WMUI_PATCH_FIXES_IMAGE_FILE` - Fixes image path
- `WMUI_UPD_MGR_HOME` - Update Manager home
- Template-specific variables (defined in template's `setEnvDefaults.sh`)

**Return Codes**:
- `0` - Success
- `1` - template.wmscript not found
- `2` - Products list file not found
- `3` - Failed to create CSV from products list
- `4` - Setup failed
- `5` - Prerequisites check failed

**Workflow**:
1. Downloads template.wmscript
2. Downloads appropriate products list file (latest or versioned)
3. Creates enhanced template with `InstallProducts` line
4. Sources `setEnvDefaults.sh` if present
5. Runs `checkPrerequisites.sh` if present
6. Calls `wmui_setup_products_and_fixes`

**Template Structure**:
```
02.templates/01.setup/<Product>/<Version>/<Variant>/
├── template.wmscript          # MUST NOT contain InstallProducts line
├── ProductsLatestList.txt     # Latest product versions
├── ProductsVersionedList.txt  # Specific product versions
├── setEnvDefaults.sh         # Optional: Environment defaults
└── checkPrerequisites.sh     # Optional: Prerequisites check
```

**Notes**:
- Automatically generates `InstallProducts` line from products list
- Products are sorted alphabetically before CSV conversion
- Enhanced template is saved to audit directory
- Temporary files are cleaned up after execution

---

## Post-Setup Functions

### Function 61: `wmui_apply_post_setup_template`

**Purpose**: Apply post-setup configuration from a template.

**Parameters**:
- `$1` - Post-setup template directory (relative to `02.templates/02.post-setup/`)

**Return Codes**:
- `0` - Success
- `1` - apply.sh not found
- `3` - Post-setup script execution failed

**Workflow**:
1. Downloads `apply.sh` from template directory
2. Sets executable permission
3. Executes `apply.sh`

**Template Structure**:
```
02.templates/02.post-setup/<Template>/
└── apply.sh                   # Post-setup script
```

**Notes**:
- chmod failure is logged as warning but doesn't stop execution
- Script is executed directly (not via `pu_audited_exec`)

---

## Function Dependencies

### Dependency Graph

```
_init (Function 01)
  └─ Required by: All functions (must be sourced first)

wmui_hunt_for_file (Function 02)
  └─ Used by: Functions 47, 61, and internally by many functions

wmui_assure_default_installer (Function 03)
  └─ Used by: Function 21

wmui_assure_default_umgr_bin (Function 04)
  └─ Used by: Function 26

wmui_generate_inventory_from_products_list (Function 05)
  └─ Used by: Function 26

wmui_get_product_list_of_template (Function 05b)
  └─ Used by: Functions 22, 27, 47

wmui_generate_products_zip_from_list (Function 21)
  └─ Used by: Function 22

wmui_generate_products_zip_from_template (Function 22)
  └─ Standalone or called by orchestration scripts

wmui_generate_fixes_zip_from_list_on_file (Function 26)
  └─ Used by: Function 27

wmui_generate_fixes_zip_from_template (Function 27)
  └─ Standalone or called by orchestration scripts

wmui_bootstrap_umgr (Function 41)
  └─ Used by: Functions 26, 46

wmui_patch_umgr (Function 42)
  └─ Used by: Functions 41, 44

wmui_install_products (Function 43)
  └─ Used by: Function 46

wmui_patch_installation (Function 44)
  └─ Used by: Function 46

wmui_remove_diagnoser_patch (Function 45)
  └─ Standalone (manual intervention)

wmui_setup_products_and_fixes (Function 46)
  └─ Used by: Function 47

wmui_apply_setup_template (Function 47)
  └─ Main entry point for template-based setup

wmui_apply_post_setup_template (Function 61)
  └─ Called after Function 47 for post-configuration
```

### External Dependencies (from PU)

All functions depend on these PU library functions:

- `pu_log_i`, `pu_log_d`, `pu_log_w`, `pu_log_e` - Logging
- `pu_audited_exec` - Audited command execution
- `pu_assure_downloadable_file` - File download with checksum
- `pu_str_substitute` - String substitution
- `pu_lines_to_csv` - Convert lines to CSV (or `linesFileToCsvString`)

---

## Usage Examples

### Example 1: Apply Setup Template (Latest Products)

```sh
# Source required libraries
. /path/to/2l-posix-shell-utils/code/2.audit.sh
. /path/to/wmui-functions.sh

# Set required environment variables
export WMUI_INSTALL_INSTALLER_BIN="/tmp/installer.bin"
export WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN="/tmp/umgr-bootstrap.bin"
export WMUI_PATCH_FIXES_IMAGE_FILE="/tmp/fixes.zip"
export WMUI_UPD_MGR_HOME="/opt/wm-umgr"
export WMUI_DOWNLOAD_USER="your-username"
export WMUI_DOWNLOAD_PASSWORD="your-password"

# Apply template using latest products
wmui_apply_setup_template "APIGateway/1101/default"
```

### Example 2: Apply Setup Template (Versioned Products)

```sh
# Apply template using specific versioned products
wmui_apply_setup_template "APIGateway/1101/default" "false"
```

### Example 3: Generate Product Image

```sh
# Generate products.zip for a template
wmui_generate_products_zip_from_template \
  "APIGateway/1101/default" \
  "/tmp/installer.bin" \
  "/tmp/images" \
  "LNXAMD64" \
  "true"
```

### Example 4: Generate Fixes Image

```sh
# Generate fixes.zip for a template
wmui_generate_fixes_zip_from_template \
  "APIGateway/1101/default" \
  "/tmp/images/fixes" \
  "2026-01-28" \
  "LNXAMD64" \
  "/opt/wm-umgr" \
  "/tmp/umgr-bootstrap.bin" \
  "true"
```

### Example 5: Manual Product Installation

```sh
# Install products manually
wmui_install_products \
  "/tmp/installer.bin" \
  "/path/to/install.wmscript" \
  "verbose"
```

### Example 6: Apply Post-Setup Template

```sh
# Apply post-setup configuration
wmui_apply_post_setup_template "APIGateway/1101/default"
```

---

## Troubleshooting

### Common Issues

#### Issue: "PU audit module not loaded"
**Solution**: Source `2.audit.sh` before sourcing `wmui-functions.sh`

#### Issue: "File not found in offline mode"
**Solution**: Ensure `WMUI_HOME` is set and contains all required files

#### Issue: "envsubst not installed"
**Solution**: Install gettext package: `apt-get install gettext` or `yum install gettext`

#### Issue: "Product installation failed"
**Solution**:
- Check debug log in audit session directory
- Verify all template variables are set
- Ensure product image file exists and is valid

#### Issue: "Fixes image creation failed"
**Solution**:
- Check Empower credentials
- Review Update Manager logs in troubleshooting dump
- Verify network connectivity (online mode)

### Debug Mode

Enable debug mode for detailed logging:

```sh
export PU_DEBUG_MODE="true"
```

This will:
- Enable verbose installer logging
- Save temporary scripts to audit directory
- Copy Update Manager logs on failure
- Use interactive error mode for installer

---

**Last Updated**: 2026-01-28