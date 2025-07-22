// lib/services/auth_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import '../services/api_client.dart';
import '../services/biometric_auth_service.dart';
import '../services/google_auth_service.dart' as google_auth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

// Auth session for persistent login
class AuthSession {
  final String userId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String sessionToken;
  final String? deviceId;
  
  bool get isValid => DateTime.now().isBefore(expiresAt);
  
  AuthSession({
    required this.userId,
    required this.sessionToken,
    this.deviceId,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 30));
    
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'sessionToken': sessionToken,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'deviceId': deviceId,
  };
  
  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    userId: json['userId'],
    sessionToken: json['sessionToken'],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    deviceId: json['deviceId'],
  );
}

// Result class for sync operations
class SyncResult {
  final bool success;
  final String message;
  final int syncedEntities;
  
  SyncResult({
    required this.success,
    required this.message,
    required this.syncedEntities,
  });
  
  static SyncResult failed(String message) => SyncResult(
    success: false,
    message: message,
    syncedEntities: 0,
  );
  
  static SyncResult success({int syncedEntities = 0, String? message}) => SyncResult(
    success: true,
    message: message ?? 'Sync completed successfully',
    syncedEntities: syncedEntities,
  );
}

// User-controlled sync settings
class SyncSettings {
  bool syncTransactions;
  bool syncBudgets;
  bool syncGoals;
  TransactionSyncLevel transactionSyncLevel;
  
  SyncSettings({
    this.syncTransactions = false, // Default to privacy-first
    this.syncBudgets = true,
    this.syncGoals = true,
    this.transactionSyncLevel = TransactionSyncLevel.metadataOnly,
  });
  
  Map<String, dynamic> toJson() => {
    'syncTransactions': syncTransactions,
    'syncBudgets': syncBudgets,
    'syncGoals': syncGoals,
    'transactionSyncLevel': transactionSyncLevel.index,
  };
  
  factory SyncSettings.fromJson(Map<String, dynamic> json) => SyncSettings(
    syncTransactions: json['syncTransactions'] ?? false,
    syncBudgets: json['syncBudgets'] ?? true,
    syncGoals: json['syncGoals'] ?? true,
    transactionSyncLevel: TransactionSyncLevel.values[json['transactionSyncLevel'] ?? 1],
  );
  
  SyncSettings copyWith({
    bool? syncTransactions,
    bool? syncBudgets,
    bool? syncGoals,
    TransactionSyncLevel? transactionSyncLevel,
  }) => SyncSettings(
    syncTransactions: syncTransactions ?? this.syncTransactions,
    syncBudgets: syncBudgets ?? this.syncBudgets,
    syncGoals: syncGoals ?? this.syncGoals,
    transactionSyncLevel: transactionSyncLevel ?? this.transactionSyncLevel,
  );
}

enum TransactionSyncLevel {
  none,           // No transaction sync
  metadataOnly,   // Only amount, date, category (no descriptions/memos)
  fullWithoutPII, // Everything except personally identifiable info
  complete        // Complete transaction details
}

// Sync strategy for different scenarios
enum SyncStrategy {
  manual,      // User-triggered sync
  immediate,   // Sync right away (foreground)
  scheduled,   // Schedule for next sync window
  background,  // Perform in background
  startup      // Sync when app starts
}

// Result class for profile existence checks
class ProfileExistenceResult {
  final bool exists;
  final bool isLocal;
  final bool isOnServer;

  ProfileExistenceResult({
    required this.exists,
    required this.isLocal,
    required this.isOnServer,
  });
}

// Login result class
class LoginResult {
  final bool success;
  final String message;
  final Profile? profile;
  final bool isFirstLogin;

  LoginResult.success({
    this.profile, 
    this.isFirstLogin = false,
  }) : success = true,
       message = 'Login successful';
       
  LoginResult.error(this.message) 
    : success = false, 
      profile = null,
      isFirstLogin = false;

  static LoginResult empty() => LoginResult.error('No profile found');
}

// Profile stats class
class ProfileStats {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final int transactionCount;
  final int activeBudgets;
  final int activeGoals;
  final DateTime? lastLogin;
  final int accountAge;

  ProfileStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.transactionCount,
    required this.activeBudgets,
    required this.activeGoals,
    this.lastLogin,
    required this.accountAge,
  });

  static ProfileStats empty() => ProfileStats(
    totalIncome: 0.0,
    totalExpense: 0.0,
    netBalance: 0.0,
    transactionCount: 0,
    activeBudgets: 0,
    activeGoals: 0,
    accountAge: 0,
  );
}

class AuthService extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final ApiClient _apiClient = ApiClient();
  final _secureStorage = const FlutterSecureStorage();
  final logger = Logger('AuthService');

  Profile? _currentProfile;
  bool _isInitialized = false;
  Box<Profile>? _profileBox;

  Profile? get currentProfile => _currentProfile;
  bool get isLoggedIn => _currentProfile != null;
  bool get isInitialized => _isInitialized;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if boxes are already open, if not open them
      if (!Hive.isBoxOpen('profiles')) {
        _profileBox = await Hive.openBox<Profile>('profiles');
      } else {
        _profileBox = Hive.box<Profile>('profiles');
      }

      // Open other necessary boxes
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }
      if (!Hive.isBoxOpen('transactions')) {
        await Hive.openBox('transactions');
      }
      if (!Hive.isBoxOpen('budgets')) {
        await Hive.openBox('budgets');
      }
      if (!Hive.isBoxOpen('goals')) {
        await Hive.openBox('goals');
      }

      // Create test profiles if none exist (for development/testing)
      await _createTestProfilesIfNeeded();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize AuthService: $e');
      }
    }
  }

  // Auto login - check for stored session and restore if valid
  Future<LoginResult> tryAutoLogin() async {
    try {
      if (_profileBox == null) {
        await initialize();
      }

      final settingsBox = Hive.box('settings');
      
      // Check if persistent login is enabled globally
      final persistentLoginEnabled = settingsBox.get(
        'persistent_login_enabled',
        defaultValue: true,
      );
      
      if (!persistentLoginEnabled) {
        return LoginResult.error('Persistent login is disabled');
      }
      
      // Try to get saved session
      final sessionJson = settingsBox.get('auth_session');
      if (sessionJson == null) {
        return LoginResult.error('No saved session found');
      }
      
      // Parse and validate session
      final session = AuthSession.fromJson(Map<String, dynamic>.from(sessionJson));
      if (!session.isValid) {
        // Clear expired session
        await settingsBox.delete('auth_session');
        return LoginResult.error('Session expired');
      }
      
      // Get profile from local storage
      final profile = _profileBox!.get(session.userId);
      if (profile == null) {
        // Profile not found locally, try to fetch from server if online
        final isConnected = await _apiClient.checkServerConnection();
        if (isConnected) {
          try {
            final serverProfile = await _apiClient.getProfile(
              userId: session.userId,
              sessionToken: session.sessionToken,
            );
            
            if (serverProfile != null) {
              // Save profile locally
              await _profileBox!.put(session.userId, serverProfile);
              _currentProfile = serverProfile;
              
              // Update session's expiry date to extend it
              _refreshSession(session);
              
              notifyListeners();
              return LoginResult.success(profile: serverProfile);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to fetch profile from server: $e');
            }
          }
        }
        
        return LoginResult.error('Profile not found');
      }
      
      // Successfully found local profile
      _currentProfile = profile;
      
      // Update last login timestamp
      final updatedProfile = profile.copyWith(lastLogin: DateTime.now());
      await _profileBox!.put(session.userId, updatedProfile);
      _currentProfile = updatedProfile;
      
      // Refresh the session
      _refreshSession(session);
      
      // Try background sync if online
      _syncInBackground();
      
      // Since this is auto-login, it's not a first login
      // but we'll still check the status for consistent UI behavior
      final isFirstTimeLogin = await isFirstLogin();
      
      notifyListeners();
      
      if (kDebugMode) {
        print('Auto login successful for profile: ${profile.email}');
      }
      
      return LoginResult.success(
        profile: updatedProfile,
        isFirstLogin: isFirstTimeLogin,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Auto login failed: $e');
      }
      return LoginResult.error('Auto login failed: ${e.toString()}');
    }
  }
  
  // Refresh an auth session to extend its validity
  Future<void> _refreshSession(AuthSession session) async {
    try {
      final settingsBox = Hive.box('settings');
      final newSession = AuthSession(
        userId: session.userId,
        sessionToken: session.sessionToken,
        deviceId: session.deviceId,
        // Create a new expiration date 30 days from now
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      
      await settingsBox.put('auth_session', newSession.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Failed to refresh session: $e');
      }
    }
  }
  
  // Perform background synchronization
  Future<void> _syncInBackground() async {
    try {
      final isConnected = await _apiClient.checkServerConnection();
      if (isConnected && _currentProfile != null) {
        // Get sync settings
        final settingsBox = Hive.box('settings');
        final syncSettingsJson = settingsBox.get(
          'sync_settings_${_currentProfile!.id}',
          defaultValue: SyncSettings().toJson(),
        );
        
        final syncSettings = SyncSettings.fromJson(
          Map<String, dynamic>.from(syncSettingsJson),
        );
        
        // Create sync manager and perform sync based on settings
        final syncManager = SyncManager(apiClient: _apiClient, profile: _currentProfile!);
        await syncManager.syncEssentialData(); // Always sync essential data
        
        // Conditional syncing based on user preferences
        if (syncSettings.syncGoals) {
          syncManager.syncGoals(); // Fire and forget
        }
        
        if (syncSettings.syncBudgets) {
          syncManager.syncBudgets(); // Fire and forget
        }
        
        if (syncSettings.syncTransactions) {
          syncManager.syncTransactions(
            level: syncSettings.transactionSyncLevel,
          ); // Fire and forget
        }
      }
    } catch (e) {
      // Silent fail for background sync
      if (kDebugMode) {
        print('Background sync failed: $e');
      }
    }
  }

  // Enable or disable persistent login
  Future<void> setPersistentLoginEnabled(bool enabled) async {
    try {
      final settingsBox = Hive.box('settings');
      await settingsBox.put('persistent_login_enabled', enabled);

      if (!enabled) {
        // If disabling persistent login, clear current session
        await logout();
      }

      if (kDebugMode) {
        print('Persistent login ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set persistent login: $e');
      }
    }
  }

  // Check if persistent login is enabled
  Future<bool> isPersistentLoginEnabled() async {
    try {
      final settingsBox = Hive.box('settings');
      return settingsBox.get('persistent_login_enabled', defaultValue: true);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check persistent login status: $e');
      }
      return false;
    }
  }

  // Create test profiles for development/testing if none exist
  Future<void> _createTestProfilesIfNeeded() async {
    try {
      _profileBox ??= await Hive.openBox<Profile>('profiles');

      if (_profileBox!.isEmpty) {
        if (kDebugMode) {
          print('No profiles found. Creating test profiles...');
        }

        // Create test business profile
        final businessProfile = Profile(
          id: const Uuid().v4(),
          type: ProfileType.business,
          pin: 'password123',
          passwordHash: Profile.hashPassword('password123'),
          name: 'Test Business',
          email: 'business@test.com',
        );

        // Create test personal profile
        final personalProfile = Profile(
          id: const Uuid().v4(),
          type: ProfileType.personal,
          pin: 'password456',
          passwordHash: Profile.hashPassword('password456'),
          name: 'Test Personal',
          email: 'personal@test.com',
        );

        await _profileBox!.put(businessProfile.id, businessProfile);
        await _profileBox!.put(personalProfile.id, personalProfile);

        if (kDebugMode) {
          print('Test profiles created:');
          print(
            '  Business: Email: ${businessProfile.email}, Password: password123',
          );
          print(
            '  Personal: Email: ${personalProfile.email}, Password: password456',
          );
        }
      } else {
        if (kDebugMode) {
          print('Existing profiles found: ${_profileBox!.length}');
          for (var key in _profileBox!.keys) {
            var profile = _profileBox!.get(key);
            print(
              '  ${profile?.type}: Email: ${profile?.email}, Name: ${profile?.name}',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating test profiles: $e');
      }
    }
  }

  // Create profile with additional metadata
  Future<bool> createProfile(Map<String, dynamic> profileData) async {
    try {
      if (kDebugMode) {
        print('Creating enhanced profile with data: $profileData');
      } // Extract email and pin, which are now primary for server interaction
      final String? email = profileData['email'];
      final String? pin = profileData['pin'];
      final String? name = profileData['name'];
      final ProfileType? profileTypeEnum = profileData['profile_type'];

      if (email == null || email.isEmpty || pin == null || pin.isEmpty) {
        if (kDebugMode) {
          print('Email or PIN is missing. Cannot create server profile.');
        }
        throw Exception('Email and PIN are required to create a profile.');
      }

      if (name == null || name.isEmpty) {
        if (kDebugMode) {
          print('Name is missing. Cannot create server profile.');
        }
        throw Exception('Name is required to create a profile.');
      }

      if (profileTypeEnum == null) {
        if (kDebugMode) {
          print('Profile type is missing. Cannot create server profile.');
        }
        throw Exception('Profile type is required to create a profile.');
      }

      final String profileTypeString =
          profileTypeEnum
              .toString()
              .split('.')
              .last; // First try to create profile on server
      try {
        final serverResponse = await _apiClient.createEnhancedProfile(
          name: name,
          profileType: profileTypeString,
          pin: pin,
          email: email,
          baseCurrency: profileData['base_currency'] ?? 'KES',
          timezone: profileData['timezone'] ?? 'GMT+3',
        );
        if (kDebugMode) {
          print('Server profile created successfully: $serverResponse');
        }

        String userId =
            serverResponse['user_id'] ??
            serverResponse['profile_id'] ??
            _uuid.v4();
        final profile = Profile(
          id: userId, // Use server-provided user_id
          type: profileData['profile_type'],
          pin: pin,
          passwordHash: Profile.hashPassword(pin),
          name: profileData['name'],
          email: email,
          baseCurrency: profileData['base_currency'] ?? 'KES',
          timezone: profileData['timezone'] ?? 'GMT+3',
        );
        _profileBox ??= await Hive.openBox<Profile>(
          'profiles',
        );
        await _profileBox!.put(userId, profile);

        final settingsBox = Hive.box('settings');
        await settingsBox.put(
          'google_drive_enabled',
          profileData['enable_google_drive'] ?? false,
        );
        await settingsBox.put('current_profile_id', userId);

        _currentProfile = profile;

        // Save to Google if requested
        if (profileData['save_to_google'] == true) {
          await saveCredentialsToGoogle();
        }

        notifyListeners();

        if (kDebugMode) {
          print(
            'Enhanced profile created successfully with email: ${profile.email}, User ID: $userId',
          );
        }

        return true;
      } catch (serverError) {
        if (kDebugMode) {
          print('Server profile creation failed: $serverError');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Enhanced profile creation failed: $e');
      }
      return false;
    }
  }

  // Basic login with email and password
  Future<LoginResult> login({
    required String email,
    required String password,
    bool createPersistentSession = true,
  }) async {
    if (kDebugMode) {
      print('Attempting login for email: $email');
    }

    try {
      _profileBox ??= await Hive.openBox<Profile>('profiles');

      for (final profile in _profileBox!.values) {
        if (profile.email == email && profile.verifyPassword(password)) {
          _currentProfile = profile.copyWith(lastLogin: DateTime.now());

          // Save updated profile with last login time
          await _profileBox!.put(profile.id, _currentProfile!);

          // Save current profile ID and create persistent session if enabled
          final settingsBox = Hive.box('settings');
          await settingsBox.put('current_profile_id', profile.id);

          // Create and save auth session for persistent login
          if (createPersistentSession) {
            final deviceId = await _getOrCreateDeviceId();
            final authSession = AuthSession(
              userId: profile.id,
              sessionToken: _createSessionToken(),
              deviceId: deviceId,
            );
            
            await settingsBox.put('auth_session', authSession.toJson());
          }
          
          final isFirstTimeLogin = await isFirstLogin();
          
          return LoginResult.success(
            profile: _currentProfile,
            isFirstLogin: isFirstTimeLogin,
          );
        }
      }
      
      return LoginResult.error('Invalid email or password');
    } catch (e) {
      if (kDebugMode) {
        print('Login failed: $e');
      }
      return LoginResult.error('Login failed: ${e.toString()}');
    }
  }

  // Enhanced login with better error handling and Google credential support
  Future<LoginResult> enhancedLogin(
    String email,
    String pin, {
    bool saveToGoogle = false,
    bool createPersistentSession = true,
  }) async {
    if (kDebugMode) {
      print('Attempting enhanced login for email: $email');
    }

    try {
      _profileBox ??= await Hive.openBox<Profile>('profiles');

      for (final profile in _profileBox!.values) {
        if (profile.email == email && profile.verifyPassword(pin)) {
          _currentProfile = profile.copyWith(lastLogin: DateTime.now());

          // Save updated profile with last login time
          await _profileBox!.put(profile.id, _currentProfile!);

          // Save current profile ID and create persistent session if enabled
          final settingsBox = Hive.box('settings');
          await settingsBox.put('current_profile_id', profile.id);

          // Create and save auth session for persistent login
          if (createPersistentSession) {
            final deviceId = await _getOrCreateDeviceId();
            final authSession = AuthSession(
              userId: profile.id,
              sessionToken: _createSessionToken(),
              deviceId: deviceId,
            );

            await settingsBox.put('auth_session', authSession.toJson());
            if (kDebugMode) {
              print('Created persistent auth session until: ${authSession.expiresAt}');
            }
          }

          // Save to Google if requested
          if (saveToGoogle) {
            await saveCredentialsToGoogle();
          }

          // Try to sync in background if online
          _startBackgroundSync();

          // Check if this is the first login for the profile
          final isFirstTimeLogin = await isFirstLogin();
          if (isFirstTimeLogin) {
            // This information will be available to the UI layer to show prompts
            if (kDebugMode) {
              print('First login detected for: ${_currentProfile!.id}');
            }
          }

          notifyListeners();

          if (kDebugMode) {
            print('Local login successful for email: $email');
          }

          // Return success with first login status to inform UI about prompts
          return LoginResult.success(
            profile: _currentProfile!,
            isFirstLogin: isFirstTimeLogin,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during login: $e');
      }
      return LoginResult.error('Login failed: ${e.toString()}');
    }

    // If we get here, no matching profile was found
    return LoginResult.error('Invalid email or PIN');
  }
      
  // Helper method to get or create a device ID
  Future<String> _getOrCreateDeviceId() async {
    final settingsBox = Hive.box('settings');
    String? deviceId = settingsBox.get('device_id');
    
    if (deviceId == null) {
      deviceId = _uuid.v4(); // Generate a new UUID for this device
      await settingsBox.put('device_id', deviceId);
    }
    
    return deviceId;
  }
  
  // Helper method to create a secure session token
  String _createSessionToken() {
    // Combine UUID with timestamp for uniqueness
    return '${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  // Start background sync process
  void _startBackgroundSync() {
    if (_currentProfile == null) return;
    
    // Use Future.delayed to run sync in background without blocking UI
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        final syncManager = SyncManager(
          apiClient: _apiClient,
          profile: _currentProfile!,
        );
        
        // Try to sync essential data first
        await syncManager.syncEssentialData();
        
        // Get sync settings and perform other syncs
        final settingsBox = Hive.box('settings');
        final syncSettingsJson = settingsBox.get(
          'sync_settings_${_currentProfile!.id}',
          defaultValue: SyncSettings().toJson(),
        );
        
        final syncSettings = SyncSettings.fromJson(
          Map<String, dynamic>.from(syncSettingsJson),
        );
        
        // Start background syncs that can run in parallel
        if (syncSettings.syncGoals) {
          syncManager.syncGoals(); // Fire and forget
        }
        
        if (syncSettings.syncBudgets) {
          syncManager.syncBudgets(); // Fire and forget
        }
        
        if (syncSettings.syncTransactions) {
          syncManager.syncTransactions(
            level: syncSettings.transactionSyncLevel,
          ); // Fire and forget
        }
      } catch (e) {
        if (kDebugMode) {
          print('Background sync after login failed: $e');
        }
      }
    });
  }
  
  // Login helper method
  Future<LoginResult> _completeLogin(Profile profile, {bool isFirstTimeLogin = false}) async {
    try {
      _currentProfile = profile.copyWith(lastLogin: DateTime.now());
      await _profileBox?.put(profile.id, _currentProfile!);
      notifyListeners();
      return LoginResult.success(
        profile: _currentProfile,
        isFirstLogin: isFirstTimeLogin,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error completing login: $e');
      }
      return LoginResult.error('Error during login process: ${e.toString()}');
    }
  }
  
  // Check if this is the first login for the current profile
  Future<bool> isFirstLogin() async {
    if (_currentProfile == null) return false;
    
    try {
      final settingsBox = Hive.box('settings');
      final key = 'first_login_${_currentProfile!.id}';
      final isFirst = settingsBox.get(key, defaultValue: true);
      
      if (isFirst) {
        // Mark as no longer first login
        await settingsBox.put(key, false);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking first login: $e');
      }
      return false;
    }
  }

  // Handle invalid login attempts (e.g., wrong email or PIN)
  Future<LoginResult> _handleInvalidLogin() async {
    // Try server login if possible
    try {
      // Server login implementation would go here
      // For now, return an error
      return LoginResult.error('Invalid email or PIN');
    } catch (e) {
      if (kDebugMode) {
        print('Server login failed: $e');
      }
      return LoginResult.error('Login failed: Unable to authenticate');
    }
  }

  // Define the missing SyncManager class
  class SyncManager {
    final ApiClient apiClient;
    final Profile profile;
    
    SyncManager({
      required this.apiClient,
      required this.profile,
    });
    
    Future<bool> syncEssentialData() async {
      try {
        // Sync essential profile data
        if (kDebugMode) {
          print('Syncing essential data for profile: ${profile.id}');
        }
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('Failed to sync essential data: $e');
        }
        return false;
      }
    }
    
    Future<bool> syncTransactions({TransactionSyncLevel level = TransactionSyncLevel.metadataOnly}) async {
      try {
        if (kDebugMode) {
          print('Syncing transactions with level: $level');
        }
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('Failed to sync transactions: $e');
        }
        return false;
      }
    }
    
    Future<bool> syncBudgets() async {
      try {
        if (kDebugMode) {
          print('Syncing budgets');
        }
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('Failed to sync budgets: $e');
        }
        return false;
      }
    }
    
    Future<bool> syncGoals() async {
      try {
        if (kDebugMode) {
          print('Syncing goals');
        }
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('Failed to sync goals: $e');
        }
        return false;
      }
    }
  }

  // Add saveCredentialsToGoogle method
  Future<bool> saveCredentialsToGoogle() async {
    try {
      if (kDebugMode) {
        print('Saving credentials to Google');
      }
      // Implementation would go here using the imported google_auth package
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save credentials to Google: $e');
      }
      return false;
    }
  }

  // Missing logger property
  final _logger = Logger('AuthService');

  // Missing SecureStorage property
  final _secureStorage = FlutterSecureStorage();

  // Logout
  Future<void> logout() async {
    try {
      // Clear biometric auth
      await biometricService.clearBiometricSession();
      
      // Check if online and invalidate session on server
      try {
        final isConnected = await _apiClient.checkServerConnection();
        
        if (isConnected && 
            _currentProfile != null && 
            _currentProfile!.sessionToken != null) {
          await _apiClient.invalidateSession(
            sessionToken: _currentProfile!.sessionToken!,
            userId: _currentProfile!.id,
          );
        }
      } catch (e) {
        _logger.warning('Failed to invalidate server session: $e');
      }
      
      // Clear current profile
      _currentProfile = null;
      
      // Clear secure storage
      await _secureStorage.delete(key: 'current_profile_id');
      await _secure_storage.delete(key: 'session_token');
      
      notifyListeners();
    } catch (e) {
      _logger.severe('Error during logout: $e');
    }
  }

  Future<bool> updateProfileName(String newName) async {
    if (_currentProfile == null || newName.trim().isEmpty) {
      return false;
    }
    
    try {
      final updatedProfile = _currentProfile!.copyWith(name: newName.trim());
      
      // Save to local storage
      await _profileBox?.put(_currentProfile!.id, updatedProfile);
      
      // Update current profile
      _currentProfile = updatedProfile;
      notifyListeners();
      
      return true;
    } catch (e) {
      _logger.severe('Failed to update profile name: $e');
      return false;
    }
  }
  
  Future<bool> updateProfileEmail(String newEmail) async {
    if (_currentProfile == null || 
        newEmail.trim().isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(newEmail)) {
      return false;
    }
    
    try {
      final updatedProfile = _currentProfile!.copyWith(email: newEmail.trim());
      
      // Save to local storage
      await _profileBox?.put(_currentProfile!.id, updatedProfile);
      
      // Update current profile
      _currentProfile = updatedProfile;
      notifyListeners();
      
      return true;
    } catch (e) {
      _logger.severe('Failed to update profile email: $e');
      return false;
    }
  }
  
  /// Sign up a new user
  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      if (_profileBox == null) {
        await initialize();
      }
      
      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return false;
      }
      
      // Check if email already exists
      final existingProfiles = _profileBox!.values.cast<Profile>().toList();
      final emailExists = existingProfiles.any((profile) => 
        profile.email.toLowerCase() == email.toLowerCase()
      );
      
      if (emailExists) {
        return false;
      }
      
      final deviceId = await _getOrCreateDeviceId();
      final sessionToken = _createSessionToken();
      final userId = _uuid.v4();
      
      // Create new profile
      final newProfile = Profile(
        id: userId,
        email: email,
        name: '$firstName $lastName',
        phoneNumber: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLogin: DateTime.now(),
        type: ProfileType.personal,
        sessionToken: sessionToken,
      );
      
      // Save locally
      await _profileBox!.put(userId, newProfile);
      
      // Set as current profile
      _currentProfile = newProfile;
      
      // Store session for auto login
      final settingsBox = Hive.box('settings');
      await settingsBox.put(
        'auth_session', 
        AuthSession(
          userId: userId,
          sessionToken: sessionToken,
          deviceId: deviceId,
        ).toJson()
      );
      
      // Try to sync with server if online
      try {
        final isConnected = await _apiClient.checkServerConnection();
        
        if (isConnected) {
          await _apiClient.createAccount(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
            deviceId: deviceId,
          );
        }
      } catch (e) {
        _logger.warning('Failed to sync new account with server: $e');
        // Continue since we already created locally
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _logger.severe('Signup failed: $e');
      return false;
    }
  }
}
