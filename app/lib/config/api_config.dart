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
  
  // Default headers to include with all requests
  final Map<String, String> defaultHeaders;
  
  // Whether to enable debug logging for API requests
  final bool enableDebugLogging;

  const ApiConfig({
    required this.primaryApiUrl,
    this.fallbackApiUrl,
    this.connectionTimeout = 10,
    this.useSecureConnections = true,
    this.apiVersion = 'v1',
    this.defaultHeaders = const {},
    this.enableDebugLogging = false,
  });
  
  // Development configuration
  factory ApiConfig.development() {
    return const ApiConfig(
      primaryApiUrl: 'beige-insects-lick.loca.lt',
      fallbackApiUrl: 'localhost:8000',
      connectionTimeout: 30,
      useSecureConnections: false, // Use HTTP for localtunnel
      apiVersion: 'v1',
      defaultHeaders: {
        'X-Client-Version': '1.0.0',
        'X-Client-Platform': 'flutter',
      },
      enableDebugLogging: true,
    );
  }
  
  // Production configuration
  factory ApiConfig.production() {
    return const ApiConfig(
      primaryApiUrl: 'api.fedha.app',
      fallbackApiUrl: 'api-backup.fedha.app',
      connectionTimeout: 15,
      useSecureConnections: true,
      apiVersion: 'v1',
      defaultHeaders: {
        'X-Client-Version': '1.0.0',
        'X-Client-Platform': 'flutter',
      },
      enableDebugLogging: false,
    );
  }
  
  // Local development configuration
  factory ApiConfig.local() {
    return const ApiConfig(
      primaryApiUrl: 'tired-dingos-beg.loca.lt',
      fallbackApiUrl: '127.0.0.1:8000',
      connectionTimeout: 15,
      useSecureConnections: false,
      apiVersion: 'v1',
      defaultHeaders: {
        'X-Client-Version': '1.0.0',
        'X-Client-Platform': 'flutter',
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
      defaultHeaders: {},
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
    Map<String, String>? defaultHeaders,
    bool? enableDebugLogging,
  }) {
    return ApiConfig(
      primaryApiUrl: primaryApiUrl ?? this.primaryApiUrl,
      fallbackApiUrl: fallbackApiUrl ?? this.fallbackApiUrl,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      useSecureConnections: useSecureConnections ?? this.useSecureConnections,
      apiVersion: apiVersion ?? this.apiVersion,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
    );
  }
}
