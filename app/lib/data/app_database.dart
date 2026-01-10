// app/lib/data/app_database.dart - UPDATED WITH MIGRATIONS
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ==================== TABLES ====================

/// Table for storing financial transactions
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // Core transaction fields
  RealColumn get amountMinor => real().map(const _DecimalConverter())();
  TextColumn get currency => text().withDefault(const Constant('KES'))();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  TextColumn get description => text().withDefault(const Constant(''))();
  
  // Category stored as string (not FK)
  TextColumn get category => text().withDefault(const Constant(''))();
  
  // Goal stored as string (not FK)
  TextColumn get goalId => text().nullable()();
  
  DateTimeColumn get date => dateTime()();
  BoolColumn get isExpense => boolean().withDefault(const Constant(true))();
  BoolColumn get isPending => boolean().withDefault(const Constant(false))();
  
  // SMS source
  TextColumn get rawSms => text().nullable()();
  
  // Profile ID
  IntColumn get profileId => integer()();
  
  // Budget category (string)
  TextColumn get budgetCategory => text().nullable()();
  
  // Additional fields
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get merchantName => text().nullable()();
  TextColumn get merchantCategory => text().nullable()();
  TextColumn get tags => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get recipient => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  
  // Sync fields
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get remoteId => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table for storing goals
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get targetMinor => real().map(const _DecimalConverter())();
  RealColumn get currentMinor => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('KES'))();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get profileId => integer()();
  
  // Sync fields
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get remoteId => text().nullable()();
  
  TextColumn get goalType => text().withDefault(const Constant('savings'))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get description => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table for storing loans:
class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get name => text().withLength(min: 1, max: 255)();
  
  // CHANGED: principal_amount (major units)
  RealColumn get principalAmount => real()();
  
  TextColumn get currency => text().withDefault(const Constant('KES'))();
  RealColumn get interestRate => real()();
  
  // NEW: interest_model field
  TextColumn get interestModel => text().withDefault(const Constant('simple'))();
  
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  IntColumn get profileId => integer()();
  TextColumn get description => text().nullable()();
  
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get remoteId => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Table for storing SMS-derived pending transactions
class PendingTransactions extends Table {
  TextColumn get id => text()();
  RealColumn get amountMinor => real().map(const _DecimalConverter())();
  TextColumn get currency => text().withDefault(const Constant('KES'))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isExpense => boolean().withDefault(const Constant(true))();
  TextColumn get rawSms => text().nullable()();
  IntColumn get profileId => integer()();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  TextColumn get category => text().withDefault(const Constant(''))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Table for risk assessments
class RiskAssessments extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get userId => text().nullable()();
  TextColumn get goal => text().nullable()();
  RealColumn get incomeRatio => real().withDefault(const Constant(50.0))();
  RealColumn get desiredReturnRatio => real().withDefault(const Constant(50.0))();
  IntColumn get timeHorizon => integer().withDefault(const Constant(5))();
  IntColumn get lossToleranceIndex => integer().nullable()();
  IntColumn get experienceIndex => integer().nullable()();
  IntColumn get volatilityReactionIndex => integer().nullable()();
  IntColumn get liquidityNeedIndex => integer().nullable()();
  IntColumn get emergencyFundMonths => integer().withDefault(const Constant(3))();
  RealColumn get riskScore => real().withDefault(const Constant(0.0))();
  TextColumn get profile => text().nullable()();
  TextColumn get allocationJson => text().nullable()();
  TextColumn get answersJson => text().nullable()();
}

// ==================== CONVERTER ====================

/// Converter for storing amounts in minor units (cents)
class _DecimalConverter extends TypeConverter<double, double> {
  const _DecimalConverter();
  
  @override
  double fromSql(double fromDb) => fromDb / 100;
  
  @override
  double toSql(double value) => value * 100;
}

// ==================== DATABASE ====================

@DriftDatabase(tables: [
  Transactions,
  Goals,
  Loans,
  PendingTransactions,
  RiskAssessments,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(QueryExecutor e) : super(e);
  
  static AppDatabase? _instance;
  
  factory AppDatabase() {
    if (_instance != null) return _instance!;
    final executor = _openConnection();
    _instance = AppDatabase._internal(executor);
    return _instance!;
  }

  @override
  int get schemaVersion => 5; // Incremented for new migration

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration from version 3 to 4: Add sync fields
        if (from < 4) {
          await m.addColumn(transactions, transactions.isSynced);
          await m.addColumn(transactions, transactions.remoteId);
          await m.addColumn(goals, goals.isSynced);
          await m.addColumn(goals, goals.remoteId);
          await m.addColumn(loans, loans.isSynced);
          await m.addColumn(loans, loans.remoteId);
        }
        
        // Migration from version 4 to 5: Update field names and add new fields
        if (from < 5) {
          // Add new transaction fields
          await m.addColumn(transactions, transactions.category);
          await m.addColumn(transactions, transactions.goalId);
          await m.addColumn(transactions, transactions.budgetCategory);
          await m.addColumn(transactions, transactions.paymentMethod);
          await m.addColumn(transactions, transactions.merchantName);
          await m.addColumn(transactions, transactions.merchantCategory);
          await m.addColumn(transactions, transactions.tags);
          await m.addColumn(transactions, transactions.reference);
          await m.addColumn(transactions, transactions.recipient);
          await m.addColumn(transactions, transactions.status);
          await m.addColumn(transactions, transactions.isRecurring);
          await m.addColumn(transactions, transactions.isPending);
          await m.addColumn(transactions, transactions.createdAt);
          await m.addColumn(transactions, transactions.updatedAt);
          
          // Add new goal fields
          await m.addColumn(goals, goals.goalType);
          await m.addColumn(goals, goals.status);
          await m.addColumn(goals, goals.description);
          await m.addColumn(goals, goals.createdAt);
          await m.addColumn(goals, goals.updatedAt);
          
          // Add new loan fields
          await m.addColumn(loans, loans.description);
          await m.addColumn(loans, loans.createdAt);
          await m.addColumn(loans, loans.updatedAt);
          
          // Add new pending transaction fields
          await m.addColumn(pendingTransactions, pendingTransactions.type);
          await m.addColumn(pendingTransactions, pendingTransactions.category);
          
          // Migrate existing data
          await _migrateExistingData();
        }
      },
    );
  }

  /// Migrate existing data to new schema
  Future<void> _migrateExistingData() async {
    try {
      print('🔄 Migrating existing data to new schema...');
      
      // Update transactions: Copy categoryId -> category
      final allTransactions = await select(transactions).get();
      for (final tx in allTransactions) {
        // Note: Old schema had 'categoryId', we need to handle this gracefully
        // Since we're adding new columns, old data will have empty strings
        await (update(transactions)..where((t) => t.id.equals(tx.id)))
          .write(TransactionsCompanion(
            updatedAt: Value(DateTime.now()),
          ));
      }
      
      // Calculate goal progress from transactions
      await _migrateGoalProgress();
      
      print('✅ Data migration complete');
    } catch (e, stackTrace) {
      print('⚠️ Error migrating data: $e');
      print(stackTrace);
    }
  }

  /// Calculate goal progress from transactions
  Future<void> _migrateGoalProgress() async {
    try {
      print('🔄 Calculating goal progress...');
      
      final allGoals = await select(goals).get();
      final allTransactions = await select(transactions).get();
      
      for (final goal in allGoals) {
        final goalTransactions = allTransactions.where((tx) =>
          tx.type.contains('savings') &&
          tx.goalId == goal.id.toString()
        );
        
        final totalSavings = goalTransactions.fold<double>(
          0.0,
          (sum, tx) => sum + tx.amountMinor,
        );
        
        await (update(goals)..where((g) => g.id.equals(goal.id)))
          .write(GoalsCompanion(
            currentMinor: Value(totalSavings),
          ));
      }
      
      print('✅ Goal progress calculated');
    } catch (e) {
      print('⚠️ Error calculating goal progress: $e');
    }
  }

  // ==================== CRUD HELPERS ====================

  // Transactions
  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
  
  Future<Transaction?> getTransactionById(int id) async {
    return await (select(transactions)..where((t) => t.id.equals(id)))
      .getSingleOrNull();
  }
  
  Future<int> deleteTransactionById(int id) => 
    (delete(transactions)..where((t) => t.id.equals(id))).go();
  
  Future<int> insertTransaction(TransactionsCompanion companion) => 
    into(transactions).insert(companion);
  
  Future<bool> updateTransaction(TransactionsCompanion companion) => 
    update(transactions).replace(companion);

  // Goals
  Future<int> insertGoal(GoalsCompanion companion) => into(goals).insert(companion);
  
  Future<List<Goal>> getAllGoals() => select(goals).get();
  
  Future<Goal?> getGoalById(int id) async {
    return await (select(goals)..where((g) => g.id.equals(id)))
      .getSingleOrNull();
  }
  
  Future<bool> updateGoal(GoalsCompanion companion) => 
    update(goals).replace(companion);
  
  Future<int> deleteGoalById(int id) => 
    (delete(goals)..where((g) => g.id.equals(id))).go();

  // Loans
  Future<int> insertLoan(LoansCompanion companion) => into(loans).insert(companion);
  
  Future<List<Loan>> getAllLoans() => select(loans).get();
  
  Future<Loan?> getLoanById(int id) async {
    return await (select(loans)..where((l) => l.id.equals(id)))
      .getSingleOrNull();
  }
  
  Future<bool> updateLoan(LoansCompanion companion) => 
    update(loans).replace(companion);
  
  Future<int> deleteLoanById(int id) => 
    (delete(loans)..where((l) => l.id.equals(id))).go();

  // Pending Transactions
  Future<int> insertPending(PendingTransactionsCompanion companion) => 
    into(pendingTransactions).insert(companion);
  
  Future<List<PendingTransaction>> getAllPending(int profileId) =>
    (select(pendingTransactions)..where((t) => t.profileId.equals(profileId))).get();
  
  Future<int> deletePending(String id) =>
    (delete(pendingTransactions)..where((t) => t.id.equals(id))).go();
}

/// Opens SQLite database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'fedha.sqlite'));
    return NativeDatabase(file);
  });
}
