import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/offline_data_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/biometric_auth_service.dart';
import '../services/permissions_service.dart';
import '../theme/app_theme.dart';
import 'main_navigation.dart';
import 'signup_screen.dart';
import 'biometric_lock_screen.dart';
import '../utils/first_login_handler.dart';
import 'permissions_screen.dart';
import '../services/sms_listener_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;
  bool _showBiometricOption = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    _checkBiometricAvailability();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRequirements(); // safe to call after first frame
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check if biometric or permissions are needed before showing login

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final shouldRemember = prefs.getBool('remember_me') ?? false;
    
    if (savedEmail != null && shouldRemember && mounted) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final biometricService = BiometricAuthService.instance;
      if (biometricService == null) return;
      
      final isSupported = await biometricService.canAuthenticate();
      final isAvailable = await biometricService.isAvailable();
      final isEnabled = await biometricService.isBiometricEnabled();

      if (mounted) {
        setState(() {
          _showBiometricOption = isSupported && isAvailable && isEnabled;
        });
      }
    } catch (e) {
      // Biometric not available
    }
  }

  // Auto-login and permission check on startup
  Future<void> _checkRequirements() async {
    // Check for permissions prompt
    final permissionsService = PermissionsService.instance;
    final needsPermissions = await permissionsService.shouldShowPermissionsPrompt();
    if (needsPermissions && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PermissionsScreen(
            onPermissionsSet: (ctx) {
              Navigator.pushReplacement(
                ctx,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Check if user is already logged in
    if (await authService.isLoggedIn()) {
      final biometricService = BiometricAuthService.instance;
      final biometricEnabled = await biometricService?.isBiometricEnabled() ?? false;
      
      if (biometricEnabled && mounted) {
        // User is logged in AND has biometric enabled
        // Show biometric lock screen for privacy protection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BiometricLockScreen(
              onAuthSuccess: () {
                // Biometric verified - proceed to main app
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                );
              },
              onSkip: () {
                // User skipped biometric - still proceed to main app
                // (data remains protected by device security)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                );
              },
            ),
          ),
        );
        return;
      } else {
        // User is logged in but no biometric required
        // Go directly to main app
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      }
    }
    
    // If not logged in, stay on login screen (default behavior)
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiClient = ApiClient();
    
    // Check server health first
    final isHealthy = await apiClient.checkServerHealth();
    
    if (!isHealthy) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not connect to server. Please check your connection and try again later.';
      });
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Save email preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);
      if (_rememberMe) {
        await prefs.setString('saved_email', _emailController.text.trim());
      } else {
        await prefs.remove('saved_email');
      }
      
      final result = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        // Save last login email for biometric login
        await prefs.setString('last_login_email', _emailController.text.trim());

        // If this is the user's first login, run the first-login prompts
        if (result.isFirstLogin) {
          try {
            await FirstLoginHandler(context, authService).handleFirstLogin();
          } catch (e) {
            // Non-fatal: continue even if prompts fail
          }
        }

        // --- BIOMETRIC RECOMMENDATION FOR USERS WHO LOG IN WITHOUT BIOMETRICS ---
        final biometricService = BiometricAuthService.instance;
        final canAuth = await biometricService?.canAuthenticate() ?? false;
        final isEnabled = await biometricService?.isBiometricEnabled() ?? false;

        // Only recommend on a cold login (not resume), only if supported but disabled
        if (canAuth && !isEnabled) {
          await _showBiometricRecommendationDialog();
        }

        // Start SMS listener
        final smsService = SmsListenerService.instance;
        final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
        final profileId = authService.currentProfile!.id;
        await smsService.startListening(
          offlineDataService: offlineDataService,
          profileId: profileId
        );

        // Register successful password login session
        await biometricService?.registerSuccessfulPasswordLogin();

        // Navigate directly to main app - biometric will be handled by main.dart if needed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
      else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred during login. Please try again.';
      });
    }
  }

  // Handle first login prompts
  Future<void> _handleFirstLogin(AuthService authService) async {
    // Create first login handler
    final firstLoginHandler = FirstLoginHandler(context, authService);
    
    // Show prompts in sequence
    await firstLoginHandler.handleFirstLogin();
  }

  Future<void> _biometricLogin() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.biometricLogin();

      if (!mounted) return;

      if (result.success) {
        // Start SMS listener
        final smsService = SmsListenerService.instance;
        final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
        final profileId = authService.currentProfile!.id;
        await smsService.startListening(
          offlineDataService: offlineDataService,
          profileId: profileId
        );

        // Navigate to main app
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Biometric authentication failed: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _showBiometricRecommendationDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enable Biometric Login'),
          content: const Text(
            'You can enable biometric authentication for faster and more secure sign-ins. '
            'Would you like to set it up now?',
          ),
          actions: [
            TextButton(
              child: const Text('Maybe Later'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Set Up'),
              onPressed: () async {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BiometricLockScreen(
                      onAuthSuccess: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF007A39),
              Color(0xFF00552A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and App Name
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Fedha',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Financial management made simple',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromRGBO(255, 255, 255, 0.86),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Login Form
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Error Message
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            
                            // Remember me and Forgot password
                            Row(
                              children: [
                                // Remember me checkbox
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: FedhaColors.primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                const Text('Remember me'),
                                
                                const Spacer(),
                                
                                // Forgot password link
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password reset feature coming soon!'),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: FedhaColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Login Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                            
                            // Biometric Login Button
                            if (_showBiometricOption) ...[
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _biometricLogin,
                                icon: const Icon(Icons.fingerprint),
                                label: const Text('Sign in with Biometrics'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: BorderSide(color: Theme.of(context).primaryColor),
                                ),
                              ),
                            ],
                            
                            // Forgot Password Link
                            TextButton(
                              onPressed: () {
                                // Navigate to forgot password screen
                              },
                              child: const Text('Forgot Password?'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
