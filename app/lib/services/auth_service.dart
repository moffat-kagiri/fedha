// UUID/PIN management

import 'package:uuid/uuid.dart';

class AuthService {
  final Uuid _uuid = const Uuid();

  // Generate new profile ID (e.g., "biz_abc123" or "personal_xyz789")
  String generateProfileId({required bool isBusiness}) {
    final prefix = isBusiness ? 'biz' : 'personal';
    return '${prefix}_${_uuid.v4().substring(0, 6)}';
  }
}