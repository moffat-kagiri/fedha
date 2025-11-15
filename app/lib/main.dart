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
// import 'config/local_server_config.dart';  // removed: file not found
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

// Background services
import 'services/background_service.dart';

// Screens
import 'screens/auth_wrapper.dart';
// import 'screens/loan_calculator_screen.dart'; // Replaced with investment calculator
import 'screens/progressive_goal_wizard_screen.dart';
import 'screens/investment_calculator_screen.dart';
import 'screens/investment_irr_calculator_screen.dart';
import 'screens/add_goal_screen.dart';
import 'screens/create_budget_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/spending_overview_screen.dart';
import 'screens/loans_tracker_screen.dart';
import 'screens/transaction_entry_unified_screen.dart';
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
// import 'screens/asset_protection_screen.dart';
import 'screens/asset_protection_intro_screen.dart';
import 'screens/health_cover_screen.dart';
import 'screens/vehicle_cover_screen.dart';
import 'screens/home_cover_screen.dart';
import 'screens/emergency_fund_screen.dart';
import 'screens/sms_review_screen.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Background task handler for various scheduled tasks
      if (task == 'daily_review_task') {
        // Determine current profile id from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final profileIdStr = prefs.getString('profile_id') ?? '';
        final profileId = int.tryParse(profileIdStr) ?? 0;

        // Initialize DB helper and count pending transactions
        final offline = OfflineDataService();
        await offline.initialize();
        final pendingCount = await offline.getPendingTransactionCount(profileId);

        // Initialize notifications (safe to call repeatedly)
        await NotificationService.instance.initialize();
        await NotificationService.instance.showPendingTransactionsNotification(pendingCount);
        return Future.value(true);
      }

      if (task == 'sms_listener_task') {
        // existing SMS listener work is handled elsewhere; keep alive
        return Future.value(true);
      }
    } catch (e) {
      // Swallow errors to avoid crashing the background isolate
      return Future.value(false);
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );


  // Register periodic SMS listener task (existing behavior)
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
    inputData: {
      'profileId': '1'
    },
  );

  // Disable Provider debug type check for Listenable/Stream types
  Provider.debugCheckInvalidValueType = null;
  
  // Initialize logging
  AppLogger.init();

  // (Hive initialization removed in favor of Drift)

  // Initialize OfflineDataService so its box references are ready
  final offlineDataService = OfflineDataService();
  await offlineDataService.initialize();

  // In debug mode, trigger a one-off manual notification shortly after
  // startup so we can verify notification behavior without waiting
  // for the background Workmanager task.
  if (kDebugMode) {
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final profileIdStr = prefs.getString('profile_id') ?? '';
        final profileId = int.tryParse(profileIdStr) ?? 0;
        final offline = OfflineDataService();
        await offline.initialize();
        final pendingCount = await offline.getPendingTransactionCount(profileId);
        await NotificationService.instance.showPendingTransactionsNotification(pendingCount);
      } catch (e) {
        // Fallback test notification
        await NotificationService.instance.showPendingTransactionsNotification(2);
      }
    });
  }

  try {
    // Initialize environment configuration
    final envConfig = EnvironmentConfig.current();
    
    // Initialize services
    final authService = AuthService.instance;
    await authService.initialize();
    
    
  // Initialize permissions service (dialogs will be prompted after UI is ready)
  final permissionsService = PermissionsService.instance;
  await permissionsService.initialize();
    
    // Initialize API configuration based on environment
    // Import the connection manager at the top of the file:
    // import 'utils/connection_manager.dart';
    
    // Check for local server flag in arguments or preferences
    final useLocalServer = true; // Using our localtunnel server
    
    // Auto-detect best connection based on platform and network availability
    final logger = AppLogger.getLogger('Main');
    logger.info('Detecting optimal connection method...');
    
    // Create API client with minimal config for connectivity check
    final tempApiClient = ApiClient.instance;
    tempApiClient.init(config: ApiConfig.development());
    final connectivityService = conn_svc.ConnectivityService(tempApiClient);
    await connectivityService.initialize();
    
    // Check if we have internet connectivity at all
    final hasConnectivity = await connectivityService.hasInternetConnection();
    logger.info('Internet connectivity available: $hasConnectivity');
    
    // Get the best available connection URL
    String? bestConnectionUrl;
    if (hasConnectivity) {
      bestConnectionUrl = await ConnectionManager.findWorkingConnection();
      AppLogger.getLogger('Main').info('Best available connection: $bestConnectionUrl');
    }
    
    // Configure API based on detection results
    ApiConfig apiConfig;
    
    // Choose configuration based on the detected connection
    if (bestConnectionUrl != null) {
      if (bestConnectionUrl.contains('trycloudflare.com')) {
        // Cloudflare tunnel is working
        apiConfig = ApiConfig.cloudflare();
        logger.info('Using Cloudflare tunnel connection');
      } else if (bestConnectionUrl.contains('192.168.')) {
        // Local network is working
        apiConfig = ApiConfig.development();
        logger.info('Using local network connection');
      } else if (bestConnectionUrl.contains('localhost') || bestConnectionUrl.contains('127.0.0.1')) {
        // Direct localhost connection
        apiConfig = ApiConfig.development();
        logger.info('Using direct localhost connection');
      } else {
        // Some other connection was found
        apiConfig = ApiConfig.development().copyWith(primaryApiUrl: bestConnectionUrl);
        logger.info('Using custom connection: $bestConnectionUrl');
      }
    } else {
      apiConfig = ApiConfig.development();
    }

  // Instantiate core services for DI
  final apiClient = ApiClient.instance;
  apiClient.init(config: apiConfig);
  final goalTransactionService = stubs.GoalTransactionService(offlineDataService);
  final textRecognitionService = stubs.TextRecognitionService(offlineDataService);
  final csvUploadService = stubs.CSVUploadService(offlineDataService);
  final smsTransactionExtractor = stubs.SmsTransactionExtractor(offlineDataService);
  final notificationService = stubs.NotificationService.instance;
  final syncService = EnhancedSyncService(offlineDataService, apiClient);
  final navigationService = stubs.NavigationService.instance;
  final senderManagementService = stubs.SenderManagementService.instance;
  final backgroundTransactionMonitor = stubs.BackgroundTransactionMonitor(offlineDataService, smsTransactionExtractor);
  final biometricAuthService = BiometricAuthService.instance!;
  final themeService = ThemeService.instance;
  final currencyService = CurrencyService();

  // Initialize local risk assessment database and service
  final db = await AppDatabase.openOnDevice();
  final riskAssessmentService = RiskAssessmentService(db);

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
          ChangeNotifierProvider<SmsListenerService>.value(
            value: SmsListenerService.instance,
          ),
          Provider<EnhancedSyncService>.value(value: syncService),
          Provider<stubs.NavigationService>.value(value: navigationService),
          Provider<stubs.SenderManagementService>.value(value: senderManagementService),
          Provider<stubs.BackgroundTransactionMonitor>.value(value: backgroundTransactionMonitor),
          Provider<BiometricAuthService>.value(value: biometricAuthService),
          ChangeNotifierProvider<PermissionsService>.value(value: permissionsService),
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider<ThemeService>.value(value: themeService),
          Provider<CurrencyService>.value(value: currencyService),
          Provider<RiskAssessmentService>.value(value: riskAssessmentService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing app: $e');
    }
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Future<void>? _initializationFuture;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializationFuture = _initializeServices();
    // After first frame, prompt for any missing permissions when UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final permissionsService = Provider.of<PermissionsService>(context, listen: false);
      if (await permissionsService.shouldShowPermissionsPrompt()) {
        await permissionsService.requestAllPermissions();
      }
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _promptBiometricOnResume();
    }
  }

  Future<void> _promptBiometricOnResume() async {
    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return;
    final authService = Provider.of<AuthService>(ctx, listen: false);
    final biometricService = BiometricAuthService.instance;
    final biometricEnabled = await biometricService?.isBiometricEnabled() ?? false;
    final hasValidSession = await biometricService?.hasValidBiometricSession() ?? false;
    if (await authService.isLoggedIn() && biometricEnabled && !hasValidSession) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => BiometricLockScreen(
            onAuthSuccess: () {
              _navigatorKey.currentState?.pop();
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // New method to check onboarding status
  Future<bool> _isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  // Service initialization for dependencies after widgets binding
  Future<void> _initializeServices() async {
    try {
      final offlineService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final smsListenerService = Provider.of<SmsListenerService>(context, listen: false);
      final backgroundMonitor = Provider.of<stubs.BackgroundTransactionMonitor>(context, listen: false);

      await offlineService.initialize();
      await authService.initialize();

      if (await authService.isLoggedIn() && authService.currentProfile != null) {
        final currentProfile = authService.currentProfile!;
        smsListenerService.setCurrentProfile(currentProfile.id);
        try {
          await backgroundMonitor.initialize();
        } catch (e) {
          if (kDebugMode) {
            print('Background monitor initialization failed: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Service initialization error: $e');
      }
      // Continue even if there are errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isOnboardingCompleted(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // While waiting, show splash screen or loader, respect user's theme choice
          return Consumer<ThemeService>(
            builder: (context, themeService, child) {
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeService.themeMode,
                home: Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App logo
                        SvgPicture.asset(
                          'assets/icons/fedha_logo.svg',
                          height: 100,
                        ),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
        // If onboarding is completed, show SignupScreen (for users returning after a failed account creation),
        // otherwise, show WelcomeOnboardingScreen
        final bool onboardingCompleted = snapshot.data!;
        final Widget homeScreen = onboardingCompleted
            ? const SignupScreen()
            : const WelcomeOnboardingScreen();

        return Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return MaterialApp(
              navigatorKey: _navigatorKey,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeService.themeMode,
              home: const AuthWrapper(),
              routes: {
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
              apiClient: Provider.of<ApiClient>(context, listen: false),
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
            },
            );
          },
        );
      }
    );
  }
}
