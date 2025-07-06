// API connection test via ngrok
// Run with: dart run test_api_connection_ngrok.dart

import 'dart:io';
import 'dart:convert';

void main() async {
  print('🌐 Testing API Connection via ngrok\n');

  try {
    final ngrokUrl = 'https://your-ngrok-url.ngrok.io';
    
    // Test connection
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('$ngrokUrl/health'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('✅ API connection successful');
    } else {
      print('❌ API connection failed: ${response.statusCode}');
    }
    
    client.close();
  } catch (e) {
    print('❌ Connection error: $e');
  }
}