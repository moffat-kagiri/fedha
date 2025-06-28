// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Models
import 'models/profile.dart';
import 'models/enhanced_profile.dart';
import 'models/transaction.dart';
import 'models/transaction_candidate.dart'; // Re-enabled with fixed typeId
import 'models/category.dart';
import 'models/client.dart';
import 'models/invoice.dart';
import 'models/goal.dart';
import 'models/budget.dart';
import 'models/sync_queue_item.dart';

// Enum Adapters
import 'adapters/enum_adapters.dart' as enum_adapters;

// Services
import 'services/auth_service.dart';
// import 'services/google_drive_service.dart';
import 'services/api_client.dart';
import 'services/offline_data_service.dart';
import 'services/enhanced_sync_service.dart';
import 'services/goal_transaction_service.dart';
import 'services/text_recognition_service.dart';
import 'services/csv_upload_service.dart';
import 'services/background_transaction_monitor.dart'; // Background service
import 'services/sms_transaction_extractor.dart';
import 'services/sms_listener_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/offline_manager.dart'; // Offline functionality
import 'services/navigation_service.dart';
import 'services/sender_management_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/background_sms_service.dart'; // New background SMS service
import 'services/background_sync_service.dart'; // Background sync service

// Screens
import 'screens/onboarding_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/auth_wrapper.dart';
import 'screens/profile_screen.dart';
import 'screens/permission_setup_screen.dart';
import 'screens/text_recognition_setup_screen.dart';
import 'screens/transaction_candidates_screen.dart';
import 'screens/csv_upload_screen.dart';
import 'screens/test_transaction_ingestion_screen.dart';
// Utils
// import 'utils/theme.dart'; // Using ThemeService instead

// Debug utilities
import 'debug_sms_senders.dart';

Future<void> initializeHive() async {
  await Hive.initFlutter(); // Register adapters (using their built-in typeIds from @HiveType annotations)
  // Generated adapters from .g.dart files
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(
    TransactionCandidateAdapter(),
  ); // Re-enabled with typeId 8
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(ProfileAdapter());
  Hive.registerAdapter(EnhancedProfileAdapter());
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(ClientAdapter());
  Hive.registerAdapter(InvoiceAdapter());
  Hive.registerAdapter(SyncQueueItemAdapter());
  Hive.registerAdapter(ProfileTypeAdapter());
  Hive.registerAdapter(InvoiceLineItemAdapter());
  Hive.registerAdapter(InvoiceStatusAdapter());
  Hive.registerAdapter(GoalTypeAdapter());
  Hive.registerAdapter(GoalStatusAdapter());
  Hive.registerAdapter(BudgetLineItemAdapter()); // Manual enum adapters
  Hive.registerAdapter(enum_adapters.TransactionTypeAdapter());
  Hive.registerAdapter(enum_adapters.TransactionCategoryAdapter());
  Hive.registerAdapter(enum_adapters.BudgetPeriodAdapter());
  Hive.registerAdapter(enum_adapters.BudgetStatusAdapter());

  // Open boxes
  await Hive.openBox<Profile>('profiles');
  await Hive.openBox<EnhancedProfile>('enhanced_profiles');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<TransactionCandidate>(
    'transaction_candidates',
  ); // Re-enabled with fixed typeId
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Client>('clients');
  await Hive.openBox<Invoice>('invoices');
  await Hive.openBox<Goal>('goals');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<SyncQueueItem>('sync_queue');
  await Hive.openBox('settings');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (check if already initialized)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Firebase already initialized, continue
      if (kDebugMode) {
        print('Firebase already initialized, continuing...');
      }
    } else {
      // Re-throw other errors
      rethrow;
    }
  }
  // Initialize background SMS monitoring (auto-start on boot)
  await BackgroundSmsService.initialize();

  // Start background monitoring if device has booted
  await BackgroundSmsService.startBackgroundMonitoring();

  // Sync any background transactions from while app was closed
  await BackgroundSyncService.syncBackgroundTransactions();

  await initializeHive();

  // Debug: Print SMS sender status on app start
  if (kDebugMode) {
    await DebugSmsSenders.printSenderStatus();
  }

  // Initialize services
  final apiClient = ApiClient();
  final offlineDataService = OfflineDataService();
  final goalTransactionService = GoalTransactionService(offlineDataService);
  final textRecognitionService = TextRecognitionService(offlineDataService);
  final csvUploadService = CSVUploadService(offlineDataService);
  final smsTransactionExtractor = SmsTransactionExtractor(offlineDataService);
  final notificationService = NotificationService.instance;
  final smsListenerService = SmsListenerService(
    smsTransactionExtractor,
    notificationService,
  );
  final syncService = EnhancedSyncService(
    apiClient: apiClient,
    offlineDataService: offlineDataService,
  );
  final authService = AuthService();
  final themeService = ThemeService();
  final navigationService = NavigationService.instance;
  final senderManagementService = SenderManagementService.instance;
  final biometricAuthService = BiometricAuthService.instance;

  // Initialize offline manager for local calculations and parsing
  final offlineManager = OfflineManager();
  await offlineManager.initialize();

  // Initialize background transaction monitor (will be started after app loads)
  final backgroundTransactionMonitor = BackgroundTransactionMonitor(
    offlineDataService,
    smsTransactionExtractor,
  );

  // Temporarily disable Google Drive to focus on core functionality
  // final googleDriveService = GoogleDriveService();
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<OfflineDataService>.value(
          value: offlineDataService,
        ),
        Provider<GoalTransactionService>.value(value: goalTransactionService),
        Provider<TextRecognitionService>.value(value: textRecognitionService),
        Provider<CSVUploadService>.value(value: csvUploadService),
        Provider<SmsTransactionExtractor>.value(value: smsTransactionExtractor),
        Provider<NotificationService>.value(value: notificationService),
        Provider<SmsListenerService>.value(value: smsListenerService),
        Provider<EnhancedSyncService>.value(value: syncService),
        Provider<BackgroundTransactionMonitor>.value(
          value: backgroundTransactionMonitor,
        ),
        Provider<NavigationService>.value(value: navigationService),
        Provider<SenderManagementService>.value(value: senderManagementService),
        Provider<BiometricAuthService>.value(value: biometricAuthService),
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => themeService),
        // Provider<GoogleDriveService>.value(value: googleDriveService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start initialization immediately and cache the future
    _initializationFuture = _initializeServicesOnce();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Only trigger sync when app goes to background - biometric handling is done in AuthWrapper
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _syncProfileOnAppBackground();
    }
  }

  Future<void> _syncProfileOnAppBackground() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isLoggedIn) {
        if (kDebugMode) {
          print('App going to background, syncing profile...');
        }
        await authService.syncProfileWithServer();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Background sync failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Fedha',
          theme: themeService.getLightTheme(),
          darkTheme: themeService.getDarkTheme(),
          themeMode: themeService.themeMode,
          navigatorKey: NavigationService.navigatorKey,
          home: FutureBuilder<void>(
            future: _initializationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF007A39),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 100,
                          color: Colors.white,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Fedha',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Loading...',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const AuthWrapper();
            },
          ),
          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/signin': (context) => const SignInScreen(),
            '/dashboard': (context) => const MainNavigation(),
            '/profile': (context) => const ProfileScreen(),
            '/permission_setup': (context) => const PermissionSetupScreen(),
            '/text_recognition_setup':
                (context) => const TextRecognitionSetupScreen(),
            '/transaction_candidates':
                (context) => const TransactionCandidatesScreen(),
            '/csv_upload': (context) => const CSVUploadScreen(),
            '/test_ingestion':
                (context) => const TestTransactionIngestionScreen(),
          },
          onGenerateRoute: (settings) {
            // Handle unknown routes gracefully
            if (settings.name?.startsWith('/edit_transaction_candidate') ==
                true) {
              // This route is obsolete - transaction editing now uses modal bottom sheets
              return null; // Let the router handle this gracefully
            }
            return null;
          },
        );
      },
    );
  }

  Future<void> _initializeServicesOnce() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final authService = Provider.of<AuthService>(context, listen: false);
    final themeService = Provider.of<ThemeService>(context, listen: false);
    try {
      // Initialize core services sequentially to avoid blocking the UI
      await Future.wait(
        [authService.initialize(), themeService.initialize()],
      ); // Only try regular auto-login - biometric auth will be handled by AuthWrapper
      await authService.tryAutoLogin();

      // Update SMS listener with current profile ID after auto-login
      final currentProfile = authService.currentProfile;
      if (currentProfile != null && mounted) {
        final smsListenerService = Provider.of<SmsListenerService>(
          context,
          listen: false,
        );
        smsListenerService.setCurrentProfile(currentProfile.id);
      }

      // Initialize background services with a longer delay to avoid blocking UI
      Future.delayed(const Duration(seconds: 10), () async {
        if (mounted) {
          try {
            final backgroundMonitor = Provider.of<BackgroundTransactionMonitor>(
              context,
              listen: false,
            );
            await backgroundMonitor.initialize();
            if (kDebugMode) {
              print('Background monitor initialized successfully');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Background monitor initialization deferred: $e');
            }
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Service initialization error: $e');
      }
    }
  }
}
