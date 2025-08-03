@echo off
REM Script to start localtunnel for the Fedha backend

echo Starting localtunnel for Fedha...

REM First check if npm is installed
where npm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: npm not found. Please install Node.js and npm first.
    echo Visit: https://nodejs.org/ to download and install Node.js
    exit /b 1
)

echo Using npx to run localtunnel...
npx localtunnel --port 8000 --subdomain tired-dingos-beg

REM If we got here, something went wrong
echo Localtunnel stopped or failed. Check for errors above.
pause
