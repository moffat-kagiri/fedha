@echo off
echo Starting Localtunnel for Fedha Backend...
echo URL: https://beige-insects-lick.loca.lt

npx localtunnel --port 8000 --subdomain beige-insects-lick

echo Tunnel closed. Press any key to exit.
pause
