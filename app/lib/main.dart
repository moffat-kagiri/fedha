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
import 'package:flutter/widgets.dart'; 
import 'package:provider/single_child_widget.dart';

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
import 'services/unified_sync_service.dart';
import 'services/connectivity_service.dart' as conn_svc;
import 'services/sms_listener_service.dart';
import 'services/permissions_service.dart';
import 'theme/app_theme.dart';
import 'services/risk_assessment_service.dart';
import 'services/profile_management_extension.dart';
import 'services/budget_service.dart';
import 'data/app_database.dart' as data_db;

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
import 'screens/budget_progress_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/connection_test_screen.dart';

// ADDED: canonical main navigation route
import 'screens/main_navigation.dart';

// ==================== BACKGROUND TASK DISPATCHER ====================

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'daily_review_task') {
        final prefs = await SharedPreferences.getInstance();
        final profileId = prefs.getString('current_profile_id') ?? '';
        
        if (profileId.isEmpty) return Future.value(false);

        final offline = OfflineDataService();
        await offline.initialize();
        final pendingCount = await offline.getPendingTransactionCount(profileId);

        await NotificationService.instance.initialize();
        await NotificationService.instance.showPendingTransactionsNotification(pendingCount);
        return Future.value(true);
      }

      if (task == 'sms_listener_task') {
        return Future.value(true);
      }
    } catch (e) {
      if (kDebugMode) print('Background task error: $e');
      return Future.value(false);
    }
    return Future.value(true);
  });
}

// ==================== MAIN ENTRY POINT ====================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Provider.debugCheckInvalidValueType = null;
  AppLogger.init();
  final logger = AppLogger.getLogger('Main');

  try {
    logger.info('🚀 Starting Fedha app...');
    
    // Initialize WorkManager
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    logger.info('✅ WorkManager initialized');

    // Initialize all services
    await _initializeServices();

    // Determine biometric requirements
    final authService = AuthService.instance;
    final biometricAuthService = BiometricAuthService.instance;
    
    final isLoggedIn = authService.hasActiveProfile;
    final biometricEnabled = biometricAuthService != null
        ? await biometricAuthService.isBiometricEnabled()
        : false;
    final hasValidSession = biometricAuthService != null
        ? await biometricAuthService.hasValidBiometricSession()
        : false;
    
    final requireBiometricOnLaunch = isLoggedIn && biometricEnabled && !hasValidSession;
    
    logger.info('''
╔════════════════════════════════════════════════════════════════
║ Auth State Summary
╠════════════════════════════════════════════════════════════════
║ Logged in: $isLoggedIn
║ Biometric enabled: $biometricEnabled
║ Valid session: $hasValidSession
║ Require unlock: $requireBiometricOnLaunch
╚════════════════════════════════════════════════════════════════
    ''');

    logger.info('✅ All services initialized successfully');
    logger.info('🎉 Launching app...');
    
    runApp(
      MultiProvider(
        providers: _buildProviders(),
        child: MyApp(requireBiometricOnLaunch: requireBiometricOnLaunch),
      ),
    );
  } catch (e, stackTrace) {
    logger.severe('❌ App initialization failed', e, stackTrace);
    _launchErrorApp(e);
  }
}

// ==================== SERVICE INITIALIZATION ====================

Future<void> _initializeServices() async {
  final logger = AppLogger.getLogger('ServiceInit');
  
  // ==================== CORE SERVICES ====================
  logger.info('Initializing core services...');
  
  final offlineDataService = OfflineDataService();
  await offlineDataService.initialize();
  logger.info('✅ Offline data service initialized');
  
  final biometricAuthService = BiometricAuthService.instance;
  await biometricAuthService?.initialize();
  logger.info('✅ Biometric auth service initialized');
  
  final permissionsService = PermissionsService.instance;
  await permissionsService.initialize();
  logger.info('✅ Permissions service initialized');
  
  final themeService = ThemeService.instance;
  await themeService.initialize();
  logger.info('✅ Theme service initialized');

  // ==================== NETWORK SERVICES ====================
  await _initializeNetworkServices();

  // ==================== SYNC & BUDGET SERVICES ====================
  final apiClient = ApiClient.instance;
  
  final unifiedSyncService = UnifiedSyncService.instance;
  await unifiedSyncService.initialize(
    offlineDataService: offlineDataService,
    apiClient: apiClient,
    authService: AuthService.instance,
  );
  logger.info('✅ Sync service initialized');

  final budgetService = BudgetService.instance;
  await budgetService.initialize(offlineDataService);
  logger.info('✅ Budget service initialized');

  // ==================== AUTH SERVICE (WITH ALL DEPENDENCIES) ====================
  final authService = AuthService.instance;
  await authService.initializeWithAllDependencies(
    offlineDataService: offlineDataService,
    biometricService: biometricAuthService,
    syncService: unifiedSyncService,
    budgetService: budgetService,
  );
  logger.info('✅ Auth service initialized with all dependencies');

  // ==================== STUB SERVICES ====================
  // Initialize stub services (these are local-only)
  final goalTransactionService = stubs.GoalTransactionService(offlineDataService);
  final textRecognitionService = stubs.TextRecognitionService(offlineDataService);
  final csvUploadService = stubs.CSVUploadService(offlineDataService);
  final smsTransactionExtractor = stubs.SmsTransactionExtractor(offlineDataService);
  logger.info('✅ Stub services initialized');

  // ==================== DATABASE & RISK SERVICES ====================
  final mainDb = data_db.AppDatabase();
  final riskAssessmentService = RiskAssessmentService(mainDb);
  logger.info('✅ Database and risk assessment services initialized');

  // ==================== BACKGROUND TASKS ====================
  if (authService.hasActiveProfile && authService.profileId != null) {
    logger.info('Registering background tasks for profile: ${authService.profileId}');
    await _registerBackgroundTasks(authService.profileId!);
  }
}

/// Initialize network services and find optimal connection
Future<void> _initializeNetworkServices() async {
  final logger = AppLogger.getLogger('NetworkInit');
  
  // ==================== STEP 1: Initialize API Client ====================
  final apiClient = ApiClient.instance;
  
  // Set initial config based on build mode
  final initialConfig = kDebugMode 
      ? ApiConfig.development() 
      : ApiConfig.production();
  
  apiClient.init(config: initialConfig);
  logger.info('API client initialized with ${kDebugMode ? "development" : "production"} config');
  
  // ==================== STEP 2: Check Connectivity ====================
  final connectivityService = conn_svc.ConnectivityService(apiClient);
  await connectivityService.initialize();
  
  final hasConnectivity = await connectivityService.hasInternetConnection();
  logger.info('Internet connectivity: ${hasConnectivity ? "✅ Available" : "❌ Unavailable"}');
  
  // ==================== STEP 3: Find Best Connection (Development Only) ====================
  if (hasConnectivity && kDebugMode) {
    logger.info('Development mode: Searching for best connection...');
    
    try {
      final bestConnectionUrl = await ConnectionManager.findWorkingConnection();
      
      if (bestConnectionUrl != null) {
        logger.info('✅ Found working connection: $bestConnectionUrl');
        
        // Determine appropriate config based on connection type
        final ApiConfig optimalConfig;
        
        if (bestConnectionUrl.contains('trycloudflare.com')) {
          // Cloudflare tunnel detected
          logger.info('Using Cloudflare tunnel configuration');
          optimalConfig = ApiConfig.cloudflare(tunnelUrl: bestConnectionUrl);
          
        } else if (bestConnectionUrl.contains('192.168.') || 
                   bestConnectionUrl.contains('10.0.2.2') ||
                   bestConnectionUrl.contains('localhost')) {
          // Local network detected
          logger.info('Using local network configuration');
          optimalConfig = ApiConfig.development().copyWith(
            primaryApiUrl: _extractHost(bestConnectionUrl),
          );
          
        } else {
          // Custom host
          logger.info('Using custom host configuration');
          optimalConfig = ApiConfig.custom(
            apiUrl: _extractHost(bestConnectionUrl),
            useSecureConnections: bestConnectionUrl.startsWith('https'),
          );
        }
        
        // Apply optimal config
        apiClient.init(config: optimalConfig);
        logger.info('API client reconfigured with optimal connection');
        
        // Verify the connection works
        final isHealthy = await apiClient.checkServerHealth();
        if (isHealthy) {
          logger.info('✅ Server health check passed');
        } else {
          logger.warning('⚠️ Server health check failed, falling back to initial config');
          apiClient.init(config: initialConfig);
        }
        
      } else {
        logger.warning('No working connection found, using initial config');
      }
      
    } catch (e, stackTrace) {
      logger.severe('Error finding optimal connection', e, stackTrace);
      logger.info('Falling back to initial configuration');
      // Keep initial config
    }
  }
  
  // ==================== STEP 4: Final Status ====================
  final finalConfig = apiClient.config;
  logger.info('''
╔════════════════════════════════════════════════════════════════
║ Network Configuration Complete
╠════════════════════════════════════════════════════════════════
║ Environment: ${kDebugMode ? "Development" : "Production"}
║ Base URL: ${apiClient.baseUrl}
║ Secure: ${finalConfig.useSecureConnections}
║ Timeout: ${finalConfig.timeoutSeconds}s
║ Connected: ${hasConnectivity ? "Yes" : "No"}
╚════════════════════════════════════════════════════════════════
  ''');
}

/// Extract host from full URL
String _extractHost(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host + (uri.hasPort ? ':${uri.port}' : '');
  } catch (e) {
    // If parsing fails, return as-is
    return url.replaceAll(RegExp(r'https?://'), '').split('/')[0];
  }
}

// ==================== PROVIDER SETUP ====================

List<SingleChildWidget> _buildProviders() {
  return [
    Provider<ApiClient>.value(value: ApiClient.instance),
    Provider<OfflineDataService>.value(value: OfflineDataService()),
    Provider<conn_svc.ConnectivityService>.value(
      value: conn_svc.ConnectivityService(ApiClient.instance),
    ),
    Provider<stubs.GoalTransactionService>.value(
      value: stubs.GoalTransactionService(OfflineDataService()),
    ),
    Provider<stubs.TextRecognitionService>.value(
      value: stubs.TextRecognitionService(OfflineDataService()),
    ),
    Provider<stubs.CSVUploadService>.value(
      value: stubs.CSVUploadService(OfflineDataService()),
    ),
    Provider<stubs.SmsTransactionExtractor>.value(
      value: stubs.SmsTransactionExtractor(OfflineDataService()),
    ),
    Provider<stubs.NotificationService>.value(
      value: stubs.NotificationService.instance,
    ),
    Provider<stubs.NavigationService>.value(
      value: stubs.NavigationService.instance,
    ),
    Provider<stubs.SenderManagementService>.value(
      value: stubs.SenderManagementService.instance,
    ),
    Provider<stubs.BackgroundTransactionMonitor>.value(
      value: stubs.BackgroundTransactionMonitor(
        OfflineDataService(),
        stubs.SmsTransactionExtractor(OfflineDataService()),
      ),
    ),
    Provider<BiometricAuthService>.value(
      value: BiometricAuthService.instance!,
    ),
    Provider<CurrencyService>.value(value: CurrencyService()),
    Provider<RiskAssessmentService>.value(
      value: RiskAssessmentService(data_db.AppDatabase()),
    ),
    ChangeNotifierProvider<SmsListenerService>.value(
      value: SmsListenerService.instance,
    ),
    ChangeNotifierProvider<UnifiedSyncService>.value(
      value: UnifiedSyncService.instance,
    ),
    ChangeNotifierProvider<PermissionsService>.value(
      value: PermissionsService.instance,
    ),
    ChangeNotifierProvider<AuthService>.value(
      value: AuthService.instance,
    ),
    ChangeNotifierProvider<ThemeService>.value(
      value: ThemeService.instance,
    ),
    ChangeNotifierProvider<BudgetService>.value(
      value: BudgetService.instance,
    ),
  ];
}

// ==================== BACKGROUND TASKS ====================

Future<void> _registerBackgroundTasks(String profileId) async {
  final logger = AppLogger.getLogger('BackgroundTasks');
  
  try {
    await Workmanager().cancelAll();
    
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
    
    await Workmanager().registerPeriodicTask(
      'daily_review',
      'daily_review_task',
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(hours: 1),
      inputData: {'profileId': profileId},
    );
    
    logger.info('✅ Background tasks registered for profile: $profileId');
  } catch (e) {
    logger.warning('⚠️ Failed to register background tasks: $e');
  }
}

// ==================== ERROR APP ====================

void _launchErrorApp(dynamic error) {
  runApp(
    MaterialApp(
      theme: AppTheme.lightTheme,
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
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => main(),
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

// ==================== MY APP ====================

class MyApp extends StatefulWidget {
  final bool requireBiometricOnLaunch;

  const MyApp({super.key, required this.requireBiometricOnLaunch});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _logger = AppLogger.getLogger('MyApp');

  bool _showBiometricOverlay = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    _logger.info('MyApp initializing...');
    
    setState(() {
      _showBiometricOverlay = widget.requireBiometricOnLaunch;
      _isInitializing = false;
    });
    
    _logger.info('MyApp ready - Biometric overlay: $_showBiometricOverlay');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    _logger.info('App lifecycle state: $state');
    
    final authService = context.read<AuthService>();
    final biometricService = context.read<BiometricAuthService>();

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        await biometricService.invalidateBiometricSession();
        _logger.info('Biometric session invalidated');
        break;

      case AppLifecycleState.resumed:
        final isLoggedIn = authService.hasActiveProfile;
        final biometricEnabled = await biometricService.isBiometricEnabled();
        final hasValidSession = await biometricService.hasValidBiometricSession();

        if (isLoggedIn && biometricEnabled && !hasValidSession) {
          if (mounted) {
            setState(() {
              _showBiometricOverlay = true;
            });
            _logger.info('Biometric overlay shown on resume');
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

  Future<void> _handleBiometricUnlock() async {
    _logger.info('✅ Biometric unlock successful');
    
    final biometricService = context.read<BiometricAuthService>();
    final authService = context.read<AuthService>();
    final syncService = context.read<UnifiedSyncService>();
    final budgetService = context.read<BudgetService>();
    
    await biometricService.registerSuccessfulBiometricSession();

    // Reload all data after unlock
    if (authService.profileId != null) {
      _logger.info('Reloading data after biometric unlock...');
      await syncService.syncAll();
      await budgetService.loadBudgetsForProfile(authService.profileId!);
    }

    // Use centralized navigation helper to ensure canonical main route
    _navigateToCanonicalMain();

    if (mounted) {
      setState(() {
        _showBiometricOverlay = false;
      });
    }
  }

  // NEW: central helper to ensure the app shows the canonical main route (with bottom nav)
  void _navigateToCanonicalMain() {
    final navigator = _navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil('/main', (route) => false);
      return;
    }

    // Fallback: schedule navigation after frame if navigator not yet available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
      } catch (e) {
        _logger.warning('Failed to navigate to canonical main route: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    if (_isInitializing) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeService.themeMode,
        home: _buildSplashScreen(),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            if (_showBiometricOverlay)
              _buildBiometricOverlay(),
          ],
        );
      },
      home: const AuthWrapper(),
      routes: _buildRoutes(),
    );
  }

  Widget _buildBiometricOverlay() {
    return Material(
      child: BiometricLockScreen(
        onAuthSuccess: _handleBiometricUnlock,
      ),
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/icons/fedha_logo.svg', height: 100),
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
      // Canonical main route for the app (bottom navigation)
      '/main': (context) => const MainNavigation(),
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
      '/device_network_info': (context) => const DeviceInfoScreen(),
      '/ip_settings': (context) => const IpSettingsScreen(),
      '/connection_test': (context) => const ConnectionTestScreen(),
      '/debt_repayment_planner': (context) => const DebtRepaymentPlannerScreen(),
      '/asset_protection': (context) => AssetProtectionIntroScreen(),
      '/asset_protection_intro': (context) => AssetProtectionIntroScreen(),
      '/asset_protection_health': (context) => HealthCoverScreen(),
      '/asset_protection_vehicle': (context) => VehicleCoverScreen(),
      '/asset_protection_home': (context) => HomeCoverScreen(),
      '/emergency-fund': (context) => const EmergencyFundScreen(),
      '/sms_review': (context) => const SmsReviewScreen(),
      '/budget_progress': (context) => const BudgetProgressScreen(),
      '/analytics': (context) => const AnalyticsScreen(),
    };
  }
}