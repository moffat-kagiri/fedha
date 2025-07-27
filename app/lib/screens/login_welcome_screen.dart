import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/connectivity_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/test_profile_creator.dart';

class LoginWelcomeScreen extends StatefulWidget {
  const LoginWelcomeScreen({Key? key}) : super(key: key);

  @override
  State<LoginWelcomeScreen> createState() => _LoginWelcomeScreenState();
}

class _LoginWelcomeScreenState extends State<LoginWelcomeScreen> {
  bool _isCheckingConnection = false;
  bool _serverConnected = true;
  late ConnectivityService _connectivityService;
  
  @override
  void initState() {
    super.initState();
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    _connectivityService = ConnectivityService(apiClient);
    _checkServerConnection();
    
    // Listen for server connectivity changes
    _connectivityService.serverStatusStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _serverConnected = isConnected;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }
  
  Future<void> _checkServerConnection() async {
    if (mounted) {
      setState(() {
        _isCheckingConnection = true;
      });
    }
    
    final isConnected = await _connectivityService.checkServerStatus();
    
    if (mounted) {
      setState(() {
        _serverConnected = isConnected;
        _isCheckingConnection = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = ResponsiveUtils.isTablet(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: SvgPicture.asset(
                  'assets/images/fedha_logo.svg',
                  width: isTablet ? 200 : 150,
                  height: isTablet ? 200 : 150,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Welcome to Fedha',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your personal finance manager',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              
              // Server connection status indicator
              if (!_serverConnected)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Server connection issue',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You can still use the app offline, but some features may be limited.',
                                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isCheckingConnection 
                            ? Icons.hourglass_top 
                            : Icons.refresh, 
                            color: Colors.red.shade700
                          ),
                          onPressed: _isCheckingConnection ? null : _checkServerConnection,
                        ),
                      ],
                    ),
                  ),
                ),
              
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/signup');
                },
                child: const Text('Sign Up'),
              ),
              // Offline mode option
              if (!_serverConnected) 
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextButton(
                    onPressed: () {
                      // Handle offline mode entry
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Entering offline mode'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      // Navigate to home screen or appropriate offline mode screen
                    },
                    child: const Text('Continue in Offline Mode'),
                  ),
                ),
              const SizedBox(height: 32),
              
              // Developer options (only in debug mode)
              if (kDebugMode)
                TextButton.icon(
                  onPressed: () {
                    // Show options dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Create Test Profiles'),
                        content: const Text(
                          'Do you want to create test profiles?\n\n'
                          '- Personal Profile: John Doe\n'
                          '- Business Profile: Acme Corporation'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushNamed(context, '/test_profiles');
                            },
                            child: const Text('Go to Screen'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await TestProfileCreator.showProfilesCreatedDialog(context);
                            },
                            child: const Text('Create Now'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.developer_mode, size: 16),
                  label: const Text('Create Test Profiles'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}