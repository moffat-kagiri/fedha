// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/logger.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:workmanager/workmanager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'services/notification_service.dart';

// Models
import 'models/profile.dart';
import 'models/transaction.dart';
import 'models/transaction_candidate.dart';
import 'models/category.dart';
import 'models/goal.dart';
import 'models/budget.dart';
import 'models/client.dart';
import 'models/invoice.dart';
import 'models/sync_queue_item.dart';
import 'models/enums.dart';

// Services
import 'services/offline_data_service.dart';
import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'services/theme_service.dart';
import 'config/api_config.dart';
import 'config/environment_config.dart';
import 'services/currency_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/service_stubs.dart' as stubs;
import 'utils/connection_manager.dart';
import 'services/enhanced_sync_service.dart';
import 'services/connectivity_service.dart' as conn_svc;
import 'services/sms_listener_service.dart';
import 'services/permissions_service.dart';
import 'theme/app_theme.dart';
import 'services/risk_assessment_service.dart';
import 'services/profile_management_extension.dart';

// Background services
import 'services/background_service.dart';

// Screens
import 'screens/auth_wrapper.dart';
import 'screens/progressive_goal_wizard_screen.dart';
import 'screens/investment_calculator_screen.dart';
import 'screens/investment_irr_calculator_screen.dart';
import 'screens/add_goal_screen.dart';
import 'screens/create_budget_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/spending_overview_screen.dart';
import 'screens/loans_tracker_screen.dart';
import 'screens/transaction_entry_unified_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/biometric_lock_screen.dart';
import 'screens/loan_calculator_screen.dart';
import 'screens/test_profiles_screen.dart';
import 'screens/connection_diagnostics_screen.dart';
import 'screens/welcome_onboarding_screen.dart';
import 'device_network_info.dart';
import 'ip_settings.dart';
import 'screens/debt_repayment_planner_screen.dart';
import 'screens/asset_protection_intro_screen.dart';
import 'screens/health_cover_screen.dart';
import 'screens/vehicle_cover_screen.dart';
import 'screens/home_cover_screen.dart';
import 'screens/emergency_fund_screen.dart';
import 'screens/sms_review_screen.dart';

/// ✅ Background task handler - isolated from main app
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'daily_review_task') {
        final prefs = await SharedPreferences.getInstance();
        // ✅ FIXED: Use correct key
        final profileId = prefs.getString('current_profile_id') ?? '';
        
        if (profileId.isEmpty) {
          return Future.value(false);
        }

        final offline = OfflineDataService();
        await offline.initialize();
        
        // ✅ FIXED: Pass String profileId
        final pendingCount = await offline.getPendingTransactionCount(profileId);

        await NotificationService.instance.initialize();
        await NotificationService.instance.showPendingTransactionsNotification(pendingCount);
        return Future.value(true);
      }

      if (task == 'sms_listener_task') {
        return Future.value(true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Background task error: $e');
      }
      return Future.value(false);
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize logging first
  Provider.debugCheckInvalidValueType = null;
  AppLogger.init();
  final logger = AppLogger.getLogger('Main');

  try {
    // ✅ STEP 1: Initialize WorkManager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // ✅ STEP 2: Initialize core singleton services
    logger.info('Initializing core services...');
    
    // Create single instance of OfflineDataService
    final offlineDataService = OfflineDataService();
    await offlineDataService.initialize();
    
    // Initialize BiometricAuthService
    final biometricAuthService = BiometricAuthService.instance;
    await biometricAuthService?.initialize();
    
    // Initialize AuthService WITH dependency injection
    final authService = AuthService.instance;
    await authService.initializeWithDependencies(
      offlineDataService: offlineDataService,
      biometricService: biometricAuthService,
    );
    
    // Initialize PermissionsService
    final permissionsService = PermissionsService.instance;
    await permissionsService.initialize();
    
    // Initialize ThemeService
    final themeService = ThemeService.instance;
    await themeService.initialize();

    // ✅ STEP 3: Initialize network services
    logger.info('Initializing network services...');
    
    final apiClient = ApiClient.instance;
    apiClient.init(config: ApiConfig.development());
    
    final connectivityService = conn_svc.ConnectivityService(apiClient);
    await connectivityService.initialize();
    
    final hasConnectivity = await connectivityService.hasInternetConnection();
    logger.info('Internet connectivity: $hasConnectivity');

    // ✅ STEP 4: Find best API connection
    String? bestConnectionUrl;
    if (hasConnectivity) {
      bestConnectionUrl = await ConnectionManager.findWorkingConnection();
      logger.info('Best connection: $bestConnectionUrl');
      
      // Update API config with best connection
      ApiConfig apiConfig;
      if (bestConnectionUrl != null) {
        if (bestConnectionUrl.contains('trycloudflare.com')) {
          apiConfig = ApiConfig.cloudflare();
        } else if (bestConnectionUrl.contains('192.168.')) {
          apiConfig = ApiConfig.development();
        } else {
          apiConfig = ApiConfig.development().copyWith(primaryApiUrl: bestConnectionUrl);
        }
        apiClient.init(config: apiConfig);
      }
    }

    // ✅ STEP 5: Initialize remaining services
    logger.info('Initializing app services...');
    
    final goalTransactionService = stubs.GoalTransactionService(offlineDataService);
    final textRecognitionService = stubs.TextRecognitionService(offlineDataService);
    final csvUploadService = stubs.CSVUploadService(offlineDataService);
    final smsTransactionExtractor = stubs.SmsTransactionExtractor(offlineDataService);
    final notificationService = stubs.NotificationService.instance;
    final syncService = EnhancedSyncService(offlineDataService, apiClient);
    final navigationService = stubs.NavigationService.instance;
    final senderManagementService = stubs.SenderManagementService.instance;
    final backgroundTransactionMonitor = stubs.BackgroundTransactionMonitor(
      offlineDataService, 
      smsTransactionExtractor
    );
    final currencyService = CurrencyService();
    
    final db = await AppDatabase.openOnDevice();
    final riskAssessmentService = RiskAssessmentService(db);

    // ✅ STEP 6: Determine biometric requirements
    final isLoggedIn = authService.hasActiveProfile;
    final biometricEnabled = biometricAuthService != null
        ? await biometricAuthService.isBiometricEnabled()
        : false;
    final hasValidSession = biometricAuthService != null
        ? await biometricAuthService.hasValidBiometricSession()
        : false;
    
    final requireBiometricOnLaunch = isLoggedIn && biometricEnabled && !hasValidSession;
    
    logger.info('Auth state - Logged in: $isLoggedIn, Biometric enabled: $biometricEnabled, '
                'Valid session: $hasValidSession, Require unlock: $requireBiometricOnLaunch');

    // ✅ STEP 7: Register background tasks
    if (isLoggedIn && authService.profileId != null) {
      await _registerBackgroundTasks(authService.profileId!);
    }

    // ✅ STEP 8: Launch app with providers
    logger.info('Launching app...');
    
    runApp(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          Provider<OfflineDataService>.value(value: offlineDataService),
          Provider<conn_svc.ConnectivityService>.value(value: connectivityService),
          Provider<stubs.GoalTransactionService>.value(value: goalTransactionService),
          Provider<stubs.TextRecognitionService>.value(value: textRecognitionService),
          Provider<stubs.CSVUploadService>.value(value: csvUploadService),
          Provider<stubs.SmsTransactionExtractor>.value(value: smsTransactionExtractor),
          Provider<stubs.NotificationService>.value(value: notificationService),
          ChangeNotifierProvider<SmsListenerService>.value(value: SmsListenerService.instance),
          Provider<EnhancedSyncService>.value(value: syncService),
          Provider<stubs.NavigationService>.value(value: navigationService),
          Provider<stubs.SenderManagementService>.value(value: senderManagementService),
          Provider<stubs.BackgroundTransactionMonitor>.value(value: backgroundTransactionMonitor),
          Provider<BiometricAuthService>.value(value: biometricAuthService!),
          ChangeNotifierProvider<PermissionsService>.value(value: permissionsService),
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider<ThemeService>.value(value: themeService),
          Provider<CurrencyService>.value(value: currencyService),
          Provider<RiskAssessmentService>.value(value: riskAssessmentService),
        ],
        child: MyApp(requireBiometricOnLaunch: requireBiometricOnLaunch),
      ),
    );
  } catch (e, stackTrace) {
    logger.severe('App initialization failed: $e', e, stackTrace);
    
    // Fallback error UI
    runApp(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Failed to Initialize App',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Restart app
                      main();
                    },
                    child: const Text('Retry'),
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

/// ✅ Centralized background task registration
Future<void> _registerBackgroundTasks(String profileId) async {
  final logger = AppLogger.getLogger('BackgroundTasks');
  
  try {
    // Cancel existing tasks first
    await Workmanager().cancelAll();
    
    // Register SMS listener
    await Workmanager().registerPeriodicTask(
      'sms_listener',
      'sms_listener_task',
      frequency: const Duration(hours: 3),
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: true,
      ),
      inputData: {'profileId': profileId},
    );
    
    // Register daily review notification
    await Workmanager().registerPeriodicTask(
      'daily_review',
      'daily_review_task',
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(hours: 1),
      inputData: {'profileId': profileId},
    );
    
    logger.info('Background tasks registered for profile: $profileId');
  } catch (e) {
    logger.warning('Failed to register background tasks: $e');
  }
}

class MyApp extends StatefulWidget {
  final bool requireBiometricOnLaunch;

  const MyApp({
    super.key,
    required this.requireBiometricOnLaunch,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _logger = AppLogger.getLogger('MyApp');

  bool _showBiometricLock = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  /// ✅ Simplified initialization
  Future<void> _initialize() async {
    _logger.info('MyApp initializing...');
    
    // Set biometric lock state based on launch requirement
    setState(() {
      _showBiometricLock = widget.requireBiometricOnLaunch;
      _isInitializing = false;
    });
    
    _logger.info('MyApp ready - Biometric lock: $_showBiometricLock');
  }

  /// ✅ Improved lifecycle handling
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    _logger.info('App lifecycle state: $state');
    
    final authService = context.read<AuthService>();
    final biometricService = context.read<BiometricAuthService>();

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Invalidate session when app goes to background
        await biometricService.invalidateBiometricSession();
        _logger.info('Biometric session invalidated');
        break;

      case AppLifecycleState.resumed:
        // Check if we need to show biometric lock
        final isLoggedIn = authService.hasActiveProfile;
        final biometricEnabled = await biometricService.isBiometricEnabled();
        final hasValidSession = await biometricService.hasValidBiometricSession();

        if (isLoggedIn && biometricEnabled && !hasValidSession) {
          if (mounted) {
            setState(() {
              _showBiometricLock = true;
            });
            _logger.info('Biometric lock required on resume');
          }
        }
        break;

      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// ✅ Simplified biometric unlock
  Future<void> _handleBiometricUnlock() async {
    _logger.info('Biometric unlock successful');
    
    final biometricService = context.read<BiometricAuthService>();
    await biometricService.registerSuccessfulBiometricSession();

    if (mounted) {
      setState(() {
        _showBiometricLock = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    // Show splash while initializing
    if (_isInitializing) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeService.themeMode,
        home: _buildSplashScreen(),
      );
    }

    // Show biometric lock if required
    if (_showBiometricLock) {
      return MaterialApp(
        navigatorKey: _navigatorKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeService.themeMode,
        home: BiometricLockScreen(
          onAuthSuccess: _handleBiometricUnlock,
        ),
      );
    }

    // Show normal app
    return MaterialApp(
      navigatorKey: _navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      home: const AuthWrapper(),
      routes: _buildRoutes(),
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/fedha_logo.svg',
              height: 100,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading...'),
          ],
        ),
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/welcome_onboarding': (context) => const WelcomeOnboardingScreen(),
      '/transactions': (context) => const TransactionsScreen(),
      '/investment_calculator': (context) => const InvestmentCalculatorScreen(),
      '/investment_irr_calculator': (context) => const InvestmentIRRCalculatorScreen(),
      '/progressive_goal_wizard': (context) => const ProgressiveGoalWizardScreen(),
      '/add_goal': (context) => const AddGoalScreen(),
      '/create_budget': (context) => const CreateBudgetScreen(),
      '/goals': (context) => const GoalsScreen(),
      '/add_transaction': (context) => const TransactionEntryUnifiedScreen(),
      '/loan_calculator': (context) => const LoanCalculatorScreen(),
      '/transaction_entry': (context) => const TransactionEntryUnifiedScreen(),
      '/detailed_transaction_entry': (context) => const TransactionEntryUnifiedScreen(),
      '/login': (context) => const LoginScreen(),
      '/signup': (context) => const SignupScreen(),
      '/test_profiles': (context) => const TestProfilesScreen(),
      '/spending_overview': (context) => const SpendingOverviewScreen(),
      '/loans_tracker': (context) => const LoansTrackerScreen(),
      '/connection_diagnostics': (context) => ConnectionDiagnosticsScreen(
            apiClient: context.read<ApiClient>(),
          ),
      '/device_network_info': (context) => const DeviceInfoScreen(),
      '/ip_settings': (context) => const IpSettingsScreen(),
      '/debt_repayment_planner': (context) => const DebtRepaymentPlannerScreen(),
      '/asset_protection': (context) => AssetProtectionIntroScreen(),
      '/asset_protection_intro': (context) => AssetProtectionIntroScreen(),
      '/asset_protection_health': (context) => HealthCoverScreen(),
      '/asset_protection_vehicle': (context) => VehicleCoverScreen(),
      '/asset_protection_home': (context) => HomeCoverScreen(),
      '/emergency-fund': (context) => const EmergencyFundScreen(),
      '/sms_review': (context) => const SmsReviewScreen(),
    };
  }
}