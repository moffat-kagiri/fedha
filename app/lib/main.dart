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

// Enum Adapters
import 'adapters/enum_adapters.dart' as enum_adapters;

// Services
import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'services/local_db.dart';
import 'services/offline_data_service.dart';
import 'services/enhanced_sync_service.dart';

// Screens
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_type_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register all type adapters
  await _registerTypeAdapters();

  // Initialize local database service
  await LocalDatabaseService.initialize();

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
      child: MyApp(),
    ),
  );
}

Future<void> _registerTypeAdapters() async {
  // Register model adapters
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProfileAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TransactionAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CategoryAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ClientAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(InvoiceAdapter());
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(InvoiceLineItemAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(GoalAdapter());
  if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(BudgetAdapter());
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(BudgetLineItemAdapter());
  }

  // Register enum adapters
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(enum_adapters.ProfileTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(enum_adapters.TransactionTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(enum_adapters.TransactionCategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(enum_adapters.CategoryTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(enum_adapters.InvoiceStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(15)) {
    Hive.registerAdapter(enum_adapters.GoalTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(16)) {
    Hive.registerAdapter(enum_adapters.GoalStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(17)) {
    Hive.registerAdapter(enum_adapters.BudgetPeriodAdapter());
  }
  if (!Hive.isAdapterRegistered(18)) {
    Hive.registerAdapter(enum_adapters.BudgetStatusAdapter());
  }
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
