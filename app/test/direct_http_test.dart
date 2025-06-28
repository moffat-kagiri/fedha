// import 'dart:convert'; // Commented out - unused
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Direct HTTP test to ngrok', () async {
    print('🔧 Testing direct HTTP request...');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'User-Agent': 'Flutter-App/1.0',
      'Cache-Control': 'no-cache',
    };

    print('📤 Headers: $headers');
    print('📤 URL: https://7a9a-41-209-9-54.ngrok-free.app/api/health/');

    try {
      final response = await http.get(
        Uri.parse('https://7a9a-41-209-9-54.ngrok-free.app/api/health/'),
        headers: headers,
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');
      print('📥 Headers: ${response.headers}');

      expect(response.statusCode, 200);
      expect(response.body, contains('healthy'));
    } catch (e) {
      print('❌ Error: $e');
      fail('HTTP request failed: $e');
    }
  });
}
