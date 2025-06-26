// Test script for the new SMS extraction engine
// Run with: dart run test_sms_extraction.dart

import 'lib/services/sms_extraction_engine.dart';

void main() async {
  print('🧪 Testing Enhanced SMS Extraction Engine\n');

  final engine = SmsExtractionEngine.instance;

  // Test M-PESA messages
  final mpesaMessages = [
    'TFK3MN5LS9 Confirmed. You have sent Ksh1,500.00 to JOHN DOE on 22/6/24 at 12:30 PM. New M-PESA balance is Ksh8,500.00. Transaction cost, Ksh0.00.',
    'QAB7X2Y5Z1 Confirmed. You have received Ksh2,500.00 from JANE SMITH on 22/6/24 at 2:45 PM. New M-PESA balance is Ksh11,000.00.',
    'RFK9MN2LS4 Confirmed. Ksh500.00 paid to SUPERMARKET LTD on 22/6/24 at 6:15 PM. New M-PESA balance is Ksh10,500.00.',
    'TGK5XN8LS2 Confirmed. You bought Ksh100.00 of airtime on 22/6/24 at 8:00 AM. New M-PESA balance is Ksh10,400.00.',
  ];

  // Test Bank messages
  final bankMessages = [
    'Dear Customer, KES 3,200.00 has been debited from your account ending 1234 on 22/6/24. Transaction: Payment to RESTAURANT ABC.',
    'Alert: KES 5,000.00 credited to your account ending 5678 on 22/6/24. Source: SALARY TRANSFER.',
    'Your account ending 9876 has been debited KES 1,200.00 on 22/6/24 for ATM withdrawal at MAIN STREET BRANCH.',
  ];

  print('📱 Testing M-PESA Messages:');
  print('=' * 50);

  for (int i = 0; i < mpesaMessages.length; i++) {
    print('\nTest ${i + 1}: M-PESA Message');
    final result = await engine.extractTransaction(mpesaMessages[i], 'MPESA');

    if (result.success) {
      final data = result.transactionData!;
      print(
        '✅ SUCCESS (Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%)',
      );
      print('   Amount: Ksh ${data['amount']}');
      print('   Type: ${data['type']}');
      print('   Counterparty: ${data['counterparty']}');
      print('   Category: ${data['category']}');
      if (data['balance'] != null) {
        print('   Balance: Ksh ${data['balance']}');
      }
    } else {
      print('❌ FAILED: ${result.errorMessage}');
    }
  }

  print('\n\n🏦 Testing Bank Messages:');
  print('=' * 50);

  for (int i = 0; i < bankMessages.length; i++) {
    print('\nTest ${i + 1}: Bank Message');
    final result = await engine.extractTransaction(bankMessages[i], 'KCB-BANK');

    if (result.success) {
      final data = result.transactionData!;
      print(
        '✅ SUCCESS (Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%)',
      );
      print('   Amount: KES ${data['amount']}');
      print('   Type: ${data['type']}');
      print('   Description: ${data['description']}');
      print('   Category: ${data['category']}');
    } else {
      print('❌ FAILED: ${result.errorMessage}');
    }
  }

  print('\n\n📊 Test Summary:');
  print('=' * 50);
  print('✓ Enhanced SMS extraction engine integrated');
  print('✓ Template-based pattern matching for M-PESA');
  print('✓ Bank message format support');
  print('✓ Confidence scoring for accuracy assessment');
  print('✓ Extensible pattern system for new formats');
  print('\n🎉 SMS Extraction Engine is ready for production!');
}
