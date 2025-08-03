# Cloudflare Tunnel Setup Script for Fedha Backend
# This script downloads and sets up cloudflared to create a tunnel to your local server

Write-Host "Setting up Cloudflare Tunnel for Fedha Backend..." -ForegroundColor Cyan

# Check if PowerShell is running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges for installation." -ForegroundColor Yellow
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

# Create a directory for cloudflared if it doesn't exist
$cloudflaredDir = "$env:USERPROFILE\cloudflared"
if (-not (Test-Path $cloudflaredDir)) {
    Write-Host "Creating directory for cloudflared..." -ForegroundColor Green
    New-Item -ItemType Directory -Path $cloudflaredDir | Out-Null
}

# Download cloudflared if not present
$cloudflaredExe = "$cloudflaredDir\cloudflared.exe"
if (-not (Test-Path $cloudflaredExe)) {
    Write-Host "Downloading cloudflared..." -ForegroundColor Green
    $downloadUrl = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
    
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $cloudflaredExe
        Write-Host "Downloaded cloudflared successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to download cloudflared: $_" -ForegroundColor Red
        exit 1
    }
}

# Add to PATH if not already there
$path = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
if (-not $path.Contains($cloudflaredDir)) {
    Write-Host "Adding cloudflared to PATH..." -ForegroundColor Green
    [Environment]::SetEnvironmentVariable("Path", $path + ";$cloudflaredDir", [EnvironmentVariableTarget]::User)
    $env:Path += ";$cloudflaredDir"
    Write-Host "Added to PATH. You may need to restart your PowerShell session." -ForegroundColor Yellow
}

# Check if cloudflared works
try {
    Write-Host "Checking cloudflared version..." -ForegroundColor Green
    & $cloudflaredExe --version
}
catch {
    Write-Host "Failed to run cloudflared: $_" -ForegroundColor Red
    exit 1
}

# Create a config file for the tunnel
$configDir = "$env:USERPROFILE\.cloudflared"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir | Out-Null
}

$configFile = "$configDir\config.yml"
$configContent = @"
# Cloudflare Tunnel configuration for Fedha Backend
tunnel: fedha-backend
credentials-file: $configDir\credentials.json

# Ingress rules for handling traffic
ingress:
  # Route traffic to local Django server
  - hostname: fedha-backend.tunnel
    service: http://localhost:8000
  
  # Catch-all rule to return 404 for any other hostnames
  - service: http_status:404
"@

Write-Host "Creating config file..." -ForegroundColor Green
Set-Content -Path $configFile -Value $configContent

# Start the tunnel in quick mode (no login required)
Write-Host "`nStarting Cloudflare Tunnel in quick mode..." -ForegroundColor Cyan
Write-Host "This will create a temporary tunnel without authentication." -ForegroundColor Yellow
Write-Host "The URL will be valid for this session only." -ForegroundColor Yellow
Write-Host "`nPress Ctrl+C to stop the tunnel when done.`n" -ForegroundColor Magenta

# Run the tunnel
& $cloudflaredExe tunnel --url http://localhost:8000

# This part only runs after the tunnel is stopped
Write-Host "`nTunnel stopped." -ForegroundColor Yellow
Write-Host "To start it again, run: cloudflared tunnel --url http://localhost:8000" -ForegroundColor Green
