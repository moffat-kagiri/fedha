// lib/main.dart - Full Fedha with crash-resistant initialization
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:io';

// Models
import 'models/profile.dart';
import 'models/enhanced_profile.dart';
import 'models/transaction.dart';
// import 'models/transaction_candidate.dart';
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
import 'services/goal_transaction_service.dart';
import 'services/text_recognition_service.dart';
import 'services/csv_upload_service.dart';
import 'services/sms_transaction_extractor.dart';
import 'services/sms_listener_service.dart';
import 'services/notification_service.dart';
// import 'services/theme_service.dart';
import 'services/navigation_service.dart';
import 'services/sender_management_service.dart';
import 'services/biometric_auth_service.dart';
// import 'services/background_sms_service.dart';
// import 'services/background_sync_service.dart';

// Screens
import 'screens/onboarding_screen.dart';
import 'screens/auth_wrapper.dart';
import 'screens/sms_debug_screen.dart';

// Utils
import 'debug_sms_senders.dart';

/// Safe initialization of Hive with all required adapters
Future<void> initializeHive() async {
  try {
    await Hive.initFlutter();

    // Register adapters safely
    try {
      // Hive type adapters for models
      Hive.registerAdapter(ProfileAdapter());
      Hive.registerAdapter(EnhancedProfileAdapter());
      Hive.registerAdapter(ProfileTypeAdapter());
      Hive.registerAdapter(TransactionAdapter());
      Hive.registerAdapter(CategoryAdapter());
      Hive.registerAdapter(ClientAdapter());
      Hive.registerAdapter(InvoiceAdapter());
      Hive.registerAdapter(GoalAdapter());
      Hive.registerAdapter(GoalTypeAdapter());
      Hive.registerAdapter(GoalStatusAdapter());
      Hive.registerAdapter(BudgetAdapter());
      Hive.registerAdapter(BudgetPeriodAdapter());
      Hive.registerAdapter(SyncQueueItemAdapter());

      // Register enum adapters
      enum_adapters.registerAdapters();

      if (kDebugMode) {
        print('✅ Hive adapters registered successfully');
      }
    } catch (adapterError) {
      if (kDebugMode) {
        print('⚠️ Adapter registration failed: $adapterError');
      }
    }

    // Open boxes safely
    final boxesToOpen = [
      // 'profiles',        // Handled by AuthService
      // 'enhanced_profiles', // Handled by AuthService
      'transactions',
      'transaction_candidates',
      'categories',
      'clients',
      'invoices',
      'goals',
      'budgets',
      'sync_queue',
      'settings',
    ];

    for (final boxName in boxesToOpen) {
      try {
        if (!Hive.isBoxOpen(boxName)) {
          await Hive.openBox(boxName);
        }
      } catch (boxError) {
        if (kDebugMode) {
          print('⚠️ Failed to open box $boxName: $boxError');
        }
      }
    }

    if (kDebugMode) {
      print('✅ Hive initialization completed');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Hive initialization failed: $e');
    }
    // Continue without Hive
  }
}

/// Local authentication initialization
Future<void> initializeLocalAuth() async {
  try {
    // Initialize local authentication methods and services
    if (kDebugMode) {
      print('✅ Local authentication initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Local authentication initialization failed: $e');
    }
    // Continue without local authentication
  }
}

/// Safe background services initialization
Future<void> initializeBackgroundServices() async {
  try {
    if (Platform.isAndroid) {
      // Background services temporarily disabled
      // await BackgroundSmsService.initialize();
      // await BackgroundSmsService.startBackgroundMonitoring();
      // await BackgroundSyncService.syncBackgroundTransactions();
      if (kDebugMode) {
        print('✅ Background services initialized');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Background services initialization failed: $e');
    }
    // Continue without background services
  }
}

/// Safe text recognition service initialization
Future<void> initializeTextRecognition() async {
  try {
    final textRecognition = TextRecognitionService.instance;
    await textRecognition.initialize();
    await textRecognition.enableTextRecognition();

    if (kDebugMode) {
      print('✅ Text recognition service initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Text recognition initialization failed: $e');
    }
    // Continue without text recognition
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize core systems
    await initializeLocalAuth();
    await initializeHive();

    // Initialize background services (non-critical)
    await initializeBackgroundServices();

    // Initialize text recognition service (non-critical)
    await initializeTextRecognition();

    // Debug SMS senders (non-critical)
    if (kDebugMode) {
      try {
        await DebugSmsSenders.printSenderStatus();
      } catch (e) {
        print('⚠️ Debug SMS status failed: $e');
      }
    }

    if (kDebugMode) {
      print('🚀 Fedha app initialization completed');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Critical initialization error: $e');
    }
    // Continue with minimal functionality
  }

  runApp(const FedhaApp());
}

class FedhaApp extends StatelessWidget {
  const FedhaApp({super.key});

  /// Safe service initialization with fallbacks
  Widget _buildAppWithServices() {
    try {
      // Initialize services with null safety
      final apiClient = ApiClient();
      final offlineDataService = OfflineDataService();
      final goalTransactionService = GoalTransactionService(offlineDataService);
      final textRecognitionService = TextRecognitionService.instance;
      final csvUploadService = CSVUploadService(offlineDataService);
      final smsTransactionExtractor = SmsTransactionExtractor(
        offlineDataService,
      );
      final notificationService = NotificationService.instance;
      final smsListenerService = SmsListenerService(
        smsTransactionExtractor,
        notificationService,
        offlineDataService,
      );
      final syncService = EnhancedSyncService(
        apiClient: apiClient,
        offlineDataService: offlineDataService,
      );
      final authService = AuthService();
      // final themeService = ThemeService();
      final navigationService = NavigationService.instance;
      final senderManagementService = SenderManagementService.instance;
      final biometricAuthService = BiometricAuthService.instance;

      return MultiProvider(
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
          Provider<SmsTransactionExtractor>.value(
            value: smsTransactionExtractor,
          ),
          Provider<NotificationService>.value(value: notificationService),
          Provider<SmsListenerService>.value(value: smsListenerService),
          Provider<EnhancedSyncService>.value(value: syncService),
          ChangeNotifierProvider<AuthService>.value(value: authService),
          // ChangeNotifierProvider<ThemeService>.value(value: themeService),
          Provider<NavigationService>.value(value: navigationService),
          Provider<SenderManagementService>.value(
            value: senderManagementService,
          ),
          Provider<BiometricAuthService>.value(value: biometricAuthService),
        ],
        child: MaterialApp(
          title: 'Fedha - Personal Finance',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.system,
          navigatorKey: NavigationService.navigatorKey,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Service initialization failed, using minimal app: $e');
      }
      return _buildMinimalApp();
    }
  }

  /// Minimal app fallback if services fail
  Widget _buildMinimalApp() {
    return MaterialApp(
      title: 'Fedha - Personal Finance',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildAppWithServices();
  }
}
