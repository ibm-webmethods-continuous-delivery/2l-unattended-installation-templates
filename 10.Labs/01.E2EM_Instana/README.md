# End-to-End Monitoring with Instana Laboratory

This laboratory demonstrates end-to-end monitoring capabilities using webMethods components with Instana integration. The lab sets up a complete environment including API Gateway, Integration Server (MSR), Universal Messaging, PostgreSQL, and ELK stack for comprehensive monitoring and observability.

## Prerequisites

### 1. System Requirements
- Docker Engine with compose support
- Minimum 8GB RAM available for containers
- Sufficient disk space for container volumes and logs
- Network connectivity for container registry access

### 2. Access to webMethods Containers
- Access to [webMethods containers](https://containers.webmethods.io) is required
- This is not a public registry - you must have appropriate entitlements
- Contact your Software AG representative for access if needed

## 3. Attention points

- The clones MUST ensure unix style end lines.
- Most likely you need to set execution flags and permissions immediately after clone. 

### 4. External Repository Dependency
- Clone the repository: `https://github.com/ibm-webmethods-continuous-delivery/5s-pub-sub-with-mon-01`
- Build the sources following the README instructions in that repository
- By default, this lab expects the repository to be located at: `../../../5s-pub-sub-with-mon-01` (relative to this lab directory). If the path is different, declare the correct on in the `.env` file.

### 5. Required Artifacts
Ensure the following artifacts are available in your `${H_WMUI_HOME}/local/artifacts/` directory:
- `default-installer.bin` - webMethods installer
- `default-upd-mgr-bootstrap.bin` - Update Manager bootstrap
- MSR fixes and products zip files (version 1101)
- API Gateway fixes and products zip files (version 1101)

Note that the first two binary artifact may be obtained by running one of the tests in the folder `03.test/framework/assureBinaries`. Ensure you have accepted IBMs webMethods terms and conditions first, by downloading these at manually least once from fix central:

- [Installer](https://www.ibm.com/support/fixcentral/options?selectionBean.selectedTab=find&selection=ibm%2fOther+software%3bWebMethods%3bibm%2fOther+software%2fIBM+webMethods+Integration+Server)
- [Update Manager](https://www.ibm.com/support/fixcentral/options?selectionBean.selectedTab=find&selection=ibm%2fOther+software%3bWebMethods%3bibm%2fOther+software%2fIBM+webMethods+Microservices+Runtime)

The other files, products and fixes zip images, may be obtained by running the test harness `03.test/framework/BuildZipImages`, considering the templates used in this lab: `DBC/1101/full`, `MSR/1101/selection-20250924` and `APIGateway/1101/cds-e2e-postgres`.

Once the artifacts are downloaded, adapt the paths in the `.env` file, for example the `fixes.zip` paths contain the download date.

Follow the README files in those folders for details.

## 6. Database Initialization

This laboratory uses Postgres as the product database for central user management and monitoring. Before launching the lab, the database must be initialized with the tool "database configurator".

The unattended installation templates uses the template `DBC/1101/full` for this purpose. Also, a convenient container image can be built using the harness `06.container-image-builders-test/DBC/1101/local-build-1`. 


## Architecture Overview

The laboratory deploys the following components:

| Component | Purpose | External Ports |
|-----------|---------|---------------|
| PostgreSQL | Database server | - (internal only) |
| Adminer | Database administration | `481`80 |
| Universal Messaging | Message broker | - (internal only) |
| Integration Server (MSR) | ESB runtime | `481`53, `481`55 |
| API Gateway | API management | `481`72, `481`73, `481`57 |
| Elasticsearch | Log aggregation | `481`20 |
| Kibana | Log visualization | `481`56 |
| Elasticvue | Elasticsearch browser | `481`81 |

*Note: `481` is the default port prefix defined in `WMUI_LAB01_PORT_PREFIX`*

## Configuration Files

### Environment Configuration
- `.env` - Main environment configuration (copy from `EXAMPLE.env`)
- `EXAMPLE.env` - Template with default values

### Docker Compose Files
- `docker-compose-init.yml` - Database initialization (run first)
- `docker-compose.yml` - Main application stack

### Configuration Directories
- `config/esb-vm1/` - Integration Server configuration
- `config/api-gw-vm1/` - API Gateway configuration
- `scripts/` - Container entry point scripts

## Setup Instructions

### 1. Prepare Environment File
```bash
cp EXAMPLE.env .env
```

Edit `.env` and update the following mandatory variables:
```env
# Update paths according to your setup
H_WMUI_HOME=../..
H_WMUI_LAB01_PUB_SUB_MON_01_REPO_HOME=../../../5s-pub-sub-with-mon-01

# Update artifact paths if different
H_WMUI_ESB_FIXES_IMAGE_PATH=${H_WMUI_HOME}/local/artifacts/fixes/MSR/1101/selection-20250924/25-09-24/fixes.zip
H_WMUI_ESB_PRODUCTS_IMAGE_PATH=${H_WMUI_HOME}/local/artifacts/products/MSR/1101/selection-20250924/products.zip
H_WMUI_APIGW_FIXES_IMAGE_PATH=${H_WMUI_HOME}/local/artifacts/fixes/APIGateway/1101/cds-e2e-postgres/25-09-24/fixes.zip
H_WMUI_APIGW_PRODUCTS_IMAGE_PATH=${H_WMUI_HOME}/local/artifacts/products/APIGateway/1101/cds-e2e-postgres/products.zip
```

### 2. Initialize Database
```bash
# On Windows
init-db.bat

# On Linux/macOS
./init-db.sh
```

This step creates the required database schemas for both MSR and API Gateway.

### 3. Start Application Stack
```bash
docker compose up -d
```

### 4. Verify Deployment
Monitor the logs to ensure all services start successfully:
```bash
docker compose logs -f
```

## Access Points

Once the deployment is complete, access the following URLs:

| Service | URL | Credentials |
|---------|-----|-------------|
| Integration Server Admin | http://localhost:48155 | Administrator/manage |
| API Gateway Admin | http://localhost:48172 | Administrator/manage |
| API Gateway Runtime | http://localhost:48173 | - |
| API Gateway IS Admin | http://localhost:48157 | Administrator/manage |
| Kibana Dashboard | http://localhost:48156 | - |
| Elasticsearch | http://localhost:48120 | - |
| Elasticvue (ES Browser) | http://localhost:48181 | - |
| Database Admin (Adminer) | http://localhost:48180 | postgres/postgres |

## End-to-End Monitoring Configuration

### Instana Agent Configuration
The lab includes E2EM (End-to-End Monitoring) agent configuration for Instana:

```env
# Instana OTEL endpoint configuration
SW_AGENT_OTEL_ENDPOINT=https://<otlp_endpoint>/v1/traces
SW_AGENT_OTEL_HEADERS=api-key#value,Content-Type#application/x-protobuf

# External monitoring system
SW_AGENT_EXTERNAL_TARGET=apm
SW_AGENT_EXTERNAL_TARGET_NAME=Instana1
```

**Important**: Update the `SW_AGENT_OTEL_ENDPOINT` and `SW_AGENT_OTEL_HEADERS` with your actual Instana configuration.

### Monitoring Features
- **Application Performance Monitoring**: Trace API calls through the entire stack
- **Infrastructure Monitoring**: Monitor container resources and health
- **Log Aggregation**: Centralized logging through ELK stack
- **Custom Dashboards**: Pre-configured Kibana dashboards for API Gateway

## Troubleshooting

### Common Issues

#### Repository Path Issues
If you see errors related to missing packages:
```
ERROR - Repository 5s-pub-sub-with-mon-01 not found
```
Verify the path in `H_WMUI_LAB01_PUB_SUB_MON_01_REPO_HOME` is correct and the repository is properly built.

#### Memory Issues
If containers fail to start due to memory constraints:
- Ensure at least 8GB RAM is available
- Consider reducing `mem_limit` values in docker-compose.yml for development

#### Database Connection Issues
If services cannot connect to the database:
1. Verify the database initialization completed successfully
2. Check PostgreSQL container logs: `docker compose logs db`
3. Ensure port 5432 is not in use by another service

#### Container Build Issues
If VM emulator containers fail to build:
1. Ensure access to container registry
2. Verify artifact paths in `.env` file
3. Check network connectivity

### Health Checks
Monitor service health using:
```bash
docker compose ps
```

All services should show "healthy" status once fully started.

### Log Analysis
View logs for specific services:
```bash
# View all logs
docker compose logs

# View specific service logs
docker compose logs esb-vm
docker compose logs apigateway
docker compose logs core-elasticsearch
```

## Known Issues and Limitations

1. **Universal Messaging Health Check**: The UM service lacks a health check configuration, which may cause dependency timing issues during startup.

2. **Resource Requirements**: The stack requires significant system resources. Monitor memory usage and adjust limits as needed.

3. **Network Configuration**: All services use the internal `n1` network. External access is only available through mapped ports.

## Cleanup

To stop and remove all containers and volumes:
```bash
# Stop services
docker compose down

# Remove volumes (WARNING: This deletes all data)
docker compose down -v

# Remove images
docker compose down --rmi all
```

## Support and Documentation

- Review container logs for detailed error information
- Check the `scripts/` directory for container initialization logic
- Refer to individual service documentation for advanced configuration
- Consult webMethods documentation for product-specific troubleshooting

## Laboratory Exercises

This environment enables the following monitoring scenarios:

1. **API Traffic Monitoring**: Deploy and monitor APIs through the complete stack
2. **Performance Analysis**: Use Instana to trace transaction performance
3. **Log Correlation**: Correlate application logs with infrastructure metrics
4. **Dashboard Creation**: Build custom monitoring dashboards in Kibana
5. **Alert Configuration**: Set up monitoring alerts based on performance thresholds

For specific laboratory exercises and use cases, refer to the additional documentation in the parent repository.
