# update_tunnel.ps1
# PowerShell script to update Cloudflare tunnel URL in the app

param (
    [Parameter(Mandatory=$true)]
    [string]$newTunnelUrl
)

# Remove https:// prefix if it exists
$cleanUrl = $newTunnelUrl -replace "^https?://", ""

# File paths
$apiConfigPath = ".\app\lib\config\api_config.dart"
$healthDashboardPath = ".\app\health_dashboard.dart"
$connectionManagerPath = ".\app\lib\utils\connection_manager.dart"

# Update ApiConfig.cloudflare()
$apiConfigContent = Get-Content -Path $apiConfigPath -Raw

if ($apiConfigContent -match "factory ApiConfig\.cloudflare\(\)") {
    Write-Host "Updating ApiConfig.cloudflare() with new tunnel URL: $cleanUrl"
    
    $updatedContent = $apiConfigContent -replace "primaryApiUrl: '.*?',(\s*//\s*Cloudflare tunnel URL)", "primaryApiUrl: '$cleanUrl',`$1"
    Set-Content -Path $apiConfigPath -Value $updatedContent
    
    Write-Host "Successfully updated ApiConfig.cloudflare()"
} else {
    Write-Host "Error: Could not find ApiConfig.cloudflare() in $apiConfigPath"
}

# Update health_dashboard.dart
$dashboardContent = Get-Content -Path $healthDashboardPath -Raw

if ($dashboardContent -match "name: 'Cloudflare Tunnel'") {
    Write-Host "Updating Health Dashboard with new tunnel URL: $cleanUrl"
    
    $updatedDashboard = $dashboardContent -replace "baseUrl: 'https://.*?',(\s*//\s*Cloudflare Tunnel)", "baseUrl: 'https://$cleanUrl',`$1"
    Set-Content -Path $healthDashboardPath -Value $updatedDashboard
    
    Write-Host "Successfully updated Health Dashboard"
} else {
    Write-Host "Error: Could not find Cloudflare Tunnel config in $healthDashboardPath"
}

# Update ConnectionManager
$connectionManagerContent = Get-Content -Path $connectionManagerPath -Raw

if ($connectionManagerContent -match "_connectionOptions") {
    Write-Host "Updating ConnectionManager with new tunnel URL: $cleanUrl"
    
    $updatedManager = $connectionManagerContent -replace "'https://.*?',(\s*//\s*Cloudflare tunnel)", "'https://$cleanUrl',`$1"
    Set-Content -Path $connectionManagerPath -Value $updatedManager
    
    Write-Host "Successfully updated ConnectionManager"
} else {
    Write-Host "Error: Could not find connection options in $connectionManagerPath"
}

Write-Host "Tunnel URL update completed!"
