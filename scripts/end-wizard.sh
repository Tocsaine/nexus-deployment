#!/bin/bash
set -a
source /scripts/.env
set +a

# Configuration
NEXUS_URL="http://localhost:8081"
ADMIN_USER="admin"
ADMIN_PASSWORD="${NEXUS_ADMIN_PASSWORD}"


# Function to disable anonymous access
disable_anonymous_access() {
    echo "Disabling anonymous access..."
    local payload=$(cat <<EOF
{
    "enabled": false,
    "userId": "anonymous",
    "realmName": "NexusAuthorizingRealm"
}
EOF
)

    local response=$(curl -s -w "%{http_code}" -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
        -H "Content-Type: application/json" \
        -X PUT "${NEXUS_URL}/service/rest/v1/security/anonymous" \
        -d "${payload}" -o /tmp/nexus_anonymous_response.json)
    local response_body=$(cat /tmp/nexus_anonymous_response.json 2>/dev/null || echo "")

    if [ "$response" -eq 204 ]; then
        echo "Anonymous access disabled successfully."
        return 0
    else
        echo "Error: Failed to disable anonymous access. HTTP status: ${response}"
        echo "Response body: ${response_body}"
        exit 1
    fi
}

# Main execution
echo "Starting Nexus wizard setup completion script..."

disable_anonymous_access
echo "Nexus wizard setup completed successfully."


exit 0
