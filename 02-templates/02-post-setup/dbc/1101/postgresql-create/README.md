# Database Configurator for PostgreSQL Server - Post Setup Template

## Purpose

This post-setup template creates webMethods database components in a PostgreSQL database server using the Database Configurator (DBC) tool. It automates the initialization of database schemas, tables, and other objects required by webMethods products.

## Scope

- **Product:** Database Configurator (DBC) 11.0.1
- **Database:** PostgreSQL
- **Action:** Create database components
- **Idempotency:** Delegated to the DBC tool, which has supported idempotency

## Prerequisites

### Software Requirements

1. **Database Configurator** must be installed at `${WMUI_WMSCRIPT_InstallDir}/common/db/bin/dbConfigurator.sh`
2. **PostgreSQL Server** must be running and accessible
3. **POSIX Shell Utilities** must be sourced (provides `pu_log_*` and `pu_audited_exec` functions)
4. **WMUI Functions** must be sourced (provides `wmui_hunt_for_file` function)

### Network Requirements

- Database server must be reachable on the specified hostname and port
- Network connectivity will be validated before attempting database operations

## Required Environment Variables

The template requires the following environment variables to be set:

### Database Connection Parameters

| Variable | Description | Example |
|----------|-------------|---------|
| `WMUI_PST_DB_SERVER_HOSTNAME` | PostgreSQL server hostname or IP | `postgresql-db-server` |
| `WMUI_PST_DB_SERVER_PORT` | PostgreSQL server port | `5432` |
| `WMUI_PST_DB_SERVER_DATABASE_NAME` | Target database name | `postgres` |
| `WMUI_PST_DB_SERVER_USER_NAME` | Database user with create privileges | `postgres` |
| `WMUI_PST_DB_SERVER_PASSWORD` | Database user password | `********` |

### Installation Parameters

| Variable | Description | Example |
|----------|-------------|---------|
| `WMUI_WMSCRIPT_InstallDir` | webMethods installation directory | `/opt/webmethods` |

## Optional Environment Variables

These variables have defaults but can be overridden:

| Variable | Default | Description |
|----------|---------|-------------|
| `WMUI_PST_DATABASE_ALREADY_CREATED` | `false` | Set to `true` to skip creation (not fully implemented) |
| `WMUI_PST_DBSERVER_PORT` | `5432` | Alternative to `WMUI_PST_DB_SERVER_PORT` |
| `WMUI_PST_DBC_COMPONENT_NAME` | `All` | Component to create (`All`, `IS`, `MWS`, etc.) |
| `WMUI_PST_DBC_COMPONENT_VERSION` | `latest` | Component version to install |

## Usage

### Direct Invocation

```bash
# Source required libraries
. /path/to/posix-shell-utils/code/1.init.sh
. /path/to/posix-shell-utils/code/5.network.sh
. /path/to/wmui-functions.sh

# Set required variables
export WMUI_PST_DB_SERVER_HOSTNAME="postgresql-server"
export WMUI_PST_DB_SERVER_PORT="5432"
export WMUI_PST_DB_SERVER_DATABASE_NAME="webmethods"
export WMUI_PST_DB_SERVER_USER_NAME="wmuser"
export WMUI_PST_DB_SERVER_PASSWORD="secret"
export WMUI_WMSCRIPT_InstallDir="/opt/webmethods"

# Apply the template
wmui_apply_post_setup_template dbc/1101/postgresql-create
```

### Via Test Harness

See the test harness in `03-test/02-templates/test-401-dbc-1101-full/` for a complete Docker-based example.

## Template Structure

The template consists of three phases executed in sequence:

### Phase 1: Set Environment Defaults (`01-set-env-defaults.sh`)

- Sets default values for optional variables
- Maps input variables to internal `WMUI_PST_*` namespace
- Does not fail if variables are missing (defaults applied)

### Phase 2: Check Prerequisites (`02-check-prerequisites.sh`)

- Validates all required functions are available
- Checks all mandatory environment variables are set
- Verifies database server connectivity
- **Exits with error code 2** if environment prerequisites fail
- **Exits with error code 3** if service prerequisites fail

### Phase 3: Apply Configuration (`03-apply.sh`)

- Catalogs the database (connectivity check)
- Creates database components using DBC
- Logs all commands (with password masking)
- **Returns error code 2** if catalog fails
- **Returns error code 3** if creation fails

## Expected Outcomes

### Success

- Database components are created in the target database
- Audit logs are generated in the session audit directory
- Exit code: `0`
- Log message: `Post setup template dbc/1101/postgresql-create applied successfully`

### Failure Scenarios

| Exit Code | Scenario | Resolution |
|-----------|----------|------------|
| 1 | Required function not found | Source POSIX utils and WMUI functions |
| 2 | Environment prerequisites failed | Check all required variables are set |
| 3 | Service prerequisites failed | Verify database server is running and reachable |
| 2 | Database catalog failed | Check database credentials and permissions |
| 3 | Database creation failed | Check database logs; may indicate objects already exist |

## Troubleshooting

### Database Connection Issues

```bash
# Test connectivity manually
nc -zv ${WMUI_PST_DB_SERVER_HOSTNAME} ${WMUI_PST_DB_SERVER_PORT}

# Or using the POSIX utils function
pu_port_is_reachable "${WMUI_PST_DB_SERVER_HOSTNAME}" "${WMUI_PST_DB_SERVER_PORT}"
```

### Permission Issues

Ensure the database user has sufficient privileges:

```sql
-- Grant necessary permissions
GRANT CREATE ON DATABASE webmethods TO wmuser;
GRANT ALL PRIVILEGES ON DATABASE webmethods TO wmuser;
```

### Component Already Exists

If database components already exist, the creation may fail. The template performs a catalog check but does not fully implement idempotent creation. Consider:

1. Dropping and recreating the database (destructive)
2. Using a fresh database
3. Setting `WMUI_PST_DATABASE_ALREADY_CREATED=true` (feature incomplete)

### Debug Mode

Enable debug logging:

```bash
export PU_DEBUG_MODE=true
```

This will output detailed command execution information.

## Audit Trail

All operations are logged to the POSIX utils audit session directory. Check:

- Command execution logs
- Database configurator output
- Error messages and stack traces

## Known Issues

⚠️ **Variable Naming Inconsistencies** (as of 2026-02-02):
- Some internal variables use incorrect prefixes
- Test harness variable mapping may be incomplete
- See analysis document for details

## Related Documentation

- Database Configurator Guide: `${WMUI_WMSCRIPT_InstallDir}/common/db/doc/`
- POSIX Shell Utils: `2l-posix-shell-utils/README.md`
- WMUI Functions: `01-scripts/wmui-functions.sh`
- Test Harness: `03-test/02-templates/test-401-dbc-1101-full/`

## Version History

- **2025**: Initial version
- **2026-02-02**: Documentation enhanced

## License

Copyright IBM Corp. 2025 - 2025
SPDX-License-Identifier: Apache-2.0
