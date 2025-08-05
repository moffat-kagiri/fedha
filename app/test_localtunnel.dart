import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('\n🔄 Testing Localtunnel connectivity for Fedha backend...\n');
  
  // Try the current localtunnel URL with both HTTP and HTTPS
  final localtunnelUrl = 'beige-insects-lick.loca.lt';
  final urls = [
    'http://$localtunnelUrl/health/',
    'https://$localtunnelUrl/health/',
    'http://localhost:8000/health/',
    'http://127.0.0.1:8000/health/',
  ];
  
  print('📋 Testing the following URLs:');
  urls.forEach((url) => print('   - $url'));
  print('');
  
  for (final url in urls) {
    try {
      print('🔍 Testing: $url');
      final response = await http.get(Uri.parse(url))
        .timeout(Duration(seconds: 5));
      
      print('📊 Status code: ${response.statusCode}');
      print('📄 Response: ${response.body.trim()}\n');
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          print('✅ SUCCESS: Server is healthy');
          print('   Version: ${data['version'] ?? 'unknown'}');
          print('   Environment: ${data['environment'] ?? 'unknown'}');
          print('   Server time: ${data['server_time'] ?? 'unknown'}\n');
        } catch (e) {
          print('⚠️ Response is not valid JSON: ${response.body}\n');
        }
      }
    } catch (e) {
      print('❌ ERROR: $e\n');
    }
  }
  
  print('📝 API Configuration Recommendations:');
  print('1. In app/lib/config/api_config.dart, update:');
  print('   - ApiConfig.development() to use HTTP (not HTTPS) with localtunnel');
  print('   - Set primaryApiUrl to: $localtunnelUrl');
  print('   - Set fallbackApiUrl to: localhost:8000');
  print('');
  print('2. In app/lib/main.dart:');
  print('   - Make sure useLocalServer = true');
  print('   - Or use environmentConfig.apiEnvironment = ApiEnvironment.development');
  print('');
  print('📱 Now test the app on your device!');
}
