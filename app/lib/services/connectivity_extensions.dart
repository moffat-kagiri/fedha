import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/connectivity_service.dart';
import '../utils/logger.dart';

/// An extension on ConnectivityService to add additional offline mode functionality
extension OfflineModeExtension on ConnectivityService {
  /// Determines if the app should enter full offline mode
  /// This considers both connection and server status, as well as user preference
  Future<bool> shouldEnterFullOfflineMode() async {
    // If we have no connection or the server is unreachable, we're already in offline mode
    if (isOfflineMode) {
      return true;
    }
    
    // Check if user has explicitly enabled offline mode in settings
    // This would be stored in user preferences
    final userPreference = await _getUserOfflinePreference();
    return userPreference;
  }
  
  /// Get user preference for offline mode
  Future<bool> _getUserOfflinePreference() async {
    // In a real implementation, this would check shared preferences
    // For now, return false (don't force offline mode if connection is available)
    return false;
  }
  
  /// Sets the user's preference for offline mode
  Future<void> setOfflineModePreference(bool preferOfflineMode) async {
    // In a real implementation, this would store in shared preferences
  }
}

/// Helper class for managing connectivity checks
class ConnectivityHelper {
  static final _logger = AppLogger.getLogger('ConnectivityHelper');
  
  /// Check if device has network connectivity
  static Future<bool> hasNetworkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      _logger.warning('Error checking network connectivity: $e');
      return false;
    }
  }
  
  /// Execute a function with retry logic when connectivity issues occur
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    required T Function() onFailure,
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    bool retryOnlyIfConnected = true,
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;
    
    while (attempts < maxRetries) {
      try {
        if (attempts > 0) {
          _logger.info('Retry attempt ${attempts+1}/$maxRetries after ${delay.inMilliseconds}ms');
          await Future.delayed(delay);
          delay *= 2; // Exponential backoff
        }
        
        // If we should only retry when connected, check connectivity first
        if (retryOnlyIfConnected && attempts > 0) {
          bool hasConnection = await hasNetworkConnection();
          if (!hasConnection) {
            _logger.warning('No network connection, aborting retry');
            return onFailure();
          }
        }
        
        return await operation();
      } catch (e) {
        _logger.warning('Operation failed (attempt ${attempts+1}): $e');
        attempts++;
        
        // If this was the last attempt, return the failure result
        if (attempts >= maxRetries) {
          _logger.warning('All retry attempts failed');
          return onFailure();
        }
      }
    }
    
    // This should never be reached due to the return in the last attempt
    return onFailure();
  }
  
  /// Execute a function with timeout and retry logic
  static Future<T> withTimeoutAndRetry<T>({
    required Future<T> Function() operation,
    required T Function() onFailure,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 2,
  }) async {
    return withRetry<T>(
      operation: () => operation().timeout(timeout),
      onFailure: onFailure,
      maxRetries: maxRetries,
    );
  }
}
