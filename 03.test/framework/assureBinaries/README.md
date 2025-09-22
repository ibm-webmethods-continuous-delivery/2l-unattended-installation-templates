# Binary Assurance Test Harnesses

This directory contains Docker-based test harnesses for validating the binary assurance functionality of the webMethods installation framework. The tests ensure that required installer binaries are properly downloaded and available before installation attempts.

## Overview

Two identical test harnesses test the same functionality on different base images:

- **`alpine/`** - Tests on Alpine Linux (lightweight)
- **`ubi-min/`** - Tests on Red Hat UBI 8 Minimal (enterprise)

## Test Purpose

Both harnesses validate the following framework functions:
- `assureDefaultInstaller()` - Ensures the webMethods installer binary is available
- `assureDefaultUpdMgrBootstrap()` - Ensures the Software AG Update Manager bootstrap binary is available

## Directory Structure

Each test harness contains:

```
[alpine|ubi-min]/
├── docker-compose.yml    # Container orchestration
├── run.bat              # Windows test runner
├── scripts/
│   └── entrypoint.sh    # Test execution script
└── local/
    └── README.md        # Local artifacts placeholder
```

## Test Harness Details

### Alpine Test Harness

**Base Image**: `alpine:latest`
**Package Dependencies**: 
- `curl` (for downloads)

**Container Configuration**:
- Mounts project root as `/mnt/WMUI`
- Mounts test scripts as `/mnt/scripts`
- Mounts local artifacts directory as `/mnt/local`
- Executes `entrypoint.sh` on startup

### UBI Minimal Test Harness

**Base Image**: `registry.access.redhat.com/ubi8/ubi-minimal`
**Package Dependencies**: 
- `which` (basic command utilities)

**Container Configuration**:
- Identical mount structure to Alpine
- Uses `microdnf` package manager instead of `apk`

## Environment Variables

Both harnesses use consistent environment variables:

| Variable | Value | Purpose |
|----------|-------|---------|
| `WMUI_INSTALL_INSTALLER_BIN` | `/mnt/local/default-installer.bin` | Expected installer binary location |
| `WMUI_PATCH_SUM_BOOTSTRAP_BIN` | `/mnt/local/default-sum-bootstrap.bin` | Expected Update Manager bootstrap location |

## Test Execution Flow

1. **Package Installation**: Install required system packages (curl/which)
2. **Framework Loading**: Source `commonFunctions.sh` and `setupFunctions.sh`
3. **Environment Logging**: Display current environment via `logEnv`
4. **Binary Assurance**: Test both installer and bootstrap availability
5. **Result Reporting**: Return accumulated error count

## Error Handling

Tests use additive error counting:
- Start with `errNo=0`
- Increment for each failed assertion: `errNo=$((errNo+1))`
- Return total error count as exit code
- Log "SUCCESS" for zero errors, "TEST FAILED!" otherwise

## Usage

### Windows (PowerShell/Command Prompt)
```batch
cd 03.test\framework\assureBinaries\alpine
.\run.bat

cd 03.test\framework\assureBinaries\ubi-min
.\run.bat
```

### Direct Docker Compose
```bash
# Alpine test
cd 03.test/framework/assureBinaries/alpine
docker compose run --rm d

# UBI test
cd 03.test/framework/assureBinaries/ubi-min
docker compose run --rm d
```

## Path Dependencies

### Required Artifacts Directory
Both tests expect artifacts in: `../../../../local/artifacts/`
Relative to each test directory, this resolves to the project root `local/artifacts/` folder.

### Framework Scripts
Tests source framework scripts from: `../../../../01.scripts/`
- `commonFunctions.sh` - Core utilities and logging
- `installation/setupFunctions.sh` - Installation and binary assurance functions

## Expected Outcomes

### Success Scenario
- Exit code: 0
- Log output: "SUCCESS"
- Both installer and bootstrap binaries available

### Failure Scenarios
- Exit code: 1-2 (depending on which binaries are missing)
- Log output: "TEST FAILED!"
- Missing binaries logged with specific error messages

## Logical Consistency Analysis

✅ **Consistent Structure**: Both harnesses have identical file organization
✅ **Correct Function Names**: Fixed to use `assureDefaultUpdMgrBootstrap` instead of non-existent `assureDefaultSumBootstrap`
✅ **Valid Path References**: All relative paths correctly resolve to framework and artifacts locations
✅ **Consistent Environment**: Both tests use same environment variable names and paths
✅ **Proper Error Handling**: Additive error counting with appropriate exit codes

## Fixed Issues

1. **YAML Syntax Error**: Removed double dash in ubi-min volumes configuration
2. **Function Name Error**: Corrected `assureDefaultSumBootstrap` to `assureDefaultUpdMgrBootstrap`
3. **Missing Version**: Added `version: '3.9'` to ubi-min docker-compose.yml for consistency

## Dependencies

- Docker and Docker Compose
- Access to container registries (Docker Hub for Alpine, Red Hat for UBI)
- Framework scripts in `01.scripts/` directory
- Artifacts directory structure in `local/artifacts/`