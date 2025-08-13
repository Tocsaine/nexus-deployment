#!/bin/bash
set -a
source /scripts/.env
set +a

# Configuration
NEXUS_URL="http://localhost:8081"
ADMIN_USER="admin"
ADMIN_PASSWORD="${NEXUS_ADMIN_PASSWORD}"
DOCKER_REPO_NAME="private-docker-hosted"
DOCKER_PORT=8344
RPM_REPO_NAME="private-rpm-hosted"
BLOBSTORE_DOCKER="docker-blobs"
BLOBSTORE_RPM="rpm-blobs"

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "Error: curl not installed"
    exit 1
fi

# Function to check if blobstore exists
check_blobstore_exists() {
    local blobstore_name=$1
    local response=$(curl -s -o /dev/null -w "%{http_code}" -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
        "${NEXUS_URL}/service/rest/v1/blobstores/${blobstore_name}")
    [ "$response" -eq 200 ] && return 0 || return 1
}

# Function to create blobstore
create_blobstore() {
    local blobstore_name=$1
    local blobstore_path=$2

    check_blobstore_exists "$blobstore_name" && { echo "Blobstore '${blobstore_name}' exists"; return 0; }

    echo "Creating blobstore '${blobstore_name}'..."
    local payload="{\"name\":\"${blobstore_name}\",\"path\":\"${blobstore_path}\"}"
    local response=$(curl -s -w "%{http_code}" -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
        -H "Content-Type: application/json" -X POST "${NEXUS_URL}/service/rest/v1/blobstores/file" \
        -d "${payload}" -o /tmp/nexus_blobstore_response.json)
    local response_body=$(cat /tmp/nexus_blobstore_response.json 2>/dev/null || echo "")

    if [ "$response" -eq 201 ] || [ "$response" -eq 204 ]; then
        echo "Blobstore '${blobstore_name}' created"
        return 0
    else
        echo "Error: Failed to create blobstore '${blobstore_name}'. HTTP: ${response}"
        echo "Response: ${response_body}"
        exit 1
    fi
}

# Function to check if repository exists
check_repo_exists() {
    local repo_name=$1
    local response=$(curl -s -o /dev/null -w "%{http_code}" -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
        "${NEXUS_URL}/service/rest/v1/repositories/${repo_name}")
    [ "$response" -eq 200 ] && return 0 || return 1
}

# Function to create Docker hosted repository
create_docker_repo() {
    local repo_name=$1
    local port=$2
    local blobstore=$3

    check_repo_exists "$repo_name" && { echo "Docker repository '${repo_name}' exists"; return 0; }

    echo "Creating Docker repository '${repo_name}'..."
    local payload="{\"name\":\"${repo_name}\",\"online\":true,\"storage\":{\"blobStoreName\":\"${blobstore}\",\"strictContentTypeValidation\":true,\"writePolicy\":\"ALLOW\"},\"docker\":{\"v1Enabled\":false,\"forceBasicAuth\":true,\"httpPort\":${port}}}"
    local response=$(curl -s -w "%{http_code}" -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
        -H "Content-Type: application/json" -X POST "${NEXUS_URL}/service/rest/v1/repositories/docker/hosted" \
        -d "${payload}" -o /tmp/nexus_docker_response.json)
    local response_body=$(cat /tmp/nexus_docker_response.json 2>/dev/null || echo "")

    if [ "$response" -eq 201 ]; then
        echo "Docker repository '${repo_name}' created on port ${port}"
        return 0
    else
        echo "Error: Failed to create Docker repository '${repo_name}'. HTTP: ${response}"
        echo "Response: ${response_body}"
        exit 1
    fi
}

# Function to create RPM (Yum) hosted repository
create_rpm_repo() {
    local repo_name=$1
    local blobstore=$2

    check_repo_exists "$repo_name" && { echo "RPM repository '${repo_name}' exists"; return 0; }

    echo "Creating RPM repository '${repo_name}'..."
    local payload="{\"name\":\"${repo_name}\",\"online\":true,\"storage\":{\"blobStoreName\":\"${blobstore}\",\"strictContentTypeValidation\":true,\"writePolicy\":\"ALLOW_ONCE\"},\"yum\":{\"repodataDepth\":0,\"deployPolicy\":\"STRICT\"}}"
    local response=$(curl -s -w "%{http_code}" -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
        -H "Content-Type: application/json" -X POST "${NEXUS_URL}/service/rest/v1/repositories/yum/hosted" \
        -d "${payload}" -o /tmp/nexus_rpm_response.json)
    local response_body=$(cat /tmp/nexus_rpm_response.json 2>/dev/null || echo "")

    if [ "$response" -eq 201 ]; then
        echo "RPM repository '${repo_name}' created"
        return 0
    else
        echo "Error: Failed to create RPM repository '${repo_name}'. HTTP: ${response}"
        echo "Response: ${response_body}"
        exit 1
    fi
}

# Main execution
create_blobstore "$BLOBSTORE_DOCKER" "/nexus-data/blobs/docker"
create_blobstore "$BLOBSTORE_RPM" "/nexus-data/blobs/rpm"
create_docker_repo "$DOCKER_REPO_NAME" "$DOCKER_PORT" "$BLOBSTORE_DOCKER"
create_rpm_repo "$RPM_REPO_NAME" "$BLOBSTORE_RPM"

echo "Done"
exit 0
