// test_api_connection.dart
import 'package:fedha/services/api_client.dart';

void main() async {
  print('🔗 Testing API connection...');

  final apiClient = ApiClient();
  final baseUrl = ApiClient.getBaseUrl();

  print('📍 Current API base URL: $baseUrl');

  try {
    // Test basic connection to health endpoint
    final response = await apiClient.testConnection();
    print('✅ Connection test successful: $response');
  } catch (e) {
    print('❌ Connection test failed: $e');
  }
}
