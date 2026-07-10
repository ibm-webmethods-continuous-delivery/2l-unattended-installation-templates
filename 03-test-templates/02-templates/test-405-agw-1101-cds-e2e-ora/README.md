# Test Template: API Gateway 11.1 with CDS on Oracle (E2E)

## Overview

This Docker Compose template provides a complete end-to-end testing environment for webMethods API Gateway 11.1 with Central Directory Services (CDS) using Oracle database and Elasticsearch with security enabled.

## Components

- **API Gateway (AGW)**: webMethods API Gateway 11.1
- **Oracle Database**: Oracle Database Free 23.5.0.0-lite
- **Elasticsearch**: Two instances with X-Pack security enabled
- **Kibana**: Dashboard and visualization tool
- **Elasticvue**: Elasticsearch content explorer for observability

## Prerequisites

1. Docker and Docker Compose installed
2. Required artifacts (see EXAMPLE.env for paths):
   - API Gateway installer binary
   - Update Manager bootstrap binary
   - Product image file
   - Fixes image file
3. DBC (Database Configurator) image built locally
4. Copy `EXAMPLE.env` to `.env` and configure all required variables

## Key Features

### Elasticsearch Security

This template has **Elasticsearch X-Pack security enabled** with the following configuration:

- **Authentication Required**: All Elasticsearch access requires valid credentials
- **Two User Types**:
  - `elastic`: Built-in superuser for administrative tasks
  - Custom user: Non-elastic user with superuser privileges (configurable via environment variables)
- **Automated Setup**: Custom user is automatically created on both Elasticsearch instances during startup
- **Kibana Integration**: Uses dedicated `kibana_system` user for service authentication

### Environment Variables

Key security-related variables in `.env`:

```bash
# Elasticsearch version
WMUI_TEST_ELK_VERSION=8.17.3

# Built-in elastic user password
WMUI_TEST_ELASTIC_PASSWORD=your_secure_password

# Custom non-elastic user credentials
WMUI_TEST_ELASTIC_USERNAME=notelastic
WMUI_TEST_NON_ELASTIC_USERNAME=notelastic
WMUI_TEST_NON_ELASTIC_PASSWORD=your_secure_password
```

### User Setup Process

The `es-setup` service automatically:
1. Waits for both Elasticsearch instances to be healthy
2. Creates a custom role with full cluster and index privileges
3. Creates the custom user with superuser role on both instances
4. Sets up Kibana system user credentials

See `scripts/setup-es-users.sh` for implementation details.

## Usage

### Starting the Environment

```bash
# Ensure .env is configured
docker-compose up -d
```

Startup sequence:
1. Oracle database initializes
2. Elasticsearch instances start with security enabled
3. Custom user setup runs automatically
4. API Gateway and Kibana start after dependencies are ready

### Accessing Services

#### Elasticsearch

Using built-in elastic user:
```bash
curl -u elastic:${WMUI_TEST_ELASTIC_PASSWORD} \
  http://localhost:${WMUI_TEST_PORT_PREFIX}20/_cluster/health
```

Using custom user:
```bash
curl -u ${WMUI_TEST_NON_ELASTIC_USERNAME}:${WMUI_TEST_NON_ELASTIC_PASSWORD} \
  http://localhost:${WMUI_TEST_PORT_PREFIX}20/_cluster/health
```

#### Kibana

Access at: `http://localhost:${WMUI_TEST_PORT_PREFIX}56`

Kibana uses the `kibana_system` user with password set to `${WMUI_TEST_ELASTIC_PASSWORD}`.

#### API Gateway

- UI: `http://localhost:${WMUI_TEST_PORT_PREFIX}55`
- Admin credentials: `Administrator` / `${WMUI_TEST_ADMIN_PASSWORD}`

#### Elasticvue

Access at: `http://localhost:${WMUI_TEST_PORT_PREFIX}80`

### Database Initialization

For Oracle database setup, use the separate initialization compose file:

```bash
docker-compose -f docker-compose-init-db.yml up
```

This runs the Database Configurator (DBC) to create required schemas and users.

## Port Configuration

All ports use the `WMUI_TEST_PORT_PREFIX` variable (default: 405):

- `${PREFIX}20`: Elasticsearch instance 1
- `${PREFIX}21`: Elasticsearch instance 2
- `${PREFIX}55`: API Gateway
- `${PREFIX}56`: Kibana
- `${PREFIX}72`: API Gateway HTTP port
- `${PREFIX}73`: API Gateway HTTPS port
- `${PREFIX}80`: Elasticvue

## Troubleshooting

### Check Elasticsearch User Setup

```bash
docker-compose logs es-setup
```

### Verify Custom User

```bash
curl -u elastic:${WMUI_TEST_ELASTIC_PASSWORD} \
  http://localhost:${WMUI_TEST_PORT_PREFIX}20/_security/user/${WMUI_TEST_NON_ELASTIC_USERNAME}
```

### Re-run User Setup

```bash
docker-compose rm -f es-setup
docker-compose up es-setup
```

### Reset Environment

```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: Deletes all data!)
docker volume rm test-405-esdata test-405-esdata2 test-405-db-data

# Start fresh
docker-compose up -d
```

## Security Best Practices

1. **Strong Passwords**: Use complex passwords for all credentials
2. **Separate Credentials**: Use different passwords for elastic and custom users
3. **Least Privilege**: Modify `scripts/setup-es-users.sh` to grant only required permissions. Open point: there is currently no documentation on this aspect.
4. **Rotate Passwords**: Regularly update passwords in production
5. **Enable TLS**: For production, enable HTTPS/TLS encryption
6. **Audit Logging**: Enable Elasticsearch audit logging for compliance

## Configuration Files

- `docker-compose.yml`: Main service definitions
- `docker-compose-init-db.yml`: Database initialization
- `EXAMPLE.env`: Environment variable template
- `scripts/setup-es-users.sh`: Elasticsearch user setup script
- `scripts/containerEntrypoint.sh`: API Gateway container entrypoint
- `config/kibana/kibana.yml`: Kibana configuration
- `config/agw/`: API Gateway configuration files

## Additional Resources

- [Elasticsearch Security Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-api.html)
- [webMethods API Gateway Documentation](https://www.ibm.com/docs/en/wam/wm-api-gateway)
- [Oracle Database Free Documentation](https://www.oracle.com/database/free/)

---

*Made with Bob*