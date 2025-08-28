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
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  TextColumn get description => text()();
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
  TextColumn get currency => text().withLength(min: 3, max: 3)();
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

/// Table for storing SMS-derived pending transactions prior to user review.
class PendingTransactions extends Table {
  TextColumn get id => text()();
  RealColumn get amountMinor => real().map(const _DecimalConverter())();
  TextColumn get currency => text().withLength(min: 3, max: 3).withDefault(const Constant('KES'))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isExpense => boolean().withDefault(const Constant(true))();
  TextColumn get rawSms => text().nullable()();
  IntColumn get profileId => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Converter for storing Decimal amounts in a real column
class _DecimalConverter extends TypeConverter<double, double> {
  const _DecimalConverter();
  @override
  double fromSql(double fromDb) => fromDb / 100;
  @override
  double toSql(double value) => value * 100;
}

@DriftDatabase(tables: [Transactions, Goals, Loans, PendingTransactions])
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
  int get schemaVersion => 1;

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
