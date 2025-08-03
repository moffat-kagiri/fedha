# Setting Up External Access for Fedha Backend

This guide provides different methods to make your locally running Fedha backend server accessible to physical devices, emulators, or external testers.

## Method 1: Local Network Access (Recommended for Development)

This is the simplest method for testing on devices connected to the same network (WiFi/LAN).

### Setup

1. Run the local network setup script:

```bash
# In the backend directory
python setup_local_network.py
```

2. Start the server with network access:

```bash
# In the backend directory
python start_server.py --host 0.0.0.0
```

3. On Windows, you can use the provided PowerShell script:

```powershell
# In the backend directory
.\start_local_server.ps1
```

4. Your app needs to be configured to use the URL provided by the setup script (http://YOUR_IP:8000)

### Testing Connection

Run the test script created by the setup:

```bash
# In the app directory
flutter run -d chrome test_local_network.dart
```

## Method 2: USB Debugging (Android Only)

For direct connection to Android devices via USB.

1. Start the server with USB debugging option:

```bash
# In the backend directory
python start_server.py --usb-debug
```

2. Connect your device via USB and enable USB debugging in developer options

3. Forward the port using ADB:

```bash
adb reverse tcp:8000 tcp:8000
```

4. Configure your app to use http://localhost:8000 or http://10.0.2.2:8000 for emulator

## Method 3: Localtunnel (When Available)

For exposing your server to the internet without needing to configure your router or firewall.

### Requirements

- Node.js and NPM installed

### Setup

1. Start your server normally:

```bash
# In the backend directory
python start_server.py
```

2. In a separate terminal, start Localtunnel:

```bash
npx localtunnel --port 8000
```

3. Configure your app to use the URL provided by Localtunnel

### Common Issues with Localtunnel

- **Connection refused error**: Some networks block the required ports. Try using a different network or method
- **Tunnel unavailable (503)**: The service might be temporarily down, try again later
- **Slow response times**: This is normal as traffic is being routed through an external server

## Method 4: ngrok (Alternative to Localtunnel)

Another service for exposing local servers to the internet.

### Setup

1. [Install ngrok](https://ngrok.com/download)
2. Start ngrok:

```bash
ngrok http 8000
```

3. Configure your app to use the URL provided by ngrok

## Method 5: Cloudflare Tunnel

For more reliable tunneling, especially on restrictive networks.

### Setup

1. [Install cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/)
2. Log in to Cloudflare:

```bash
cloudflared tunnel login
```

3. Create and start a tunnel:

```bash
cloudflared tunnel --url http://localhost:8000
```

4. Configure your app to use the URL provided by Cloudflare

## Troubleshooting

### Cannot Connect to Server

1. Verify the server is running
2. Check firewall settings and allow the required port (default: 8000)
3. Make sure the device is on the same network (for local network method)
4. Check ALLOWED_HOSTS in backend/settings.py includes your IP or '*'

### API Connection Errors in the App

1. Verify the correct URL is set in the app configuration
2. Try accessing the API through a web browser to test connectivity
3. Check for HTTPS vs HTTP mismatches in the URL

### Network Restrictions

If your network blocks outgoing connections (common in corporate environments):
- Try USB debugging instead of tunneling services
- Use mobile hotspot instead of corporate/school WiFi
- Switch to a local network method instead of tunneling
