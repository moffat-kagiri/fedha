@echo off
echo === Fedha Backend Server with Localtunnel ===
echo Starting server at port 8000 with external access...
echo.

echo 1. Starting localtunnel in a separate window...
start cmd /k "npx localtunnel --port 8000 --subdomain beige-insects-lick"

echo 2. Starting Django server...
python start_server.py

echo.
echo === Server shutdown ===
