// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'utils/logger.dart';

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
import 'services/theme_service.dart' as theme_svc;
import 'config/api_config.dart';
import 'config/environment_config.dart';
import 'config/local_server_config.dart';
import 'services/currency_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/service_stubs.dart' as stubs;
import 'utils/connection_manager.dart';
import 'services/enhanced_sync_service.dart';
import 'services/connectivity_service_new.dart' as conn_svc;
import 'services/sms_listener_service.dart';
import 'services/permissions_service.dart';
import 'utils/enum_adapters.dart' as enum_adapters;

// Screens
import 'screens/auth_wrapper.dart';
import 'screens/loan_calculator_screen.dart';
import 'screens/progressive_goal_wizard_screen.dart';
import 'screens/add_goal_screen.dart';
import 'screens/create_budget_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/sms_review_screen.dart';
import 'screens/spending_overview_screen.dart';
import 'screens/loans_tracker_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/transaction_entry_screen.dart';
import 'screens/detailed_transaction_entry_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/test_profiles_screen.dart';
import 'screens/connection_diagnostics_screen.dart';
import 'health_dashboard.dart';
import 'device_network_info.dart';
import 'ip_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging
  AppLogger.init();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(TransactionAdapter());
  // Use custom adapter instead of generated one to ensure enum compatibility
  Hive.registerAdapter(CustomTransactionCandidateAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(ProfileAdapter());
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(ClientAdapter());
  Hive.registerAdapter(InvoiceAdapter());
  Hive.registerAdapter(SyncQueueItemAdapter());
  // Generated enum adapters
  Hive.registerAdapter(ProfileTypeAdapter());
  Hive.registerAdapter(GoalTypeAdapter());
  Hive.registerAdapter(GoalStatusAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(PaymentMethodAdapter());
  Hive.registerAdapter(TransactionCategoryAdapter());
  Hive.registerAdapter(TransactionStatusAdapter());
  Hive.registerAdapter(RecurringTypeAdapter());
  Hive.registerAdapter(NotificationTypeAdapter());
  Hive.registerAdapter(AccountTypeAdapter());
  Hive.registerAdapter(InvoiceStatusAdapter());
  Hive.registerAdapter(enum_adapters.BudgetPeriodAdapter());
  Hive.registerAdapter(enum_adapters.BudgetStatusAdapter());

  // Open boxes
  await Hive.openBox<Profile>('profiles');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Goal>('goals');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Client>('clients');
  await Hive.openBox<Invoice>('invoices');
  await Hive.openBox<SyncQueueItem>('sync_queue');

  try {
    // Initialize environment configuration
    final envConfig = EnvironmentConfig.current();
    
    // Initialize services
    final authService = AuthService();
    await authService.initialize();
    
    // Initialize permissions service
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
    final tempApiClient = ApiClient(config: ApiConfig.development());
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
    } else if (envConfig.isProduction) {
      apiConfig = ApiConfig.production();
      logger.info('Using production connection');
    } else if (envConfig.type == EnvironmentType.staging) {
      apiConfig = ApiConfig.production().copyWith(enableDebugLogging: true);
      logger.info('Using staging connection with debug logging');
    } else {
      apiConfig = ApiConfig.development();
      logger.info('Using default development connection');
    }
    
    // Create API client with config
    final apiClient = ApiClient(config: apiConfig);
    final offlineDataService = OfflineDataService();
    final goalTransactionService = stubs.GoalTransactionService(offlineDataService);
    final textRecognitionService = stubs.TextRecognitionService(offlineDataService);
    final csvUploadService = stubs.CSVUploadService(offlineDataService);
    final smsTransactionExtractor = stubs.SmsTransactionExtractor(offlineDataService);
    final notificationService = stubs.NotificationService.instance;
    
    // Make sure we have a non-nullable instance
    final biometricAuthService = BiometricAuthService.instance!;
    await biometricAuthService.initialize();
    
    // Initialize SMS listener service
    final smsListenerService = SmsListenerService.instance;
    // Initialize will be called as needed
    
    final syncService = EnhancedSyncService(
      offlineDataService,
      apiClient,
    );
    // Services already initialized above
    final themeService = theme_svc.ThemeService.instance;
    final currencyService = CurrencyService();
    await currencyService.loadCurrency(); // Initialize currency service
    final navigationService = stubs.NavigationService.instance;
    final senderManagementService = stubs.SenderManagementService.instance;

    // Initialize offline manager for local calculations and parsing
    final offlineManager = stubs.OfflineManager();
    await offlineManager.initialize();

    // Initialize background transaction monitor (will be started after app loads)
    final backgroundTransactionMonitor = stubs.BackgroundTransactionMonitor(
      offlineDataService,
      smsTransactionExtractor,
    );

    // We already have a connectivity service initialized above
    // No need to create it again
    
    runApp(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider<OfflineDataService>.value(value: offlineDataService),
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
          Provider<BiometricAuthService>.value(value: biometricAuthService),
          ChangeNotifierProvider<PermissionsService>.value(value: permissionsService),
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider(create: (_) => themeService),
          ChangeNotifierProvider<CurrencyService>.value(value: currencyService),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializationFuture = _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      // Store references to providers before any awaits to avoid context usage across async gaps
      final offlineService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final smsListenerService = Provider.of<stubs.SmsListenerService>(context, listen: false);
      final backgroundMonitor = Provider.of<stubs.BackgroundTransactionMonitor>(context, listen: false);
      
      // Now we can use awaits safely
      await offlineService.initialize();
      await authService.initialize();

      // Check if user is logged in and set current profile
      if (authService.isLoggedIn() && authService.currentProfile != null) {
        final currentProfile = authService.currentProfile!;
        
        // Set current profile for SMS listener
        smsListenerService.setCurrentProfile(currentProfile.id);

        // Initialize background monitor if needed
        try {
          await backgroundMonitor.initialize();
        } catch (e) {
          if (kDebugMode) {
            print('Background monitor initialization failed: $e');
          }
        }
      }
      
      // Services initialized successfully
    } catch (e) {
      if (kDebugMode) {
        print('Service initialization error: $e');
      }
      // Continue even if there are errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<theme_svc.ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Fedha',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007A39)), // Fedha green
            useMaterial3: true,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A39),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          darkTheme: ThemeData.dark(
            useMaterial3: true,
          ),
          themeMode: themeService.themeMode,
          routes: {
            '/loan_calculator': (context) => const LoanCalculatorScreen(),
            '/progressive_goal_wizard': (context) => const ProgressiveGoalWizardScreen(),
            '/add_goal': (context) => const AddGoalScreen(),
            '/create_budget': (context) => const CreateBudgetScreen(),
            '/goals': (context) => const GoalsScreen(),
            '/sms_review': (context) => const SmsReviewScreen(),
            '/add_transaction': (context) => const AddTransactionScreen(),
            '/transaction_entry': (context) => const TransactionEntryScreen(),
            '/detailed_transaction_entry': (context) => const DetailedTransactionEntryScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/test_profiles': (context) => const TestProfilesScreen(),
            '/spending_overview': (context) => const SpendingOverviewScreen(),
            '/loans_tracker': (context) => const LoansTrackerScreen(),
            '/connection_diagnostics': (context) => ConnectionDiagnosticsScreen(
              apiClient: Provider.of<ApiClient>(context, listen: false),
            ),
            '/health_dashboard': (context) => const HealthDashboard(),
            '/device_network_info': (context) => const DeviceInfoScreen(),
            '/ip_settings': (context) => const IpSettingsScreen(),
          },
          home: FutureBuilder<void>(
            future: _initializationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initializationFuture = _initializeServices();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return const AuthWrapper();
            },
          ),
        );
      },
    );
  }
}
