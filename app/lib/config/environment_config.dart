import 'package:flutter/foundation.dart';

/// Enum representing different environment types
enum EnvironmentType {
  production,
  development,
  staging,
  testing,
}

/// Configuration for the app environment
class EnvironmentConfig {
  // Current environment type
  final EnvironmentType type;
  
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
  
  // Get the environment name as a string
  String get environment {
    return type.toString().split('.').last;
  }
  
  const EnvironmentConfig._({
    required this.type,
    required this.isProduction,
    required this.enableAnalytics,
    required this.showDeveloperMenu,
    required this.enableDebugLogging,
    required this.useMockServices,
  });
  
  // Production environment
  factory EnvironmentConfig.production() {
    return const EnvironmentConfig._(
      type: EnvironmentType.production,
      isProduction: true,
      enableAnalytics: true,
      showDeveloperMenu: false,
      enableDebugLogging: false,
      useMockServices: false,
    );
  }
  
  // Development environment
  factory EnvironmentConfig.development() {
    return const EnvironmentConfig._(
      type: EnvironmentType.development,
      isProduction: false,
      enableAnalytics: false,
      showDeveloperMenu: true,
      enableDebugLogging: true,
      useMockServices: false,
    );
  }
  
  // Staging environment
  factory EnvironmentConfig.staging() {
    return const EnvironmentConfig._(
      type: EnvironmentType.staging,
      isProduction: false,
      enableAnalytics: true,
      showDeveloperMenu: false,
      enableDebugLogging: true,
      useMockServices: false,
    );
  }
  
  // Testing environment
  factory EnvironmentConfig.testing() {
    return const EnvironmentConfig._(
      type: EnvironmentType.testing,
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
      return EnvironmentConfig.production();
    } else if (kProfileMode) {
      return EnvironmentConfig.staging();
    } else {
      return EnvironmentConfig.development();
    }
  }
}
