import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

 part 'app_database.g.dart';

/// Table for storing transactions with an encrypted relational schema.
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  RealColumn get amountMinor => real().map(const _DecimalConverter())();
  TextColumn get currency => text()();
  TextColumn get description => text()();
  // Persist category chosen by user
  TextColumn get categoryId => text().withDefault(const Constant(''))();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isExpense => boolean().withDefault(const Constant(true))();
  TextColumn get rawSms => text().nullable()();
  IntColumn get profileId => integer()();
}

/// Table for storing goals.
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get targetMinor => real().map(const _DecimalConverter())();
  TextColumn get currency => text()();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get profileId => integer()();
}

/// Table for storing loans.
class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get principalMinor => integer()();
  TextColumn get currency => text().withDefault(const Constant('KES'))();
  RealColumn get interestRate => real().withDefault(const Constant(0.0))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  // Removed invalid foreign key constraint; just store profileId
  IntColumn get profileId => integer()();
}

/// Table for storing user profiles with app-specific data
class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Remote auth ID - used to link with auth service
  TextColumn get authId => text().unique()();
  // Display name for the app
  TextColumn get displayName => text()();
  // Preferred currency for new transactions
  TextColumn get defaultCurrency => text().withDefault(const Constant('KES'))();
  // Budget period preference (monthly/weekly)
  TextColumn get budgetPeriod => text().withDefault(const Constant('monthly'))();
  // Last sync timestamp
  DateTimeColumn get lastSync => dateTime().nullable()();
  // Account creation date
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table for storing app settings
class AppSettings extends Table {
  // Using integer as primary key for single row
  IntColumn get id => integer()();
  // Theme preference (system/light/dark)
  TextColumn get theme => text().withDefault(const Constant('system'))();
  // Biometric auth enabled
  BoolColumn get biometricEnabled => boolean().withDefault(const Constant(false))();
  // SMS scanning enabled
  BoolColumn get smsEnabled => boolean().withDefault(const Constant(true))();
  // Budget alerts enabled
  BoolColumn get budgetAlerts => boolean().withDefault(const Constant(true))();
  // Goal reminders enabled
  BoolColumn get goalReminders => boolean().withDefault(const Constant(true))();
  // Data backup frequency (daily/weekly/monthly)
  TextColumn get backupFrequency => text().withDefault(const Constant('weekly'))();
  // Remember me flag for login
  BoolColumn get rememberMe => boolean().withDefault(const Constant(false))();
  // Saved email for login
  TextColumn get savedEmail => text().nullable()();
  // Onboarding complete flag
  BoolColumn get onboardingComplete => boolean().withDefault(const Constant(false))();
  // Permissions prompt shown flag
  BoolColumn get permissionsPromptShown => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing notifications
class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Notification title
  TextColumn get title => text()();
  // Notification body
  TextColumn get body => text()();
  // Type of notification (transaction/budget/goal)
  TextColumn get type => text()();
  // Associated entity ID (transaction ID, budget ID, etc.)
  IntColumn get entityId => integer().nullable()();
  // When to show the notification
  DateTimeColumn get scheduledFor => dateTime()();
  // Whether notification has been read
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  // When the notification was created
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // Profile ID for the notification
  IntColumn get profileId => integer()();
}

/// Table for storing SMS-derived pending transactions prior to user review.
class PendingTransactions extends Table {
  TextColumn get id => text()();
  RealColumn get amountMinor => real().map(const _DecimalConverter())();
  TextColumn get currency => text().withDefault(const Constant('KES'))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isExpense => boolean().withDefault(const Constant(true))();
  TextColumn get rawSms => text().nullable()();
  IntColumn get profileId => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Table for storing expense/income categories.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get iconKey => text().withDefault(const Constant('default_icon'))();
  TextColumn get colorKey => text().withDefault(const Constant('default_color'))();
  // Whether this is an expense or income category
  BoolColumn get isExpense => boolean().withDefault(const Constant(true))();
  // For custom ordering in UI
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  // Link to profile
  IntColumn get profileId => integer()();
}

/// Table for storing monthly/periodic budgets
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  // The spending limit in minor units (cents/cents equivalent)
  RealColumn get limitMinor => real().map(const _DecimalConverter())();
  // The currency for this budget
  TextColumn get currency => text().withDefault(const Constant('KES'))();
  // Optional category this budget is tracking
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  // The month this budget applies to
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  // Whether this is a recurring budget
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  // The profile this budget belongs to
  IntColumn get profileId => integer()();
}

/// Converter for storing Decimal amounts in a real column
class _DecimalConverter extends TypeConverter<double, double> {
  const _DecimalConverter();
  @override
  double fromSql(double fromDb) => fromDb / 100;
  @override
  double toSql(double value) => value * 100;
}

@DriftDatabase(tables: [
  Transactions, Goals, Loans, PendingTransactions, Categories, Budgets,
  UserProfiles, AppSettings, Notifications
])
class AppDatabase extends _$AppDatabase {
  // Singleton instance
  AppDatabase._internal(QueryExecutor e) : super(e);

  static AppDatabase? _instance;

  factory AppDatabase() {
    if (_instance != null) return _instance!;
    final executor = _openEncryptedConnection();
    _instance = AppDatabase._internal(executor);
    return _instance!;
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Insert default app settings
      await into(appSettings).insert(
        AppSettingsCompanion.insert(
          id: const Value(1),
          theme: const Value('system'),
          biometricEnabled: const Value(false),
          smsEnabled: const Value(true),
          budgetAlerts: const Value(true),
          goalReminders: const Value(true),
          backupFrequency: const Value('weekly'),
        ),
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Create new tables
        await m.createTable(userProfiles);
        await m.createTable(appSettings);
        await m.createTable(notifications);
        
        // Migrate existing settings from SharedPreferences
        await _migrateFromSharedPreferences();
      }
    },
    beforeOpen: (details) async {
      // Ensure we have app settings
      final settings = await getAppSettings();
      if (settings == null) {
        await into(appSettings).insert(
          AppSettingsCompanion.insert(
            id: const Value(1),
            theme: const Value('system'),
            biometricEnabled: const Value(false),
            smsEnabled: const Value(true),
            budgetAlerts: const Value(true),
            goalReminders: const Value(true),
            backupFrequency: const Value('weekly'),
          ),
        );
      }
    },
  );

  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Insert app settings with existing preferences
    await into(appSettings).insert(
      AppSettingsCompanion.insert(
        id: const Value(1),
        theme: Value(prefs.getString('theme') ?? 'system'),
        biometricEnabled: Value(prefs.getBool('biometric_enabled') ?? false),
        smsEnabled: Value(prefs.getBool('sms_enabled') ?? true),
        budgetAlerts: Value(prefs.getBool('budget_alerts') ?? true),
        goalReminders: Value(prefs.getBool('goal_reminders') ?? true),
        backupFrequency: const Value('weekly'),
      ),
    );
    
    // Clear old SharedPreferences
    await prefs.clear();
  }

  // CRUD helpers for Transactions
  Future<int> insertTransaction(TransactionsCompanion companion) => into(transactions).insert(companion);
  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
  Future<int> deleteTransactionById(int id) => 
    (delete(transactions)..where((tbl) => tbl.id.equals(id))).go();

  // CRUD helpers for Goals
  Future<int> insertGoal(GoalsCompanion companion) => into(goals).insert(companion);
  Future<List<Goal>> getAllGoals() => select(goals).get();

  // CRUD helpers for Loans
  Future<int> insertLoan(LoansCompanion companion) => into(loans).insert(companion);
  Future<List<Loan>> getAllLoans() => select(loans).get();
  
  // CRUD helpers for pending SMS transactions
  Future<int> insertPending(PendingTransactionsCompanion companion) => into(pendingTransactions).insert(companion);
  Future<List<PendingTransaction>> getAllPending(int profileId) =>
    (select(pendingTransactions)..where((tbl) => tbl.profileId.equals(profileId))).get();
  Future<int> deletePending(String id) =>
    (delete(pendingTransactions)..where((tbl) => tbl.id.equals(id))).go();

  // CRUD helpers for UserProfiles
  Future<UserProfile?> getUserProfileByAuthId(String authId) =>
    (select(userProfiles)..where((tbl) => tbl.authId.equals(authId)))
      .getSingleOrNull();
  
  Future<int> insertUserProfile(UserProfilesCompanion companion) =>
    into(userProfiles).insert(companion);
  
  Future<bool> updateUserProfile(UserProfilesCompanion companion) =>
    update(userProfiles).replace(companion);

  // AppSettings helpers
  Future<AppSetting?> getAppSettings() =>
    (select(appSettings)..where((tbl) => tbl.id.equals(1)))
      .getSingleOrNull();
  
  Future<int> insertAppSettings(AppSettingsCompanion companion) =>
    into(appSettings).insert(companion);
  
  Future<bool> updateAppSettings(AppSettingsCompanion companion) =>
    update(appSettings).replace(companion);

  // Notifications helpers
  Future<int> insertNotification(NotificationsCompanion companion) =>
    into(notifications).insert(companion);
  
  Future<List<Notification>> getUnreadNotifications(int profileId) =>
    (select(notifications)
      ..where((tbl) => tbl.profileId.equals(profileId) & tbl.isRead.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.scheduledFor, mode: OrderingMode.desc)]))
      .get();
  
  Future<List<Notification>> getAllNotifications(int profileId) =>
    (select(notifications)
      ..where((tbl) => tbl.profileId.equals(profileId))
      ..orderBy([(t) => OrderingTerm(expression: t.scheduledFor, mode: OrderingMode.desc)]))
      .get();
  
  Future<int> markNotificationAsRead(int id) =>
    (update(notifications)..where((tbl) => tbl.id.equals(id)))
      .write(const NotificationsCompanion(isRead: Value(true)));
  
  Future<int> deleteOldNotifications(DateTime before) =>
    (delete(notifications)..where((tbl) => tbl.scheduledFor.isSmallerThanValue(before)))
      .go();
    (delete(pendingTransactions)..where((tbl) => tbl.id.equals(id))).go();

  // Category operations
  Future<int> insertCategory(CategoriesCompanion category) => 
      into(categories).insert(category);
  
  Future<List<Category>> getCategories(int profileId) =>
      (select(categories)..where((c) => c.profileId.equals(profileId))).get();
      
  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();
      
  Stream<List<Category>> watchCategories(int profileId) =>
      (select(categories)..where((c) => c.profileId.equals(profileId))).watch();

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  // Budget operations  
  Future<int> saveBudget(BudgetsCompanion budget) =>
      into(budgets).insert(budget);
      
  Future<List<Budget>> getAllBudgets(int profileId) =>
      (select(budgets)..where((b) => b.profileId.equals(profileId))).get();
      
  Future<Budget?> getCurrentBudget(int profileId) =>
      (select(budgets)
        ..where((b) => b.profileId.equals(profileId))
        ..where((b) => b.startDate.lessOrEqual(currentDate()))
        ..where((b) => b.endDate.greaterOrEqual(currentDate()))
      ).getSingleOrNull();

  Future<int> deleteBudget(int id) =>
      (delete(budgets)..where((b) => b.id.equals(id))).go();
      
  Future<int> updateBudget(int id, BudgetsCompanion budget) =>
      (update(budgets)..where((b) => b.id.equals(id))).write(budget);

  Future<int> updateCategory(int id, CategoriesCompanion category) =>
      (update(categories)..where((c) => c.id.equals(id))).write(category);
      
  Stream<List<Budget>> watchBudgets(int profileId) =>
      (select(budgets)..where((b) => b.profileId.equals(profileId))).watch();
}

/// Opens a regular SQLite database without encryption for now
LazyDatabase _openEncryptedConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'fedha.sqlite'));
    
    // Open a normal SQLite database without encryption
    return NativeDatabase(file);
  });
}
