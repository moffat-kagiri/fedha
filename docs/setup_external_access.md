# Setting up External Access for Fedha Backend

This guide explains how to set up external access to your locally running Fedha backend server, allowing you to test the mobile app with your local development environment.

## Option 1: Using Localtunnel (Recommended)

[Localtunnel](https://localtunnel.github.io/www/) is an open-source tool that exposes your local web server to the internet with a public URL. It's free, easy to use, and doesn't require an account.

### Prerequisites
- Node.js and npm installed
- Fedha backend server running locally

### Automatic Setup

1. Start your backend server with the `--tunnel` option:
   ```
   python start_server.py --tunnel
   ```
   
   This will:
   - Start your Django server
   - Set up a localtunnel connection
   - Configure the app with the tunnel URL automatically

### Manual Setup

If the automatic setup doesn't work, you can start the tunnel manually:

1. Start your Django server:
   ```
   python start_server.py
   ```

2. In a separate terminal, run the tunnel script:
   - On Windows: `start_tunnel.bat`
   - On Mac/Linux: `./start_tunnel.sh`

3. Update the app configuration:
   ```
   python update_app_config.py
   ```

### Using a Custom Subdomain

If you want to use a custom subdomain for your tunnel:

1. Edit the `start_tunnel.bat` or `start_tunnel.sh` file
2. Change the `--subdomain` parameter to your desired name

## Option 2: Using ngrok

ngrok is another popular tool for exposing local servers to the internet. It offers more features but has some limitations in the free tier.

### Setup

1. [Download ngrok](https://ngrok.com/download) and sign up for a free account
2. Authenticate ngrok with your auth token:
   ```
   ngrok config add-authtoken YOUR_AUTH_TOKEN
   ```
3. Expose your Django server:
   ```
   ngrok http 8000
   ```
4. Update your app configuration with the ngrok URL

## Updating the App Configuration

When using either localtunnel or ngrok, you'll need to update the API configuration in your Flutter app:

1. Open `app/lib/config/api_config.dart`
2. Update the `primaryApiUrl` in the `ApiConfig.development()` factory:
   ```dart
   factory ApiConfig.development() {
     return const ApiConfig(
       primaryApiUrl: 'your-tunnel-url.loca.lt',
       // ...
     );
   }
   ```

## Troubleshooting

### Connection Issues
- Ensure your backend server is running before starting the tunnel
- Check that the port number in the tunnel command matches the port your server is running on
- Try using HTTP instead of HTTPS in your app configuration

### App Unable to Connect
- Verify the URL in your app configuration matches the tunnel URL
- Check if the tunnel is still active (they can expire after a period of inactivity)
- Make sure the health check endpoint (`/health/`) is available in your backend
