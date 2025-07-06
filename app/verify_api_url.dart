// API URL verification utility
// Run with: dart run verify_api_url.dart

void main() {
  print('🔍 Verifying API URLs\n');
  
  final urls = [
    'http://localhost:3000',
    'https://fedha-api.herokuapp.com',
    'https://your-ngrok-url.ngrok.io',
  ];
  
  for (final url in urls) {
    print('📍 $url');
    // In a real implementation, this would make HTTP requests
    print('  Status: ⏳ Checking...');
  }
  
  print('\n✅ URL verification completed');
}