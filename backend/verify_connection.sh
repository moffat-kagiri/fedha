#!/bin/bash
# Script to verify the Fedha network connection setup

echo "======================================"
echo "     FEDHA CONNECTION VERIFICATION    "
echo "======================================"
echo ""

# Check if Django server is running
echo "[1] Checking if Django server is running..."
curl -s http://127.0.0.1:8000/api/health/ > /dev/null
if [ $? -eq 0 ]; then
  echo "✅ Django server is running"
else
  echo "❌ Django server is NOT running. Please start it with:"
  echo "   cd backend && python manage.py runserver 0.0.0.0:8000"
  exit 1
fi

# Test the health endpoint
echo ""
echo "[2] Testing health endpoint..."
HEALTH_RESULT=$(curl -s http://127.0.0.1:8000/api/health/)
echo "Health endpoint response:"
echo $HEALTH_RESULT | python -m json.tool
echo ""

# Get local IP address
echo "[3] Getting local network IP..."
IP_ADDRESS=$(ipconfig | grep -A 5 "Wireless LAN adapter" | grep "IPv4" | cut -d ":" -f 2 | tr -d " ")
echo "Your local IP address is: $IP_ADDRESS"
echo "Make sure this matches the primaryApiUrl in api_config.dart"
echo ""

# Verify Flutter app config
echo "[4] Checking Flutter app configuration..."
if [ -f ../app/lib/config/api_config.dart ]; then
  echo "API config file exists at: app/lib/config/api_config.dart"
  grep -A 10 "primaryApiUrl" ../app/lib/config/api_config.dart | head -n 10
else
  echo "❌ Could not find API config file"
fi

echo ""
echo "======================================"
echo "     CONNECTION SETUP COMPLETE       "
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Start your Flutter app with: flutter run"
echo "2. Verify connectivity in the app"
echo "3. If issues persist, check CONNECTION_GUIDE.md for troubleshooting"
