// lib/main.dart - Full Fedha with crash-resistant initialization
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'firebase_options.dart';

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
import 'services/offline_first_auth_service.dart';
import 'services/api_client.dart';
import 'services/offline_data_service.dart';
import 'services/sync_service.dart';
import 'services/goal_transaction_service.dart';
import 'services/text_recognition_service.dart';
import 'services/csv_upload_service.dart';
import 'services/sms_transaction_extractor.dart';
import 'services/sms_listener_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/navigation_service.dart';
import 'services/sender_management_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/background_sms_service.dart';
import 'services/background_sync_service.dart';

// Screens
import 'screens/onboarding_screen.dart';
import 'screens/auth_wrapper.dart';

// Utils
import 'debug_sms_senders.dart';

/// Safe initialization of Hive with all required adapters
Future<void> initializeHive() async {
  try {
    await Hive.initFlutter();

    // Register adapters safely
    try {
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ProfileAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(EnhancedProfileAdapter());
      }
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TransactionAdapter());
      }
      if (!Hive.isAdapterRegistered(9)) {
        // Hive.registerAdapter(TransactionCandidateAdapter()); // TODO: Implement when model is ready
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ClientAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(InvoiceAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(GoalAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(BudgetAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(SyncQueueItemAdapter());
      }

      // Register enum adapters safely
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
      'profiles',
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

    // Open typed boxes separately
    try {
      if (!Hive.isBoxOpen('enhanced_profiles')) {
        await Hive.openBox<EnhancedProfile>('enhanced_profiles');
      }
    } catch (boxError) {
      if (kDebugMode) {
        print('⚠️ Failed to open enhanced_profiles box: $boxError');
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

/// Safe Firebase initialization
Future<void> initializeFirebaseSafe() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
      }
    } else {
      if (kDebugMode) {
        print('ℹ️ Firebase already initialized');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Firebase initialization failed: $e');
    }
    // Continue without Firebase
  }
}

/// Safe background services initialization
Future<void> initializeBackgroundServices() async {
  try {
    if (Platform.isAndroid) {
      await BackgroundSmsService.initialize();
      await BackgroundSmsService.startBackgroundMonitoring();
      await BackgroundSyncService.syncBackgroundTransactions();
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize core systems
    await initializeFirebaseSafe();
    await initializeHive();

    // Initialize background services (non-critical)
    await initializeBackgroundServices();

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
      final textRecognitionService = TextRecognitionService(offlineDataService);
      final csvUploadService = CSVUploadService(offlineDataService);
      final smsTransactionExtractor = SmsTransactionExtractor(
        offlineDataService,
      );
      final notificationService = NotificationService.instance;
      final smsListenerService = SmsListenerService(
        smsTransactionExtractor,
        notificationService,
      );
      final syncService = SyncService(
        apiClient: apiClient,
        offlineDataService: offlineDataService,
      );
      final authService = OfflineFirstAuthService.instance;
      final themeService = ThemeService();
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
          Provider<TextRecognitionService>.value(value: textRecognitionService),
          Provider<CSVUploadService>.value(value: csvUploadService),
          Provider<SmsTransactionExtractor>.value(
            value: smsTransactionExtractor,
          ),
          Provider<NotificationService>.value(value: notificationService),
          Provider<SmsListenerService>.value(value: smsListenerService),
          Provider<SyncService>.value(value: syncService),
          ChangeNotifierProvider<OfflineFirstAuthService>.value(
            value: authService,
          ),
          ChangeNotifierProvider<ThemeService>.value(value: themeService),
          Provider<NavigationService>.value(value: navigationService),
          Provider<SenderManagementService>.value(
            value: senderManagementService,
          ),
          Provider<BiometricAuthService>.value(value: biometricAuthService),
        ],
        child: Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return MaterialApp(
              title: 'Fedha - Personal Finance',
              theme: themeService.lightTheme,
              darkTheme: themeService.darkTheme,
              themeMode: themeService.themeMode,
              navigatorKey: NavigationService.navigatorKey,
              home: const AuthWrapper(),
              debugShowCheckedModeBanner: false,
            );
          },
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
