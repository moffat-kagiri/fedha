// Test loan calculator API connectivity
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/services/api_client.dart';

Future<void> testLoanCalculatorApi() async {
  print('🧮 Testing Loan Calculator API Connectivity');
  print('=' * 50);

  final apiClient = ApiClient();

  // Test 1: Health Check
  print('\n1. Testing API Health Check...');
  try {
    final isHealthy = await apiClient.healthCheck();
    if (isHealthy) {
      print('✅ API Health Check: PASSED');
    } else {
      print('❌ API Health Check: FAILED');
      return;
    }
  } catch (e) {
    print('❌ API Health Check Error: $e');
    return;
  }

  // Test 2: Basic Loan Calculation
  print('\n2. Testing Basic Loan Calculation...');
  try {
    final result = await apiClient.calculateLoanPayment(
      principal: 200000.00,
      annualRate: 4.5,
      termYears: 30,
      interestType: 'REDUCING',
      paymentFrequency: 'MONTHLY',
    );

    print('✅ Loan Calculation: SUCCESS');
    print('   Monthly Payment: \$${result['monthly_payment']}');
    print('   Total Amount: \$${result['total_amount']}');
    print('   Total Interest: \$${result['total_interest']}');
  } catch (e) {
    print('❌ Loan Calculation Error: $e');
  }

  // Test 3: Interest Rate Solver
  print('\n3. Testing Interest Rate Solver...');
  try {
    final result = await apiClient.solveInterestRate(
      principal: 200000.00,
      payment: 1013.37,
      termYears: 30,
      paymentFrequency: 'MONTHLY',
    );

    print('✅ Interest Rate Solver: SUCCESS');
    print('   Calculated Rate: ${result['annual_rate']}%');
    print('   Converged: ${result['converged']}');
  } catch (e) {
    print('❌ Interest Rate Solver Error: $e');
  }

  // Test 4: Early Payment Calculator
  print('\n4. Testing Early Payment Calculator...');
  try {
    final result = await apiClient.calculateEarlyPaymentSavings(
      principal: 200000.00,
      annualRate: 4.5,
      termYears: 30,
      extraPayment: 200.00,
      paymentFrequency: 'MONTHLY',
      extraPaymentType: 'MONTHLY',
    );

    print('✅ Early Payment Calculator: SUCCESS');
    print('   Interest Savings: \$${result['interest_savings']}');
    print('   Time Savings: ${result['time_savings_months']} months');
  } catch (e) {
    print('❌ Early Payment Calculator Error: $e');
  }

  // Test 5: ROI Calculator
  print('\n5. Testing ROI Calculator...');
  try {
    final result = await apiClient.calculateROI(
      initialInvestment: 10000.00,
      finalValue: 15000.00,
      timeYears: 3.0,
    );

    print('✅ ROI Calculator: SUCCESS');
    print('   ROI Percentage: ${result['roi_percentage']}%');
    print('   Annualized Return: ${result['annualized_return']}%');
  } catch (e) {
    print('❌ ROI Calculator Error: $e');
  }

  // Test 6: Compound Interest Calculator
  print('\n6. Testing Compound Interest Calculator...');
  try {
    final result = await apiClient.calculateCompoundInterest(
      principal: 5000.00,
      annualRate: 7.0,
      timeYears: 10.0,
      compoundingFrequency: 'MONTHLY',
      additionalPayment: 200.00,
      additionalFrequency: 'MONTHLY',
    );

    print('✅ Compound Interest Calculator: SUCCESS');
    print('   Future Value: \$${result['future_value']}');
    print('   Total Interest: \$${result['total_interest']}');
    print('   Total Contributions: \$${result['total_contributions']}');
  } catch (e) {
    print('❌ Compound Interest Calculator Error: $e');
  }

  print('\n' + '=' * 50);
  print('🎯 Loan Calculator API Test Complete!');
}

// Direct HTTP test for debugging
Future<void> testDirectHttpConnection() async {
  print('\n🔍 Testing Direct HTTP Connection...');

  const baseUrl = 'http://127.0.0.1:8000/api';

  try {
    // Test health endpoint
    final healthResponse = await http.get(
      Uri.parse('$baseUrl/health/'),
      headers: {'Content-Type': 'application/json'},
    );

    print('Health Check Status: ${healthResponse.statusCode}');
    if (healthResponse.statusCode == 200) {
      print('✅ Direct HTTP connection successful');

      // Test loan calculator endpoint
      final loanData = {
        'principal': 100000.00,
        'annual_rate': 5.0,
        'term_years': 30,
        'interest_type': 'REDUCING',
        'payment_frequency': 'MONTHLY',
      };

      final loanResponse = await http.post(
        Uri.parse('$baseUrl/calculators/loan/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loanData),
      );

      print('Loan Calculator Status: ${loanResponse.statusCode}');
      print('Loan Calculator Response: ${loanResponse.body}');
    } else {
      print('❌ Direct HTTP connection failed');
      print('Response: ${healthResponse.body}');
    }
  } catch (e) {
    print('❌ Direct HTTP Error: $e');
  }
}

void main() async {
  await testDirectHttpConnection();
  await testLoanCalculatorApi();
}
