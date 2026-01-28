# Binary Assurance Test Harnesses

This directory contains Docker-based test harnesses for validating the binary assurance functionality of the webMethods installation framework. The tests ensure that required installer binaries are properly downloaded and available before installation attempts.

## Overview

Two identical test harnesses test the same functionality on different base images:

- **`alpine/`** - Tests on Alpine Linux (lightweight)
- **`ubi-min/`** - Tests on Red Hat UBI Minimal (enterprise)

## Test Purpose

Both harnesses validate the following framework functions:
- `wmui_assure_default_installer()` - Ensures the webMethods installer binary is available
- `wmui_assure_default_umgr_bin()` - Ensures the webMethods Update Manager bootstrap binary is available

## Directory Structure

Each test harness contains:

```
[alpine|ubi-min]/
├── docker-compose.yml    # Container orchestration
├── run.bat              # Windows test runner
└── scripts/
    └── entrypoint.sh    # Test execution script
```

## Test Harness Details

### Alpine Test Harness

**Base Image**: `alpine:latest`
**Package Dependencies**:
- `curl` (for downloads)

**Container Configuration**:
- Mounts PU library via `H_PU_HOME` → `TEST_PU_HOME`
- Mounts WMUI home via `H_WMUI_HOME` → `TEST_WMUI_HOME`
- Mounts test scripts as `/mnt/scripts`
- Mounts artifacts directory via `H_WMUI_ARTIFACTS_DIR` → `TEST_ARTIFACTS_HOME`
- Executes `entrypoint.sh` on startup

### UBI Minimal Test Harness

**Base Image**: Custom image `vm-emu-min-local-wmui-u:ubi9`
**Prerequisites**: Build image using [7u-container-images](https://github.com/ibm-webmethods-continuous-delivery/7u-container-images/blob/main/images/u/ubi9/vm-emu/minimal/build-local-wmui.bat)

**Package Dependencies**:
- `which` (basic command utilities)

**Container Configuration**:
- Mounts WMUI home as `/opt/iwcd/wmui`
- Mounts test scripts as `/mnt/scripts`
- Mounts artifacts directory as `/mnt/artifacts`
- Includes persistent volumes for installation, audit, and Update Manager
- Executes `entrypoint.sh` on startup

## Environment Variables

### Alpine Test

| Variable | Purpose |
|----------|---------|
| `H_PU_HOME` | Host path to PU library |
| `TEST_PU_HOME` | Container path for PU library |
| `H_WMUI_HOME` | Host path to WMUI repository |
| `TEST_WMUI_HOME` | Container path for WMUI repository |
| `H_WMUI_ARTIFACTS_DIR` | Host path to artifacts directory |
| `TEST_ARTIFACTS_HOME` | Container path for artifacts |
| `TEST_INSTALLER_BIN` | Expected installer binary location |
| `TEST_UMGR_BIN` | Expected Update Manager bootstrap location |

### UBI Minimal Test

| Variable | Purpose |
|----------|---------|
| `TEST_INSTALLER_BIN` | Expected installer binary location (`/mnt/artifacts/default-installer.bin`) |
| `TEST_UMGR_BIN` | Expected Update Manager bootstrap location (`/mnt/artifacts/default-umgr-bootstrap.bin`) |

## Test Execution Flow

1. **Package Installation**: Install required system packages (curl/which)
2. **Framework Loading**: Source PU libraries and WMUI functions
3. **Binary Assurance**: Test both installer and Update Manager bootstrap availability
4. **Result Reporting**: Return accumulated error count

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

## Expected Outcomes

### Success Scenario
- Exit code: 0
- Log output: "SUCCESS"
- Both installer and bootstrap binaries available

### Failure Scenarios
- Exit code: 1-2 (depending on which binaries are missing)
- Log output: "TEST FAILED!"
- Missing binaries logged with specific error messages

## Dependencies

- Docker and Docker Compose
- Access to container registries (Docker Hub for Alpine, custom image for UBI)
- PU library (2l-posix-shell-utils)
- WMUI framework scripts in `01.scripts/` directory
- Artifacts directory with installer and Update Manager binaries

## Notes

- Both tests validate the same functionality on different base images
- Tests follow consistent patterns for maintainability
- Environment variable-based paths allow flexible deployment
- UBI test requires pre-built custom image with WMUI dependencies