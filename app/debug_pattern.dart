import 'lib/services/sms_extraction_engine.dart';

void main() async {
  // Test confidence calculation directly
  print('--- Testing Confidence Calculation ---');
  
  final extractedData = {
    'amount': 1500.0,
    'type': 'expense',
    'vendor': 'JOHN DOE',
    'description': 'Money transfer to JOHN DOE',
    'category': 'money_transfer',
    'reference': 'TFK3MN5LS9',
    'date': DateTime.now(),
  };
  
  // Manually calculate confidence like the pattern does
  double confidence = 0.0;
  if (extractedData['amount'] != null) confidence += 0.4;
  if (extractedData['vendor'] != null) confidence += 0.2;
  if (extractedData['type'] != null) confidence += 0.2;
  if (extractedData['reference'] != null) confidence += 0.1;
  if (extractedData['date'] != null) confidence += 0.1;
  
  print('Calculated confidence: $confidence');
  print('Threshold: 0.7');
  print('Above threshold: ${confidence >= 0.7}');
  
  // Now test the actual engine
  final engine = SmsExtractionEngine.instance;
  
  final testMessage = 'TFK3MN5LS9 Confirmed. You have sent Ksh1,500.00 to JOHN DOE on 22/6/24 at 12:30 PM. New M-PESA balance is Ksh8,500.00. Transaction cost, Ksh0.00.';
  
  print('\n--- Testing Full Engine ---');
  print('Testing message: $testMessage');
  print('Sender: MPESA');
  
  final result = await engine.extractTransaction(testMessage, 'MPESA');
  
  if (result.success) {
    print('✅ SUCCESS');
    print('Confidence: ${result.confidence}');
    print('Data: ${result.transactionData}');
  } else {
    print('❌ FAILED: ${result.errorMessage}');
  }
}
