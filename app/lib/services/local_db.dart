// lib/services/local_db.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/profile.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../models/goal.dart';
import '../models/budget.dart';

/// Comprehensive local database service for offline functionality
/// Manages all Hive boxes and provides unified access to local data
class LocalDatabaseService {
  // Box names constants
  static const String _profilesBox = 'profiles';
  static const String _transactionsBox = 'transactions';
  static const String _categoriesBox = 'categories';
  static const String _clientsBox = 'clients';
  static const String _invoicesBox = 'invoices';
  static const String _goalsBox = 'goals';
  static const String _budgetsBox = 'budgets';
  static const String _settingsBox = 'settings';
  static const String _syncQueueBox = 'sync_queue';

  // Lazy boxes for better performance with large datasets
  static Box<Profile>? _profiles;
  static Box<Transaction>? _transactions;
  static Box<Category>? _categories;
  static Box<Client>? _clients;
  static Box<Invoice>? _invoices;
  static Box<Goal>? _goals;
  static Box<Budget>? _budgets;
  static Box<dynamic>? _settings;
  static Box<dynamic>? _syncQueue;

  /// Initialize all Hive boxes and register adapters
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register type adapters
    _registerAdapters();

    // Open all boxes
    await _openBoxes();
  }

  /// Register all Hive type adapters
  static void _registerAdapters() {
    // Only register if not already registered
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProfileAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ClientAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(InvoiceAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(GoalAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(BudgetAdapter());

    // Register enum adapters
    // Register enum adapters if they exist in individual model files
    // Add enum adapter registrations here when enum adapters are created
  }

  /// Open all Hive boxes
  static Future<void> _openBoxes() async {
    _profiles = await Hive.openBox<Profile>(_profilesBox);
    _transactions = await Hive.openBox<Transaction>(_transactionsBox);
    _categories = await Hive.openBox<Category>(_categoriesBox);
    _clients = await Hive.openBox<Client>(_clientsBox);
    _invoices = await Hive.openBox<Invoice>(_invoicesBox);
    _goals = await Hive.openBox<Goal>(_goalsBox);
    _budgets = await Hive.openBox<Budget>(_budgetsBox);
    _settings = await Hive.openBox(_settingsBox);
    _syncQueue = await Hive.openBox(_syncQueueBox);
  }

  // Getters for boxes
  Box<Profile> get profiles => _profiles!;
  Box<Transaction> get transactions => _transactions!;
  Box<Category> get categories => _categories!;
  Box<Client> get clients => _clients!;
  Box<Invoice> get invoices => _invoices!;
  Box<Goal> get goals => _goals!;
  Box<Budget> get budgets => _budgets!;
  Box<dynamic> get settings => _settings!;
  Box<dynamic> get syncQueue => _syncQueue!;

  /// Clear all data (useful for logout or reset)
  Future<void> clearAllData() async {
    await _profiles?.clear();
    await _transactions?.clear();
    await _categories?.clear();
    await _clients?.clear();
    await _invoices?.clear();
    await _goals?.clear();
    await _budgets?.clear();
    await _settings?.clear();
    await _syncQueue?.clear();
  }

  /// Close all boxes
  Future<void> closeAllBoxes() async {
    await _profiles?.close();
    await _transactions?.close();
    await _categories?.close();
    await _clients?.close();
    await _invoices?.close();
    await _goals?.close();
    await _budgets?.close();
    await _settings?.close();
    await _syncQueue?.close();
  }

  /// Get database size information
  Map<String, int> getDatabaseInfo() {
    return {
      'profiles': _profiles?.length ?? 0,
      'transactions': _transactions?.length ?? 0,
      'categories': _categories?.length ?? 0,
      'clients': _clients?.length ?? 0,
      'invoices': _invoices?.length ?? 0,
      'goals': _goals?.length ?? 0,
      'budgets': _budgets?.length ?? 0,
      'settings': _settings?.length ?? 0,
      'syncQueue': _syncQueue?.length ?? 0,
    };
  }

  /// Export data for backup
  Map<String, dynamic> exportData() {
    return {
      'profiles': _profiles?.values.map((e) => e.toJson()).toList() ?? [],
      'transactions':
          _transactions?.values.map((e) => e.toJson()).toList() ?? [],
      'categories': _categories?.values.map((e) => e.toJson()).toList() ?? [],
      'clients': _clients?.values.map((e) => e.toJson()).toList() ?? [],
      'invoices': _invoices?.values.map((e) => e.toJson()).toList() ?? [],
      'goals': _goals?.values.map((e) => e.toJson()).toList() ?? [],
      'budgets': _budgets?.values.map((e) => e.toJson()).toList() ?? [],
      'settings': _settings?.toMap() ?? {},
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Import data from backup
  Future<void> importData(Map<String, dynamic> data) async {
    // Clear existing data
    await clearAllData();

    // Import profiles
    if (data['profiles'] != null) {
      for (var json in data['profiles']) {
        final profile = Profile.fromJson(json);
        await _profiles?.put(profile.id, profile);
      }
    }

    // Import transactions
    if (data['transactions'] != null) {
      for (var json in data['transactions']) {
        final transaction = Transaction.fromJson(json);
        await _transactions?.put(transaction.uuid, transaction);
      }
    }

    // Import other entities...
    // Add similar logic for other data types
  }
}
