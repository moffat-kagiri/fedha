// A test script to verify the network connection setup
import 'dart:io';
import 'package:dio/dio.dart';

const Map<String, String> serverConfigs = {
  'development': '192.168.100.6:8000',
  'androidEmulator': '10.0.2.2:8000',
  'staging': 'staging-api.fedha.app',
  'production': 'api.fedha.app',
};

void main() async {
  print('🔍 Fedha Network Connection Test');
  print('===============================\n');
  
  // Test all configurations
  for (var env in serverConfigs.keys) {
    await testConnection(env, serverConfigs[env]!);
  }
  
  print('\n✅ Test completed');
}

Future<void> testConnection(String environment, String server) async {
  print('Testing $environment environment: $server');
  
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 10);
  
  // Test regular HTTP
  await _testProtocol(dio, server, false, environment);
  
  // Test HTTPS if not development
  if (environment != 'development' && environment != 'androidEmulator') {
    await _testProtocol(dio, server, true, environment);
  }
  
  print('');
}

Future<void> _testProtocol(Dio dio, String server, bool useHttps, String environment) async {
  final protocol = useHttps ? 'HTTPS' : 'HTTP';
  final scheme = useHttps ? 'https' : 'http';
  
  try {
    // Test base connection
    final baseUrl = '$scheme://$server';
    print('  Testing $protocol connection to $baseUrl');
    
    try {
      await dio.get(baseUrl, 
          options: Options(validateStatus: (status) => true));
      print('  ✅ Base connection successful');
    } catch (e) {
      print('  ❌ Base connection failed: ${e.toString().split('\n')[0]}');
    }
    
    // Test health endpoint
    final healthUrl = '$scheme://$server/api/health/';
    print('  Testing health endpoint: $healthUrl');
    
    try {
      final response = await dio.get(healthUrl, 
          options: Options(validateStatus: (status) => true));
      
      if (response.statusCode == 200) {
        print('  ✅ Health endpoint returned 200');
        
        if (response.data is Map && response.data['status'] == 'healthy') {
          print('  ✅ Health status: healthy');
        } else {
          print('  ⚠️ Health endpoint format incorrect or status not healthy');
        }
      } else {
        print('  ❌ Health endpoint returned ${response.statusCode}');
      }
    } catch (e) {
      print('  ❌ Health endpoint failed: ${e.toString().split('\n')[0]}');
    }
  } catch (e) {
    print('  ❌ Connection test error: ${e.toString().split('\n')[0]}');
  }
}
