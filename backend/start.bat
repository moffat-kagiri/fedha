@echo off
REM Fedha Backend Quick Start Script for Windows

echo 🚀 Fedha Backend Quick Start
echo ==============================

REM Check if we're in the backend directory
if not exist "manage.py" (
    echo ❌ manage.py not found. Please run this script from the backend directory.
    pause
    exit /b 1
)

REM Find virtual environment
set "venv_found="
for %%v in (.venv .v venv env) do (
    if exist "%%v" (
        set "venv_found=%%v"
        echo ✅ Found virtual environment: %%v
        goto :activate_venv
    )
)

REM Create virtual environment if not found
echo 📦 Creating virtual environment (.venv)...
python -m venv .venv
if errorlevel 1 (
    echo ❌ Failed to create virtual environment
    pause
    exit /b 1
)
set "venv_found=.venv"

:activate_venv
REM Activate virtual environment
echo 🔄 Activating virtual environment...
call "%venv_found%\Scripts\activate.bat"

REM Install requirements
if exist "requirements.txt" (
    echo 📦 Installing/updating requirements...
    pip install -r requirements.txt
)

REM Start server
echo 🌐 Starting server...
python start_server.py

pause
