@echo off
echo ======================================
echo      FEDHA CONNECTION VERIFICATION    
echo ======================================
echo.

REM Check if Django server is running
echo [1] Checking if Django server is running...
curl -s http://127.0.0.1:8000/api/health/ > nul 2>&1
if %ERRORLEVEL% EQU 0 (
  echo ✅ Django server is running
) else (
  echo ❌ Django server is NOT running. Please start it with:
  echo    cd backend ^&^& python manage.py runserver 0.0.0.0:8000
  exit /b 1
)

REM Test the health endpoint
echo.
echo [2] Testing health endpoint...
echo Health endpoint response:
curl -s http://127.0.0.1:8000/api/health/
echo.
echo.

REM Get local IP address
echo [3] Getting local network IP...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
  set IP=%%a
  goto :found_ip
)
:found_ip
echo Your local IP address is:%IP%
echo Make sure this matches the primaryApiUrl in api_config.dart
echo.

REM Verify Flutter app config
echo [4] Checking Flutter app configuration...
if exist "..\app\lib\config\api_config.dart" (
  echo API config file exists at: app/lib/config/api_config.dart
  findstr /C:"primaryApiUrl" "..\app\lib\config\api_config.dart"
) else (
  echo ❌ Could not find API config file
)

echo.
echo ======================================
echo      CONNECTION SETUP COMPLETE       
echo ======================================
echo.
echo Next steps:
echo 1. Start your Flutter app with: flutter run
echo 2. Verify connectivity in the app
echo 3. If issues persist, check CONNECTION_GUIDE.md for troubleshooting
