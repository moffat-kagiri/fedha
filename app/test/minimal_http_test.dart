import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Minimal HTTP test to ngrok', () async {
    print('🔧 Testing minimal HTTP request...');

    try {
      // Test 1: No headers
      print('Test 1: No headers');
      final response1 = await http.get(
        Uri.parse('https://7a9a-41-209-9-54.ngrok-free.app/api/health/'),
      );
      print('📥 Status: ${response1.statusCode}, Body: ${response1.body}');

      // Test 2: Only ngrok header
      print('Test 2: Only ngrok header');
      final response2 = await http.get(
        Uri.parse('https://7a9a-41-209-9-54.ngrok-free.app/api/health/'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      print('📥 Status: ${response2.statusCode}, Body: ${response2.body}');

      // Test 3: Content-Type only
      print('Test 3: Content-Type only');
      final response3 = await http.get(
        Uri.parse('https://7a9a-41-209-9-54.ngrok-free.app/api/health/'),
        headers: {'Content-Type': 'application/json'},
      );
      print('📥 Status: ${response3.statusCode}, Body: ${response3.body}');
    } catch (e) {
      print('❌ Error: $e');
    }
  });
}
