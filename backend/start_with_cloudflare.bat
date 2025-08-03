@echo off
REM Script to run Fedha Backend with a public URL via Cloudflare
REM This script uses Cloudflare's quick tunnels which don't require login

echo Starting Fedha Backend with Cloudflare Tunnel...
echo.

REM Check if Python is available
where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Python not found
    echo Install Python from https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Start Django server in the background
start cmd /c "python start_server.py"
echo Django server starting...
echo.

REM Check if cloudflared is installed
where cloudflared >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Using existing cloudflared installation
    cloudflared tunnel --url http://localhost:8000
) else (
    echo Cloudflared not found, downloading temporary copy...
    
    REM Create a temporary directory
    mkdir temp_cloudflared 2>nul
    cd temp_cloudflared
    
    REM Download cloudflared
    curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -o cloudflared.exe
    
    if exist cloudflared.exe (
        echo Starting tunnel...
        cloudflared.exe tunnel --url http://localhost:8000
        
        REM Clean up after tunnel is closed
        cd ..
        rmdir /s /q temp_cloudflared
    ) else (
        echo Failed to download cloudflared
        echo Please install it manually from: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/
    )
)

echo.
echo Tunnel closed. The Django server may still be running.
echo To stop it, find the command window and press Ctrl+C
pause
