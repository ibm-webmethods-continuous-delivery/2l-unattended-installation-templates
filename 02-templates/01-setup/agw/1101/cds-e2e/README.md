# Setup template agw/1101/cds-e2e

This template sets up webMethods API Gateway 11.1 with:
- Central Users and Common Directory Services (CDS)
- End-to-End Monitoring (E2E)
- External database support (PostgreSQL/Oracle)

## Required Variables

The following environment variables MUST be set before applying this template:

- `WMUI_WMSCRIPT_TaskEngineRuntimeUrlName` - JDBC URL for CDS database (URL-encoded)
- `WMUI_WMSCRIPT_TaskEngineRuntimeUserName` - Database username for CDS
- `WMUI_WMSCRIPT_TaskEngineRuntimePasswordName` - Database password for CDS

## Optional Variables

The following variables have defaults but can be overridden:

- `WMUI_WMSCRIPT_HostName` - Hostname (default: localhost)
- `WMUI_WMSCRIPT_InstallDir` - Installation directory (default: /opt/webmethods)
- `WMUI_WMSCRIPT_adminPassword` - Admin password (default: manage)
- `WMUI_WMSCRIPT_IntegrationServerPort` - IS HTTP port (default: 5555)
- `WMUI_WMSCRIPT_IntegrationServersecurePort` - IS HTTPS port (default: 5553)
- `WMUI_WMSCRIPT_IntegrationServerdiagnosticPort` - IS diagnostic port (default: 9999)
- `WMUI_WMSCRIPT_YAIHttpPort` - API Gateway HTTP port (default: 9072)
- `WMUI_WMSCRIPT_YAIHttpsPort` - API Gateway HTTPS port (default: 9073)

## Database Configuration

### PostgreSQL Example
```sh
export WMUI_WMSCRIPT_TaskEngineRuntimeUrlName="jdbc%3Awm%3Apostgresql%3A%2F%2Fdbhost%3A5432%3BDatabaseName%3Dcds"
export WMUI_WMSCRIPT_TaskEngineRuntimeUserName="cdsuser"
export WMUI_WMSCRIPT_TaskEngineRuntimePasswordName="cdspass"
```

### Oracle Example
```sh
export WMUI_WMSCRIPT_TaskEngineRuntimeUrlName="jdbc%3Awm%3Aoracle%3Athin%3A%40dbhost%3A1521%3Aorcl"
export WMUI_WMSCRIPT_TaskEngineRuntimeUserName="cdsuser"
export WMUI_WMSCRIPT_TaskEngineRuntimePasswordName="cdspass"
```

Note: JDBC URLs must be URL-encoded. Use the PU library's `urlencode` function if needed.