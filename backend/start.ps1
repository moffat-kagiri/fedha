# Fedha Backend Quick Start Script for Windows
# This script activates the virtual environment and starts the server

param(
    [string]$Host = "0.0.0.0",
    [string]$Port = "8000",
    [switch]$SkipMigrate,
    [switch]$SkipChecks
)

Write-Host "🚀 Fedha Backend Quick Start" -ForegroundColor Green
Write-Host "=" * 30

# Check if we're in the backend directory
if (-not (Test-Path "manage.py")) {
    Write-Host "❌ manage.py not found. Please run this script from the backend directory." -ForegroundColor Red
    exit 1
}

# Find and activate virtual environment
$venvPaths = @(".venv", ".v", "venv", "env")
$venvFound = $null

foreach ($venvName in $venvPaths) {
    if (Test-Path $venvName) {
        $venvFound = $venvName
        Write-Host "✅ Found virtual environment: $venvName" -ForegroundColor Green
        break
    }
}

if (-not $venvFound) {
    Write-Host "📦 Creating virtual environment (.venv)..." -ForegroundColor Yellow
    python -m venv .venv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to create virtual environment" -ForegroundColor Red
        exit 1
    }
    $venvFound = ".venv"
}

# Activate virtual environment
$activateScript = "$venvFound\Scripts\Activate.ps1"
if (Test-Path $activateScript) {
    Write-Host "🔄 Activating virtual environment..." -ForegroundColor Cyan
    & $activateScript
} else {
    Write-Host "⚠️  PowerShell activation script not found, using fallback" -ForegroundColor Yellow
}

# Install requirements if needed
if (Test-Path "requirements.txt") {
    $pipExe = "$venvFound\Scripts\pip.exe"
    if (Test-Path $pipExe) {
        Write-Host "📦 Installing/updating requirements..." -ForegroundColor Cyan
        & $pipExe install -r requirements.txt
    }
}

# Build start_server.py arguments
$args = @()
if ($Host -ne "0.0.0.0") { $args += "--host", $Host }
if ($Port -ne "8000") { $args += "--port", $Port }
if ($SkipMigrate) { $args += "--skip-migrate" }
if ($SkipChecks) { $args += "--skip-checks" }

# Start the server
Write-Host "🌐 Starting server..." -ForegroundColor Green
python start_server.py @args
