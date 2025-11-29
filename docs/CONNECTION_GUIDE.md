# Fedha App Connection Guide

This guide explains how to set up and use different connection methods for the Fedha app.

## Connection Options

The Fedha app supports multiple connection methods to the backend:

1. **Direct Local Connection**: http://localhost:8000
   - For development on the same machine
   - Fastest performance
   - No external access

2. **Local Network Connection**: http://192.168.1.100:8000 (adjust IP as needed)
   - For development across devices on the same network
   - Good performance
   - Limited to devices on the same network

3. **Cloudflare Tunnel**: https://place-jd-telecom-hi.trycloudflare.com (or your current tunnel URL)
   - For remote access from anywhere
   - Secure HTTPS connection
   - Free tier has limitations (disconnects after 24h)

## Setting Up Cloudflare Tunnel

### Quick Start (Manual)

1. Download Cloudflared:
   ```powershell
   Invoke-WebRequest -Uri https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe -OutFile "$env:TEMP\cloudflared.exe"
   ```

2. Start the tunnel:
   ```powershell
   cd C:\GitHub\fedha\backend
   & "$env:TEMP\cloudflared.exe" tunnel --url http://localhost:8000
   ```

3. Note the generated URL (e.g., https://place-jd-telecom-hi.trycloudflare.com)

### Permanent Named Tunnel (Production)

For a more stable solution, set up a named tunnel:

1. Log in to Cloudflare:
   ```powershell
   & "$env:TEMP\cloudflared.exe" login
   ```

2. Create a named tunnel:
   ```powershell
   & "$env:TEMP\cloudflared.exe" tunnel create fedha-app
   ```

3. Configure the tunnel:
   ```powershell
   # Create config file
   $configContent = @"
tunnel: <YOUR_TUNNEL_ID>
credentials-file: C:\GitHub\fedha\.cloudflared\<YOUR_TUNNEL_ID>.json
ingress:
  - hostname: fedha-app.yourdomain.com
    service: http://localhost:8000
  - service: http_status:404
"@
   New-Item -Path "C:\GitHub\fedha\.cloudflared\" -ItemType Directory -Force
   Set-Content -Path "C:\GitHub\fedha\.cloudflared\config.yml" -Value $configContent
   ```

4. Route DNS to your tunnel:
   ```powershell
   & "$env:TEMP\cloudflared.exe" tunnel route dns <YOUR_TUNNEL_ID> fedha-app.yourdomain.com
   ```

5. Start the tunnel:
   ```powershell
   & "$env:TEMP\cloudflared.exe" tunnel run fedha-app
   ```

## Testing Connections

Use the provided health dashboard to test all connection options:

```powershell
cd C:\GitHub\fedha\app
flutter run -d chrome health_dashboard.dart
```

## Troubleshooting

### Backend Not Responding

1. Ensure Django server is running:
   ```powershell
   cd C:\GitHub\fedha\backend
   python manage.py runserver 0.0.0.0:8000
   ```

2. Check if the server is bound to all interfaces (0.0.0.0)

3. Verify your local network IP address is correct in ALLOWED_HOSTS:
   ```
   # Run the IP update script to automatically detect and configure your IP
   cd C:\GitHub\fedha\backend
   python update_ip.py
   ```

   Common mistakes:
   - Including the port number (use '192.168.1.100' not '192.168.1.100:8000')
   - Using the wrong IP address (your IP might be different from the example)

### CORS Issues

If you see CORS errors in the browser console:

1. Ensure the Django backend has CORS headers enabled for your origin
2. For quick testing, you can add the provided CorsMiddleware class to your Django middleware

### Cloudflare Connection Issues

1. Check if the tunnel is running (terminal should show active connection)
2. Verify that the Django server is running on port 8000
3. Try accessing the tunnel URL directly in a browser
4. **Make sure the tunnel domain is in Django's ALLOWED_HOSTS**:

   ```python
   # In backend/settings.py
   ALLOWED_HOSTS = [
       'localhost',
       '127.0.0.1',
       '0.0.0.0',
       '192.168.1.100',  # Your local network IP
       'place-jd-telecom-hi.trycloudflare.com',  # Cloudflare tunnel domain
   ]
   ```

   If you see a `DisallowedHost` error, this is always the solution - add your tunnel domain to ALLOWED_HOSTS.

5. Check CORS settings are properly configured:
   ```python
   # In backend/settings.py
   CORS_ALLOW_ALL_ORIGINS = True  # For development - restrict in production
   CORS_ALLOW_CREDENTIALS = True
   ```
   
   If you're seeing CORS errors, make sure the middleware is in the correct order:
   ```python
   MIDDLEWARE = [
       'corsheaders.middleware.CorsMiddleware',  # Must be before CommonMiddleware
       'django.middleware.security.SecurityMiddleware',
       'django.contrib.sessions.middleware.SessionMiddleware',
       'django.middleware.common.CommonMiddleware',
       # ... other middleware ...
   ]
   ```

## Connection Fallback in the App

The app now implements automatic connection fallback:

1. It will try to connect to each endpoint in this order:
   - Local direct
   - Local network
   - Cloudflare tunnel

2. The first working connection will be used for API communication

3. The ConnectionManager logs the selected connection in the app logs
