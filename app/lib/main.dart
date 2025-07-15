// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Models
import 'models/profile.dart';
import 'models/enhanced_profile.dart';
import 'models/transaction.dart';
import 'models/category.dart';
import 'models/client.dart';
import 'models/invoice.dart';
import 'models/goal.dart';
import 'models/budget.dart';
import 'models/sync_queue_item.dart';

// Services
import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'services/offline_data_service.dart';
import 'services/goal_transaction_service.dart';
import 'services/text_recognition_service.dart';
import 'services/csv_upload_service.dart';
import 'services/sms_transaction_extractor.dart';
import 'services/sms_listener_service.dart';
import 'services/background_sms_service.dart';
import 'services/permission_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/navigation_service.dart';
import 'services/sender_management_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/streak_service.dart';

// Screens
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/enhanced_budget_screen.dart';
import 'screens/enhanced_goals_screen.dart';

// Widgets
import 'widgets/auth_wrapper.dart';
// Utils
// import 'utils/theme.dart'; // Using ThemeService instead

Future<void> initializeHive() async {
  await Hive.initFlutter(); // Register adapters (using their built-in typeIds from @HiveType annotations)
  // Generated adapters from .g.dart files
  Hive.registerAdapter(TransactionAdapter());
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
  // Note: All enum adapters are now generated automatically

  // Open boxes
  await Hive.openBox<Profile>('profiles');
  await Hive.openBox<EnhancedProfile>('enhanced_profiles');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Client>('clients');
  await Hive.openBox<Invoice>('invoices');
  await Hive.openBox<Goal>('goals');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<SyncQueueItem>('sync_queue');
  await Hive.openBox('settings');
}

void main() async {
  await initializeHive();
  // Set API base URL for real device testing
  ApiClient.configureApiForRealDevice();

  // Initialize services
  final apiClient = ApiClient();
  final offlineDataService = OfflineDataService();
  final goalTransactionService = GoalTransactionService(offlineDataService);
  final textRecognitionService = TextRecognitionService();
  final csvUploadService = CSVUploadService(offlineDataService);
  final smsTransactionExtractor = SmsTransactionExtractor(offlineDataService);
  final notificationService = NotificationService.instance;
  final permissionService = PermissionService.instance;
  final smsListenerService = SmsListenerService(
    smsTransactionExtractor,
    notificationService,
    offlineDataService,
  );
  final backgroundSmsService = BackgroundSmsService(
    smsListenerService,
    permissionService,
  );
  final authService = AuthService();
  final themeService = ThemeService();
  final navigationService = NavigationService.instance;
  final senderManagementService = SenderManagementService.instance;
  final biometricAuthService = BiometricAuthService.instance;
  final streakService = StreakService.instance;

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
        ChangeNotifierProvider<TextRecognitionService>.value(
          value: textRecognitionService,
        ),
        Provider<CSVUploadService>.value(value: csvUploadService),
        Provider<SmsTransactionExtractor>.value(value: smsTransactionExtractor),
        Provider<NotificationService>.value(value: notificationService),
        Provider<PermissionService>.value(value: permissionService),
        Provider<SmsListenerService>.value(value: smsListenerService),
        Provider<BackgroundSmsService>.value(value: backgroundSmsService),
        Provider<NavigationService>.value(value: navigationService),
        Provider<SenderManagementService>.value(value: senderManagementService),
        Provider<BiometricAuthService>.value(value: biometricAuthService),
        ChangeNotifierProvider<StreakService>.value(value: streakService),
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => themeService),
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
  bool _permissionsRequested = false;
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

  Future<void> _requestPermissionsIfNeeded() async {
    if (_permissionsRequested || !mounted) return;
    _permissionsRequested = true;

    final permissionService = Provider.of<PermissionService>(
      context,
      listen: false,
    );

    // Check which permissions are missing
    final currentPermissions = await permissionService.checkAllPermissions();
    final criticalPermissions = permissionService.getCriticalPermissions();
    final descriptions = permissionService.getPermissionDescriptions();

    final missingCritical =
        criticalPermissions
            .where((permission) => currentPermissions[permission] != true)
            .toList();

    if (missingCritical.isNotEmpty && mounted) {
      // Show permission explanation dialog
      final shouldRequest = await _showPermissionDialog(
        missingCritical,
        descriptions,
      );

      if (shouldRequest && mounted) {
        // Request the permissions
        await permissionService.requestAllPermissions();
      }
    }
  }

  Future<bool> _showPermissionDialog(
    List<String> missingPermissions,
    Map<String, String> descriptions,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.security, color: Color(0xFF007A39)),
                  SizedBox(width: 8),
                  Text('Permissions Required'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fedha needs the following permissions to provide the best experience:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    ...missingPermissions.map(
                      (permission) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: Color(0xFF007A39),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                descriptions[permission] ??
                                    'Required for app functionality',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can change these permissions later in your device settings.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not Now'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Grant Permissions'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Fedha',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF007A39),
              brightness: Brightness.light,
            ),
            primaryColor: const Color(0xFF007A39),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF007A39),
              brightness: Brightness.dark,
            ),
            primaryColor: const Color(0xFF007A39),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
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
            '/profile': (context) => const ProfileScreen(),
            '/signin': (context) => const AuthWrapper(),
            '/enhanced_budget': (context) => const EnhancedBudgetScreen(),
            '/enhanced_goals': (context) => const EnhancedGoalsScreen(),
          },
          onGenerateRoute: (settings) {
            // Handle unknown routes gracefully
            if (settings.name?.startsWith('/edit_transaction_candidate') ==
                true) {
              // This route is obsolete - transaction editing now uses modal bottom sheets
              return MaterialPageRoute(
                builder: (context) => const AuthWrapper(),
                settings: settings,
              );
            }
            // Default fallback for any unknown route
            return MaterialPageRoute(
              builder: (context) => const AuthWrapper(),
              settings: settings,
            );
          },
        );
      },
    );
  }

  Future<void> _initializeServicesOnce() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      // Initialize core services sequentially to avoid blocking the UI
      await Future.wait([authService.initialize()]);

      // Request permissions on first startup
      await _requestPermissionsIfNeeded();

      // Only try regular auto-login - biometric auth will be handled by AuthWrapper
      if (mounted) {
        await authService.tryAutoLogin();
      }

      // Update SMS listener with current profile ID after auto-login
      if (mounted) {
        final currentProfile = authService.currentProfile;
        if (currentProfile != null) {
          final smsListenerService = Provider.of<SmsListenerService>(
            context,
            listen: false,
          );
          final backgroundSmsService = Provider.of<BackgroundSmsService>(
            context,
            listen: false,
          );
          smsListenerService.setCurrentProfile(currentProfile.id);
          // Start background SMS service for auto-logged in users
          backgroundSmsService.startListening();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Service initialization error: $e');
      }
      // Clear any invalid session state
      if (mounted) {
        await authService.logout();
      }
    }
  }
}
