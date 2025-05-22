// UUID/PIN management

import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:fedha/services/api_client.dart';

import '../models/profile.dart'; // Add this import

// Add this extension if you can't modify the Profile class directly
extension ProfileExtension on Profile {
  bool verifyPin(String pin) {
    return hashPin(pin) == pinHash;
  }
  
  String hashPin(String pin) {
    // Simple hash function (for demonstration purposes)
    return pin.split('').reversed.join();
  }
}

class AuthService extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final ApiClient _apiClient = ApiClient();

  get currentProfileId => null;
  Profile? _currentProfile;

  Profile? get currentProfile => _currentProfile;

    Future<bool> login(ProfileType profileType, String pin) async {
      final profileBox = Hive.box<Profile>('profiles');
      final profiles = profileBox.values.where((p) => p.type == profileType).toList();

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

Future<void> createProfile({required bool isBusiness, required String pin}) async {
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
  Future<bool> login(String profileId, String pin) async {
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
      pinHash: hashPin(pin)
      );
    } catch (e) {
      // Continue even if server sync fails
      if (kDebugMode) {
      print('Server sync failed: $e');
      }
    }
    return true; // Return true if login successful, false otherwise
  }
}