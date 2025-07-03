# Setting up ngrok for Fedha Backend Access

## What is ngrok?
ngrok creates a secure tunnel to your local development server, making it accessible from anywhere.

## Setup Steps:

### 1. Install ngrok
- Download from https://ngrok.com/download
- Extract to a folder and add to PATH
- Sign up for free account at https://ngrok.com

### 2. Authenticate ngrok
```bash
ngrok authtoken YOUR_AUTH_TOKEN
```

### 3. Start your Django server
```bash
cd c:\GitHub\fedha\backend
python start_server.py
```

### 4. In another terminal, start ngrok
```bash
ngrok http 8000
```

### 5. Update Flutter app
- Copy the https URL from ngrok (e.g., `https://7a9a-41-209-9-54.ngrok-free.app`)
- Update `api_client.dart`:

```dart
static String get _baseUrl {
  if (kIsWeb) {
    return "http://127.0.0.1:8000/api";
  } else {
    // Use ngrok URL for mobile testing
    return "https://7a9a-41-209-9-54.ngrok-free.app/api";
  }
}
```

## Benefits:
- Works on real devices
- Secure HTTPS connection
- Accessible from anywhere
- No network configuration needed

## Note:
Free ngrok URLs change every time you restart. For persistent URLs, upgrade to paid plan.
