// UUID/PIN management

import 'package:fedha/models/enhanced_profile.dart' as enhanced;
import 'package:fedha/services/api_client.dart';
import 'package:fedha/services/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/profile.dart';

// Add this extension if you can't modify the Profile class directly
extension ProfileExtension on Profile {
  bool verifyPin(String pin) {
    return hashPin(pin) == pinHash;
  }

  String hashPin(String pin) {
    // Simple hash function (for demonstration purposes)
    return pin.split('').reversed.join();
  }

  DateTime? get lastLogin => null; // Add lastLogin getter
  set lastLogin(DateTime? value) {} // Add lastLogin setter

  DateTime get createdAt => DateTime.now(); // Add createdAt getter

  String? get name => null; // Add name getter
  String? get email => null; // Add email getter
  String? get baseCurrency => null; // Add baseCurrency getter
  String? get timezone => null; // Add timezone getter
}

class AuthService extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final ApiClient _apiClient = ApiClient();

  get currentProfileId => null;
  Profile? _currentProfile;

  Profile? get currentProfile => _currentProfile;

  Profile? get profile => _currentProfile;

  Future<bool> login(ProfileType profileType, String pin) async {
    final profileBox = Hive.box<Profile>('profiles');
    final profiles =
        profileBox.values.where((p) => p.type == profileType).toList();

    for (final profile in profiles) {
      if (profile.verifyPin(pin)) {
        _currentProfile = profile;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void logout() {
    _currentProfile = null;
    notifyListeners();
  }

  bool get isLoggedIn => _currentProfile != null;

  // Verify PIN with user ID and account type
  Future<bool> verifyPin(
    String userId,
    String pin,
    ProfileType accountType,
  ) async {
    try {
      // For now, simulate PIN verification based on user ID format and PIN
      // In a real app, you would validate against stored user data

      // Check if userId format matches account type
      final isValidFormat =
          (accountType == ProfileType.business &&
              userId.toLowerCase().startsWith('biz-')) ||
          (accountType == ProfileType.personal &&
              userId.toLowerCase().startsWith('per-'));

      if (!isValidFormat) {
        return false;
      }

      // For demo purposes, accept any 4-digit PIN for now
      // In production, you'd validate against stored PIN hash
      if (pin.length == 4 && RegExp(r'^[0-9]+$').hasMatch(pin)) {
        // Create a temporary profile for the session
        final profileBox = await Hive.openBox('profiles');

        // Check if profile exists, if not create a temporary one
        String profileId = userId;
        var existingProfile = profileBox.get(profileId);

        if (existingProfile == null) {
          // Create a new profile entry
          existingProfile = {
            'id': profileId,
            'type': accountType,
            'pinHash': hashPin(pin),
          };
          await profileBox.put(profileId, existingProfile);
        }

        // Set current profile
        _currentProfile = Profile(
          id: profileId,
          type: accountType,
          pinHash: hashPin(pin),
          name: null,
          email: null,
          baseCurrency: null,
          timezone: null,
        );

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('PIN verification error: $e');
      }
      return false;
    }
  }

  // Generate new profile ID (e.g., "biz_abc123" or "personal_xyz789")
  String generateProfileId({required bool isBusiness}) {
    final prefix = isBusiness ? 'biz' : 'personal';
    return '${prefix}_${_uuid.v4().substring(0, 6)}';
  }

  // Generate new PIN (e.g., "123456")
  String generatePin() {
    return _uuid.v4().substring(0, 6);
  }

  // Hash the PIN for secure storage
  String hashPin(String pin) {
    // Simple hash function (for demonstration purposes)
    return pin.split('').reversed.join();
  }

  // Validate the PIN against the stored hash
  bool validatePin(String pin, String hashedPin) {
    return hashPin(pin) == hashedPin;
  }

  Future<void> createProfile({
    required bool isBusiness,
    required String pin,
  }) async {
    final authService = AuthService();
    final profileId = authService.generateProfileId(isBusiness: isBusiness);
    final pinHash = authService.hashPin(pin);

    // Save to Hive
    final profileBox = await Hive.openBox('profiles');
    await profileBox.put(profileId, {
      'id': profileId,
      'isBusiness': isBusiness,
      'pinHash': pinHash,
    });

    // Sync with Django (optional)
    await _apiClient.createProfile(
      profileId: profileId,
      isBusiness: isBusiness,
      pinHash: pinHash,
    );
  }

  Future<bool> loginWithProfileId(String profileId, String pin) async {
    // Get profile from Hive
    final profileBox = await Hive.openBox('profiles');
    final profile = profileBox.get(profileId);

    if (profile == null) {
      return false; // Profile not found
    }

    // Validate PIN
    final storedPinHash = profile['pinHash'];
    if (!validatePin(pin, storedPinHash)) {
      return false; // Invalid PIN
    }

    // Try to sync with server
    try {
      await _apiClient.verifyProfile(
        profileId: profileId,
        pinHash: hashPin(pin),
      );
    } catch (e) {
      // Continue even if server sync fails
      if (kDebugMode) {
        print('Server sync failed: $e');
      }
    }
    return true; // Return true if login successful, false otherwise
  }

  // Create enhanced profile with additional metadata
  Future<bool> createEnhancedProfile(Map<String, dynamic> profileData) async {
    try {
      final profileId = generateProfileId(
        isBusiness: profileData['profile_type'] == ProfileType.business,
      );
      final pinHash = hashPin(profileData['pin']);

      // Create profile object
      final profile = Profile(
        id: profileId,
        type: profileData['profile_type'],
        pinHash: pinHash,
        name: profileData['name'],
        email: profileData['email'],
        baseCurrency: profileData['base_currency'] ?? 'KES',
        timezone: profileData['timezone'] ?? 'GMT+3',
      );

      // Save to Hive
      final profileBox = await Hive.openBox<Profile>('profiles');
      await profileBox.put(profileId, profile);

      // Save additional settings
      final settingsBox = await Hive.openBox('settings');
      await settingsBox.put(
        'google_drive_enabled',
        profileData['enable_google_drive'] ?? false,
      );

      // Sync with backend
      try {
        await _apiClient.createProfile(
          profileId: profileId,
          isBusiness: profileData['profile_type'] == ProfileType.business,
          pinHash: pinHash,
        );
      } catch (e) {
        // Continue even if server sync fails
        if (kDebugMode) {
          print('Server sync failed: $e');
        }
      }

      // Set as current profile
      _currentProfile = profile;
      notifyListeners();

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Enhanced profile creation failed: $e');
      }
      return false;
    }
  }

  // Enhanced login with better error handling
  Future<enhanced.LoginResult> enhancedLogin(
    ProfileType profileType,
    String pin,
  ) async {
    try {
      final profileBox = Hive.box<Profile>('profiles');
      final profiles =
          profileBox.values.where((p) => p.type == profileType).toList();

      for (final profile in profiles) {
        if (profile.verifyPin(pin)) {
          _currentProfile = profile;
          notifyListeners();

          // Update last login time
          profile.lastLogin = DateTime.now();
          await profileBox.put(profile.id, profile);

          // Sync with server
          try {
            await _apiClient.verifyProfile(
              profileId: profile.id,
              pinHash: hashPin(pin),
            );
          } catch (e) {
            // Continue even if server sync fails
            if (kDebugMode) {
              print('Server sync failed: $e');
            }
          }

          return enhanced.LoginResult.success();
        }
      }

      return enhanced.LoginResult.error(
        'Invalid PIN for selected profile type',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      return enhanced.LoginResult.error('Login failed. Please try again.');
    }
  }

  // Get profile statistics
  Future<enhanced.ProfileStats> getProfileStats() async {
    if (_currentProfile == null) {
      return enhanced.ProfileStats.empty();
    }

    try {
      final transactionBox = await Hive.openBox('transactions');
      final budgetBox = await Hive.openBox('budgets');
      final goalBox = await Hive.openBox('goals');

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

      return enhanced.ProfileStats(
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
      return enhanced.ProfileStats.empty();
    }
  }

  // Check if profile needs PIN change (first-time login)
  bool requiresPinChange() {
    if (_currentProfile == null) return false;

    // If never logged in before or account is very new
    if (_currentProfile!.lastLogin == null) return true;

    final daysSinceCreation =
        DateTime.now().difference(_currentProfile!.createdAt).inDays;
    return daysSinceCreation < 1 && _currentProfile!.lastLogin == null;
  }

  // Change PIN
  Future<bool> changePin(String currentPin, String newPin) async {
    if (_currentProfile == null) return false;

    try {
      // Verify current PIN
      if (!_currentProfile!.verifyPin(currentPin)) {
        return false;
      }

      // Update PIN by creating a new profile instance
      final newPinHash = hashPin(newPin);
      _currentProfile = Profile(
        id: _currentProfile!.id,
        type: _currentProfile!.type,
        pinHash: newPinHash,
        name: _currentProfile!.name,
        email: _currentProfile!.email,
        baseCurrency: _currentProfile!.baseCurrency,
        timezone: _currentProfile!.timezone,
      );

      // Save to Hive
      final profileBox = await Hive.openBox<Profile>('profiles');
      await profileBox.put(_currentProfile!.id, _currentProfile!);

      // Sync with server
      try {
        // TODO: Implement PIN change API endpoint
      } catch (e) {
        if (kDebugMode) {
          print('Server PIN change sync failed: $e');
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('PIN change failed: $e');
      }
      return false;
    }
  }

  // ...existing code...
}
