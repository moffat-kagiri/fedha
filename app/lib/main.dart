// lib/main.dart
import 'package:flutter/material.dart';
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

// Enum Adapters
import 'adapters/enum_adapters.dart' as enum_adapters;

// Services
import 'services/auth_service.dart';
import 'services/enhanced_auth_service.dart';
// import 'services/google_drive_service.dart';
import 'services/api_client.dart';
import 'services/offline_data_service.dart';
import 'services/enhanced_sync_service.dart';

// Screens
import 'screens/onboarding_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/profile_screen.dart';

// Utils
import 'utils/theme.dart';

Future<void> initializeHive() async {
  await Hive.initFlutter();
  // Register all adapters
  // Generated adapters from .g.dart files
  Hive.registerAdapter(TransactionAdapter());
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
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Client>('clients');
  await Hive.openBox<Invoice>('invoices');
  await Hive.openBox<Goal>('goals');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox<SyncQueueItem>('sync_queue');
  await Hive.openBox('settings');
  await Hive.openBox('settings');
}

void main() async {
  await initializeHive();
  // Initialize services
  final apiClient = ApiClient();
  final offlineDataService = OfflineDataService();
  final syncService = EnhancedSyncService(
    apiClient: apiClient,
    offlineDataService: offlineDataService,
  );
  final authService = AuthService();
  final enhancedAuthService = EnhancedAuthService();
  // Temporarily disable Google Drive to focus on core functionality
  // final googleDriveService = GoogleDriveService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<OfflineDataService>.value(value: offlineDataService),
        Provider<EnhancedSyncService>.value(value: syncService),
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => enhancedAuthService),
        // Provider<GoogleDriveService>.value(value: googleDriveService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final enhancedAuthService = Provider.of<EnhancedAuthService>(context);
    return MaterialApp(
      title: 'Fedha',
      theme: FedhaTheme.lightTheme,
      darkTheme: FedhaTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: FutureBuilder<bool>(
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
          } else if (enhancedAuthService.isLoggedIn) {
            return const MainNavigation();
          } else {
            return const SignInScreen();
          }
        },
      ),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/signin': (context) => const SignInScreen(),
        '/dashboard': (context) => const MainNavigation(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }

  Future<bool> _checkFirstTime() async {
    final settingsBox = Hive.box('settings');
    return settingsBox.get('first_time', defaultValue: true);
  }
}
