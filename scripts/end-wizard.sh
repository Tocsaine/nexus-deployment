#!/bin/bash
set -a
source /scripts/.env
set +a

# Configuration
NEXUS_URL="http://localhost:8081"
ADMIN_USER="admin"
ADMIN_PASSWORD="${NEXUS_ADMIN_PASSWORD}" # Replace with current admin password or use env var

# Function to check if setup wizard is active
check_wizard_active() {
    local response=$(curl -s -w "%{http_code}" -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
        "${NEXUS_URL}/service/rest/v1/setup" -o /tmp/nexus_setup_response.json)
    local response_body=$(cat /tmp/nexus_setup_response.json 2>/dev/null || echo "")

    if [ "$response" -eq 200 ]; then
        local is_complete=$(echo "$response_body" | grep -o '"complete":true')
        if [ -z "$is_complete" ]; then
            echo "Setup wizard is active."
            return 0 # Wizard active
        else
            echo "Setup wizard is already complete. Skipping setup steps."
            return 1 # Wizard complete
        fi
    else
        echo "Error: Failed to check setup wizard status. HTTP status: ${response}"
        echo "Response body: ${response_body}"
        exit 1
    fi
}

# Function to accept license agreement
accept_license() {
    echo "Accepting license agreement..."
    local response=$(curl -s -w "%{http_code}" -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
        -H "Content-Type: application/json" \
        -X POST "${NEXUS_URL}/service/rest/v1/setup/license" -o /tmp/nexus_license_response.json)
    local response_body=$(cat /tmp/nexus_license_response.json 2>/dev/null || echo "")

    if [ "$response" -eq 204 ]; then
        echo "License agreement accepted successfully."
        return 0
    else
        echo "Error: Failed to accept license agreement. HTTP status: ${response}"
        echo "Response body: ${response_body}"
        exit 1
    fi
}

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


# Check if wizard is active
if check_wizard_active; then
    # Step 1: Accept license
    accept_license

    # Step 2: Password already changed (skip, as you confirmed it's done)

    # Step 3: Disable anonymous access
    disable_anonymous_access

    echo "Nexus wizard setup completed successfully."
else
    echo "No further setup required."
fi

exit 0
