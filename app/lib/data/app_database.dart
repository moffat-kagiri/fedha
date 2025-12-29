import 'dart:io';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Drift table + Database (Service file)
class RiskAssessments extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get userId => text().nullable()();
  TextColumn get goal => text().nullable()();
  RealColumn get incomeRatio => real().withDefault(Constant(50.0))();
  RealColumn get desiredReturnRatio => real().withDefault(Constant(50.0))();
  IntColumn get timeHorizon => integer().withDefault(Constant(5))();
  IntColumn get lossToleranceIndex => integer().nullable()();
  IntColumn get experienceIndex => integer().nullable()();
  IntColumn get volatilityReactionIndex => integer().nullable()();
  IntColumn get liquidityNeedIndex => integer().nullable()();
  IntColumn get emergencyFundMonths => integer().withDefault(Constant(3))();
  RealColumn get riskScore => real().withDefault(Constant(0.0))();
  TextColumn get profile => text().nullable()();
  TextColumn get allocationJson => text().nullable()();
  TextColumn get answersJson => text().nullable()();
}

// Update the DriftDatabase annotation:
@DriftDatabase(tables: [Transactions, Goals, Loans, PendingTransactions, RiskAssessments])

// Table for storing financial transactions.
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
  TextColumn get goalId => text().nullable()();
  TextColumn get transactionType => text().withDefault(const Constant('expense'))();
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
  RealColumn get currentMinor => real().withDefault(const Constant(0.0))();
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

// Table for storing SMS-derived pending transactions prior to user review.
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

// Converter for storing Decimal amounts in a real column
class _DecimalConverter extends TypeConverter<double, double> {
  const _DecimalConverter();
  @override
  double fromSql(double fromDb) => fromDb / 100;
  @override
  double toSql(double value) => value * 100;
}

@DriftDatabase(tables: [Transactions, Goals, Loans, PendingTransactions, RiskAssessments])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(QueryExecutor e) : super(e);
  static AppDatabase? _instance;
  factory AppDatabase() {
    if (_instance != null) return _instance!;
    final executor = _openEncryptedConnection();
    _instance = AppDatabase._internal(executor);
    return _instance!;
  }

  // ⭐ UPDATE schema version
  @override
  int get schemaVersion => 3; // Changed from 2 to 3

  // ⭐ ADD migration
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          await m.addColumn(goals, goals.currentMinor);
          await _migrateGoalProgress(); // Calculate existing progress
        }
      },
    );
  }

  // Helper method to migrate existing goal progress
  Future<void> _migrateGoalProgress() async {
    try {
      print('🔄 Migrating goal progress...');
      
      // Get all goals
      final allGoals = await select(goals).get();
      
      // Get all transactions
      final allTransactions = await select(transactions).get();
      
      // For each goal, calculate current amount from transactions
      for (final goal in allGoals) {
        final goalTransactions = allTransactions.where((tx) =>
          tx.transactionType?.contains('savings') == true &&
          tx.goalId == goal.id.toString()
        );
        
        final totalSavings = goalTransactions.fold<double>(
          0.0,
          (sum, tx) => sum + tx.amountMinor,
        );
        
        // Update goal with calculated currentMinor
        await (update(goals)..where((g) => g.id.equals(goal.id)))
          .write(GoalsCompanion(
            currentMinor: Value(totalSavings),
          ));
      }
      
      print('✅ Goal progress migration complete');
    } catch (e) {
      print('⚠️ Error migrating goal progress: $e');
      // Don't throw - migration should continue even if this fails
    }
  }

  // CRUD helpers for Transactions
  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
    Future<Transaction?> getTransactionById(int id) async {
    return await (select(transactions)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }
  Future<int> deleteTransactionById(int id) => 
    (delete(transactions)..where((tbl) => tbl.id.equals(id))).go();
  Future<int> insertTransaction(TransactionsCompanion companion) => into(transactions).insert(companion);

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
}

/// Opens a regular SQLite database without encryption for now
LazyDatabase _openEncryptedConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'fedha.sqlite'));
    return NativeDatabase(file);
  });
}
