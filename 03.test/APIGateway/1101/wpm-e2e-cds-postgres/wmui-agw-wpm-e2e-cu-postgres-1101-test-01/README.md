# API Gateway 1101 with PostgreSQL CDS Test Harness

This test harness validates the `APIGateway/1101/wpm-e2e-cu-postgres` template, which sets up API Gateway with Central Directory Services database (CDS) on PostgreSQL.

## Files Overview

- **`docker-compose-init.yml`** - Database initialization setup (run once)
- **`docker-compose.yml`** - Main application setup (reusable)
- **`scripts-init/dbInitEntrypoint.sh`** - Database initialization script
- **`scripts/containerEntrypoint.sh`** - Main application startup script
- **`EXAMPLE.env`** - Environment configuration template
- **`.env`** - Local environment configuration (not committed)

## Overview

This test harness combines:
- **API Gateway 1101** - Core API Gateway functionality
- **PostgreSQL Database** - For Central DataStore (CDS) 
- **Elasticsearch** - For analytics and logging
- **Kibana** - For dashboards and visualization
- **Adminer** - For database administration

## Prerequisites

1. Ensure you have the required installation assets:
   - Default installer binary
   - Update Manager bootstrap binary  
   - Products ZIP file for `APIGateway/1101/wpm-e2e-cu-postgres`
   - Fixes ZIP file for the corresponding version

2. Copy `EXAMPLE.env` to `.env` and update the paths to point to your local assets.

## Usage

### Two-Step Setup Process

This test harness uses a two-step process to ensure proper database initialization:

#### Step 1: Database Initialization (Run Once)
The first step creates and initializes the PostgreSQL database with webMethods schemas:

```bash
# Copy and customize environment file
cp EXAMPLE.env .env
# Edit .env file with correct paths to your local assets

init-db.bat

## OR

# Initialize the database (run only once or when volumes are deleted)
docker-compose -f docker-compose-init.yml up

# Wait for initialization to complete, then stop the init containers
docker-compose -f docker-compose-init.yml down
```

#### Step 2: Main Application (Can be run repeatedly)
The second step starts the full API Gateway application with the pre-initialized database:

```bash
# Start the main application
docker-compose up -d

# Monitor the API Gateway startup
docker-compose logs -f apigateway
```

### Important Notes

- **Run initialization only once**: The database initialization (`docker-compose-init.yml`) should only be run when setting up fresh volumes or when the database is empty.
- **Reusable main setup**: The main setup (`docker-compose.yml`) can be run repeatedly using the same initialized database volumes.
- **Volume persistence**: The database volumes (`db-data`) persist the initialized schemas between runs.

### Troubleshooting

If you see an error like "Database is not initialized with webMethods schemas!", you need to run the initialization step first:

```bash
docker-compose down -v  # Remove all volumes
docker-compose -f docker-compose-init.yml up  # Re-initialize
docker-compose -f docker-compose-init.yml down
docker-compose up -d  # Start main application
```

## Access Points

Once the setup is complete, you can access:

- **API Gateway Admin UI**: `http://localhost:${H_WMUI_PORT_PREFIX}55`
- **API Gateway REST**: `http://localhost:${H_WMUI_PORT_PREFIX}72`
- **API Gateway HTTPS**: `https://localhost:${H_WMUI_PORT_PREFIX}73`
- **Database Admin (Adminer)**: `http://localhost:${H_WMUI_PORT_PREFIX}80`
- **Elasticsearch**: `http://localhost:${H_WMUI_PORT_PREFIX}20`
- **Elasticvue**: `http://localhost:${H_WMUI_PORT_PREFIX}81`
- **Kibana**: `http://localhost:${H_WMUI_PORT_PREFIX}56`

## Database Configuration

The test uses PostgreSQL with these default settings:
- **Host**: `postgresql-db-server` (internal network)
- **Database**: `postgres`
- **User**: `postgres`
- **Password**: `postgres`
- **Port**: `5432`

## Features Tested

- **Database Schema Initialization**: Creates webMethods database schemas in PostgreSQL
- **API Gateway Installation**: Installs API Gateway with CDS configuration
- **Database Connectivity**: Validates connection to pre-initialized PostgreSQL database
- **Integration Server Startup**: Ensures proper startup and health checks
- **Elasticsearch Integration**: Connects to Elasticsearch for analytics
- **Kibana Dashboard Integration**: Provides dashboard access and configuration

## Cleanup

### Stop Application (Keep Database)
To stop the application while preserving the initialized database:
```bash
docker-compose down -t 20
```

### Complete Cleanup (Remove Everything)
To stop and remove all containers and volumes (requires re-initialization):
```bash
# Stop main application
docker-compose down -t 20 -v

# Clean up any remaining init containers/volumes
docker-compose -f docker-compose-init.yml down -v
```

### Restart After Cleanup
After complete cleanup, you need to re-initialize:
```bash
docker-compose -f docker-compose-init.yml up    # Re-initialize database
docker-compose -f docker-compose-init.yml down
docker-compose up -d                            # Start application
```

## Notes

- Default port prefix is `442` (configurable via `H_WMUI_PORT_PREFIX`)
- The setup automatically waits for database availability
- API Gateway health check ensures proper startup
- All logs are available via `docker-compose logs`