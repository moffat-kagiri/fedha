// lib/config/api_config.dart

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
      primaryApiUrl: 'api.fedhaapp.com',  // Replace with your actual production domain
      fallbackApiUrl: 'api-backup.fedhaapp.com',  // Optional backup server
      useSecureConnections: true,
      timeoutSeconds: 30,
      maxRetries: 3,
    );
  }

  /// Development configuration (localhost)
  factory ApiConfig.development() {
    return const ApiConfig(
      primaryApiUrl: '10.0.2.2:8000',  // Android emulator localhost
      // Alternative for iOS simulator: 'localhost:8000'
      // Alternative for physical device: Use your computer's LAN IP
      fallbackApiUrl: null,
      useSecureConnections: false,
      timeoutSeconds: 30,
      maxRetries: 3,
    );
  }

  /// Cloudflare tunnel configuration (for remote testing)
  factory ApiConfig.cloudflare({required String tunnelUrl}) {
    // Extract host from full URL
    final host = tunnelUrl
        .replaceAll(RegExp(r'https?://'), '')
        .split('/')[0];
    
    return ApiConfig(
      primaryApiUrl: host,
      fallbackApiUrl: null,
      useSecureConnections: true,  // Cloudflare tunnels use HTTPS
      timeoutSeconds: 45,  // Longer timeout for tunnels
      maxRetries: 2,
    );
  }

  /// Custom configuration (for any custom setup)
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