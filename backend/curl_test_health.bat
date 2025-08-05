@echo off
echo Testing Django health endpoint with curl...
echo.

echo 1. Testing localhost:
curl -s http://localhost:8000/api/health/
echo.
echo.

echo 2. Testing local IP (192.168.100.6):
curl -s http://192.168.100.6:8000/api/health/
echo.
echo.

echo 3. Testing Cloudflare tunnel:
curl -s https://place-jd-telecom-hi.trycloudflare.com/api/health/
echo.

echo Tests completed! If you don't see valid JSON responses above,
echo there might be connectivity issues.
pause
