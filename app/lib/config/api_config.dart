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

  /// Development configuration (for local development)
  /// CRITICAL: Update the IP address to match YOUR computer's IP
  factory ApiConfig.development() {
    // ⚠️ IMPORTANT: Replace this with YOUR computer's actual IP address
    // 
    // To find your IP:
    // - Windows: Open CMD and type: ipconfig
    //   Look for "IPv4 Address" under your active network adapter
    // - Mac: Open Terminal and type: ifconfig | grep "inet "
    // - Linux: Open Terminal and type: ip addr show
    //
    // Common IP formats:
    // - Local machine: 127.0.0.1 or localhost (for emulator on same machine)
    // - Android emulator: 10.0.2.2 (special alias to host machine)
    // - Physical device: 192.168.x.x (your computer's local network IP)
    
    const String computerIp = '192.168.100.6';
    
    return ApiConfig(
      primaryApiUrl: '$computerIp:8000',
      fallbackApiUrl: '10.0.2.2:8000',  // Fallback for Android emulator
      useSecureConnections: false,  // HTTP for local development
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