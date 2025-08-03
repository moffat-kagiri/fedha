# Fedha Backend Local Network Startup Script for Windows
# This script sets up local network access and starts the Django server

# ANSI Color codes for PowerShell
$ESC = [char]27
$GREEN = "$ESC[32m"
$YELLOW = "$ESC[33m"
$RESET = "$ESC[0m"
$CYAN = "$ESC[36m"
$RED = "$ESC[31m"

Write-Host "$GREEN🔧 Setting up Fedha Backend for local network access...$RESET"

# Get directory of this script
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $ScriptPath

# Run the local network setup script
Write-Host "$CYAN📡 Setting up network configuration...$RESET"
python setup_local_network.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "$RED❌ Failed to setup local network configuration$RESET"
    exit 1
}

# Start the Django server
Write-Host "$YELLOW🚀 Starting Django server...$RESET"
Write-Host "$CYAN💡 Press Ctrl+C to stop the server$RESET"
python start_server.py --host 0.0.0.0

# Handle server exit
Write-Host "$RED🛑 Server stopped$RESET"
