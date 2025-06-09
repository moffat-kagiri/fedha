import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test integration between Flutter and Django backend
Future<void> testBackendIntegration() async {
  print('🧮 Testing Flutter-Django Financial Calculator Integration');

  const String baseUrl = 'http://127.0.0.1:8000/api';

  // Test data - same as our accuracy verification
  final testData = {
    'principal': 200000.00,
    'annual_rate': 4.5,
    'term_years': 30,
    'interest_type': 'REDUCING',
    'payment_frequency': 'MONTHLY',
  };

  try {
    print('Testing loan payment calculation...');
    print('Input: ${jsonEncode(testData)}');

    final response = await http.post(
      Uri.parse('$baseUrl/calculators/loan/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(testData),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final payment = double.parse(result['payment_amount'].toString());

      print('✅ SUCCESS: Flutter-Django integration working!');
      print('Monthly Payment: \$${payment.toStringAsFixed(2)}');

      // Verify accuracy
      const expected = 1013.37;
      if ((payment - expected).abs() < 0.01) {
        print('✅ ACCURACY VERIFIED: Payment matches expected value!');
        return;
      } else {
        print(
          '❌ ACCURACY ISSUE: Expected \$${expected.toStringAsFixed(2)}, got \$${payment.toStringAsFixed(2)}',
        );
      }
    } else {
      print('❌ FAILED: HTTP ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ ERROR: $e');
  }
}

void main() async {
  await testBackendIntegration();
}
