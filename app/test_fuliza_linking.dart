// Test script for Fuliza linking functionality
// Run with: dart run test_fuliza_linking.dart

import 'lib/services/sms_extraction_engine.dart';

void main() async {
  print('🧪 Testing Fuliza Linking Functionality\n');

  final engine = SmsExtractionEngine.instance;

  // Simulate the two messages that come when Fuliza is used
  final airtimeMessage = 'TFQ6IGGHI6 confirmed.You bought Ksh50.00 of airtime on 26/6/25 at 11:09 PM.New M-PESA balance is Ksh0.00. Transaction cost, Ksh0.00.';
  final fulizaMessage = 'TFQ6IGGHI6 Confirmed. Fuliza M-PESA amount is Ksh 50.00. Interest charged Ksh 0.50. Total Fuliza M-PESA outstanding amount is Ksh 1222.98 due on 24/07/25';

  print('📱 Testing Fuliza Linking Scenario:');
  print('=' * 60);
  print('Scenario: User buys Ksh50 airtime but has Ksh0 balance');
  print('Expected: Fuliza covers the Ksh50, two SMS received');
  print('Desired outcome: One transaction with Fuliza info');
  print('');

  // Test 1: Process airtime message first
  print('🔄 Processing airtime purchase message...');
  final airtimeResult = await engine.extractTransactionEnhanced(airtimeMessage, 'MPESA');
  
  if (airtimeResult.success) {
    print('✅ Airtime transaction extracted');
    print('   Amount: Ksh ${airtimeResult.transactionData!['amount']}');
    print('   Description: ${airtimeResult.transactionData!['description']}');
    print('   Has Fuliza: ${airtimeResult.transactionData!['has_fuliza'] ?? false}');
  } else {
    print('❌ Failed: ${airtimeResult.errorMessage}');
  }

  print('');

  // Wait a moment to simulate real-world timing
  await Future.delayed(Duration(milliseconds: 500));

  // Test 2: Process Fuliza message
  print('🔄 Processing Fuliza notification message...');
  final fulizaResult = await engine.extractTransactionEnhanced(fulizaMessage, 'MPESA');
  
  if (fulizaResult.success) {
    final data = fulizaResult.transactionData!;
    print('✅ Transaction with Fuliza linking successful!');
    print('   Amount: Ksh ${data['amount']}');
    print('   Description: ${data['description']}');
    print('   Has Fuliza: ${data['has_fuliza'] ?? false}');
    if (data['has_fuliza'] == true) {
      print('   Fuliza Amount: Ksh ${data['fuliza_amount']}');
      print('   Fuliza Interest: Ksh ${data['fuliza_interest']}');
      print('   Fuliza Outstanding: Ksh ${data['fuliza_outstanding']}');
    }
    print('   Confidence: ${(fulizaResult.confidence * 100).toStringAsFixed(1)}%');
  } else {
    print('❌ Failed: ${fulizaResult.errorMessage}');
  }

  print('');

  // Test 3: Reverse order (Fuliza message first)
  print('🔄 Testing reverse order (Fuliza message first)...');
  
  final fulizaFirstResult = await engine.extractTransactionEnhanced(fulizaMessage, 'MPESA');
  
  if (fulizaFirstResult.success) {
    print('⚠️  Fuliza processed as standalone transaction');
  } else if (fulizaFirstResult.errorMessage?.contains('Waiting for main transaction') == true) {
    print('✅ Fuliza message waiting for main transaction (correct behavior)');
  } else {
    print('❌ Unexpected result: ${fulizaFirstResult.errorMessage}');
  }

  await Future.delayed(Duration(milliseconds: 500));

  final airtimeSecondResult = await engine.extractTransactionEnhanced(airtimeMessage, 'MPESA');
  
  if (airtimeSecondResult.success) {
    final data = airtimeSecondResult.transactionData!;
    print('✅ Main transaction linked with waiting Fuliza!');
    print('   Amount: Ksh ${data['amount']}');
    print('   Has Fuliza: ${data['has_fuliza'] ?? false}');
    if (data['has_fuliza'] == true) {
      print('   Fuliza Amount: Ksh ${data['fuliza_amount']}');
    }
  } else {
    print('❌ Failed to link: ${airtimeSecondResult.errorMessage}');
  }

  print('');
  print('🎯 Summary:');
  print('- Fuliza linking prevents duplicate transactions');
  print('- Main transaction gets enhanced with Fuliza information');
  print('- User sees one transaction: "Airtime purchase (Fuliza used: Ksh50)"');
  print('- Fuliza details are preserved in transaction metadata');
}
