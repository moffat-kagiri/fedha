import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔧 DEBUG: Testing ngrok headers...');

  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  print('📤 Headers being sent: $headers');

  try {
    final response = await http.get(
      Uri.parse('https://7a9a-41-209-9-54.ngrok-free.app/api/health/'),
      headers: headers,
    );

    print('📥 Response Status: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');
    print('📥 Response Headers: ${response.headers}');
  } catch (e) {
    print('❌ Error: $e');
  }
}
