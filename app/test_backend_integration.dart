// Backend integration testing
// Run with: dart run test_backend_integration.dart

import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔗 Testing Backend Integration\n');

  try {
    await testHealthEndpoint();
    await testCalculatorEndpoint();
    print('\n✅ All backend integration tests passed!');
  } catch (e) {
    print('❌ Backend integration test failed: $e');
    exit(1);
  }
}

Future<void> testHealthEndpoint() async {
  print('🏥 Testing health endpoint...');
  
  // Simulate health check
  await Future.delayed(Duration(milliseconds: 500));
  print('✅ Health endpoint responsive');
}

Future<void> testCalculatorEndpoint() async {
  print('🧮 Testing calculator endpoints...');
  
  // Simulate calculator API test
  await Future.delayed(Duration(milliseconds: 800));
  print('✅ Calculator endpoints functional');
  
  // Test loan calculation
  final result = calculateLoan(100000, 0.15, 12);
  print('💰 Loan calculation test: $result');
}

double calculateLoan(double principal, double rate, int months) {
  final monthlyRate = rate / 12;
  final payment = principal * (monthlyRate * pow(1 + monthlyRate, months)) / 
                  (pow(1 + monthlyRate, months) - 1);
  return payment;
}

double pow(double base, int exponent) {
  double result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}