import 'package:flutter/foundation.dart';

/// Configuration for the API endpoints and settings
class ApiConfig {
  // Primary API endpoint
  final String primaryApiUrl;
  
  // Fallback API endpoint (used when primary fails)
  final String? fallbackApiUrl;
  
  // Connection timeout in seconds
  final int connectionTimeout;
  
  // Whether to use secure connections (HTTPS)
  final bool useSecureConnections;
  
  // API version
  final String apiVersion;
  
  // Standardized health endpoint path (used for server health checks)
  final String apiHealthEndpoint;
  
  // Default headers to include with all requests
  final Map<String, String> defaultHeaders;
  
  // Whether to enable debug logging for API requests
  final bool enableDebugLogging;
  const ApiConfig({
    required this.primaryApiUrl,
    required this.fallbackApiUrl,
    required this.connectionTimeout,
    required this.useSecureConnections,
    required this.apiVersion,
    required this.apiHealthEndpoint,
    required this.defaultHeaders,
    required this.enableDebugLogging,
  });
  
  // Development configuration
  factory ApiConfig.development() {
    return const ApiConfig(
      primaryApiUrl: '192.168.100.6:8000',
      fallbackApiUrl: '10.0.2.2:8000',  // Android emulator loopback
      connectionTimeout: 30,
      useSecureConnections: false, // Use HTTP for local network
      apiVersion: 'v1',
      apiHealthEndpoint: 'api/health/',
      defaultHeaders: {
        'X-Client-Version': '1.0.0',
        'X-Client-Platform': 'flutter',
        'X-Environment': 'development',
      },
      enableDebugLogging: true,
    );
  }
  
  // Production configuration
  factory ApiConfig.production() {
    return ApiConfig(
      primaryApiUrl: 'api.fedha.app',
      fallbackApiUrl: '192.168.100.6:8000',
      connectionTimeout: 20,
      useSecureConnections: true,
      apiVersion: 'v1',
      apiHealthEndpoint: 'api/health/',
      defaultHeaders: {
        'X-Client-Version': '1.0.0',
        'X-Client-Platform': 'flutter',
        'X-Environment': 'production',
      },
      enableDebugLogging: false,
    );
  }
  
  // Staging with Cloudflare tunnel configuration
  factory ApiConfig.cloudflare() {
    return const ApiConfig(
      primaryApiUrl: 'lake-consistently-affects-applications.trycloudflare.com',
      fallbackApiUrl: '192.168.100.6:8000',
      connectionTimeout: 20,
      useSecureConnections: true,
      apiVersion: 'v1',
      apiHealthEndpoint: 'api/health/',
      defaultHeaders: {
        'X-Client-Version': '1.0.0',
        'X-Client-Platform': 'flutter',
        'X-Environment': 'staging',
      },
      enableDebugLogging: true,
    );
  }
  
  // Local development configuration
  factory ApiConfig.local() {
    return const ApiConfig(
      primaryApiUrl: '192.168.100.6:8000', 
      fallbackApiUrl: '127.0.0.1:8000',
      connectionTimeout: 15,
      useSecureConnections: false,
      apiVersion: 'v1',
      apiHealthEndpoint: 'api/health/',
      defaultHeaders: {
        'X-Client-Version': '1.0.0',
        'X-Client-Platform': 'flutter',
        'X-Environment': 'local',
      },
      enableDebugLogging: true,
    );
  }
  
  // Mock API configuration (no actual network calls)
  factory ApiConfig.mock() {
    return const ApiConfig(
      primaryApiUrl: 'mock-api',
      fallbackApiUrl: null,
      connectionTimeout: 1,
      useSecureConnections: false,
      apiVersion: 'v1',
      apiHealthEndpoint: 'health/',
      defaultHeaders: {
        'X-Environment': 'mock',
      },
      enableDebugLogging: true,
    );
  }
  
  // Staging configuration for pre-production testing
  factory ApiConfig.staging() {
    return const ApiConfig(
      primaryApiUrl: 'staging-api.fedha.app',
      fallbackApiUrl: 'staging-backup.fedha.app',
      connectionTimeout: 20,
      useSecureConnections: true,
      apiVersion: 'v1',
      apiHealthEndpoint: 'api/health/',
      defaultHeaders: {
        'X-Client-Version': '1.0.0',
        'X-Client-Platform': 'flutter',
        'X-Environment': 'staging',
      },
      enableDebugLogging: true,
    );
  }
  
  // Get the primary API base URL with protocol
  String get primaryBaseUrl {
    final protocol = useSecureConnections ? 'https' : 'http';
    return '$protocol://$primaryApiUrl';
  }
  
  // Get the fallback API base URL with protocol, or null if not configured
  String? get fallbackBaseUrl {
    if (fallbackApiUrl == null) return null;
    final protocol = useSecureConnections ? 'https' : 'http';
    return '$protocol://$fallbackApiUrl';
  }
  
  // Get the primary API endpoint for a specific path
  String getEndpoint(String path) {
    return '$primaryBaseUrl/$apiVersion/$path';
  }
  
  // Get the fallback API endpoint for a specific path
  String? getFallbackEndpoint(String path) {
    if (fallbackApiUrl == null) return null;
    return '$fallbackBaseUrl/$apiVersion/$path';
  }
  
  // Create a copy of this configuration with some values updated
  ApiConfig copyWith({
    String? primaryApiUrl,
    String? fallbackApiUrl,
    int? connectionTimeout,
    bool? useSecureConnections,
    String? apiVersion,
    String? apiHealthEndpoint,
    Map<String, String>? defaultHeaders,
    bool? enableDebugLogging,
  }) {
    return ApiConfig(
      primaryApiUrl: primaryApiUrl ?? this.primaryApiUrl,
      fallbackApiUrl: fallbackApiUrl ?? this.fallbackApiUrl,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      useSecureConnections: useSecureConnections ?? this.useSecureConnections,
      apiVersion: apiVersion ?? this.apiVersion,
      apiHealthEndpoint: apiHealthEndpoint ?? this.apiHealthEndpoint,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
    );
  }
  
  // Get health check URL for the primary API
  String get healthCheckUrl {
    final protocol = useSecureConnections ? 'https' : 'http';
    return '$protocol://$primaryApiUrl/$apiHealthEndpoint';
  }
  
  // Get health check URL for the fallback API
  String? get fallbackHealthCheckUrl {
    if (fallbackApiUrl == null) return null;
    final protocol = useSecureConnections ? 'https' : 'http';
    return '$protocol://$fallbackApiUrl/$apiHealthEndpoint';
  }
}
