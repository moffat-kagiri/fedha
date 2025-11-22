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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---- Background / scheduler initialization ----
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Register periodic SMS listener task 
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

  // ---- Global debug and logger setup ----
  Provider.debugCheckInvalidValueType = null;
  AppLogger.init();

  // ---- Core local services that need early init ----
  final offlineDataService = OfflineDataService();
  await offlineDataService.initialize();

  // ---- Consolidated service boot (AuthService only once here) ----
  try {
    final envConfig = EnvironmentConfig.current();

    // Initialize AuthService exactly once at cold start.
    final authService = AuthService.instance;
    await authService.initialize();

    // Initialize permissions service (dialogs to be invoked after UI is ready)
    final permissionsService = PermissionsService.instance;
    await permissionsService.initialize();

    // Initialize API connectivity detection and configuration
    final tempApiClient = ApiClient.instance;
    tempApiClient.init(config: ApiConfig.development());
    final connectivityService = conn_svc.ConnectivityService(tempApiClient);
    await connectivityService.initialize();
    final hasConnectivity = await connectivityService.hasInternetConnection();
    AppLogger.getLogger('Main').info('Internet connectivity available: $hasConnectivity');

    String? bestConnectionUrl;
    if (hasConnectivity) {
      bestConnectionUrl = await ConnectionManager.findWorkingConnection();
      AppLogger.getLogger('Main').info('Best available connection: $bestConnectionUrl');
    }

    ApiConfig apiConfig;
    if (bestConnectionUrl != null) {
      if (bestConnectionUrl.contains('trycloudflare.com')) {
        apiConfig = ApiConfig.cloudflare();
      } else if (bestConnectionUrl.contains('192.168.')) {
        apiConfig = ApiConfig.development();
      } else if (bestConnectionUrl.contains('localhost') || bestConnectionUrl.contains('127.0.0.1')) {
        apiConfig = ApiConfig.development();
      } else {
        apiConfig = ApiConfig.development().copyWith(primaryApiUrl: bestConnectionUrl);
      }
    } else {
      apiConfig = ApiConfig.development();
    }

    // Finalize API client for the app
    final apiClient = ApiClient.instance;
    apiClient.init(config: apiConfig);

    // Instantiate other core services (stubs / singletons)
    final goalTransactionService = stubs.GoalTransactionService(offlineDataService);
    final textRecognitionService = stubs.TextRecognitionService(offlineDataService);
    final csvUploadService = stubs.CSVUploadService(offlineDataService);
    final smsTransactionExtractor = stubs.SmsTransactionExtractor(offlineDataService);
    final notificationService = stubs.NotificationService.instance;
    final syncService = EnhancedSyncService(offlineDataService, apiClient);
    final navigationService = stubs.NavigationService.instance;
    final senderManagementService = stubs.SenderManagementService.instance;
    final backgroundTransactionMonitor = stubs.BackgroundTransactionMonitor(offlineDataService, smsTransactionExtractor);
    final biometricAuthService = BiometricAuthService.instance; // may be null-safe in your implementation
    final themeService = ThemeService.instance;
    await themeService.initialize();
    final currencyService = CurrencyService();

    // DB / risk service init
    final db = await AppDatabase.openOnDevice();
    final riskAssessmentService = RiskAssessmentService(db);

    // -------- Determine whether we should require biometric on cold launch ----------
    // Desired behavior: if user previously logged in AND biometrics are enabled,
    // the app should present the biometric lock screen before showing app content.
    final bool isLoggedIn = await authService.isLoggedIn();
    final bool biometricEnabled = (biometricAuthService != null)
        ? await (biometricAuthService.isBiometricEnabled() ?? Future.value(false))
        : false;
    final bool requireBiometricOnLaunch = isLoggedIn && biometricEnabled;

    AppLogger.getLogger('Main').info('requireBiometricOnLaunch: $requireBiometricOnLaunch');

    // -------- Provide services and hand off to MyApp (root) ----------
    // NOTE: MyApp will be updated next to:
    //   - accept `requireBiometricOnLaunch` and handle the root-level biometric gating,
    //   - own lifecycle invalidation on paused, and
    //   - avoid re-initializing AuthService (we already did it here).
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
        // Pass the flag into MyApp; next edit will make MyApp consume it.
        child: MyApp(requireBiometricOnLaunch: requireBiometricOnLaunch),
      ),
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing app: $e');
    }
    // Fallback UI when initialization fails
    runApp(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: Center(child: Text('Error initializing app: $e')),
        ),
      ),
    );
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

  bool _biometricAuthenticated = false;
  bool _loadingInitialState = true;
  bool _showBiometricLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepareRootState();
  }

  // ---------------------------------------------------------------------------
  // PREPARE ROOT STATE (cold launch gating)
  // ---------------------------------------------------------------------------
  Future<void> _prepareRootState() async {
    final authService = AuthService.instance;
    final biometricService = BiometricAuthService.instance;

    final isLoggedIn = await authService.isLoggedIn();
    final biometricEnabled =
        await (biometricService?.isBiometricEnabled() ?? Future.value(false));

    // Should we require biometric lock *right now* on cold launch?
    if (widget.requireBiometricOnLaunch) {
      setState(() {
        _showBiometricLock = true;
      });
    }

    setState(() {
      _loadingInitialState = false;
    });
  }

  // ---------------------------------------------------------------------------
  // APP LIFECYCLE HANDLER (resume + pause)
  // ---------------------------------------------------------------------------
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final biometricService = BiometricAuthService.instance;

    if (state == AppLifecycleState.paused) {
      // Invalidate the biometric session for security
      await biometricService?.invalidateBiometricSession();
    }

    if (state == AppLifecycleState.resumed) {
      // Only require biometric if user is logged in, biometric is enabled, 
      // AND there's no valid session
      final authService = AuthService.instance;
      final isLoggedIn = await authService.isLoggedIn();
      
      // Use explicit null checks and await
      final biometricEnabled = biometricService != null 
          ? await biometricService.isBiometricEnabled() 
          : false;
      final hasValidSession = biometricService != null 
          ? await biometricService.hasValidBiometricSession() 
          : false;

      if (isLoggedIn && biometricEnabled && !hasValidSession && mounted) {
        setState(() {
          _showBiometricLock = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BIOMETRIC UNLOCK CALLBACK
  // ---------------------------------------------------------------------------
  Future<void> _handleBiometricUnlock() async {
    final biometricService = BiometricAuthService.instance;
    await biometricService?.registerSuccessfulBiometricSession();

    setState(() {
      _showBiometricLock = false;
      _biometricAuthenticated = true;
    });
  }

  // ---------------------------------------------------------------------------
  // ROOT BUILD METHOD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    // Still loading initial state? Show splash.
    if (_loadingInitialState) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeService.themeMode,
        home: Scaffold(
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
              ],
            ),
          ),
        ),
      );
    }

    // If biometric lock required, render it *as the root page*
    if (_showBiometricLock) {
      return MaterialApp(
        navigatorKey: _navigatorKey,                 
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeService.themeMode,          
        home: BiometricLockScreen(
          onAuthSuccess: _handleBiometricUnlock,
        ),
        routes: { /* same routes map as below if needed */ },
      );
    }

    // Otherwise, load the normal app routing
    return MaterialApp(
      navigatorKey: _navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      home: const AuthWrapper(),
      // (Keep your routes unchanged)
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
  }
}
