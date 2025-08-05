# Reliable Network Connection Protocol for Fedha App

This document provides a comprehensive guide for establishing and maintaining reliable network connectivity between the Fedha Flutter app and backend server across different environments.

## Architecture Overview

The Fedha app uses a multi-layered network connection approach:

1. **Primary Connection**: Direct connection to a known API endpoint
2. **Fallback System**: Automated fallback to secondary endpoints when primary fails
3. **Health Verification**: Standardized endpoint to verify server availability
4. **Offline Mode**: Graceful degradation when no connection is available
5. **Auto-Recovery**: Periodic reconnection attempts in the background

## Connection Endpoint Strategy

### 1. Development Environment

For local development with direct network access:

```dart
// In api_config.dart
factory ApiConfig.development() {
  return const ApiConfig(
    primaryApiUrl: '192.168.100.6:8000',  // Local network IP
    fallbackApiUrl: '10.0.2.2:8000',      // Android emulator loopback
    connectionTimeout: 30,
    useSecureConnections: false,          // Use HTTP for development
    apiVersion: 'v1',
    apiHealthEndpoint: 'api/health/',     // IMPORTANT: Standardized health endpoint
    defaultHeaders: {
      'X-Client-Version': '1.0.0',
      'X-Client-Platform': 'flutter',
      'X-Environment': 'development',
    },
    enableDebugLogging: true,
  );
}
```

### 2. Staging Environment

For testing with tunneled connections or staging servers:

```dart
// In api_config.dart
factory ApiConfig.staging() {
  return const ApiConfig(
    primaryApiUrl: 'staging-api.fedha.app',  // Primary staging server
    fallbackApiUrl: 'staging-backup.fedha.app', // Backup staging server
    connectionTimeout: 20,
    useSecureConnections: true,             // Use HTTPS for staging
    apiVersion: 'v1',
    apiHealthEndpoint: 'api/health/',       // IMPORTANT: Standardized health endpoint
    defaultHeaders: {
      'X-Client-Version': '1.0.0',
      'X-Client-Platform': 'flutter',
      'X-Environment': 'staging',
    },
    enableDebugLogging: true,
  );
}
```

### 3. USB Debugging (Android Only)

For direct connection to Android devices via USB.

1. Connect your device via USB
2. Enable USB debugging in developer options
3. Run the following command:
   ```bash
   adb reverse tcp:8000 tcp:8000
   ```
4. Configure the app to use `localhost:8000`

## Troubleshooting Connection Issues

### Check Server Status

1. Ensure the server is running with proper network access:
   ```bash
   python start_server.py --host 0.0.0.0
   ```

2. Verify the server is accessible from your device's browser:
   - Open a browser on your mobile device
   - Navigate to `http://192.168.100.6:8000/api/health/` (replace with your IP)
   - You should see a health status response with server information

### Common Issues

1. **503 - Tunnel Unavailable**
   - This indicates the tunnel service (Localtunnel, ngrok) is having issues
   - Solution: Switch to direct IP connection or restart the tunnel

2. **Connection Refused**
   - The server might not be running or there's a network/firewall issue
   - Solution: Verify the server is running and check firewall settings

3. **SSL/HTTPS Issues**
   - Mixed content errors can occur if the app tries to use HTTPS with a non-HTTPS server
   - Solution: Set `useSecureConnections: false` in the ApiConfig

4. **Network Restrictions**
   - Some networks block certain ports or services
   - Solution: Try using a mobile hotspot instead of restricted WiFi

## Testing the Connection Protocol

### Using the Connection Verification Script

The Fedha backend includes a script that can verify all aspects of the connection setup:

```bash
# For Windows
cd backend
.\verify_connection.bat

# For Linux/Mac
cd backend
bash verify_connection.sh
```

The verification script will:
1. Confirm the Django server is running with the health endpoint accessible
2. Display the health endpoint response to verify it's working correctly
3. Detect your local IP address for proper API configuration
4. Check that the Flutter app's API configuration matches your setup

### Using the Flutter Test Script

The Fedha app also includes a test script that can verify connectivity to all configured environments:

```bash
cd app
dart run test_network_connection.dart
```

This script will:
1. Test connectivity to development, staging, and production servers
2. Verify the health endpoint on each server
3. Test both HTTP and HTTPS protocols as appropriate
4. Provide detailed output on connection status and any errors

### Manual Testing Procedure

1. **Verify API configuration**:
   ```dart
   print('API Configuration: ${ApiConfig.development().toString()}');
   ```

2. **Test health endpoint directly**:
   ```dart
   final bool isHealthy = await apiClient.checkServerHealth();
   print('Server health status: $isHealthy');
   ```
   
3. **Test fallback mechanism**:
   ```dart
   // Intentionally use an invalid primary URL
   final ApiConfig testConfig = ApiConfig(
     primaryApiUrl: 'invalid-server:8000',
     fallbackApiUrl: '192.168.100.6:8000',
     // other config options...
   );
   
   final ApiClient testClient = ApiClient(config: testConfig);
   final bool fallbackWorks = await testClient.checkServerHealth();
   print('Fallback mechanism working: $fallbackWorks');
   ```

## Configuration Checklist

- [ ] Server is running with `--host 0.0.0.0` (use `start_server.bat` in backend folder)
- [ ] Server IP address is correctly set in ApiConfig
- [ ] `useLocalServer = true` in main.dart
- [ ] `useSecureConnections` is set correctly (false for HTTP)
- [ ] Device and server are on the same network
- [ ] Firewall allows connections on port 8000
- [x] Standardized health endpoint is implemented on the server
- [ ] App has been restarted after configuration changes

## Implementation Details

### Flutter ApiClient Implementation

Implement a robust ApiClient in your Flutter app:

```dart
// In api_client.dart
class ApiClient {
  final ApiConfig config;
  final Dio _dio;
  final ConnectivityService _connectivityService;
  
  ApiClient({
    required this.config, 
    required ConnectivityService connectivityService
  }) : 
    _dio = Dio(),
    _connectivityService = connectivityService {
    // Configure Dio client with timeout and interceptors
    _dio.options.connectTimeout = Duration(seconds: config.connectionTimeout);
    _dio.options.receiveTimeout = Duration(seconds: config.connectionTimeout);
    _dio.options.headers = config.defaultHeaders;
    
    // Add logging interceptor if debug logging is enabled
    if (config.enableDebugLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }
  
  // Check server health using standardized endpoint
  Future<bool> checkServerHealth() async {
    // First check if device has internet connectivity
    final hasConnectivity = await _connectivityService.checkConnectivity();
    if (!hasConnectivity) {
      return false;
    }
    
    // Try primary URL first
    bool isHealthy = await _checkUrlHealth(config.primaryApiUrl);
    
    // If primary fails, try fallback URL
    if (!isHealthy && config.fallbackApiUrl != null) {
      isHealthy = await _checkUrlHealth(config.fallbackApiUrl!);
    }
    
    return isHealthy;
  }
  
  Future<bool> _checkUrlHealth(String baseUrl) async {
    try {
      // Construct the proper health URL using the standardized endpoint
      final scheme = config.useSecureConnections ? 'https' : 'http';
      final healthUrl = '$scheme://$baseUrl/${config.apiHealthEndpoint}';
      
      final response = await _dio.get(healthUrl);
      
      // Check for successful response and status
      if (response.statusCode == 200 && 
          response.data is Map &&
          response.data['status'] == 'healthy') {
        return true;
      }
      return false;
    } catch (e) {
      // Any exception means the health check failed
      return false;
    }
  }
  
  // Regular API methods would go here...
}
```

### Django Health Endpoint Setup

Create a standardized health endpoint in your Django backend:

1. Create a new file `health/views.py`:
```python
from django.http import JsonResponse
from django.views.decorators.http import require_GET
from django.db import connection
from django.conf import settings
import os

@require_GET
def health_check(request):
    """
    Standard health check endpoint that verifies:
    1. API is accessible
    2. Database connection is working
    3. Returns version and environment information
    """
    # Check database connection
    db_healthy = True
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
    except Exception:
        db_healthy = False
    
    # Get version from settings or environment
    version = getattr(settings, 'API_VERSION', os.environ.get('API_VERSION', 'v1'))
    environment = getattr(settings, 'ENVIRONMENT', os.environ.get('ENVIRONMENT', 'development'))
    
    response_data = {
        "status": "healthy" if db_healthy else "degraded",
        "version": version,
        "environment": environment,
        "database": "connected" if db_healthy else "disconnected",
        "timestamp": timezone.now().isoformat()
    }
    
    # If not healthy, return 503 status
    status_code = 200 if db_healthy else 503
    
    return JsonResponse(response_data, status=status_code)
```

2. Create `health/urls.py`:
```python
from django.urls import path
from .views import health_check

urlpatterns = [
    path('health/', health_check, name='health_check'),
]
```

3. Update your main `urls.py` to include the health check:
```python
from django.urls import path, include

urlpatterns = [
    # ... other URL patterns
    path('api/', include('health.urls')),  # Makes the endpoint available at /api/health/
]
```

## Advanced Connection Management

### Offline Mode Implementation

To enable a graceful fallback to offline mode when no connection is available:

```dart
// In your service or app initialization
Future<void> initializeNetworkConnection() async {
  try {
    // Try to connect to server with standardized health endpoint
    final bool isServerReachable = await apiClient.checkServerHealth();
    if (!isServerReachable) {
      // Enable offline mode logic
      appState.setOfflineMode(true);
      
      // Optional: Schedule periodic reconnection attempts
      _scheduleReconnectionAttempts();
    } else {
      appState.setOfflineMode(false);
      // Sync any pending offline data
      syncOfflineData();
    }
  } catch (e) {
    // Handle connection errors
    appState.setOfflineMode(true);
    logger.error('Connection error: $e');
  }
}
```

### Auto-Recovery System

Implement a background service to periodically attempt reconnection:

```dart
// In a network_manager.dart file
void _scheduleReconnectionAttempts() {
  // Cancel any existing timer
  _reconnectionTimer?.cancel();
  
  // Create a new periodic timer that attempts reconnection
  _reconnectionTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
    logger.info('Attempting to reconnect to server...');
    
    final bool isServerReachable = await apiClient.checkServerHealth();
    if (isServerReachable) {
      logger.info('Reconnection successful');
      appState.setOfflineMode(false);
      
      // Sync any pending offline data
      syncOfflineData();
      
      // Cancel the timer since we've reconnected
      timer.cancel();
      _reconnectionTimer = null;
    } else {
      logger.info('Reconnection attempt failed, will retry later');
    }
  });
}
```

### Production Environment Configuration

For your live production application:

```dart
// In api_config.dart
factory ApiConfig.production() {
  return const ApiConfig(
    primaryApiUrl: 'api.fedha.app',         // Primary production API
    fallbackApiUrl: 'api-backup.fedha.app', // Backup production API 
    connectionTimeout: 15,
    useSecureConnections: true,             // Always use HTTPS in production
    apiVersion: 'v1',
    apiHealthEndpoint: 'api/health/',       // IMPORTANT: Standardized health endpoint
    defaultHeaders: {
      'X-Client-Version': '1.0.0',
      'X-Client-Platform': 'flutter',
      'X-Environment': 'production',
    },
    enableDebugLogging: false,              // Disable debug logging in production
  );
}
