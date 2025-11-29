#!/bin/bash
# update_tunnel.sh
# Shell script to update Cloudflare tunnel URL in the app

if [ -z "$1" ]; then
    echo "Error: No tunnel URL provided"
    echo "Usage: ./update_tunnel.sh <new_tunnel_url>"
    exit 1
fi

# Get the new tunnel URL from arguments
NEW_TUNNEL_URL="$1"

# Remove https:// prefix if it exists
CLEAN_URL=$(echo "$NEW_TUNNEL_URL" | sed -E 's|^https?://||')

# File paths
API_CONFIG_PATH="./app/lib/config/api_config.dart"
HEALTH_DASHBOARD_PATH="./app/health_dashboard.dart"
CONNECTION_MANAGER_PATH="./app/lib/utils/connection_manager.dart"

# Update ApiConfig.cloudflare()
if grep -q "factory ApiConfig\.cloudflare()" "$API_CONFIG_PATH"; then
    echo "Updating ApiConfig.cloudflare() with new tunnel URL: $CLEAN_URL"
    
    sed -i -E "s|primaryApiUrl: '.*?',(\s*//\s*Cloudflare tunnel URL)|primaryApiUrl: '$CLEAN_URL',\1|" "$API_CONFIG_PATH"
    
    echo "Successfully updated ApiConfig.cloudflare()"
else
    echo "Error: Could not find ApiConfig.cloudflare() in $API_CONFIG_PATH"
fi

# Update health_dashboard.dart
if grep -q "name: 'Cloudflare Tunnel'" "$HEALTH_DASHBOARD_PATH"; then
    echo "Updating Health Dashboard with new tunnel URL: $CLEAN_URL"
    
    sed -i -E "s|baseUrl: 'https://.*?',(\s*//\s*Cloudflare Tunnel)|baseUrl: 'https://$CLEAN_URL',\1|" "$HEALTH_DASHBOARD_PATH"
    
    echo "Successfully updated Health Dashboard"
else
    echo "Error: Could not find Cloudflare Tunnel config in $HEALTH_DASHBOARD_PATH"
fi

# Update ConnectionManager
if grep -q "_connectionOptions" "$CONNECTION_MANAGER_PATH"; then
    echo "Updating ConnectionManager with new tunnel URL: $CLEAN_URL"
    
    sed -i -E "s|'https://.*?',(\s*//\s*Cloudflare tunnel)|'https://$CLEAN_URL',\1|" "$CONNECTION_MANAGER_PATH"
    
    echo "Successfully updated ConnectionManager"
else
    echo "Error: Could not find connection options in $CONNECTION_MANAGER_PATH"
fi

echo "Tunnel URL update completed!"
