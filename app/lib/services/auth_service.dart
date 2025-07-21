// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../models/enums.dart';
import '../services/api_client.dart';
import '../services/biometric_auth_service.dart';
import '../services/google_auth_service.dart';

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
    createdAt: DateTime.parse(json['createdAt']),
    expiresAt: DateTime.parse(json['expiresAt']),
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

enum SyncStrategy {
  manual,     // User-triggered sync
  scheduled,  // Scheduled periodic sync
  background, // Background sync (e.g. after login)
  startup     // Sync when app starts
}

// TimeoutException class for sync operations
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => message;
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
      // TODO: Fix login to use userId instead of email
      // For now, try to find local profile by email
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
        
  // Check if this is the user's first login
  Future<bool> isFirstLogin() async {
    if (_currentProfile == null) return false;
    
    final settingsBox = Hive.box('settings');
    final String profileFirstLoginKey = 'first_login_completed_${_currentProfile!.id}';
    final bool firstLoginCompleted = settingsBox.get(profileFirstLoginKey, defaultValue: false);
    
    return !firstLoginCompleted;
  }
  
  // Mark first login as completed
  Future<void> markFirstLoginCompleted() async {
    if (_currentProfile == null) return;
    
    final settingsBox = Hive.box('settings');
    final String profileFirstLoginKey = 'first_login_completed_${_currentProfile!.id}';
    await settingsBox.put(profileFirstLoginKey, true);
  }
  
  // Check if biometric prompt has been shown
  Future<bool> shouldShowBiometricPrompt() async {
    if (_currentProfile == null) return false;
    
    final settingsBox = Hive.box('settings');
    final String biometricPromptKey = 'biometric_prompt_shown_${_currentProfile!.id}';
    final bool biometricPromptShown = settingsBox.get(biometricPromptKey, defaultValue: false);
    
    // Only show if the device supports biometrics
    final BiometricAuthService biometricService = BiometricAuthService.instance;
    final bool deviceSupportsBiometrics = await biometricService.canUseBiometrics();
    
    return !biometricPromptShown && deviceSupportsBiometrics;
  }
  
  // Mark biometric prompt as shown
  Future<void> markBiometricPromptShown() async {
    if (_currentProfile == null) return;
    
    final settingsBox = Hive.box('settings');
    final String biometricPromptKey = 'biometric_prompt_shown_${_currentProfile!.id}';
    await settingsBox.put(biometricPromptKey, true);
  }
  
  // Check if permissions prompt has been shown
  Future<bool> shouldShowPermissionsPrompt() async {
    if (_currentProfile == null) return false;
    
    final settingsBox = Hive.box('settings');
    final String permissionsPromptKey = 'permissions_prompt_shown_${_currentProfile!.id}';
    final bool permissionsPromptShown = settingsBox.get(permissionsPromptKey, defaultValue: false);
    
    return !permissionsPromptShown;
  }
  
  // Mark permissions prompt as shown
  Future<void> markPermissionsPromptShown() async {
    if (_currentProfile == null) return;
    
    final settingsBox = Hive.box('settings');
    final String permissionsPromptKey = 'permissions_prompt_shown_${_currentProfile!.id}';
    await settingsBox.put(permissionsPromptKey, true);
  }
  
  // Enable biometric authentication for the current user
  Future<bool> enableBiometricAuth() async {
    if (_currentProfile == null) return false;
    
    try {
      final BiometricAuthService biometricService = BiometricAuthService.instance;
      
      // Check if biometrics can be used on this device
      if (!await biometricService.canUseBiometrics()) {
        return false;
      }
      
      // Authenticate with biometric to confirm user identity
      final bool authenticated = await biometricService.authenticateWithBiometric(
        'Please verify your identity to enable biometric authentication'
      );
      
      if (!authenticated) {
        return false;
      }
      
      // Create biometric session
      await biometricService.createBiometricSession(_currentProfile!.id);
      
      // Mark biometric auth as enabled for this profile
      final settingsBox = Hive.box('settings');
      await settingsBox.put('biometric_enabled_${_currentProfile!.id}', true);
      
      if (kDebugMode) {
        print('Biometric authentication enabled for profile: ${_currentProfile!.email}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to enable biometric authentication: $e');
      }
      return false;
    }
  }
        
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
        }
      }
      return LoginResult.error('Invalid email or PIN');

      /* TODO: Restore server login with userId
      final serverProfileData = await _apiClient.loginProfile(
        userId: userId,  // Need to get userId from email somehow
        pin: pin,
      );

      if (kDebugMode) {
        print('Server login successful: $serverProfileData');
      }

      // Create profile from server data
      final String serverId = serverProfileData['id']?.toString() ?? email;
      final profileToSave = Profile(
        id: serverId,
        type: ProfileType.values.firstWhere(
          (e) =>
              e.toString().split('.').last == serverProfileData['profile_type'],
          orElse: () => ProfileType.personal,
        ),
        passwordHash: Profile.hashPassword(pin),
        name: serverProfileData['name'] ?? 'Default Name',
        email: email,
        baseCurrency: serverProfileData['base_currency'] ?? 'KES',
        timezone: serverProfileData['timezone'] ?? 'GMT+3',
      );

      _profileBox ??= await Hive.openBox<Profile>('profiles');
      await _profileBox!.put(serverId, profileToSave);

      final settingsBox = Hive.box('settings');
      await settingsBox.put('current_profile_id', serverId);

      _currentProfile = profileToSave;
      notifyListeners();

      if (kDebugMode) {
        print('Enhanced login successful for email: $email');
      }

      return LoginResult.success(profile: profileToSave);
      */
    } catch (e) {
      if (kDebugMode) {
        print('Enhanced login failed: $e');
      }
      return LoginResult.error('Login failed: $e');
    }
  }

  // Login with email and pin
  Future<bool> login(
    String email,
    String pin, {
    bool saveToGoogle = false,
  }) async {
    final result = await enhancedLogin(email, pin, saveToGoogle: saveToGoogle);
    return result.success;
  }

  // Signup with email and password
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

      // Check if email already exists
      final existingProfiles = _profileBox!.values
          .where((p) => p.email?.toLowerCase() == email.toLowerCase())
          .toList();
      
      if (existingProfiles.isNotEmpty) {
        return false; // Email already exists
      }

      // Create new profile
      final newProfile = Profile(
        id: const Uuid().v4(),
        name: '$firstName $lastName',
        email: email,
        type: ProfileType.personal,
        pin: password, // Using password as pin for now
      );

      // Save profile
      await _profileBox!.put(newProfile.id, newProfile);

      // Set as current profile
      _currentProfile = newProfile;
      
      final settingsBox = Hive.box('settings');
      await settingsBox.put('current_profile_id', newProfile.id);

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Signup failed: $e');
      }
      return false;
    }
  }

  // Login by profile type (for backward compatibility)
  Future<bool> loginByType(ProfileType profileType, String password) async {
    try {
      if (_profileBox == null) {
        await initialize();
      }

      final profiles =
          _profileBox!.values.where((p) => p.type == profileType).toList();

      for (final profile in profiles) {
        if (profile.verifyPassword(password)) {
          _currentProfile = profile.copyWith(lastLogin: DateTime.now());

          // Update last login
          await _profileBox!.put(profile.id, _currentProfile!);

          final settingsBox = Hive.box('settings');
          await settingsBox.put('current_profile_id', profile.id);

          notifyListeners();

          if (kDebugMode) {
            print('Login successful for profile type: $profileType');
          }

          return true;
        }
      }

      if (kDebugMode) {
        print('Login failed for profile type: $profileType');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      return false;
    }
  }

  // Set initial password for new profiles
  Future<bool> setInitialPassword(String newPassword) async {
    if (_currentProfile == null) {
      if (kDebugMode) {
        print('No current profile to set password for');
      }
      return false;
    }

    try {
      // Update password hash
      final newPasswordHash = Profile.hashPassword(newPassword);

      _currentProfile = _currentProfile!.copyWith(
        passwordHash: newPasswordHash,
      );

      // Save locally
      _profileBox ??= await Hive.openBox<Profile>('profiles');
      await _profileBox!.put(_currentProfile!.id, _currentProfile!);

      notifyListeners();

      if (kDebugMode) {
        print(
          'Initial password set successfully for profile: ${_currentProfile!.email}',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set initial password: $e');
      }
      return false;
    }
  }

  // Change password for existing profiles
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_currentProfile == null) {
      if (kDebugMode) {
        print('No current profile to change password for');
      }
      return false;
    }

    try {
      // Verify current password
      if (!_currentProfile!.verifyPassword(currentPassword)) {
        if (kDebugMode) {
          print('Current password verification failed');
        }
        return false;
      } // Try to update password on server first
      try {
        await _apiClient.updateEnhancedProfile(
          email: _currentProfile!.email!,
          passwordHash: Profile.hashPassword(newPassword),
          name: _currentProfile!.name!,
          baseCurrency: _currentProfile!.baseCurrency,
          timezone: _currentProfile!.timezone,
        );

        if (kDebugMode) {
          print('Server password update successful');
        }
      } catch (serverError) {
        if (kDebugMode) {
          print(
            'Server password update failed, continuing with local update: $serverError',
          );
        }
        // Continue with local update even if server fails
      }

      // Update password hash locally
      final newPasswordHash = Profile.hashPassword(newPassword);

      _currentProfile = _currentProfile!.copyWith(
        passwordHash: newPasswordHash,
      );

      // Save locally
      _profileBox ??= await Hive.openBox<Profile>('profiles');
      await _profileBox!.put(_currentProfile!.id, _currentProfile!);

      notifyListeners();

      if (kDebugMode) {
        print(
          'Password changed successfully for profile: ${_currentProfile!.email}',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to change password: $e');
      }
      return false;
    }
  }

  // Biometric Authentication Methods

  /// Try auto-login with biometric authentication
  Future<bool> tryBiometricAutoLogin() async {
    try {
      final BiometricAuthService biometricService =
          BiometricAuthService.instance;

      // Check if biometric session is valid
      final bool hasValidSession =
          await biometricService.hasValidBiometricSession();
      if (!hasValidSession) {
        return false;
      }

      // Check if we have a current profile stored
      final settingsBox = Hive.box('settings');
      final currentProfileId = settingsBox.get('current_profile_id');

      if (currentProfileId != null) {
        final profile = _profileBox!.get(currentProfileId);
        if (profile != null) {
          // Authenticate with biometric
          final bool authenticated = await biometricService
              .authenticateWithBiometric(
                'Please verify your identity to access your account',
              );

          if (authenticated) {
            _currentProfile = profile.copyWith(lastLogin: DateTime.now());
            await _profileBox!.put(profile.id, _currentProfile!);
            notifyListeners();

            if (kDebugMode) {
              print(
                'Biometric auto-login successful for profile: ${profile.email}',
              );
            }
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Biometric auto-login failed: $e');
      }
      return false;
    }
  }

  /// Login with biometric authentication
  Future<bool> loginWithBiometric() async {
    try {
      final BiometricAuthService biometricService =
          BiometricAuthService.instance;

      // Check if biometric is available and enabled
      if (!await biometricService.isBiometricEnabled()) {
        if (kDebugMode) {
          print('Biometric authentication is not enabled');
        }
        return false;
      }

      // Authenticate with biometric
      final bool authenticated = await biometricService
          .authenticateWithBiometric(
            'Please verify your identity to access your account',
          );

      if (!authenticated) {
        return false;
      }

      // Get current profile
      final settingsBox = Hive.box('settings');
      final currentProfileId = settingsBox.get('current_profile_id');

      if (currentProfileId != null) {
        final profile = _profileBox!.get(currentProfileId);
        if (profile != null) {
          _currentProfile = profile.copyWith(lastLogin: DateTime.now());
          await _profileBox!.put(profile.id, _currentProfile!);
          notifyListeners();

          if (kDebugMode) {
            print('Biometric login successful for profile: ${profile.email}');
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Biometric login failed: $e');
      }
      return false;
    }
  }

  /// Check if biometric setup should be prompted
  Future<bool> shouldPromptBiometricSetup() async {
    try {
      final BiometricAuthService biometricService =
          BiometricAuthService.instance;
      return await biometricService.shouldPromptBiometricSetup();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking biometric setup prompt: $e');
      }
      return false;
    }
  }

  // Check if a profile exists with the given email
  Future<ProfileExistenceResult> checkProfileExists(String email) async {
    try {
      _profileBox ??= await Hive.openBox<Profile>('profiles');

      // Check local storage
      bool isLocal = false;
      for (var profile in _profileBox!.values) {
        if (profile.email == email) {
          isLocal = true;
          break;
        }
      } // Check server
      bool isOnServer = false;
      try {
        await _apiClient.getEnhancedProfile(email: email);
        isOnServer = true; // If no exception is thrown, profile exists
      } catch (e) {
        if (kDebugMode) {
          print('Server check failed: $e');
        }
        isOnServer = false;
      }

      return ProfileExistenceResult(
        exists: isLocal || isOnServer,
        isLocal: isLocal,
        isOnServer: isOnServer,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Profile existence check failed: $e');
      }
      return ProfileExistenceResult(
        exists: false,
        isLocal: false,
        isOnServer: false,
      );
    }
  }

  // Get profile statistics
  Future<ProfileStats> getProfileStats() async {
    if (_currentProfile == null) {
      return ProfileStats.empty();
    }

    try {
      final transactionBox = Hive.box('transactions');
      final budgetBox = Hive.box('budgets');
      final goalBox = Hive.box('goals');

      final profileTransactions =
          transactionBox.values
              .where((t) => t['profileId'] == _currentProfile!.id)
              .toList();

      final totalIncome = profileTransactions
          .where((t) => t['type'] == 'income')
          .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0));

      final totalExpense = profileTransactions
          .where((t) => t['type'] == 'expense')
          .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0));

      final activeBudgets =
          budgetBox.values
              .where(
                (b) =>
                    b['profileId'] == _currentProfile!.id &&
                    b['isActive'] == true,
              )
              .length;

      final activeGoals =
          goalBox.values
              .where(
                (g) =>
                    g['profileId'] == _currentProfile!.id &&
                    g['isCompleted'] == false,
              )
              .length;

      return ProfileStats(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: totalIncome - totalExpense,
        transactionCount: profileTransactions.length,
        activeBudgets: activeBudgets,
        activeGoals: activeGoals,
        lastLogin: _currentProfile!.lastLogin,
        accountAge:
            DateTime.now().difference(_currentProfile!.createdAt).inDays,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get profile stats: $e');
      }
      return ProfileStats.empty();
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Clear current profile
      _currentProfile = null;

      // Clear stored sessions
      final settingsBox = Hive.box('settings');
      await settingsBox.delete('current_profile_id');
      await settingsBox.delete('auth_session');

      // Clear biometric session
      final biometricService = BiometricAuthService.instance;
      await biometricService.clearBiometricSession();
      
      // Perform any server-side logout if needed and we're online
      try {
        final isConnected = await _apiClient.checkServerConnection();
        if (isConnected) {
          // Invalidate session on server
          final authSession = settingsBox.get('auth_session');
          if (authSession != null) {
            final session = AuthSession.fromJson(Map<String, dynamic>.from(authSession));
            await _apiClient.invalidateSession(
              userId: session.userId,
              sessionToken: session.sessionToken,
            );
          }
        }
      } catch (serverError) {
        // Silently fail server logout - local logout succeeded
        if (kDebugMode) {
          print('Server logout failed, but local logout succeeded: $serverError');
        }
      }

      if (kDebugMode) {
        print('AuthService: User logged out successfully');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error during logout: $e');
      }
    }
  }

  // Get all profiles (for profile selection)
  List<Profile> getAllProfiles() {
    try {
      if (_profileBox == null) return [];
      return _profileBox!.values.toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get all profiles: $e');
      }
      return [];
    }
  }

  // Delete profile
  Future<bool> deleteProfile(String profileId) async {
    try {
      _profileBox ??= await Hive.openBox<Profile>('profiles');

      final profile = _profileBox!.get(profileId);
      if (profile == null) {
        if (kDebugMode) {
          print('Profile not found for deletion: $profileId');
        }
        return false;
      }

      // Try to delete from server first
      try {
        await _apiClient.deleteEnhancedProfile(email: profile.email!);
        if (kDebugMode) {
          print('Server profile deletion successful');
        }
      } catch (serverError) {
        if (kDebugMode) {
          print(
            'Server profile deletion failed, continuing with local deletion: $serverError',
          );
        }
      }

      // Delete locally
      await _profileBox!.delete(profileId);

      // If this was the current profile, logout
      if (_currentProfile?.id == profileId) {
        await logout();
      }

      if (kDebugMode) {
        print('Profile deleted successfully: $profileId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete profile: $e');
      }
      return false;
    }
  }

  // Sync profile with server
  Future<void> syncProfileWithServer() async {
    if (_currentProfile == null) return;
    try {
      // Attempt to sync with server
      await _apiClient.updateEnhancedProfile(
        email: _currentProfile!.email!,
        name: _currentProfile!.name!,
        baseCurrency: _currentProfile!.baseCurrency,
        timezone: _currentProfile!.timezone,
      );

      if (kDebugMode) {
        print('Profile sync with server successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Profile sync with server failed: $e');
      }
    }
  }

  // Check if profile needs password change (first-time login)
  bool requiresPasswordChange() {
    if (_currentProfile == null) return false;

    // If never logged in before or account is very new
    if (_currentProfile!.lastLogin == null) return true;

    final daysSinceCreation =
        DateTime.now().difference(_currentProfile!.createdAt).inDays;
    return daysSinceCreation < 1 && _currentProfile!.lastLogin == null;
  }

  // Update profile name
  Future<bool> updateProfileName(String newName) async {
    if (_currentProfile == null || newName.trim().isEmpty) {
      return false;
    }

    try {
      // Update the profile locally
      final updatedProfile = _currentProfile!.copyWith(name: newName.trim());

      // Save to local storage
      await _profileBox?.put(_currentProfile!.id, updatedProfile);

      // Update current profile
      _currentProfile = updatedProfile;
      notifyListeners();

      // TODO: Sync with server if needed
      // _syncProfileWithServer();

      if (kDebugMode) {
        print('Profile name updated successfully: $newName');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update profile name: $e');
      }
      return false;
    }
  }

  // Update profile email
  Future<bool> updateProfileEmail(String newEmail) async {
    if (_currentProfile == null ||
        newEmail.trim().isEmpty ||
        !newEmail.contains('@')) {
      return false;
    }

    try {
      // Update the profile locally
      final updatedProfile = _currentProfile!.copyWith(email: newEmail.trim());

      // Save to local storage
      await _profileBox?.put(_currentProfile!.id, updatedProfile);

      // Update current profile
      _currentProfile = updatedProfile;
      notifyListeners();

      // TODO: Sync with server if needed
      // _syncProfileWithServer();

      if (kDebugMode) {
        print('Profile email updated successfully: $newEmail');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update profile email: $e');
      }
      return false;
    }
  }

  // Google Credential Management Methods

  /// Save login credentials to Google account
  Future<bool> saveCredentialsToGoogle() async {
    try {
      if (_currentProfile == null) {
        if (kDebugMode) {
          print('AuthService: No current profile to save credentials for');
        }
        return false;
      }

      final googleAuthService = GoogleAuthService.instance;
      final success = await googleAuthService.saveCredentialsToGoogle(
        email: _currentProfile!.email ?? '',
        name: _currentProfile!.name ?? '',
      );

      if (success) {
        // Mark that credentials are saved to Google for this profile
        final settingsBox = Hive.box('settings');
        await settingsBox.put('credentials_saved_to_google', true);
        await settingsBox.put('google_saved_profile_id', _currentProfile!.id);

        if (kDebugMode) {
          print(
            'AuthService: Credentials saved to Google for profile: ${_currentProfile!.email}',
          );
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error saving credentials to Google: $e');
      }
      return false;
    }
  }

  /// Check if credentials are saved to Google for current profile
  Future<bool> areCredentialsSavedToGoogle() async {
    try {
      final settingsBox = Hive.box('settings');
      final credentialsSaved = settingsBox.get(
        'credentials_saved_to_google',
        defaultValue: false,
      );
      final savedProfileId = settingsBox.get('google_saved_profile_id');

      // Check if the saved profile matches current profile
      if (_currentProfile != null && savedProfileId == _currentProfile!.id) {
        return credentialsSaved;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error checking Google credentials status: $e');
      }
      return false;
    }
  }

  /// Clear Google credential association
  Future<void> clearGoogleCredentials() async {
    try {
      final settingsBox = Hive.box('settings');
      await settingsBox.delete('credentials_saved_to_google');
      await settingsBox.delete('google_saved_profile_id');

      final googleAuthService = GoogleAuthService.instance;
      await googleAuthService.clearSavedCredentials();

      if (kDebugMode) {
        print('AuthService: Google credentials cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error clearing Google credentials: $e');
      }
    }
  }

  // Session Management Methods

  /// Create a new auth session
  Future<AuthSession?> createSession(String userId) async {
    try {
      final sessionToken = _uuid.v4(); // Generate a new session token
      final newSession = AuthSession(
        userId: userId,
        sessionToken: sessionToken,
      );

      // Save session to secure storage or database
      // TODO: Implement secure storage
      // await _secureStorage.write(key: 'auth_session', value: newSession.toJson());

      if (kDebugMode) {
        print('AuthService: Session created for user: $userId');
      }

      return newSession;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error creating session: $e');
      }
      return null;
    }
  }

  /// Validate the current auth session
  Future<bool> validateSession(AuthSession session) async {
    try {
      // Check if session is still valid
      if (!session.isValid) {
        if (kDebugMode) {
          print('AuthService: Session is expired for user: ${session.userId}');
        }
        return false;
      }

      // Optionally, you can add more validation logic here
      // e.g., check if the user still exists on the server

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error validating session: $e');
      }
      return false;
    }
  }

  /// End the current auth session
  Future<void> endSession(AuthSession session) async {
    try {
      // Remove session from secure storage or database
      // TODO: Implement secure storage
      // await _secureStorage.delete(key: 'auth_session');

      if (kDebugMode) {
        print('AuthService: Session ended for user: ${session.userId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error ending session: $e');
      }
    }
  }

  // Sync Manager Methods

  enum SyncStrategy { 
    immediate,  // Sync right away (profile changes)
    scheduled,  // Daily/weekly sync
    background, // Low-priority background sync
    manual      // User-initiated sync
  }

  class SyncManager {
    final ApiClient apiClient;
    final Profile profile;
    DateTime? _lastFullSync;
    bool _isSyncing = false;
    
    SyncManager({required this.apiClient, required this.profile}) {
      _lastFullSync = _loadLastSyncTime();
    }
    
    DateTime? _loadLastSyncTime() {
      try {
        final settingsBox = Hive.box('settings');
        final lastSyncString = settingsBox.get('last_full_sync_${profile.id}');
        if (lastSyncString != null) {
          return DateTime.parse(lastSyncString);
        }
        return null;
      } catch (e) {
        if (kDebugMode) {
          print('Error loading last sync time: $e');
        }
        return null;
      }
    }
    
    Future<void> _saveLastSyncTime(DateTime time) async {
      final settingsBox = Hive.box('settings');
      await settingsBox.put('last_full_sync_${profile.id}', time.toIso8601String());
      _lastFullSync = time;
    }
    
    Future<bool> _hasNetworkConnection() async {
      try {
        return await apiClient.checkServerConnection();
      } catch (e) {
        return false;
      }
    }
    
    Future<SyncSettings> _getSyncSettings() async {
      try {
        final settingsBox = Hive.box('settings');
        final rawSettings = settingsBox.get('sync_settings_${profile.id}');
        if (rawSettings != null) {
          return SyncSettings.fromJson(Map<String, dynamic>.from(rawSettings));
        }
        return SyncSettings(); // Default settings
      } catch (e) {
        if (kDebugMode) {
          print('Error getting sync settings: $e');
        }
        return SyncSettings(); // Default settings
      }
    }

    Future<void> updateSyncSettings(SyncSettings settings) async {
      final settingsBox = Hive.box('settings');
      await settingsBox.put('sync_settings_${profile.id}', settings.toJson());
    }
    
    // Sync essential data that should always be synced
    Future<SyncResult> syncEssentialData() async {
      if (!await _hasNetworkConnection()) {
        return SyncResult.failed('No network connection');
      }
      
      try {
        // Sync profile data
        final profileResult = await syncProfile();
        
        // Sync categories (they are essential for app functioning)
        final categoriesResult = await syncCategories();
        
        return SyncResult.success(
          syncedEntities: profileResult.syncedEntities + categoriesResult.syncedEntities,
          message: 'Essential data synced successfully',
        );
      } catch (e) {
        return SyncResult.failed('Failed to sync essential data: ${e.toString()}');
      }
    }
    
    Future<SyncResult> syncProfile() async {
      if (!await _hasNetworkConnection()) {
        return SyncResult.failed('No network connection');
      }
      
      try {
        // Push local profile changes to server
        await apiClient.updateProfile(profile);
        
        // Get latest profile from server
        final serverProfile = await apiClient.getProfile(
          userId: profile.id,
          sessionToken: profile.sessionToken,
        );
        
        if (serverProfile != null) {
          // Merge changes
          final mergedProfile = _mergeProfiles(profile, serverProfile);
          
          // Save merged profile locally
          final profileBox = Hive.box<Profile>('profiles');
          await profileBox.put(profile.id, mergedProfile);
          
          return SyncResult.success(
            syncedEntities: 1,
            message: 'Profile synced successfully',
          );
        }
        
        return SyncResult.success(
          syncedEntities: 0,
          message: 'No profile changes to sync',
        );
      } catch (e) {
        return SyncResult.failed('Failed to sync profile: ${e.toString()}');
      }
    }
    
    // Helper method to intelligently merge profiles
    Profile _mergeProfiles(Profile local, Profile server) {
      // Take the most recently updated profile as the base
      final baseProfile = local.lastUpdated.isAfter(server.lastUpdated) 
          ? local 
          : server;
      
      // Merge specific fields that might have been updated independently
      return baseProfile.copyWith(
        // Use most recent settings for each field
        email: server.lastUpdated.isAfter(local.lastUpdated) ? server.email : local.email,
        displayName: server.lastUpdated.isAfter(local.lastUpdated) ? server.displayName : local.displayName,
        preferences: _mergePreferences(local.preferences, server.preferences),
        lastSyncDate: DateTime.now(),
      );
    }
    
    Map<String, dynamic> _mergePreferences(Map<String, dynamic>? local, Map<String, dynamic>? server) {
      if (local == null) return server ?? {};
      if (server == null) return local;
      
      // Start with all local preferences
      final merged = Map<String, dynamic>.from(local);
      
      // Add/override with server preferences
      server.forEach((key, value) {
        merged[key] = value;
      });
      
      return merged;
    }
    
    Future<void> scheduleSyncs() async {
      // Daily background sync at 2 AM
      // This is just a placeholder - actual implementation would use platform-specific background tasks
      
      if (kDebugMode) {
        print('Scheduling daily background sync');
      }
      
      // Check if we need to sync based on time since last sync
      if (_lastFullSync == null || 
          DateTime.now().difference(_lastFullSync!).inHours > 24) {
        // It's been more than 24 hours since last sync
        syncAll(strategy: SyncStrategy.background);
      }
    }

    Future<SyncResult> syncCategories() async {
      if (!await _hasNetworkConnection()) {
        return SyncResult.failed('No network connection');
      }
      
      try {
        // Get categories box
        final categoriesBox = Hive.box('categories');
        
        // Get server categories
        final serverCategories = await apiClient.getCategories(
          userId: profile.id,
          sessionToken: profile.sessionToken,
        );
        
        if (serverCategories == null || serverCategories.isEmpty) {
          // No categories on server, push local categories
          final localCategories = categoriesBox.values.toList();
          if (localCategories.isNotEmpty) {
            await apiClient.updateCategories(
              userId: profile.id,
              sessionToken: profile.sessionToken,
              categories: localCategories,
            );
            return SyncResult.success(
              syncedEntities: localCategories.length,
              message: 'Local categories pushed to server',
            );
          }
          return SyncResult.success(
            syncedEntities: 0,
            message: 'No categories to sync',
          );
        }
        
        // We have server categories, merge with local
        final localCategories = categoriesBox.values.toList();
        final mergedCategories = _mergeCategories(localCategories, serverCategories);
        
        // Update local categories
        await categoriesBox.clear();
        for (final category in mergedCategories) {
          await categoriesBox.put(category['id'], category);
        }
        
        // Push merged categories back to server if needed
        if (_hasLocalChanges(localCategories, serverCategories)) {
          await apiClient.updateCategories(
            userId: profile.id,
            sessionToken: profile.sessionToken,
            categories: mergedCategories,
          );
        }
        
        return SyncResult.success(
          syncedEntities: mergedCategories.length,
          message: 'Categories synced successfully',
        );
      } catch (e) {
        return SyncResult.failed('Failed to sync categories: ${e.toString()}');
      }
    }
    
    bool _hasLocalChanges(List localItems, List serverItems) {
      if (localItems.length != serverItems.length) return true;
      
      // Compare last updated timestamps
      for (final localItem in localItems) {
        final serverItem = serverItems.firstWhere(
          (item) => item['id'] == localItem['id'],
          orElse: () => null,
        );
        
        if (serverItem == null) return true;
        
        final localTimestamp = DateTime.parse(localItem['lastUpdated']);
        final serverTimestamp = DateTime.parse(serverItem['lastUpdated']);
        
        if (localTimestamp.isAfter(serverTimestamp)) return true;
      }
      
      return false;
    }
    
    List _mergeCategories(List local, List server) {
      final mergedMap = <String, dynamic>{};
      
      // Add all server categories
      for (final item in server) {
        mergedMap[item['id']] = item;
      }
      
      // Add or update with local categories if they're newer
      for (final item in local) {
        final id = item['id'];
        if (!mergedMap.containsKey(id)) {
          mergedMap[id] = item;
        } else {
          final localTimestamp = DateTime.parse(item['lastUpdated']);
          final serverTimestamp = DateTime.parse(mergedMap[id]['lastUpdated']);
          
          if (localTimestamp.isAfter(serverTimestamp)) {
            mergedMap[id] = item;
          }
        }
      }
      
      return mergedMap.values.toList();
    }
    
    Future<SyncResult> syncBudgets() async {
      if (!await _hasNetworkConnection()) {
        return SyncResult.failed('No network connection');
      }
      
      try {
        // Get budgets box
        final budgetsBox = Hive.box('budgets');
        
        // Get server budgets
        final serverBudgets = await apiClient.getBudgets(
          userId: profile.id,
          sessionToken: profile.sessionToken,
        );
        
        if (serverBudgets == null || serverBudgets.isEmpty) {
          // No budgets on server, push local budgets
          final localBudgets = budgetsBox.values.toList();
          if (localBudgets.isNotEmpty) {
            await apiClient.updateBudgets(
              userId: profile.id,
              sessionToken: profile.sessionToken,
              budgets: localBudgets,
            );
            return SyncResult.success(
              syncedEntities: localBudgets.length,
              message: 'Local budgets pushed to server',
            );
          }
          return SyncResult.success(
            syncedEntities: 0,
            message: 'No budgets to sync',
          );
        }
        
        // We have server budgets, merge with local
        final localBudgets = budgetsBox.values.toList();
        final mergedBudgets = _mergeBudgets(localBudgets, serverBudgets);
        
        // Update local budgets
        await budgetsBox.clear();
        for (final budget in mergedBudgets) {
          await budgetsBox.put(budget['id'], budget);
        }
        
        // Push merged budgets back to server if needed
        if (_hasLocalChanges(localBudgets, serverBudgets)) {
          await apiClient.updateBudgets(
            userId: profile.id,
            sessionToken: profile.sessionToken,
            budgets: mergedBudgets,
          );
        }
        
        return SyncResult.success(
          syncedEntities: mergedBudgets.length,
          message: 'Budgets synced successfully',
        );
      } catch (e) {
        return SyncResult.failed('Failed to sync budgets: ${e.toString()}');
      }
    }
    
    List _mergeBudgets(List local, List server) {
      // Similar to merge categories but with budget-specific logic
      return _mergeGenericEntities(local, server);
    }
    
    List _mergeGenericEntities(List local, List server) {
      final mergedMap = <String, dynamic>{};
      
      // Add all server entities
      for (final item in server) {
        mergedMap[item['id']] = item;
      }
      
      // Add or update with local entities if they're newer
      for (final item in local) {
        final id = item['id'];
        if (!mergedMap.containsKey(id)) {
          mergedMap[id] = item;
        } else {
          final localTimestamp = DateTime.parse(item['lastUpdated']);
          final serverTimestamp = DateTime.parse(mergedMap[id]['lastUpdated']);
          
          if (localTimestamp.isAfter(serverTimestamp)) {
            mergedMap[id] = item;
          }
        }
      }
      
      return mergedMap.values.toList();
    }
    
    Future<SyncResult> syncGoals() async {
      if (!await _hasNetworkConnection()) {
        return SyncResult.failed('No network connection');
      }
      
      try {
        // Get goals box
        final goalsBox = Hive.box('goals');
        
        // Get server goals
        final serverGoals = await apiClient.getGoals(
          userId: profile.id,
          sessionToken: profile.sessionToken,
        );
        
        // Merge and sync following the same pattern as budgets
        final localGoals = goalsBox.values.toList();
        final mergedGoals = _mergeGoals(localGoals, serverGoals ?? []);
        
        // Update local goals
        await goalsBox.clear();
        for (final goal in mergedGoals) {
          await goalsBox.put(goal['id'], goal);
        }
        
        // Push to server if we have local changes
        if (serverGoals == null || _hasLocalChanges(localGoals, serverGoals)) {
          await apiClient.updateGoals(
            userId: profile.id,
            sessionToken: profile.sessionToken,
            goals: mergedGoals,
          );
        }
        
        return SyncResult.success(
          syncedEntities: mergedGoals.length,
          message: 'Goals synced successfully',
        );
      } catch (e) {
        return SyncResult.failed('Failed to sync goals: ${e.toString()}');
      }
    }
    
    List _mergeGoals(List local, List server) {
      return _mergeGenericEntities(local, server);
    }
    
    Future<SyncResult> syncTransactions({TransactionSyncLevel level = TransactionSyncLevel.metadataOnly}) async {
      if (!await _hasNetworkConnection() || level == TransactionSyncLevel.none) {
        return SyncResult.failed('No network connection or transaction sync disabled');
      }
      
      try {
        // Get transactions box
        final transactionsBox = Hive.box('transactions');
        
        // Get server transactions
        final serverTransactions = await apiClient.getTransactions(
          userId: profile.id,
          sessionToken: profile.sessionToken,
          syncLevel: level.index,
        );
        
        // Handle transaction sync based on sync level
        final localTransactions = transactionsBox.values.toList();
        final filteredLocalTransactions = _filterTransactionsForSync(localTransactions, level);
        final mergedTransactions = _mergeTransactions(filteredLocalTransactions, serverTransactions ?? [], level);
        
        // Update local transactions
        // Note: We don't clear the box because we might have local transactions that we're not syncing
        // Instead we update or add the merged transactions
        for (final transaction in mergedTransactions) {
          await transactionsBox.put(transaction['id'], transaction);
        }
        
        // Push to server if we have local changes and user has opted to sync
        if (level != TransactionSyncLevel.metadataOnly && 
            (serverTransactions == null || _hasLocalTransactionChanges(filteredLocalTransactions, serverTransactions))) {
          await apiClient.updateTransactions(
            userId: profile.id,
            sessionToken: profile.sessionToken,
            transactions: mergedTransactions,
            syncLevel: level.index,
          );
        }
        
        return SyncResult.success(
          syncedEntities: mergedTransactions.length,
          message: 'Transactions synced successfully',
        );
      } catch (e) {
        return SyncResult.failed('Failed to sync transactions: ${e.toString()}');
      }
    }
    
    List _filterTransactionsForSync(List transactions, TransactionSyncLevel level) {
      if (level == TransactionSyncLevel.none) {
        return [];
      }
      
      if (level == TransactionSyncLevel.metadataOnly) {
        return transactions.map((tx) => {
          'id': tx['id'],
          'amount': tx['amount'],
          'date': tx['date'],
          'categoryId': tx['categoryId'],
          'type': tx['type'],
          'lastUpdated': tx['lastUpdated'],
        }).toList();
      }
      
      if (level == TransactionSyncLevel.fullWithoutPII) {
        return transactions.map((tx) {
          final result = Map<String, dynamic>.from(tx);
          // Remove PII fields
          result.remove('memo');
          result.remove('personalNotes');
          result.remove('location');
          result.remove('contactInfo');
          return result;
        }).toList();
      }
      
      // Complete sync
      return transactions;
    }
    
    bool _hasLocalTransactionChanges(List localItems, List serverItems) {
      return _hasLocalChanges(localItems, serverItems);
    }
    
    List _mergeTransactions(List local, List server, TransactionSyncLevel level) {
      if (level == TransactionSyncLevel.none) {
        return [];
      }
      
      return _mergeGenericEntities(local, server);
    }
    
    Future<SyncResult> syncAll({SyncStrategy strategy = SyncStrategy.scheduled}) async {
      // Prevent multiple simultaneous syncs
      if (_isSyncing) {
        return SyncResult(
          success: false,
          message: 'Sync already in progress',
          syncedEntities: 0,
        );
      }
      
      _isSyncing = true;
      
      try {
        if (!await _hasNetworkConnection()) {
          _isSyncing = false;
          return SyncResult(
            success: false,
            message: 'No network connection',
            syncedEntities: 0,
          );
        }
        
        final settings = await _getSyncSettings();
        int syncedEntities = 0;
        
        // Always sync profile and categories
        final profileResults = await syncProfile();
        syncedEntities += profileResults.syncedEntities;
        
        final categoriesResults = await syncCategories();
        syncedEntities += categoriesResults.syncedEntities;
        
        // Conditional syncs based on settings
        if (settings.syncBudgets) {
          final budgetResults = await syncBudgets();
          syncedEntities += budgetResults.syncedEntities;
        }
        
        if (settings.syncGoals) {
          final goalResults = await syncGoals();
          syncedEntities += goalResults.syncedEntities;
        }
        
        if (settings.syncTransactions) {
          final transactionResults = await syncTransactions(
            level: settings.transactionSyncLevel,
          );
          syncedEntities += transactionResults.syncedEntities;
        }
        
        // Record successful sync time
        await _saveLastSyncTime(DateTime.now());
        
        _isSyncing = false;
        return SyncResult(
          success: true,
          message: 'Sync completed successfully',
          syncedEntities: syncedEntities,
        );
      } catch (e) {
        _isSyncing = false;
        if (kDebugMode) {
          print('Sync failed: $e');
        }
        return SyncResult(
          success: false,
          message: 'Sync failed: $e',
          syncedEntities: 0,
        );
      }
    }

    Future<SyncResult> syncProfile(Profile profile, {SyncStrategy strategy = SyncStrategy.immediate}) async {
      try {
        if (!await _hasNetworkConnection()) {
          return SyncResult(
            success: false,
            message: 'No network connection',
            syncedEntities: 0,
          );
        }
        
        if (kDebugMode) {
          print('Syncing profile: ${profile.id}');
        }
        
        // Try to sync with server
        await _apiClient.updateEnhancedProfile(
          email: profile.email ?? '',
          name: profile.name ?? '',
          baseCurrency: profile.baseCurrency,
          timezone: profile.timezone,
          // Add other fields as needed
        );
        
        return SyncResult(
          success: true,
          message: 'Profile synced successfully',
          syncedEntities: 1,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Profile sync failed: $e');
        }
        return SyncResult(
          success: false,
          message: 'Profile sync failed: $e',
          syncedEntities: 0,
        );
      }
    }
    
    Future<SyncResult> _syncProfiles() async {
      try {
        final profileBox = await Hive.openBox<Profile>('profiles');
        int syncedCount = 0;
        
        for (final profile in profileBox.values) {
          try {
            // Check if this profile has changed since last sync
            if (profile.lastModified == null || 
                profile.lastSynced == null || 
                profile.lastModified!.isAfter(profile.lastSynced!)) {
              
              // Profile needs sync
              await _apiClient.updateEnhancedProfile(
                email: profile.email ?? '',
                name: profile.name ?? '',
                baseCurrency: profile.baseCurrency,
                timezone: profile.timezone,
                // Add other fields as needed
              );
              
              // Update lastSynced
              final updatedProfile = profile.copyWith(lastSynced: DateTime.now());
              await profileBox.put(profile.id, updatedProfile);
              syncedCount++;
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to sync profile ${profile.id}: $e');
            }
            // Continue with next profile
          }
        }
        
        return SyncResult(
          success: true,
          message: 'Synced $syncedCount profiles',
          syncedEntities: syncedCount,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Profile sync failed: $e');
        }
        return SyncResult(
          success: false,
          message: 'Profile sync failed: $e',
          syncedEntities: 0,
        );
      }
    }
    
    Future<SyncResult> _syncBudgets() async {
      try {
        final budgetBox = await Hive.openBox('budgets');
        int syncedCount = 0;
        
        // Implementation will depend on your Budget model
        // This is a placeholder implementation
        
        return SyncResult(
          success: true,
          message: 'Synced $syncedCount budgets',
          syncedEntities: syncedCount,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Budget sync failed: $e');
        }
        return SyncResult(
          success: false,
          message: 'Budget sync failed: $e',
          syncedEntities: 0,
        );
      }
    }
    
    Future<SyncResult> _syncGoals() async {
      try {
        final goalBox = await Hive.openBox('goals');
        int syncedCount = 0;
        
        // Implementation will depend on your Goal model
        // This is a placeholder implementation
        
        return SyncResult(
          success: true,
          message: 'Synced $syncedCount goals',
          syncedEntities: syncedCount,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Goal sync failed: $e');
        }
        return SyncResult(
          success: false,
          message: 'Goal sync failed: $e',
          syncedEntities: 0,
        );
      }
    }
    
    Future<SyncResult> _syncTransactions([TransactionSyncLevel level = TransactionSyncLevel.metadataOnly]) async {
      try {
        final transactionBox = await Hive.openBox('transactions');
        int syncedCount = 0;
        
        // Skip if user doesn't want to sync transactions
        if (level == TransactionSyncLevel.none) {
          return SyncResult(
            success: true,
            message: 'Transactions sync disabled by user',
            syncedEntities: 0,
          );
        }
        
        // Implementation will depend on your Transaction model and sync level
        // This is a placeholder implementation
        
        return SyncResult(
          success: true,
          message: 'Synced $syncedCount transactions',
          syncedEntities: syncedCount,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Transaction sync failed: $e');
        }
        return SyncResult(
          success: false,
          message: 'Transaction sync failed: $e',
          syncedEntities: 0,
        );
      }
    }
  }
}

// Alias for backward compatibility with EnhancedAuthService
typedef EnhancedAuthService = AuthService;

// Session class for managing authentication sessions
class AuthSession {
  final String userId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String sessionToken;
  
  bool get isValid => DateTime.now().isBefore(expiresAt);
  
  AuthSession({
    required this.userId,
    required this.sessionToken,
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
  };
  
  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    userId: json['userId'],
    sessionToken: json['sessionToken'],
    createdAt: DateTime.parse(json['createdAt']),
    expiresAt: DateTime.parse(json['expiresAt']),
  );
}
