# External Access Options for Fedha Backend

This guide provides multiple methods to expose your local Fedha backend server to the internet or other devices for testing.

## Table of Contents
1. [Cloudflare Tunnel (Recommended)](#cloudflare-tunnel-recommended)
2. [Localtunnel (Alternative)](#localtunnel-alternative)
3. [Network Access (Local Network Only)](#network-access-local-network-only)
4. [Updating the App Configuration](#updating-the-app-configuration)
5. [Troubleshooting](#troubleshooting)

## Cloudflare Tunnel (Recommended)

Cloudflare Tunnel (formerly Argo Tunnel) is a reliable service that creates a secure tunnel between your local server and the internet. It works well even in restrictive network environments.

### Quick Start

We've created a simple script to set this up for you:

```bash
# Run the batch file (Windows)
start_with_cloudflare.bat
```

This script will:
1. Start your Django backend server
2. Download and run cloudflared if needed
3. Create a tunnel and provide a public URL

When you see a URL like `https://something-random.trycloudflare.com`, that's your public backend URL!

### Manual Setup

If the script doesn't work, you can install cloudflared manually:

1. Download from [Cloudflare's website](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/)
2. Run your Django server: `python start_server.py`
3. In another terminal, run: `cloudflared tunnel --url http://localhost:8000`

## Localtunnel (Alternative)

Localtunnel is another option but may have connectivity issues in some networks.

### Quick Start

```bash
# Install Localtunnel (requires Node.js and npm)
npm install -g localtunnel

# Start your Django server
python start_server.py

# In another terminal, create the tunnel
lt --port 8000
```

## Network Access (Local Network Only)

If you just need to access the server from devices on your local network:

1. Start the server with: `python start_server.py`
2. Find your local IP address (shown in the server startup message)
3. Use the URL format: `http://<your-local-ip>:8000` (e.g., `http://192.168.1.100:8000`)

## Updating the App Configuration

After getting your public URL, you need to update your Flutter app to use it:

```bash
# Run the updater script and follow the prompts
python update_api_config.py
```

Or manually:
1. Open `app/lib/services/api/api_config.dart`
2. Find the development configuration and replace the URL
3. Make sure to use `http://` or `https://` as appropriate

## Troubleshooting

### "Connection refused" or "Tunnel unavailable"

- **Firewall issues**: Your network may be blocking the tunnel service
  - Try the Cloudflare Tunnel method which often works better in restrictive networks
  - Check your firewall settings and allow outbound connections on ports 22, 80, 443 and 8000

### "Cannot connect to server" from mobile app

- Verify the server is running and accessible via the URL in a browser
- Check that the API configuration in the app is using the correct URL
- Ensure you're using the right protocol (`http://` vs `https://`)

### "Certificate verification failed"

- For HTTP URLs, make sure you've disabled SSL verification in your app
- For HTTPS URLs with self-signed certificates, you may need to add certificate exceptions

### Tunnel disconnects frequently

- Some free tunnel services have timeouts or connection limits
- For longer development sessions, consider using Cloudflare Tunnel which is more stable
