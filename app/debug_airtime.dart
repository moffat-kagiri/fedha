import 'lib/services/sms_extraction_engine.dart';

void main() async {
  print('🔍 Debugging Airtime Pattern Matching');
  
  final testMessage = 'TFQ6IGGHI6 confirmed.You bought Ksh50.00 of airtime on 26/6/25 at 11:09 PM.New M-PESA balance is Ksh0.00. Transaction cost, Ksh0.00.';
  
  print('Message: $testMessage');
  
  // Test the specific airtime pattern
  final airtimePattern = RegExp(
    r'(?:you\s+)?bought\s+ksh\s*([0-9,]+\.?[0-9]*)\s+of\s+airtime',
    caseSensitive: false,
  );
  
  final match = airtimePattern.firstMatch(testMessage);
  if (match != null) {
    print('✅ Airtime pattern matches!');
    print('Amount: ${match.group(1)}');
  } else {
    print('❌ Airtime pattern does not match');
    
    // Try a simpler pattern
    final simplePattern = RegExp(r'bought.*?ksh.*?airtime', caseSensitive: false);
    if (simplePattern.hasMatch(testMessage)) {
      print('✅ Simple pattern matches - issue with amount extraction');
    } else {
      print('❌ Even simple pattern fails');
    }
  }
  
  // Test full extraction
  final engine = SmsExtractionEngine.instance;
  final result = await engine.extractTransaction(testMessage, 'MPESA');
  
  if (result.success) {
    print('✅ Full extraction success');
    print('Confidence: ${result.confidence}');
    print('Data: ${result.transactionData}');
  } else {
    print('❌ Full extraction failed: ${result.errorMessage}');
  }
}
