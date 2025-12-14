// lib/config/api_config.dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  final String primaryApiUrl;
  final String? fallbackApiUrl;
  final bool useSecureConnections;
  final int timeoutSeconds;
  final int maxRetries;

  const ApiConfig({
    required this.primaryApiUrl,
    this.fallbackApiUrl,
    this.useSecureConnections = true,
    this.timeoutSeconds = 30,
    this.maxRetries = 3,
  });

  /// Production configuration (for production builds)
  factory ApiConfig.production() {
    return const ApiConfig(
      primaryApiUrl: 'api.fedhaapp.com',  // Your production domain
      fallbackApiUrl: null,
      useSecureConnections: true,
      timeoutSeconds: 30,
      maxRetries: 3,
    );
  }

  /// Development configuration (for development)
  factory ApiConfig.development() {
    // CRITICAL: Replace with YOUR computer's IP address
    const String computerIp = '192.168.1.100';  // ⚠️ CHANGE THIS!
    
    return ApiConfig(
      primaryApiUrl: '$computerIp:8000',
      fallbackApiUrl: null,
      useSecureConnections: false,  // HTTP for local dev
      timeoutSeconds: 30,
      maxRetries: 3,
    );
  }

  /// Cloudflare tunnel configuration (for remote testing)
  factory ApiConfig.cloudflare({required String tunnelUrl}) {
    final host = tunnelUrl
        .replaceAll(RegExp(r'https?://'), '')
        .split('/')[0];
    
    return ApiConfig(
      primaryApiUrl: host,
      fallbackApiUrl: null,
      useSecureConnections: true,
      timeoutSeconds: 45,
      maxRetries: 2,
    );
  }

  /// Custom configuration
  factory ApiConfig.custom({
    required String apiUrl,
    bool useSecureConnections = false,
    int timeoutSeconds = 30,
  }) {
    return ApiConfig(
      primaryApiUrl: apiUrl,
      fallbackApiUrl: null,
      useSecureConnections: useSecureConnections,
      timeoutSeconds: timeoutSeconds,
      maxRetries: 3,
    );
  }

  /// Create a copy with modified fields
  ApiConfig copyWith({
    String? primaryApiUrl,
    String? fallbackApiUrl,
    bool? useSecureConnections,
    int? timeoutSeconds,
    int? maxRetries,
  }) {
    return ApiConfig(
      primaryApiUrl: primaryApiUrl ?? this.primaryApiUrl,
      fallbackApiUrl: fallbackApiUrl ?? this.fallbackApiUrl,
      useSecureConnections: useSecureConnections ?? this.useSecureConnections,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }

  /// Get full endpoint URL
  String getEndpoint(String path) {
    final scheme = useSecureConnections ? 'https' : 'http';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$scheme://$primaryApiUrl/$cleanPath';
  }

  /// Health check URL
  String get healthCheckUrl => getEndpoint('api/health/');

  @override
  String toString() {
    return 'ApiConfig(url: $primaryApiUrl, secure: $useSecureConnections, timeout: ${timeoutSeconds}s)';
  }
}