@echo off
echo ===================================================
echo Fedha Django Server Connectivity Troubleshooter
echo ===================================================
echo.
echo This script will help diagnose network connectivity issues
echo with your Django backend server.
echo.

REM Check if Django server is running
echo Checking if Django server is running...
powershell -Command "Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue" > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [SUCCESS] Django server is running on port 8000
) else (
    echo [WARNING] Django server doesn't appear to be running on port 8000
    echo           Start it with: python manage.py runserver 0.0.0.0:8000
)
echo.

REM Get IP address
echo Checking network configuration...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /r "IPv4.*192\.168\."') do (
    set IP_ADDR=%%a
    set IP_ADDR=!IP_ADDR:~1!
    goto :found_ip
)
:found_ip
echo Your local IP address appears to be: %IP_ADDR%
echo.

REM Check firewall status for port 8000
echo Checking Windows Firewall status for port 8000...
netsh advfirewall firewall show rule name=all | findstr /C:"LocalPort  8000" > nul
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Found firewall rule(s) for port 8000
) else (
    echo [WARNING] No specific firewall rule found for port 8000
    echo           This might be blocking network connections to your Django server
    echo.
    echo Would you like to create a firewall rule to allow inbound connections to port 8000? (Y/N)
    set /p CREATE_RULE=
    if /i "!CREATE_RULE!"=="Y" (
        echo Creating firewall rule for Django development server...
        netsh advfirewall firewall add rule name="Django Dev Server" dir=in action=allow protocol=TCP localport=8000
        echo Firewall rule created.
    )
)
echo.

REM Check local connectivity
echo Testing local connectivity to Django server...
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:8000/api/health/' -UseBasicParsing -TimeoutSec 2; Write-Host \"[SUCCESS] Local connection working! Status code: $($response.StatusCode)\"; } catch { Write-Host \"[WARNING] Could not connect to localhost:8000/api/health/: $_\" }"
echo.

echo ===================================================
echo Network Connection Steps to Try
echo ===================================================
echo.
echo 1. Make sure Django server is running with:
echo    python manage.py runserver 0.0.0.0:8000
echo.
echo 2. Check if ALLOWED_HOSTS in settings.py includes your IP address:
echo    Current IP detected as: %IP_ADDR%
echo.
echo 3. Try temporarily disabling Windows Defender Firewall to test if
echo    that's blocking the connection:
echo    netsh advfirewall set allprofiles state off
echo.
echo 4. If using the Cloudflare tunnel, ensure it's running:
echo    %TEMP%\cloudflared.exe tunnel --url http://localhost:8000
echo.
echo 5. Check if the Django server correctly handles CORS with cross-origin
echo    requests by ensuring corsheaders is installed and configured.
echo.

echo ===================================================
echo Press any key to exit...
pause > nul
