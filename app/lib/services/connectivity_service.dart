import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';
import '../services/api_client.dart';
import '../utils/logger.dart';

/// Enum representing connectivity status
enum ConnectivityStatus {
  /// Device has connectivity and server is reachable
  online,
  
  /// Device has connectivity but server is unreachable
  serverUnreachable,
  
  /// Device has no connectivity
  noConnection,
  
  /// Offline mode is explicitly enabled by user
  offlineMode,
}

/// A service that handles connectivity monitoring and server status checking
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final ApiClient _apiClient;
  final Logger _logger;
  
  bool _hasConnection = false;
  bool _serverReachable = false;
  
  // Stream controllers
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  final StreamController<bool> _serverStatusController = StreamController<bool>.broadcast();
  
  // Timer for periodic connectivity checks
  Timer? _periodicCheckTimer;
  
  // Streams
  Stream<bool> get connectionStream => _connectionStatusController.stream;
  Stream<bool> get serverStatusStream => _serverStatusController.stream;
  
  // Getters
  bool get hasConnection => _hasConnection;
  bool get isServerReachable => _serverReachable;
  
  ConnectivityService(this._apiClient) : _logger = AppLogger.getLogger('ConnectivityService') {
    // Initialize connection monitoring
    _initConnectivity();
  }
  
  /// Initialize the connectivity service
  Future<void> initialize() async {
    await _checkConnectivity();
    _setupConnectivityListener();
  }
  
  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Try to connect to a reliable host to verify actual internet connectivity
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        return false;
      }
      
      return false;
    } catch (e) {
      _logger.severe('Error checking internet connection: $e');
      return false;
    }
  }
  
  // Initialize connectivity monitoring (used in constructor)
  void _initConnectivity() {
    _logger.info('Initializing connectivity monitoring');
    _checkConnectivity();
  }
  
  // Setup connectivity change listener (used in initialize method)
  void _setupConnectivityListener() {
    _logger.info('Setting up connectivity listener');
    _connectivity.onConnectivityChanged.listen((result) {
      _logger.info('Connectivity changed: $result');
      _checkConnectivity();
    });
  }
  
  // Check connectivity status
  Future<void> _checkConnectivity() async {
    try {
      _logger.info('Checking connectivity...');
      
      // Check basic connectivity first
      final connectivityResult = await _connectivity.checkConnectivity();
      final hadConnection = _hasConnection; // Store previous state
      
      if (connectivityResult == ConnectivityResult.none) {
        _hasConnection = false;
        _serverReachable = false;
        
        _logger.warning('No connectivity detected');
        
        if (hadConnection) {
          // Only notify if state changed
          _connectionStatusController.add(false);
          _serverStatusController.add(false);
        }
        return;
      }
      
      // We have some form of connectivity, check actual internet connection
      try {
        final result = await InternetAddress.lookup('google.com');
        final hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        
        if (!hasInternet) {
          _hasConnection = false;
          _serverReachable = false;
          
          _logger.warning('Internet not reachable');
          
          if (hadConnection) {
            _connectionStatusController.add(false);
            _serverStatusController.add(false);
          }
          return;
        }
        
        // We have internet, now check server
        _hasConnection = true;
        
        if (hadConnection != _hasConnection) {
          _connectionStatusController.add(true);
        }
        
        // Check if our API server is reachable
        _checkServerReachability();
      } catch (e) {
        _logger.warning('Error checking internet: $e');
        _hasConnection = false;
        _serverReachable = false;
        
        if (hadConnection) {
          _connectionStatusController.add(false);
          _serverStatusController.add(false);
        }
      }
    } catch (e) {
      _logger.severe('Error in _checkConnectivity: $e');
    }
    
    // Start periodic checks if needed
    startPeriodicChecks();
  }
  
  // Check if the API server is reachable
  Future<void> _checkServerReachability() async {
    try {
      _logger.info('Checking server reachability...');
      final wasReachable = _serverReachable;
      
      final isReachable = await _apiClient.checkServerHealth();
      _serverReachable = isReachable;
      
      _logger.info('Server reachable: $_serverReachable');
      
      if (wasReachable != _serverReachable) {
        _serverStatusController.add(_serverReachable);
      }
    } catch (e) {
      _logger.warning('Error checking server reachability: $e');
      _serverReachable = false;
      _serverStatusController.add(false);
    }
  }
  
  // Simple attempt to reconnect (called by the periodic check timer)
  Future<bool> _simpleReconnect() async {
    await _checkConnectivity();
    return _serverReachable;
  }
  
  // Start periodic connectivity checks (every 30 seconds)
  void startPeriodicChecks({Duration interval = const Duration(seconds: 30)}) {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(interval, (_) {
      if (!_hasConnection || !_serverReachable) {
        _logger.info('Performing periodic connectivity check...');
        _simpleReconnect();
      }
    });
    _logger.info('Started periodic connectivity checks: ${interval.inSeconds}s');
  }
  
  // Update connection status based on connectivity result (helper for the onConnectivityChanged listener)
  
  // Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) async {
    final bool previousConnectionState = _hasConnection;
    _hasConnection = (result != ConnectivityResult.none);
    
    // Log the connectivity change
    if (previousConnectionState != _hasConnection) {
      _logger.info('Network connection changed: ${_hasConnection ? 'Connected' : 'Disconnected'}');
      if (_hasConnection) {
        _logger.info('Connection type: ${result.toString()}');
      }
    }
    
    _connectionStatusController.add(_hasConnection);
    
    // If we have a connection, also check server status
    if (_hasConnection) {
      await checkServerStatus();
    } else {
      _serverReachable = false;
      _serverStatusController.add(false);
      _logger.info('Offline mode activated (no network connection)');
    }
  }
  
  // Check if server is reachable
  Future<bool> checkServerStatus() async {
    if (!_hasConnection) {
      _logger.info('No network connection, skipping server check');
      return false;
    }
    
    try {
      _logger.info('Testing server connection...');
      
      // This will automatically try the fallback server if needed
      _serverReachable = await _apiClient.testConnection();
      _serverStatusController.add(_serverReachable);
      
      if (_serverReachable) {
        _logger.info('Server connection established' + 
          (_apiClient.isUsingFallbackServer ? ' (using fallback server)' : ''));
      } else {
        _logger.warning('All server connections failed, entering offline mode');
      }
      
      return _serverReachable;
    } catch (e) {
      _logger.warning('Failed to check server status: $e');
      _serverReachable = false;
      _serverStatusController.add(false);
      return false;
    }
  }
  
  // Try to reconnect to server with option to force a new check
  Future<bool> attemptReconnect({bool force = false}) async {
    if (force) {
      _logger.info('Forcing connectivity check...');
      _initConnectivity(); // Don't await since it's void now
      await _checkConnectivity(); // Add this line to ensure connectivity is checked
    }
    
    if (!_hasConnection) {
      _logger.info('No network connection available, skipping server reconnection');
      return false;
    }
    
    try {
      // Try to reset to primary server if we're on fallback
      if (_apiClient.isUsingFallbackServer) {
        _logger.info('Attempting to reconnect to primary server...');
        _apiClient.resetToPrimaryServer();
      }
      
      // Check server status with appropriate timeout
      return await checkServerStatus().timeout(
        Duration(seconds: 10), // Slightly longer timeout for reconnection attempts
        onTimeout: () {
          _logger.warning('Server reconnection attempt timed out');
          _serverReachable = false;
          _serverStatusController.add(false);
          return false;
        }
      );
    } catch (e) {
      _logger.severe('Error during reconnect attempt: $e');
      return false;
    }
  }
  
  // Try reconnection with exponential backoff strategy
  Future<bool> attemptReconnectWithBackoff({
    int initialDelaySeconds = 2,
    int maxAttempts = 5,
    int maxDelaySeconds = 60,
  }) async {
    int currentDelay = initialDelaySeconds;
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // Wait before attempting reconnection (except first attempt)
      if (attempt > 0) {
        _logger.info('Waiting $currentDelay seconds before retry attempt ${attempt+1}/$maxAttempts');
        await Future.delayed(Duration(seconds: currentDelay));
        
        // Exponential backoff with max cap
        currentDelay = (currentDelay * 2).clamp(initialDelaySeconds, maxDelaySeconds);
      }
      
      _logger.info('Reconnection attempt ${attempt+1}/$maxAttempts');
      final success = await attemptReconnect(force: true);
      if (success) {
        _logger.info('Reconnection successful on attempt ${attempt+1}');
        return true;
      }
      
      // If network connection is lost during retry attempts, abort early
      if (!_hasConnection) {
        _logger.info('Network connection lost during retry attempts, aborting');
        return false;
      }
    }
    
    _logger.warning('All reconnection attempts failed after $maxAttempts tries');
    return false;
  }
  
  // Check if we are in offline mode
  bool get isOfflineMode => !_hasConnection || !_serverReachable;
  
  // More detailed status
  ConnectivityStatus get status {
    if (!_hasConnection) {
      return ConnectivityStatus.noConnection;
    } else if (!_serverReachable) {
      return ConnectivityStatus.serverUnreachable;
    } else {
      return ConnectivityStatus.online;
    }
  }
  
  // Dispose resources
  void dispose() {
    _periodicCheckTimer?.cancel();
    _connectionStatusController.close();
    _serverStatusController.close();
    _logger.info('ConnectivityService resources disposed');
  }
}
