# Scripts for webMethods provisioning contexts

## General Rules applied

The project is built so that scripts may be downloaded or injected into linux nodes, either hosts, vms or containers. It is based on the "posix utils" repository in the same IWCD framework.

The scripts themselves have minimal comments to keep them light.

All files that require parameters are managed with gnu envsusbst. This means that all properties will be sourceable shell files.

### Template variables

By convention, the wmscript templates will contain lines such as the following one when dealing with variables. Templates built before this convention are deprecated. Whenever a key contains a point (`.`) it is substituted with underscore (`_`)

```sh
key=${WMUI_WMSCRIPT_Key}
```

example

```sh
InstallDir=${WMUI_WMSCRIPT_InstallDir}
```

## Important notes
It is the caller responsibility to:

- properly cater for env variables substitutions in the provided files.
- properly prepare url-encoded variables (use the common lib primitives)

## Exit & Return Codes

### Success Code
By convention all functions must return 0 if successful. Return codes then will be specific to each function

### Return Code Logic
**Code 0**: Always means success across all functions.

**Codes 1-99**: Function-specific return codes. Each function defines its own semantics for these codes. The same code number can mean different things in different functions (e.g., code 1 means "invalid installer file" in `installProducts()` but "template.wmscript not found" in `applySetupTemplate()`).

**Codes 100+**: Global framework codes with consistent meaning across all functions. These represent framework-level issues that transcend individual function boundaries (e.g., prerequisites not met, environment issues, network failures).

### Global Framework Codes (100+)
These codes have consistent meaning across all functions:

|Code|Description|
|-|-|
|100|Basic prerequisites not met / Expected files missing|
|101|Environment variables substitution failed|
|102|Network operation failed (curl, download)|
|103|Critical setup operation failed|
|104|Offline mode prerequisites not met|

## Notes
For the moment everything works with version 10.5 and Update Manager v11. The scripts are also follwoing a "use before reuse" principle, reusability with other versions will be evaluated when the need manifests.

## setupFunctions.sh Overview

The `setupFunctions.sh` module provides a comprehensive framework for automated webMethods product installation and configuration. It handles the complete lifecycle from product installation to patches and post-setup configuration.

### Key Functions

#### Product Installation
- **`installProducts()`** - Core function that installs webMethods products using installer scripts
  - Handles environment variable substitution in wmscript templates
  - Provides detailed logging and error handling

#### Update Manager Operations
- **`bootstrapUpdMgr()`** - Bootstraps Software AG Update Manager for patch management
- **`patchUpdMgr()`** - Updates the Update Manager itself using provided images
- **`patchInstallation()`** - Applies patches to installed products via Update Manager
- **`removeDiagnoserPatch()`** - Removes specific engineering patches when needed

#### Template Management
- **`applySetupTemplate()`** - Orchestrates complete setup from template directories
  - Downloads required files from cache/repository
  - Sources environment defaults and checks prerequisites
  - **NEW**: Automatically generates `InstallProducts` line from product lists
  - Supports `useLatest` parameter (YES/NO) to choose between latest or versioned products
  - Creates temporary enhanced template and calls `setupProductsAndFixes()`
- **`setupProductsAndFixes()`** - High-level function combining product install + patching

#### Image Generation (Online Mode)
- **`generateProductsImageFromTemplate()`** - Creates product images from SDC using templates
- **`generateFixesImageFromTemplate()`** - Creates fixes images from Empower using product inventories

#### Utility Functions
- **`assureDownloadableFile()`** - Downloads and validates files using SHA256 checksums
- **`assureDefaultInstaller()`** - Ensures default webMethods installer is available
- **`checkSetupTemplateBasicPrerequisites()`** - Validates required environment variables
- **`checkEmpowerCredentials()`** - Validates Software AG Empower credentials

### Template Structure Requirements

Each setup template in `02.templates/01.setup/` must follow this structure:

```
<Product>/<Version>/<Variant>/
├── template.wmscript          # Installation script (MUST NOT contain InstallProducts)
├── ProductsLatestList.txt     # Latest product versions (one per line)
├── ProductsVersionedList.txt  # Specific product versions (one per line)
├── setEnvDefaults.sh         # Optional: Environment variable defaults
└── checkPrerequisites.sh     # Optional: Custom prerequisite checks
```

### Product List Management

**NEW BEHAVIOR**: The `InstallProducts` property is now generated automatically during installation:

- Templates **MUST NOT** contain the `InstallProducts` line in `template.wmscript`
- Products are read from `ProductsLatestList.txt` (default) or `ProductsVersionedList.txt`
- Products are sorted alphabetically and converted to comma-separated format
- Use `useLatest=NO` parameter to use versioned products instead of latest

### Environment Variables

The framework relies on these key environment variables:

- `WMUI_INSTALL_INSTALLER_BIN` - Path to webMethods installer binary
- `WMUI_INSTALL_IMAGE_FILE` - Path to product installation image
- `WMUI_PATCH_AVAILABLE` - Whether patches should be applied (0/1)
- `WMUI_PATCH_UPD_MGR_BOOTSTRAP_BIN` - Path to Update Manager bootstrap
- `WMUI_PATCH_FIXES_IMAGE_FILE` - Path to fixes image file
- `WMUI_ONLINE_MODE` - Framework online mode (0=offline, 1=online)
- `WMUI_SDC_ONLINE_MODE` - SDC connection mode (0=offline, 1=online)

### Typical Workflow

1. **Environment Setup** - Set required environment variables
2. **Template Application** - Call `applySetupTemplate()` with template path and optional `useLatest` parameter
3. **Product Installation** - Framework downloads template files, generates InstallProducts line, and installs products
4. **Patch Application** - If enabled, applies latest fixes via Update Manager
5. **Post-Setup** - Optionally runs post-setup scripts for configuration

### Function Usage Examples

```bash
# Apply template using latest products (default)
applySetupTemplate "APIGateway/1101/default"

# Apply template using specific versioned products
applySetupTemplate "APIGateway/1101/default" "NO"
```
