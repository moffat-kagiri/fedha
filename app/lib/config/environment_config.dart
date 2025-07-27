import 'package:flutter/foundation.dart';

/// Configuration for the app environment
class EnvironmentConfig {
  // Environment type constants
  static const String ENV_PRODUCTION = 'production';
  static const String ENV_DEVELOPMENT = 'development';
  static const String ENV_STAGING = 'staging';
  static const String ENV_TESTING = 'testing';
  
  // Current environment
  final String environment;
  
  // Whether this is a production environment
  final bool isProduction;
  
  // Whether to enable analytics
  final bool enableAnalytics;
  
  // Whether to show developer menu
  final bool showDeveloperMenu;
  
  // Whether to enable debug logging
  final bool enableDebugLogging;
  
  // Whether to use mock services
  final bool useMockServices;
  
  const EnvironmentConfig._({
    required this.environment,
    required this.isProduction,
    required this.enableAnalytics,
    required this.showDeveloperMenu,
    required this.enableDebugLogging,
    required this.useMockServices,
  });
  
  // Production environment
  factory EnvironmentConfig.productionConfig() {
    return const EnvironmentConfig._(
      environment: ENV_PRODUCTION,
      isProduction: true,
      enableAnalytics: true,
      showDeveloperMenu: false,
      enableDebugLogging: false,
      useMockServices: false,
    );
  }
  
  // Development environment
  factory EnvironmentConfig.developmentConfig() {
    return const EnvironmentConfig._(
      environment: ENV_DEVELOPMENT,
      isProduction: false,
      enableAnalytics: false,
      showDeveloperMenu: true,
      enableDebugLogging: true,
      useMockServices: false,
    );
  }
  
  // Staging environment
  factory EnvironmentConfig.stagingConfig() {
    return const EnvironmentConfig._(
      environment: ENV_STAGING,
      isProduction: false,
      enableAnalytics: true,
      showDeveloperMenu: false,
      enableDebugLogging: true,
      useMockServices: false,
    );
  }
  
  // Testing environment
  factory EnvironmentConfig.testingConfig() {
    return const EnvironmentConfig._(
      environment: ENV_TESTING,
      isProduction: false,
      enableAnalytics: false,
      showDeveloperMenu: true,
      enableDebugLogging: true,
      useMockServices: true,
    );
  }
  
  // Create instance based on current environment
  factory EnvironmentConfig.current() {
    // Use debug mode to determine environment for now
    // This can be extended to use flavor-based configuration
    if (kReleaseMode) {
      return EnvironmentConfig.productionConfig();
    } else if (kProfileMode) {
      return EnvironmentConfig.stagingConfig();
    } else {
      return EnvironmentConfig.developmentConfig();
    }
  }
}
