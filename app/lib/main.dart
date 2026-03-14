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
import 'package:provider/single_child_widget.dart';
import 'dart:async' show unawaited;

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
import 'services/transaction_event_service.dart';
import 'services/goal_transaction_service.dart';
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
import 'screens/budget_management_screen.dart';
import 'screens/budget_review_screen.dart';

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

  // ✅ FAST PATH: Only initialize what's needed to show first frame
  await OfflineDataService().initialize();

  Provider.debugCheckInvalidValueType = null;
  AppLogger.init();
  final logger = AppLogger.getLogger('Main');

  try {
    logger.info('🚀 Starting Fedha app...');

    // WorkManager init is fast (no network) — keep on critical path
    await Workmanager().initialize(callbackDispatcher);

    // ✅ Initialize all LOCAL services synchronously
    await _initializeLocalServices();

    // ✅ Resolve auth/biometric state from local storage only (no network)
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

    logger.info('✅ Local services ready — launching app');

    // ✅ Launch the app immediately with local data
    runApp(
      MultiProvider(
        providers: _buildProviders(),
        child: MyApp(requireBiometricOnLaunch: requireBiometricOnLaunch),
      ),
    );

    // ✅ Network discovery runs AFTER first frame is painted — never blocks UI
    unawaited(_initializeNetworkServicesInBackground());

  } catch (e, stackTrace) {
    logger.severe('❌ App initialization failed', e, stackTrace);
    _launchErrorApp(e);
  }
}

// ==================== LOCAL-ONLY SERVICE INITIALIZATION ====================
// Everything here reads from disk or memory only. No network calls. No timeouts.
// This runs on the critical path before runApp.

Future<void> _initializeLocalServices() async {
  final logger = AppLogger.getLogger('ServiceInit');

  logger.info('Initializing local services...');

  // These are all local/disk operations — fast and safe offline
  final biometricAuthService = BiometricAuthService.instance;
  await biometricAuthService?.initialize();
  logger.info('✅ Biometric auth service initialized');

  final permissionsService = PermissionsService.instance;
  await permissionsService.initialize();
  logger.info('✅ Permissions service initialized');

  final themeService = ThemeService.instance;
  await themeService.initialize();
  logger.info('✅ Theme service initialized');

  // Auth service restores profile from SharedPreferences — no network needed
  final authService = AuthService.instance;
  await authService.initializeWithDependencies(
    offlineDataService: OfflineDataService(),
    biometricService: BiometricAuthService.instance,
  );
  logger.info('✅ Auth service initialized');

  // Sync and budget services initialize their local state only
  final apiClient = ApiClient.instance;
  final offlineDataService = OfflineDataService();

  // ✅ Init API client with config only — no health check here
  final initialConfig = kDebugMode
      ? ApiConfig.development()
      : ApiConfig.production();
  apiClient.init(config: initialConfig);
  logger.info('✅ API client configured (no connection test)');

  final unifiedSyncService = UnifiedSyncService.instance;
  await unifiedSyncService.initialize(
    offlineDataService: offlineDataService,
    apiClient: apiClient,
    authService: authService,
  );
  logger.info('✅ Sync service initialized');

  offlineDataService.setSyncService(unifiedSyncService);

  final budgetService = BudgetService.instance;
  await budgetService.initialize(offlineDataService);
  logger.info('✅ Budget service initialized');

  logger.info('✅ All local services ready');
}


// ==================== BACKGROUND NETWORK INITIALIZATION ====================
// Runs after runApp — the UI is already visible. Any delay here is invisible
// to the user. ConnectivityService and sync will notify listeners when ready.

Future<void> _initializeNetworkServicesInBackground() async {
  final logger = AppLogger.getLogger('NetworkInit');

  try {
    logger.info('🌐 Starting background network initialization...');

    final apiClient = ApiClient.instance;

    // Step 1: Fast connectivity check using the platform's network status
    // (connectivity_plus reads the OS — no HTTP request, near-instant)
    final connectivityService = conn_svc.ConnectivityService(apiClient);
    await connectivityService.initialize();

    final hasConnectivity = await connectivityService.hasInternetConnection();
    logger.info('Internet: ${hasConnectivity ? "✅ Available" : "❌ Unavailable"}');

    if (!hasConnectivity) {
      logger.info('Offline — skipping server discovery');
      return;
    }

    // Step 2: In debug mode, probe for the best local endpoint.
    // Use a short overall timeout cap so even a slow LAN doesn't hang here.
    if (kDebugMode) {
      logger.info('Dev mode: probing for best connection (capped at 5s)...');

      try {
        final bestConnectionUrl = await ConnectionManager
            .findWorkingConnection()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                logger.warning('Connection probe timed out — using default config');
                return null;
              },
            );

        if (bestConnectionUrl != null) {
          final ApiConfig optimalConfig;

          if (bestConnectionUrl.contains('trycloudflare.com')) {
            optimalConfig = ApiConfig.cloudflare(tunnelUrl: bestConnectionUrl);
          } else if (bestConnectionUrl.contains('192.168.') ||
              bestConnectionUrl.contains('10.0.2.2') ||
              bestConnectionUrl.contains('localhost')) {
            optimalConfig = ApiConfig.development().copyWith(
              primaryApiUrl: _extractHost(bestConnectionUrl),
            );
          } else {
            optimalConfig = ApiConfig.custom(
              apiUrl: _extractHost(bestConnectionUrl),
              useSecureConnections: bestConnectionUrl.startsWith('https'),
            );
          }

          apiClient.init(config: optimalConfig);
          logger.info('✅ API client reconfigured: $bestConnectionUrl');

          // Quick health verify — also capped
          final isHealthy = await apiClient
              .checkServerHealth()
              .timeout(
                const Duration(seconds: 3),
                onTimeout: () => false,
              );

          if (!isHealthy) {
            logger.warning('Health check failed — reverting to default config');
            final fallback = kDebugMode
                ? ApiConfig.development()
                : ApiConfig.production();
            apiClient.init(config: fallback);
          }
        }
      } catch (e) {
        logger.warning('Connection probe error (non-fatal): $e');
      }
    }

    // Step 3: If user is logged in, trigger background sync now that
    // network is confirmed available.
    final authService = AuthService.instance;
    if (authService.hasActiveProfile && authService.profileId != null) {
      logger.info('🔄 Triggering post-startup background sync...');
      unawaited(_runPostStartupSync(authService.profileId!));
    }

    logger.info('✅ Background network initialization complete');
  } catch (e, stackTrace) {
    logger.warning('Background network init failed (non-fatal): $e', e, stackTrace);
    // Never rethrow — the app is already running fine with local data
  }
}


// ==================== POST-STARTUP SYNC ====================
// Called only after network is confirmed. Keeps startup clean.
Future<void> _runPostStartupSync(String profileId) async {
  final logger = AppLogger.getLogger('PostStartupSync');

  try {
    final offlineDataService = OfflineDataService();
    final unifiedSyncService = UnifiedSyncService.instance;
    final budgetService = BudgetService.instance;
    final transactionEventService = TransactionEventService();

    unifiedSyncService.setCurrentProfile(profileId);

    final syncResult = await unifiedSyncService.syncAll();
    if (syncResult.success) {
      logger.info('✅ Post-startup sync complete. '
          'Downloaded: ${syncResult.totalDownloaded}, '
          'Uploaded: ${syncResult.totalUploaded}');
    }

    // Use the correct service and method name
    await transactionEventService.recalculateAll(profileId);
    await budgetService.loadBudgetsForProfile(profileId);

    await _registerBackgroundTasks(profileId);

    final smsService = SmsListenerService.instance;
    await smsService.startListening(
      offlineDataService: offlineDataService,
      profileId: profileId,
    );

    logger.info('✅ Post-startup background processing complete');
  } catch (e, stackTrace) {
    logger.warning('Post-startup sync failed (non-fatal)', e, stackTrace);
  }
}

Future<void> _initializeNetworkServices() async {
  final logger = AppLogger.getLogger('NetworkInit');
  // ==================== STEP 1: Initialize API Client ====================
  
  final apiClient = ApiClient.instance;

  final initialConfig = kDebugMode 
      ? ApiConfig.development() 
      : ApiConfig.production();
  
  apiClient.init(config: initialConfig);
  logger.info('API client initialized with ${kDebugMode ? "development" : "production"} config');
  
  // Set initial config based on build mode
  
  final connectivityService = conn_svc.ConnectivityService(apiClient);
  await connectivityService.initialize();
  
  final hasConnectivity = await connectivityService.hasInternetConnection();
  logger.info('Internet connectivity: ${hasConnectivity ? "✅ Available" : "❌ Unavailable"}');

  if (hasConnectivity && kDebugMode) {
    logger.info('Development mode: Searching for best connection...');
    
    try {
      final bestConnectionUrl = await ConnectionManager.findWorkingConnection();
      
      if (bestConnectionUrl != null) {
        logger.info('✅ Found working connection: $bestConnectionUrl');
  // ==================== STEP 3: Find Best Connection (Development Only) ====================

        final ApiConfig optimalConfig;
        
        if (bestConnectionUrl.contains('trycloudflare.com')) {
          logger.info('Using Cloudflare tunnel configuration');
          optimalConfig = ApiConfig.cloudflare(tunnelUrl: bestConnectionUrl);
        } else if (bestConnectionUrl.contains('192.168.') || 
                   bestConnectionUrl.contains('10.0.2.2') ||
                   bestConnectionUrl.contains('localhost')) {
          logger.info('Using local network configuration');
          optimalConfig = ApiConfig.development().copyWith(
            primaryApiUrl: _extractHost(bestConnectionUrl),
        );
      } else {
          logger.info('Using custom host configuration');
          optimalConfig = ApiConfig.custom(
            apiUrl: _extractHost(bestConnectionUrl),
            useSecureConnections: bestConnectionUrl.startsWith('https'),
          );
        }
        
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
      }
    
    } catch (e, stackTrace) {
      logger.severe('Error finding optimal connection', e, stackTrace);
    }
  }
}

String _extractHost(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host + (uri.hasPort ? ':${uri.port}' : '');
  } catch (e) {
    return url.replaceAll(RegExp(r'https?://'), '').split('/')[0];
  }
}

// ==================== PROVIDER SETUP ====================

List<SingleChildWidget> _buildProviders() {
  return [
    Provider<OfflineDataService>.value(
      value: OfflineDataService(), // Returns the singleton instance
    ),
    Provider<ApiClient>.value(value: ApiClient.instance),
    Provider<conn_svc.ConnectivityService>.value(
      value: conn_svc.ConnectivityService(ApiClient.instance),
    ),
    Provider<GoalTransactionService>.value(
      value: GoalTransactionService(OfflineDataService()),
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
    ChangeNotifierProvider<TransactionEventService>(
      create: (_) => TransactionEventService(),
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

// ==================== BACKGROUND TASK REGISTRATION (Updated) ====================

Future<void> _registerBackgroundTasks(String profileId) async {
  final logger = AppLogger.getLogger('BackgroundTasks');
  
  try {
    // Cancel all existing tasks first
    await Workmanager().cancelAll();
    logger.info('Cancelled existing background tasks');
    
    // ==================== SMS LISTENER TASK (HIGH FREQUENCY) ====================
    // This runs frequently to catch SMS messages quickly
    await Workmanager().registerPeriodicTask(
      'sms_listener',
      'sms_listener_task',
      frequency: const Duration(minutes: 15), // Minimum allowed by WorkManager
      initialDelay: const Duration(seconds: 30), // Start quickly
      constraints: Constraints(
        networkType: NetworkType.notRequired, // Works offline
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false, // Less restrictive
      ),
      inputData: {
        'profileId': profileId,
        'task_type': 'sms_processing',
      },
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
    
    logger.info('✅ SMS listener task registered');
    
    // ==================== DAILY REVIEW TASK ====================
    // This sends notifications once per day
    await Workmanager().registerPeriodicTask(
      'daily_review',
      'daily_review_task',
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: true,
      ),
      inputData: {
        'profileId': profileId,
        'task_type': 'daily_notification',
      },
    );
    
    logger.info('✅ Daily review task registered');
    
    // ==================== SYNC TASK (BACKGROUND SYNC) ====================
    // This runs periodically to sync data in background
    await Workmanager().registerPeriodicTask(
      'background_sync',
      'background_sync_task',
      frequency: const Duration(hours: 4), // Sync every 4 hours
      initialDelay: const Duration(minutes: 5),
      constraints: Constraints(
        networkType: NetworkType.connected, // Needs network for sync
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: true, // Sync when device is idle
        requiresStorageNotLow: false,
      ),
      inputData: {
        'profileId': profileId,
        'task_type': 'background_sync',
      },
    );
    
    logger.info('✅ Background sync task registered');
    
    // ==================== ONE-TIME IMMEDIATE TASK ====================
    // Process SMS immediately on registration
    await Workmanager().registerOneOffTask(
      'sms_immediate',
      'sms_listener_task',
      initialDelay: const Duration(seconds: 5),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      inputData: {
        'profileId': profileId,
        'task_type': 'immediate_check',
      },
    );

    logger.info('✅ All background tasks registered for profile: $profileId');
  } catch (e, stackTrace) {
    logger.severe('⚠️ Failed to register background tasks', e, stackTrace);
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
        
        // SMS listener continues in background via WorkManager
        _logger.info('Background SMS processing will continue');
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
        } else if (isLoggedIn) {
          // 🔴 CRITICAL: Set profile for sync service on resume
          final syncService = context.read<UnifiedSyncService>();
          if (authService.profileId != null) {
            syncService.setCurrentProfile(authService.profileId!);
          }
          
          // Restart foreground SMS listener
          _restartForegroundSmsListener();
          
          // 🔴 CRITICAL: Trigger sync on resume
          _syncDataOnResume(authService.profileId);
        }
        break;

      default:
        break;
    }
  }
  
  /// 🔴 NEW: Sync data when app resumes
  Future<void> _syncDataOnResume(String? profileId) async {
    if (profileId == null) return;
    
    try {
      final syncService = context.read<UnifiedSyncService>();
      
      // Only sync if last sync was more than 30 minutes ago
      final lastSyncTime = syncService.lastSyncTime;
      final shouldSync = lastSyncTime == null || 
          DateTime.now().difference(lastSyncTime) > const Duration(minutes: 30);
      
      if (shouldSync) {
        _logger.info('🔄 Syncing data on resume...');
        final result = await syncService.syncAll();
        if (result.success) {
          _logger.info('✅ Resume sync successful. Downloaded: ${result.totalDownloaded}');
        }
      } else {
        _logger.info('Skipping resume sync - last sync was recent');
      }
    } catch (e) {
      _logger.warning('Resume sync failed (non-critical): $e');
    }
  }
  
  /// Restart foreground SMS listener when app resumes
  Future<void> _restartForegroundSmsListener() async {
    try {
      final authService = context.read<AuthService>();
      final offlineService = context.read<OfflineDataService>();
      
      if (authService.profileId != null) {
        final smsService = SmsListenerService.instance;
        await smsService.startListening(
          offlineDataService: offlineService,
          profileId: authService.profileId!,
        );
        _logger.info('✅ Foreground SMS listener restarted');
      }
    } catch (e, stackTrace) {
      _logger.warning('Failed to restart SMS listener', e, stackTrace);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// ⭐ FIXED: Instant navigation after biometric unlock
  /// Data syncing happens in background after navigation
  Future<void> _handleBiometricUnlock() async {
    _logger.info('✅ Biometric unlock successful');
    
    final authService = context.read<AuthService>();
    final syncService = context.read<UnifiedSyncService>();
    
    // 🔴 CRITICAL: Set profile for sync service
    if (authService.profileId != null) {
      syncService.setCurrentProfile(authService.profileId!);
    }
    
    // Navigate FIRST - instant response
    _navigateToCanonicalMain();
    
    // Hide overlay
    if (mounted) {
      setState(() {
        _showBiometricOverlay = false;
      });
    }

    // Set biometric session, NO SYNC HERE - we will sync in background after 
    // CRUD operations to avoid duplicate sync calls on resume and unlock
    Future.microtask(() async {
        final biometricService = context.read<BiometricAuthService>();
        await biometricService.registerSuccessfulBiometricSession();

        // ✅ Removed sync from here to avoid duplicate sync calls on resume and unlock
    });
  }

  /// ⭐ NEW: Background data sync after biometric unlock
  /// This runs asynchronously without blocking navigation
  Future<void> _syncDataInBackground() async {
    try {
      _logger.info('🔄 Syncing data in background...');
      
      final authService = context.read<AuthService>();
      final syncService = context.read<UnifiedSyncService>();
      final budgetService = context.read<BudgetService>();
      
      if (authService.profileId != null) {
        // Sync data without blocking UI
        final syncResult = await syncService.syncAll();
        if (syncResult.success) {
          _logger.info('✅ Background sync complete. Downloaded: ${syncResult.totalDownloaded}');
        }
        
        await budgetService.loadBudgetsForProfile(authService.profileId!);
        
        _logger.info('✅ Background processing complete');
      }
    } catch (e, stackTrace) {
      _logger.warning('Background sync failed (non-critical)', e, stackTrace);
      // Don't show error to user - app still works with local data
    }
  }

  /// Navigate to main screen
  void _navigateToCanonicalMain() {
    final navigator = _navigatorKey.currentState;
    if (navigator != null) {
      // Use pushReplacement for instant transition
      navigator.pushNamedAndRemoveUntil('/main', (route) => false);
      return;
    }

    // Fallback: schedule navigation after frame
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
      '/budget_management': (context) => const BudgetManagementScreen(),
      '/budget_review': (context) {
        final budget = ModalRoute.of(context)!.settings.arguments as Budget;
        return BudgetReviewScreen(budget: budget);
      },
    };
  }
}
