// UUID/PIN management

import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

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
}

Future<void> createProfile({required bool isBusiness, required String pin}) async {
  final profileId = generateProfileId(isBusiness: isBusiness);
  final pinHash = _hashPin(pin);

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