// lib/utils/test_profile_creator.dart - FIXED VERSION
// Only showing the part that needs to be fixed

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/offline_data_service.dart';
import '../models/profile.dart';

class TestProfileCreator {
  final AuthService _authService;
  final OfflineDataService _offlineDataService;

  TestProfileCreator({
    required AuthService authService,
    required OfflineDataService offlineDataService,
  })  : _authService = authService,
        _offlineDataService = offlineDataService;

  /// Create a test profile with sample data
  Future<Profile?> createTestProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      // Generate unique email if not provided
      final testEmail = email ?? 
          'test.${DateTime.now().millisecondsSinceEpoch}@fedha.test';
      
      final testFirstName = firstName ?? 'Test';
      final testLastName = lastName ?? 'User';
      
      if (kDebugMode) {
        print('Creating test profile: $testEmail');
      }

      // FIXED: Use initializeWithDependencies if not already initialized
      if (!_authService.isInitialized) {
        await _authService.initializeWithDependencies(
          offlineDataService: _offlineDataService,
          biometricService: null,
        );
      }

      // Create profile via signup
      final success = await _authService.signup(
        firstName: testFirstName,
        lastName: testLastName,
        email: testEmail,
        password: 'TestPassword123!',
      );

      if (!success) {
        if (kDebugMode) {
          print('Failed to create test profile');
        }
        return null;
      }

      final profile = _authService.currentProfile;
      
      if (kDebugMode) {
        print('Test profile created: ${profile?.name} (${profile?.email})');
      }

      return profile;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating test profile: $e');
      }
      return null;
    }
  }

  /// Load sample transactions for testing
  Future<void> loadSampleTransactions(String profileId) async {
    try {
      if (kDebugMode) {
        print('Loading sample transactions for profile: $profileId');
      }

      // Sample transactions would be created here
      // This is just a placeholder - implement based on your needs
      final sampleTransactions = _generateSampleTransactions(profileId);
      
      for (final transaction in sampleTransactions) {
        await _offlineDataService.saveTransaction(transaction);
      }

      if (kDebugMode) {
        print('Loaded ${sampleTransactions.length} sample transactions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading sample transactions: $e');
      }
    }
  }

  List<Map<String, dynamic>> _generateSampleTransactions(String profileId) {
    // Generate sample transactions
    // Implement based on your Transaction model structure
    return [
      // Add sample transaction data here
    ];
  }

  /// Clean up test profile
  Future<void> deleteTestProfile() async {
    try {
      if (_authService.currentProfile != null) {
        await _authService.logout();
        
        if (kDebugMode) {
          print('Test profile cleaned up');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up test profile: $e');
      }
    }
  }
}