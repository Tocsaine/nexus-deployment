#!/bin/bash
set -a
source /scripts/.env
set +a

# Configuration
NEXUS_URL="http://localhost:8081"
ADMIN_USER="admin"
CURRENT_PASSWORD="admin123"
NEW_PASSWORD="${NEXUS_ADMIN_PASSWORD}"

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "Error: curl is required but not installed. Please install curl."
    exit 1
fi

# Function to check Nexus API availability
check_nexus_status() {
    local response=$(curl -s -o /dev/null -w "%{http_code}" -u "${ADMIN_USER}:${CURRENT_PASSWORD}" \
        "${NEXUS_URL}/service/rest/v1/status")
    if [ "$response" -eq 200 ]; then
        return 0 # Nexus is up
    else
        echo "Error: Nexus API is not available or credentials are incorrect. HTTP status: ${response}"
        exit 1
    fi
}

# Function to change admin password
change_admin_password() {
    local user_id=$1
    local new_password=$2

    echo "Changing password for user '${user_id}'..."
    local response=$(curl -s -w "%{http_code}" -u "${ADMIN_USER}:${CURRENT_PASSWORD}" \
        -H "Content-Type: text/plain" \
        -X PUT "${NEXUS_URL}/service/rest/v1/security/users/${user_id}/change-password" \
        -d "${new_password}" -o /tmp/nexus_response.json)

    local response_body=$(cat /tmp/nexus_response.json 2>/dev/null || echo "")

    if [ "$response" -eq 204 ]; then
        echo "Password for user '${user_id}' changed successfully."
        return 0
    else
        echo "Error: Failed to change password for user '${user_id}'. HTTP status: ${response}"
        echo "Response body: ${response_body}"
        exit 1
    fi
}

# Main execution
echo "Starting Nexus admin password change script..."

# Check Nexus API status
check_nexus_status

# Change admin password
change_admin_password "$ADMIN_USER" "$NEW_PASSWORD"

echo "Password change completed successfully."


exit 0
