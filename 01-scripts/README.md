# WMUI Scripts - webMethods Unattended Installation

## Overview

This directory contains shell scripts for automated webMethods product installation and configuration. The scripts are designed to be downloaded or injected into Linux nodes (hosts, VMs, or containers) and are based on the [POSIX Shell Utils (PU)](../../2l-posix-shell-utils/) framework.

## Documentation Structure

- **[coding-conventions.md](./coding-conventions.md)** - Coding standards and naming conventions
- **[reference.md](./reference.md)** - Comprehensive function reference with parameters and environment variables
- **README.md** (this file) - Quick start and overview

## Quick Start

### Prerequisites

1. **POSIX Shell Utils**: Source the PU library before using WMUI functions
   ```sh
   . /path/to/2l-posix-shell-utils/code/2.audit.sh
   . /path/to/wmui-functions.sh
   ```

2. **Required Tools**:
   - `envsubst` (from gettext package)
   - `curl` (for online mode)
   - Standard POSIX utilities

### Basic Usage

```sh
# Set required framework variables
export WMUI_INSTALL_INSTALLER_BIN="/tmp/installer.bin"
export WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN="/tmp/umgr-bootstrap.bin"
export WMUI_PATCH_FIXES_IMAGE_FILE="/tmp/fixes.zip"
export WMUI_UPD_MGR_HOME="/opt/wm-umgr"
export WMUI_DOWNLOAD_USER="your-username"
export WMUI_DOWNLOAD_PASSWORD="your-password"

# Set required template variables (WMUI_WMSCRIPT_* convention)
export WMUI_WMSCRIPT_HostName="myhost.example.com"
export WMUI_WMSCRIPT_imageFile="/tmp/products.zip"
export WMUI_WMSCRIPT_InstallDir="/opt/webmethods"
export WMUI_WMSCRIPT_adminPassword="manage"
# ... plus any template-specific variables

# Apply template using latest products (default)
wmui_apply_setup_template "APIGateway/1101/default"

# Apply template using specific versioned products
wmui_apply_setup_template "APIGateway/1101/default" "false"
```

## Key Concepts

### Operating Modes

The framework supports two operating modes:

- **Online Mode** (`WMUI_ONLINE_MODE=true`): Downloads files from GitHub repository as needed
- **Offline Mode** (`WMUI_ONLINE_MODE=false`): Requires all files to be present locally in `WMUI_HOME`

### Template Structure

Setup templates follow a standardized structure in `02.templates/01.setup/`:

```
<Product>/<Version>/<Variant>/
├── template.wmscript          # Installation script (MUST NOT contain InstallProducts)
├── products-latest-list.txt     # Latest product versions (one per line)
├── products-versioned-list.txt  # Specific product versions (one per line)
├── setEnvDefaults.sh         # Optional: Environment variable defaults
└── checkPrerequisites.sh     # Optional: Custom prerequisite checks
```

### Product List Management

**IMPORTANT**: The `InstallProducts` property is generated automatically:

- Templates **MUST NOT** contain the `InstallProducts` line in `template.wmscript`
- Products are read from `products-latest-list.txt` (default) or `products-versioned-list.txt`
- Products are sorted alphabetically and converted to comma-separated format
- Use second parameter `"false"` to use versioned products instead of latest

### Template Variable Convention

**IMPORTANT**: All wmscript template variables follow a strict naming convention.

By convention, wmscript templates use environment variables with the `WMUI_WMSCRIPT_` prefix:

```sh
key=${WMUI_WMSCRIPT_Key}
```

**Rules**:
- All template variables **MUST** use `WMUI_WMSCRIPT_` prefix
- Variable name **MUST** mirror the wmscript key name exactly
- When a key contains a dot (`.`), substitute with underscore (`_`)
- This convention applies to ALL variables used in template.wmscript files

**Example**:
```sh
# In template.wmscript:
InstallDir=${WMUI_WMSCRIPT_InstallDir}
HostName=${WMUI_WMSCRIPT_HostName}
imageFile=${WMUI_WMSCRIPT_imageFile}
adminPassword=${WMUI_WMSCRIPT_adminPassword}
TaskEngineRuntimeUrlName=${WMUI_WMSCRIPT_TaskEngineRuntimeUrlName}
```

**Required Variables** (present in all templates):
- `WMUI_WMSCRIPT_HostName` - Hostname for the installation
- `WMUI_WMSCRIPT_imageFile` - Path to products image file
- `WMUI_WMSCRIPT_InstallDir` - Installation directory path

**Template-Specific Variables**: Each template may require additional variables. Check the template's `setEnvDefaults.sh` file for defaults and required variables.

**Note**: The framework uses these variables directly from the environment, eliminating redundant extraction from wmscript files. Ensure all required variables are set before calling `wmui_apply_setup_template()`.

## Core Functions

### High-Level Functions

| Function | Purpose | Reference |
|----------|---------|-----------|
| `wmui_apply_setup_template` | Apply complete setup template (main entry point) | [Function 47](./reference.md#function-47-wmui_apply_setup_template) |
| `wmui_apply_post_setup_template` | Apply post-setup configuration | [Function 61](./reference.md#function-61-wmui_apply_post_setup_template) |
| `wmui_setup_products_and_fixes` | Install products and apply patches | [Function 46](./reference.md#function-46-wmui_setup_products_and_fixes) |

### Image Generation Functions

| Function | Purpose | Reference |
|----------|---------|-----------|
| `wmui_generate_products_zip_from_template` | Generate products.zip for template | [Function 22](./reference.md#function-22-wmui_generate_products_zip_from_template) |
| `wmui_generate_fixes_zip_from_template` | Generate fixes.zip for template | [Function 27](./reference.md#function-27-wmui_generate_fixes_zip_from_template) |

### Installation Functions

| Function | Purpose | Reference |
|----------|---------|-----------|
| `wmui_install_products` | Install webMethods products | [Function 43](./reference.md#function-43-wmui_install_products) |
| `wmui_patch_installation` | Apply fixes to installation | [Function 44](./reference.md#function-44-wmui_patch_installation) |
| `wmui_bootstrap_umgr` | Bootstrap Update Manager | [Function 41](./reference.md#function-41-wmui_bootstrap_umgr) |

For complete function documentation, see [reference.md](./reference.md).

## Return Codes

### Success Code
**Code 0**: Always means success across all functions.

### Function-Specific Codes (1-99)
Each function defines its own semantics for codes 1-99. The same code number can mean different things in different functions. Refer to individual function documentation in [reference.md](./reference.md).

### Global Framework Codes (100+)
These codes have consistent meaning across all functions:

| Code | Description |
|------|-------------|
| 100 | Basic prerequisites not met / Expected files missing |
| 101 | Environment variables substitution failed |
| 102 | Network operation failed (curl, download) |
| 103 | Critical setup operation failed |
| 104 | Offline mode prerequisites not met |

## Environment Variables

### Essential Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `WMUI_HOME` | WMUI repository home (required in offline mode) | None |
| `WMUI_ONLINE_MODE` | Framework online/offline mode | `true` |
| `WMUI_INSTALL_INSTALLER_BIN` | Path to installer binary | `/tmp/WMUI/installer.bin` |
| `WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN` | Path to Update Manager bootstrap | `/tmp/WMUI/umgr-bootstrap.bin` |
| `WMUI_PATCH_FIXES_IMAGE_FILE` | Path to fixes image | None |
| `WMUI_UPD_MGR_HOME` | Update Manager installation directory | `/opt/wm-umgr` |
| `WMUI_DOWNLOAD_USER` | Download credentials username | None |
| `WMUI_DOWNLOAD_PASSWORD` | Download credentials password | None |

For a complete list of environment variables, see [reference.md - Environment Variables](./reference.md#environment-variables).

## Typical Workflow

1. **Environment Setup** - Set required environment variables
2. **Template Application** - Call `wmui_apply_setup_template()` with template path
3. **Product Installation** - Framework downloads template files, generates InstallProducts line, and installs products
4. **Patch Application** - If patches available, applies fixes via Update Manager
5. **Post-Setup** - Optionally run `wmui_apply_post_setup_template()` for additional configuration

## Important Notes

### Caller Responsibilities

It is the caller's responsibility to:
- Properly set all required environment variables
- Ensure environment variable substitution works correctly in template files
- Prepare URL-encoded variables when needed (use PU library primitives)

### Script Design

- Scripts have minimal comments to keep them lightweight
- All parameter files use `envsubst` for variable substitution
- Scripts are designed for injection into Linux environments

### Version Support

Currently tested with:
- webMethods version 10.5, 10.11, 10.15, 11.01
- Update Manager v11

The scripts follow a "use before reuse" principle. Reusability with other versions will be evaluated as needed.

## Troubleshooting

### Common Issues

1. **"PU audit module not loaded"**
   - Solution: Source `2.audit.sh` before `wmui-functions.sh`

2. **"envsubst not installed"**
   - Solution: Install gettext package

3. **"File not found in offline mode"**
   - Solution: Ensure `WMUI_HOME` is set and contains all required files

4. **Product installation failed**
   - Check debug log in audit session directory
   - Verify all template variables are set
   - Enable debug mode: `export PU_DEBUG_MODE="true"`

For detailed troubleshooting, see [reference.md - Troubleshooting](./reference.md#troubleshooting).

## Related Documentation

- **Coding Conventions**: [coding-conventions.md](./coding-conventions.md)
- **Function Reference**: [reference.md](./reference.md)
- **POSIX Utils**: [../../2l-posix-shell-utils/](../../2l-posix-shell-utils/)
- **Templates**: [../02.templates/](../02.templates/)

---

**Last Updated**: 2026-01-28
