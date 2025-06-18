// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Models
import 'models/profile.dart';
import 'models/enhanced_profile.dart';
import 'models/transaction.dart';
import 'models/transaction_candidate.dart';
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

// Screens
import 'screens/onboarding_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/profile_screen.dart';
import 'screens/text_recognition_setup_screen.dart';
import 'screens/transaction_candidates_screen.dart';
import 'screens/csv_upload_screen.dart';
import 'screens/test_transaction_ingestion_screen.dart';

// Utils
import 'utils/theme.dart';

Future<void> initializeHive() async {
  await Hive.initFlutter();
  // Register all adapters  // Generated adapters from .g.dart files
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionCandidateAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(ProfileAdapter());
  Hive.registerAdapter(ProfileTypeAdapter()); // From enhanced_profile.g.dart
  Hive.registerAdapter(EnhancedProfileAdapter());
  Hive.registerAdapter(SyncQueueItemAdapter());
  Hive.registerAdapter(ClientAdapter());
  Hive.registerAdapter(InvoiceAdapter());
  Hive.registerAdapter(InvoiceLineItemAdapter());
  Hive.registerAdapter(InvoiceStatusAdapter());
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(GoalTypeAdapter());
  Hive.registerAdapter(GoalStatusAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(BudgetLineItemAdapter());

  // Manual enum adapters
  Hive.registerAdapter(enum_adapters.TransactionTypeAdapter());
  Hive.registerAdapter(enum_adapters.TransactionCategoryAdapter());
  Hive.registerAdapter(enum_adapters.BudgetPeriodAdapter());
  Hive.registerAdapter(enum_adapters.BudgetStatusAdapter());
  // Open boxes
  await Hive.openBox<Profile>('profiles');
  await Hive.openBox<EnhancedProfile>('enhanced_profiles');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<TransactionCandidate>('transaction_candidates');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Client>('clients');
  await Hive.openBox<Invoice>('invoices');
  await Hive.openBox<Goal>('goals');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<SyncQueueItem>('sync_queue');
  await Hive.openBox('settings');
}

void main() async {
  await initializeHive(); // Initialize services
  final apiClient = ApiClient();
  final offlineDataService = OfflineDataService();
  final goalTransactionService = GoalTransactionService(offlineDataService);
  final textRecognitionService = TextRecognitionService(offlineDataService);
  final csvUploadService = CSVUploadService(offlineDataService);
  final syncService = EnhancedSyncService(
    apiClient: apiClient,
    offlineDataService: offlineDataService,
  );
  final authService = AuthService();
  // Temporarily disable Google Drive to focus on core functionality
  // final googleDriveService = GoogleDriveService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<OfflineDataService>.value(value: offlineDataService),
        Provider<GoalTransactionService>.value(value: goalTransactionService),
        Provider<TextRecognitionService>.value(value: textRecognitionService),
        Provider<CSVUploadService>.value(value: csvUploadService),
        Provider<EnhancedSyncService>.value(value: syncService),
        ChangeNotifierProvider(create: (_) => authService),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Trigger sync when app goes to background or is paused
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
    return MaterialApp(
      title: 'Fedha',
      theme: FedhaTheme.lightTheme,
      darkTheme: FedhaTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: FutureBuilder<void>(
        future: _initializeServices(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Consumer<AuthService>(
            builder: (context, authService, child) {
              return FutureBuilder<bool>(
                future: _checkFirstTime(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final isFirstTime = snapshot.data ?? true;

                  if (isFirstTime) {
                    return const OnboardingScreen();
                  } else if (authService.isLoggedIn) {
                    return const MainNavigation();
                  } else {
                    return const SignInScreen();
                  }
                },
              );
            },
          );
        },
      ),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/signin': (context) => const SignInScreen(),
        '/dashboard': (context) => const MainNavigation(),
        '/profile': (context) => const ProfileScreen(),
        '/text_recognition_setup':
            (context) => const TextRecognitionSetupScreen(),
        '/transaction_candidates':
            (context) => const TransactionCandidatesScreen(),
        '/csv_upload': (context) => const CSVUploadScreen(),
        '/test_ingestion': (context) => const TestTransactionIngestionScreen(),
      },
    );
  }

  Future<void> _initializeServices(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.initialize();
    await authService.tryAutoLogin(); // Using the correct method name
  }

  Future<bool> _checkFirstTime() async {
    final settingsBox = Hive.box('settings');
    return settingsBox.get('first_time', defaultValue: true);
  }
}
