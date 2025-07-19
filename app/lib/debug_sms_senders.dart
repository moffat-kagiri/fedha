// Debug utility for SMS senders
class DebugSmsSenders {
  static Future<void> printSenderStatus() async {
    print('=== SMS Sender Debug Status ===');
    print('SMS Listening: Disabled (Debug Mode)');
    print('Known Senders: 0');
    print('Recent Messages: 0');
    print('===============================');
  }
}
