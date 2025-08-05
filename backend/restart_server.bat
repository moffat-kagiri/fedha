@echo off
echo ===================================================
echo Starting Django Server for Fedha Project
echo ===================================================
echo.
echo This will start the Django server on all network interfaces
echo (0.0.0.0) so it can be accessed across the local network.
echo.
echo Press CTRL+C to stop the server
echo.

REM Kill any existing Python processes using port 8000
echo Checking for existing Django processes...
for /f "tokens=5" %%a in ('netstat -ano ^| find ":8000" ^| find "LISTENING"') do (
    echo Found existing process with PID %%a, terminating...
    taskkill /F /PID %%a >nul 2>&1
)

echo Starting Django server...
echo.
python manage.py runserver 0.0.0.0:8000
