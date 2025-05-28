// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Models
import 'models/profile.dart';
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
import 'services/api_client.dart';
import 'services/offline_data_service.dart';
import 'services/enhanced_sync_service.dart';

// Screens
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_type_screen.dart';

Future<void> initializeHive() async {
  await Hive.initFlutter();
  // Register all adapters
  Hive.registerAdapter(ProfileAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(enum_adapters.TransactionTypeAdapter());
  Hive.registerAdapter(enum_adapters.TransactionCategoryAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(ClientAdapter());
  Hive.registerAdapter(InvoiceAdapter());
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(SyncQueueItemAdapter());

  // Open boxes
  await Hive.openBox<Profile>('profiles');
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
  WidgetsFlutterBinding.ensureInitialized();

  await initializeHive();

  // Initialize services
  final apiClient = ApiClient();
  final offlineDataService = OfflineDataService();
  final syncService = EnhancedSyncService(
    apiClient: apiClient,
    offlineDataService: offlineDataService,
  );
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<OfflineDataService>.value(value: offlineDataService),
        Provider<EnhancedSyncService>.value(value: syncService),
        ChangeNotifierProvider(create: (_) => authService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      title: 'Fedha',
      theme: ThemeData(primaryColor: const Color.fromARGB(255, 0, 122, 57)),
      initialRoute: '/',
      routes: {
        '/':
            (context) =>
                authService.isLoggedIn
                    ? const DashboardScreen()
                    : const ProfileTypeScreen(),
        '/login':
            (context) =>
                const ProfileTypeScreen(), // Redirect to ProfileTypeScreen to select a profile type first
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
