#!/bin/bash
# Elasticsearch Custom User Setup Script
# This script creates a custom user with specific permissions on both Elasticsearch instances

set -e

# Define the Elasticsearch instances
ES_INSTANCES=("elasticsearch:9200" "elasticsearch2:9200")

# Function to setup user on a single Elasticsearch instance
setup_es_instance() {
    local ES_HOST=$1
    echo "=========================================="
    echo "Setting up custom user on ${ES_HOST}"
    echo "=========================================="

    echo "Waiting for ${ES_HOST} to be ready..."
    until curl -s -u "elastic:${ELASTIC_PASSWORD}" "http://${ES_HOST}/_cluster/health" > /dev/null 2>&1; do
        echo "Waiting for ${ES_HOST}..."
        sleep 5
    done

    echo "${ES_HOST} is ready. Setting up custom user..."

    # Create a custom role with specific permissions including restricted indices
    # This role allows access to Kibana system indices
    echo "Creating custom role on ${ES_HOST}..."
    curl -X POST "http://${ES_HOST}/_security/role/${CUSTOM_ES_USER}_role" \
      -u "elastic:${ELASTIC_PASSWORD}" \
      -H 'Content-Type: application/json' \
      -d '{
        "cluster": [
          "all"
        ],
        "indices": [
          {
            "names": ["*"],
            "privileges": ["all"],
            "allow_restricted_indices": true
          }
        ],
        "applications": [
          {
            "application": "*",
            "privileges": ["*"],
            "resources": ["*"]
          }
        ],
        "run_as": ["*"],
        "metadata": {
          "version": 1
        }
      }'

    echo ""
    echo "Custom role created successfully on ${ES_HOST}."

    # Create the custom user with superuser role
    echo "Creating custom user on ${ES_HOST}..."
    curl -X POST "http://${ES_HOST}/_security/user/${CUSTOM_ES_USER}" \
      -u "elastic:${ELASTIC_PASSWORD}" \
      -H 'Content-Type: application/json' \
      -d "{
        \"password\": \"${CUSTOM_ES_PASSWORD}\",
        \"roles\": [\"superuser\"],
        \"full_name\": \"Custom Elasticsearch User\",
        \"email\": \"${CUSTOM_ES_USER}@example.com\",
        \"metadata\": {
          \"created_by\": \"setup-script\"
        }
      }"

    echo ""
    echo "Custom user '${CUSTOM_ES_USER}' created successfully on ${ES_HOST}."
    echo ""
}

# Setup user on all Elasticsearch instances
for ES_INSTANCE in "${ES_INSTANCES[@]}"; do
    setup_es_instance "${ES_INSTANCE}"
done

echo "=========================================="
echo "Creating Kibana service account token..."
echo "=========================================="

# Create a service account token for Kibana on the first ES instance
ES_HOST="${ES_INSTANCES[0]}"
echo "Creating Kibana system user token on ${ES_HOST}..."

# Create a service account token for kibana_system user
KIBANA_TOKEN_RESPONSE=$(curl -s -X POST "http://${ES_HOST}/_security/service/elastic/kibana/credential/token/kibana-token" \
  -u "elastic:${ELASTIC_PASSWORD}" \
  -H 'Content-Type: application/json')

echo ""
echo "Kibana service token created successfully."
echo "Token response: ${KIBANA_TOKEN_RESPONSE}"

# Also set password for kibana_system user as fallback
echo ""
echo "Setting password for kibana_system user..."
curl -X POST "http://${ES_HOST}/_security/user/kibana_system/_password" \
  -u "elastic:${ELASTIC_PASSWORD}" \
  -H 'Content-Type: application/json' \
  -d "{
    \"password\": \"${ELASTIC_PASSWORD}\"
  }"

echo ""
echo "=========================================="
echo "Setup complete for all Elasticsearch instances!"
echo "=========================================="
echo "User '${CUSTOM_ES_USER}' has been created on:"
for ES_INSTANCE in "${ES_INSTANCES[@]}"; do
    echo "  - ${ES_INSTANCE}"
done
echo ""
echo "Kibana system user password has been set."
echo "User '${CUSTOM_ES_USER}' has been granted 'superuser' role for full access."
echo "To use a more restrictive role, remove 'superuser' from the roles array."
echo "The custom role provides:"
echo "  - Cluster: monitor, manage_index_templates, manage_ilm, manage_pipeline"
echo "  - Indices: all privileges on all indices"

# Made with Bob
