import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import '../data/app_database.dart';

class UserProfileService extends ChangeNotifier {
  final AppDatabase _db;
  UserProfile? _currentProfile;
  
  UserProfileService(this._db);
  
  UserProfile? get currentProfile => _currentProfile;
  
  // Initialize with auth ID
  Future<void> initialize(String authId) async {
    _currentProfile = await _db.getUserProfileByAuthId(authId);
    notifyListeners();
  }
  
  // Create new profile
  Future<void> createProfile({
    required String authId,
    required String displayName,
    String defaultCurrency = 'KES',
    String budgetPeriod = 'monthly',
  }) async {
    final id = await _db.insertUserProfile(
      UserProfilesCompanion.insert(
        authId: authId,
        displayName: displayName,
        defaultCurrency: Value(defaultCurrency),
        budgetPeriod: Value(budgetPeriod),
        createdAt: Value(DateTime.now()),
      ),
    );
    
    _currentProfile = await _db.getUserProfileByAuthId(authId);
    notifyListeners();
    
    // No need to return anything since return type is Future<void>
  }
  
  // Update profile
  Future<void> updateProfile({
    String? displayName,
    String? defaultCurrency,
    String? budgetPeriod,
  }) async {
    if (_currentProfile == null) return;
    
    await _db.updateUserProfile(
      UserProfilesCompanion(
        id: Value(_currentProfile!.id),
        displayName: displayName != null ? Value(displayName) : const Value.absent(),
        defaultCurrency: defaultCurrency != null ? Value(defaultCurrency) : const Value.absent(),
        budgetPeriod: budgetPeriod != null ? Value(budgetPeriod) : const Value.absent(),
      ),
    );
    
    _currentProfile = await _db.getUserProfileByAuthId(_currentProfile!.authId);
    notifyListeners();
  }
  
  // Update sync timestamp
  Future<void> updateLastSync() async {
    if (_currentProfile == null) return;
    
    await _db.updateUserProfile(
      UserProfilesCompanion(
        id: Value(_currentProfile!.id),
        lastSync: Value(DateTime.now()),
      ),
    );
    
    _currentProfile = await _db.getUserProfileByAuthId(_currentProfile!.authId);
    notifyListeners();
  }
  
  // Get sync status
  bool get needsSync {
    if (_currentProfile?.lastSync == null) return true;
    final lastSync = _currentProfile!.lastSync!;
    final now = DateTime.now();
    return now.difference(lastSync).inHours > 24;
  }
}
