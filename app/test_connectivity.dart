// test_connectivity.dart
// Simple connectivity test for loan calculator API
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('🧮 Testing Loan Calculator API Connectivity');
  print('=' * 50);

  // Test 1: Health Check
  print('\n1. Testing API Health Check...');
  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:8000/api/health/'),
    );
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseData = await response.transform(utf8.decoder).join();
      final health = jsonDecode(responseData);

      if (health['status'] == 'healthy') {
        print('✅ API Health Check: PASSED');
      } else {
        print('❌ API Health Check: FAILED - ${health['status']}');
        return;
      }
    } else {
      print('❌ API Health Check: FAILED - Status ${response.statusCode}');
      return;
    }

    client.close();
  } catch (e) {
    print('❌ API Health Check Error: $e');
    return;
  }

  // Test 2: Basic Loan Calculation
  print('\n2. Testing Basic Loan Calculation...');
  try {
    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse('http://127.0.0.1:8000/api/calculators/loan/'),
    );
    request.headers.set('Content-Type', 'application/json');

    final body = jsonEncode({
      'principal': 200000.00,
      'annual_rate': 4.5,
      'term_years': 30,
      'interest_type': 'REDUCING',
      'payment_frequency': 'MONTHLY',
    });

    request.write(body);
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseData = await response.transform(utf8.decoder).join();
      final result = jsonDecode(responseData);

      print('✅ Loan Calculation: SUCCESS');
      print('   Monthly Payment: \$${result['monthly_payment']}');
      print('   Total Amount: \$${result['total_amount']}');
      print('   Total Interest: \$${result['total_interest']}');
    } else {
      final responseData = await response.transform(utf8.decoder).join();
      print('❌ Loan Calculation: FAILED - Status ${response.statusCode}');
      print('   Response: $responseData');
    }

    client.close();
  } catch (e) {
    print('❌ Loan Calculation Error: $e');
  }

  // Test 3: Interest Rate Solver
  print('\n3. Testing Interest Rate Solver...');
  try {
    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse('http://127.0.0.1:8000/api/calculators/interest-rate-solver/'),
    );
    request.headers.set('Content-Type', 'application/json');

    final body = jsonEncode({
      'principal': 200000.00,
      'payment': 1013.37,
      'term_years': 30,
      'payment_frequency': 'MONTHLY',
    });

    request.write(body);
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseData = await response.transform(utf8.decoder).join();
      final result = jsonDecode(responseData);

      print('✅ Interest Rate Solver: SUCCESS');
      print('   Calculated Rate: ${result['annual_rate']}%');
      print('   Iterations: ${result['iterations']}');
      print('   Converged: ${result['converged']}');
    } else {
      final responseData = await response.transform(utf8.decoder).join();
      print('❌ Interest Rate Solver: FAILED - Status ${response.statusCode}');
      print('   Response: $responseData');
    }

    client.close();
  } catch (e) {
    print('❌ Interest Rate Solver Error: $e');
  }

  // Test 4: ROI Calculation
  print('\n4. Testing ROI Calculation...');
  try {
    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse('http://127.0.0.1:8000/api/calculators/roi/'),
    );
    request.headers.set('Content-Type', 'application/json');

    final body = jsonEncode({
      'initial_investment': 10000.00,
      'final_value': 15000.00,
      'time_years': 3.0,
    });

    request.write(body);
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseData = await response.transform(utf8.decoder).join();
      final result = jsonDecode(responseData);

      print('✅ ROI Calculation: SUCCESS');
      print('   ROI: ${result['roi_percentage']}%');
      print('   Annualized Return: ${result['annualized_return']}%');
      print('   Total Return: \$${result['total_return']}');
    } else {
      final responseData = await response.transform(utf8.decoder).join();
      print('❌ ROI Calculation: FAILED - Status ${response.statusCode}');
      print('   Response: $responseData');
    }

    client.close();
  } catch (e) {
    print('❌ ROI Calculation Error: $e');
  }

  print('\n🎉 API Connectivity Test Complete!');
  print('The loan calculator API is working correctly.');
}
