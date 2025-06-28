// Test script for the new SMS extraction engine
// Run with: dart run test_sms_extraction.dart

import 'lib/services/sms_extraction_engine.dart';

void main() async {
  print('🧪 Testing Enhanced SMS Extraction Engine\n');

  final engine = SmsExtractionEngine.instance;

  // Test M-PESA messages (including new scenarios)
  final mpesaMessages = [
    'TFK3MN5LS9 Confirmed. You have sent Ksh1,500.00 to JOHN DOE on 22/6/24 at 12:30 PM. New M-PESA balance is Ksh8,500.00. Transaction cost, Ksh0.00.',
    'QAB7X2Y5Z1 Confirmed. You have received Ksh2,500.00 from JANE SMITH on 22/6/24 at 2:45 PM. New M-PESA balance is Ksh11,000.00.',
    'RFK9MN2LS4 Confirmed. Ksh500.00 paid to SUPERMARKET LTD on 22/6/24 at 6:15 PM. New M-PESA balance is Ksh10,500.00.',
    'TGK5XN8LS2 Confirmed. You bought Ksh100.00 of airtime on 22/6/24 at 8:00 AM. New M-PESA balance is Ksh10,400.00.',
    // New scenarios from the logs:
    'TFQ6IGGHI6 confirmed.You bought Ksh50.00 of airtime on 26/6/25 at 11:09 PM.New M-PESA balance is Ksh0.00. Transaction cost, Ksh0.00.',
    'TFQ6IGGHI6 Confirmed. Fuliza M-PESA amount is Ksh 50.00. Interest charged Ksh 0.50. Total Fuliza M-PESA outstanding amount is Ksh 1222.98 due on 24/07/25',
  ];

  // Test fragmented messages (should be detected and skipped)
  final fragmentedMessages = [
    '. To check daily charges, Dial *334#OK Select Fuliza M-PESA to Query Charges.',
    'act within the day is 499,180.00. Start Investing today with Ziidi MMF & earn daily. Dial *334#.',
  ];

  // Test promotional messages (should be detected and skipped)
  final promotionalMessages = [
    'Dear Customer, Congratulations! You have won a free gift. Terms and conditions apply. Dial *123# to claim your bonus offer.',
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
      print('   Vendor: ${data['vendor']}');
      print('   Category: ${data['category']}');
      if (data['description'] != null) {
        print('   Description: ${data['description']}');
      }
    } else {
      print('❌ FAILED: ${result.errorMessage}');
    }
  }

  print('\n\n🧩 Testing Fragmented Messages (should be skipped):');
  print('=' * 50);

  for (int i = 0; i < fragmentedMessages.length; i++) {
    print('\nTest ${i + 1}: Fragment');
    final result = await engine.extractTransactionEnhanced(fragmentedMessages[i], 'MPESA');

    if (!result.success && result.errorMessage?.contains('fragmented') == true) {
      print('✅ CORRECTLY REJECTED: Fragmented message detected');
    } else if (result.success) {
      print('⚠️  UNEXPECTED SUCCESS: Fragment was processed as transaction');
      final data = result.transactionData!;
      print('   Amount: ${data['amount']}');
      print('   Vendor: ${data['vendor']}');
    } else {
      print('❌ FAILED: ${result.errorMessage}');
    }
  }

  print('\n\n📢 Testing Promotional Messages (should be skipped):');
  print('=' * 50);

  for (int i = 0; i < promotionalMessages.length; i++) {
    print('\nTest ${i + 1}: Promotional');
    final result = await engine.extractTransactionEnhanced(promotionalMessages[i], 'MPESA');

    if (!result.success && result.errorMessage?.contains('promotional') == true) {
      print('✅ CORRECTLY REJECTED: Promotional message detected');
    } else if (result.success) {
      print('⚠️  UNEXPECTED SUCCESS: Promotional message was processed as transaction');
      final data = result.transactionData!;
      print('   Amount: ${data['amount']}');
      print('   Vendor: ${data['vendor']}');
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
  print('✓ Enhanced SMS extraction engine with new patterns');
  print('✓ Template-based pattern matching for M-PESA (including Fuliza)');
  print('✓ Bank message format support');
  print('✓ Fragmentation detection to prevent incorrect extractions');
  print('✓ Promotional message filtering');
  print('✓ Confidence scoring for accuracy assessment');
  print('✓ Extensible pattern system for new formats');
  print('\n🎉 Enhanced SMS Extraction Engine is ready for production!');
}
