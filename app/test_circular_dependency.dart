// Test file to verify circular dependency is fixed
import 'lib/services/enhanced_auth_service.dart';
import 'lib/services/auth_service.dart';

void main() {
  print('Testing circular dependency fix...');

  try {
    // This should not cause a stack overflow anymore
    final enhancedAuth = EnhancedAuthService();
    print('✅ EnhancedAuthService created successfully');

    final auth = AuthService();
    print('✅ AuthService created successfully');

    final authWithoutEnhanced = AuthService.withoutEnhancedAuth();
    print('✅ AuthService.withoutEnhancedAuth() created successfully');

    print('🎉 Circular dependency has been resolved!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
