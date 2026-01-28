# Coding Conventions for WMUI Scripts

## Overview

This document defines the coding conventions for the webMethods Unattended Installation (WMUI) scripts. These conventions are based on the [POSIX Shell Utils (PU) conventions](../../2l-posix-shell-utils/Conventions.md) with specific adaptations for this project.

## Relationship to POSIX Utils

The WMUI scripts depend on and follow the conventions established in the `2l-posix-shell-utils` repository. For comprehensive details on the base conventions, refer to:

- **Base Conventions**: [c/iwcd/2l-posix-shell-utils/Conventions.md](../../2l-posix-shell-utils/Conventions.md)
- **Detailed Rules**: [c/iwcd/2l-posix-shell-utils/.ai-assist/RULES.md](../../2l-posix-shell-utils/.ai-assist/RULES.md)

## POSIX Compliance Exception

**IMPORTANT**: While the PU library strictly enforces POSIX compliance, the WMUI scripts have **one exception**:

- **`local` keyword is accepted**: Function-scoped variables may use the `local` keyword for clarity
- All local variables MUST be prefixed with `l_` (lowercase L followed by underscore)

This is explicitly documented in the file header:

```sh
# WARNING: POSIX compatibility is pursued, but this is not a strict POSIX script.
# The following exceptions apply
# - local variables for functions
# shellcheck disable=SC3043
```

## Naming Conventions

### Functions

#### Public Functions
- **Pattern**: `wmui_<action>` or `wmui_<module>_<action>`
- **Prefix**: No underscore prefix
- **Visibility**: Intended for external use
- **Examples**:
  - `wmui_hunt_for_file`
  - `wmui_install_products`
  - `wmui_apply_setup_template`

#### Private Functions
- **Pattern**: `_<action>`
- **Prefix**: Single underscore `_`
- **Visibility**: Internal to the file
- **Examples**:
  - `_init` (internal initialization)

### Variables

#### Environment Constants (External Input)
- **Pattern**: `WMUI_<NAME>` or `<EXTERNAL_NAME>`
- **Case**: UPPER_CASE with underscores
- **Mutability**: MUST NOT be modified by scripts (read-only)
- **Source**: Set by external environment before script execution
- **Examples**:
  - `WMUI_HOME` - WMUI repository home directory
  - `WMUI_ONLINE_MODE` - Framework online/offline mode
  - `WMUI_INSTALL_INSTALLER_BIN` - Path to installer binary
  - `WMUI_DOWNLOAD_USER` - Download credentials username
  - `WMUI_DOWNLOAD_PASSWORD` - Download credentials password

#### File-Scoped Private Variables
- **Pattern**: `__wmui_<name>`
- **Case**: lowercase with underscores
- **Prefix**: Double underscore `__`
- **Visibility**: Private to all functions within the file
- **Export**: May be exported if needed across script boundaries
- **Lifecycle**: Persist throughout script execution
- **Examples**:
  - `__wmui_online_mode` - Internal online mode flag
  - `__wmui_cache_home` - Cache directory path
  - `__wmui_default_installer_bin` - Default installer binary path
  - `__wmui_default_umgr_home` - Default Update Manager home

#### Function-Scoped Local Variables
- **Pattern**: `l_<name>`
- **Case**: lowercase with underscores
- **Prefix**: `l_` (lowercase L followed by underscore)
- **Keyword**: Uses `local` keyword (POSIX exception)
- **Visibility**: Private to a single function only
- **Lifecycle**: Automatically scoped to function by `local` keyword
- **Examples**:
  - `local l_installer_bin="${1}"`
  - `local l_result_curl=$?`
  - `local l_products_csv`
  - `local l_temp_install_script`

### Variable Scope Summary Table

| Scope | Pattern | Prefix | Case | Export | Keyword | Example |
|-------|---------|--------|------|--------|---------|---------|
| Environment Constant | `WMUI_<NAME>` | None | UPPER | No | N/A | `WMUI_HOME` |
| File-Scoped Private | `__wmui_<name>` | `__` | lower | Maybe | N/A | `__wmui_cache_home` |
| Function-Scoped Local | `l_<name>` | `l_` | lower | No | `local` | `l_installer_bin` |

## Key Differences from PU Conventions

| Aspect | PU Convention | WMUI Convention | Reason |
|--------|---------------|-----------------|--------|
| POSIX Compliance | Strict | Relaxed (allows `local`) | Improved readability |
| Local Variables | `__<file>_<func>_<name>` | `l_<name>` with `local` keyword | Simpler, clearer |
| File-Scoped Vars | `__<file>__<name>` | `__wmui_<name>` | Project-specific prefix |
| Public Functions | `pu_<action>` | `wmui_<action>` | Project-specific prefix |

## Boolean Values Convention

Following PU conventions:

- **True Value**: Boolean variables MUST contain the string `"true"` (lowercase) to represent true
- **False Value**: Any other value, or a missing/unset variable, represents false
- **Testing**: Always use string comparison: `[ "${variable}" = "true" ]`

**Examples**:
```sh
# Setting boolean values
__wmui_online_mode="${WMUI_ONLINE_MODE:-true}"
__wmui_product_online_mode="${WMUI_PRODUCT_ONLINE_MODE:-true}"

# Testing boolean values
if [ "${__wmui_online_mode}" = "true" ]; then
  pu_log_i "Working in online mode"
fi
```

## Function Documentation

Each function MUST include:

1. **Function number comment** (e.g., `# Function 01`)
2. **Purpose description**
3. **Parameters documentation** with:
   - Parameter number (e.g., `# $1`)
   - Description
   - Whether OPTIONAL or required
   - Default value if applicable
4. **Return codes** (if non-standard)

**Example**:
```sh
# Function 03 - assure default installer
wmui_assure_default_installer() {
  # Parameters
  # $1 - OPTIONAL installer binary location, defaulted to ${WMUI_INSTALL_INSTALLER_BIN}
  local l_installer_bin="${1:-${__wmui_default_installer_bin}}"
  # ... function implementation
}
```

## Return Code Conventions

### Success Code
- **Code 0**: Always means success across all functions

### Function-Specific Codes (1-99)
- Each function defines its own semantics for codes 1-99
- Same code number can mean different things in different functions
- Document function-specific codes in function comments

### Global Framework Codes (100+)
These codes have consistent meaning across all functions:

| Code | Description |
|------|-------------|
| 100 | Basic prerequisites not met / Expected files missing |
| 101 | Environment variables substitution failed |
| 102 | Network operation failed (curl, download) |
| 103 | Critical setup operation failed |
| 104 | Offline mode prerequisites not met |

## Dependencies

### Required External Tools
- `envsubst` - For environment variable substitution in templates
- `curl` - For downloading files in online mode
- Standard POSIX utilities: `grep`, `sed`, `awk`, `sort`, etc.

### Required PU Modules
The WMUI scripts require the following PU modules to be sourced:

1. **2.audit.sh** - MUST be sourced before wmui-functions.sh
   - Provides `__2__audit_session_dir` variable
   - Provides `pu_audited_exec` function

2. **Logging functions** (from PU):
   - `pu_log_i` - Info logging
   - `pu_log_d` - Debug logging
   - `pu_log_w` - Warning logging
   - `pu_log_e` - Error logging

3. **Utility functions** (from PU):
   - `pu_assure_public_file` - File download with checksum validation
   - `pu_str_substitute` - String substitution utility
   - `pu_lines_to_csv` - Convert lines to CSV format

## Template Variable Convention

By convention, wmscript templates contain lines in the following format:

```sh
key=${WMUI_WMSCRIPT_Key}
```

**Rules**:
- All template variables use `WMUI_WMSCRIPT_` prefix
- When a key contains a dot (`.`), it is substituted with underscore (`_`)
- Example: `Install.Dir` becomes `${WMUI_WMSCRIPT_Install_Dir}`

**Example**:
```sh
InstallDir=${WMUI_WMSCRIPT_InstallDir}
LicenseAgree=${WMUI_WMSCRIPT_LicenseAgree}
imageFile=${WMUI_WMSCRIPT_imageFile}
```

## Code Organization

### Function Numbering
Functions are organized in numbered groups:

- **01-09**: Initialization and utility functions
- **21-30**: Image generation functions (products.zip)
- **41-50**: Setup and installation functions
- **61+**: Post-setup functions

### File Structure
```
01.scripts/
├── wmui-functions.sh          # Main function library
├── coding-conventions.md      # This file
├── reference.md               # Function reference documentation
└── README.md                  # General overview and usage
```

## Best Practices

1. **Always check prerequisites** before executing operations
2. **Use PU logging functions** for all output
3. **Validate file existence** before operations
4. **Clean up temporary files** after use
5. **Use meaningful variable names** that describe their purpose
6. **Document return codes** for each function
7. **Handle both online and offline modes** appropriately
8. **Protect sensitive data** (passwords) in logs and audit trails

## Validation Checklist

Before committing code, verify:

- [ ] All functions follow public/private naming rules
- [ ] All local variables use `l_` prefix with `local` keyword
- [ ] All file-scoped variables use `__wmui_` prefix
- [ ] Environment constants are not modified
- [ ] Function numbers are documented in comments
- [ ] Parameters are documented with OPTIONAL/required status
- [ ] Return codes are documented
- [ ] Boolean values use "true" string convention
- [ ] Temporary files are cleaned up
- [ ] PU logging functions are used consistently

---

**Last Updated**: 2026-01-28