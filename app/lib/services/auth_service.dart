// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'api_client.dart';
import '../models/enhanced_profile.dart';
import 'biometric_auth_service.dart';

class AuthService extends ChangeNotifier {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _currentProfile != null;
  final Uuid _uuid = const Uuid();
  final ApiClient _apiClient = ApiClient();

  EnhancedProfile? _currentProfile;
  EnhancedProfile? get currentProfile => _currentProfile;
  String? get currentProfileId => _currentProfile?.id;

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize biometric auth
    try {
      await BiometricAuthService.instance.initialize();
    } catch (_) {}
    // Load persisted profile ID
    try {
      final settingsBox = await Hive.openBox('settings');
      final savedId = settingsBox.get('currentProfileId') as String?;
      if (savedId != null) {
        final profileBox = await Hive.openBox<EnhancedProfile>('profiles');
        final profile = profileBox.get(savedId);
        if (profile != null) {
          _currentProfile = profile;
          // Attempt biometric unlock
          await loginWithBiometric();
        }
      }
    } catch (_) {}
    _isInitialized = true;
    notifyListeners();
  }

  String _hashPassword(String password) => password.split('').reversed.join();

  String _generateProfileId(bool isBusiness) {
    final prefix = isBusiness ? 'biz' : 'personal';
    return '${prefix}_${_uuid.v4().substring(0, 6)}';
  }

  Future<void> createProfile({
    required ProfileType type,
    required String name,
    String? email,
    required String password,
  }) async {
    final profileId = _generateProfileId(type == ProfileType.business);
    final hashed = _hashPassword(password);
    final now = DateTime.now();
    final profile = EnhancedProfile(
      id: profileId,
      type: type,
      passwordHash: hashed,
      name: name,
      email: email,
      lastLogin: now,
      createdAt: now,
    );
    final box = await Hive.openBox<EnhancedProfile>('profiles');
    await box.put(profile.id, profile);
    _currentProfile = profile;
    // Persist current profile
    final settingsBox = await Hive.openBox('settings');
    await settingsBox.put('currentProfileId', profile.id);
    notifyListeners();
    // Optionally sync
    await _apiClient.createProfile(
      profileId: profile.id,
      isBusiness: type == ProfileType.business,
      pinHash: hashed,
    );
  }

  Future<bool> login({
    required String profileId,
    required String password,
  }) async {
    final box = await Hive.openBox<EnhancedProfile>('profiles');
    final profile = box.get(profileId);
    if (profile == null) return false;
    if (_hashPassword(password) != profile.passwordHash) return false;
    _currentProfile = profile;
    // Persist current profile
    final settingsBox = await Hive.openBox('settings');
    await settingsBox.put('currentProfileId', profile.id);
    notifyListeners();
    try {
      await _apiClient.verifyProfile(
        profileId: profileId,
        pinHash: profile.passwordHash,
      );
    } catch (_) {}
    return true;
  }

  /// Login by ProfileType (first matching profile)
  Future<bool> loginByType(ProfileType type, String password) async {
    final box = await Hive.openBox<EnhancedProfile>('profiles');
    final profile = box.values.cast<EnhancedProfile?>().firstWhere(
      (p) => p != null && p.type == type,
      orElse: () => null,
    );
    if (profile == null) return false;
    return login(profileId: profile.id, password: password);
  }

  Future<bool> loginWithBiometric() async {
    final bio = BiometricAuthService.instance;
    if (_currentProfile == null) return false;
    final authenticated = await bio.authenticate();
    if (authenticated) {
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentProfile == null) return false;
    // Verify current password
    if (_hashPassword(currentPassword) != _currentProfile!.passwordHash) {
      return false;
    }
    // Update and persist
    final profile = _currentProfile!;
    profile.passwordHash = _hashPassword(newPassword);
    final box = await Hive.openBox<EnhancedProfile>('profiles');
    await box.put(profile.id, profile);
    notifyListeners();
    return true;
  }

  Future<void> updateCurrency(String currency) async {
    if (_currentProfile == null) return;
    final profile = _currentProfile!;
    profile.baseCurrency = currency;
    final box = await Hive.openBox<EnhancedProfile>('profiles');
    await box.put(profile.id, profile);
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      // Clear current profile
      _currentProfile = null;

      // Clear persisted profile ID
      final settingsBox = await Hive.openBox('settings');
      await settingsBox.delete('currentProfileId');

      // Notify listeners of state change
      notifyListeners();

      if (kDebugMode) {
        print('✅ User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error signing out: $e');
      }
    }
  }
}

// Alias for backward compatibility with EnhancedAuthService
typedef EnhancedAuthService = AuthService;
