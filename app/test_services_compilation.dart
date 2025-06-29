// Simple test to check if services compile correctly
import '../lib/services/api_client.dart';
import '../lib/services/auth_service.dart';
import '../lib/services/firebase_auth_service.dart';
import '../lib/services/auth_api_client.dart';

void main() {
  print('Services compilation test');

  // Test if classes can be instantiated
  final apiClient = ApiClient();
  final authService = AuthService();
  final firebaseAuthService = FirebaseAuthService();

  print('✅ ApiClient: ${apiClient.runtimeType}');
  print('✅ AuthService: ${authService.runtimeType}');
  print('✅ FirebaseAuthService: ${firebaseAuthService.runtimeType}');
  print('✅ AuthApiClient: ${AuthApiClient}');

  print('All services compile successfully!');
}
