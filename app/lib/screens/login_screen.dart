import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
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
    _checkRequirements();
    _checkBiometricAvailability();
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
    // Check for biometric session
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.initialize();
    if (authService.isLoggedIn()) {
      final biometricService = BiometricAuthService.instance;
      final biometricEnabled = await biometricService?.isBiometricEnabled() ?? false;
      final hasValid = await biometricService?.hasValidBiometricSession() ?? false;
      if (biometricEnabled && !hasValid && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BiometricLockScreen(
              onAuthSuccess: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                );
              },
              onSkip: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                );
              },
            ),
          ),
        );
        return;
      }
      // Already logged in
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    }
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
        // Set up biometric auth if available
        final biometricService = BiometricAuthService.instance;
        if (biometricService != null) {
          await biometricService.setBiometricSession();
        }
        
        // Start SMS listener for this profile
        final smsService = SmsListenerService.instance;
        smsService.setCurrentProfile(authService.currentProfile!.id);
        await smsService.startListening();
        
        // Login successful, navigate to main screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
        
        // If this is the user's first login, show first login prompts
        if (result.isFirstLogin) {
          // Small delay to allow the UI to update
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (mounted) {
            // Show first login prompts
            await _handleFirstLogin(authService);
          }
        }
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      final biometricService = BiometricAuthService.instance;
      if (biometricService == null) return;
      
      final success = await biometricService.authenticate(
        localizedReason: 'Please authenticate to sign in',
      );
      
      if (success) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final result = await authService.loginWithBiometric();
        
        if (!mounted) return;

        if (!result.success) {
          setState(() {
            _errorMessage = 'Biometric login failed';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Biometric authentication failed';
        });
      }
    }
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
