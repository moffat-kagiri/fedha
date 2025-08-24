import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Table for storing transactions with an encrypted relational schema.
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  RealColumn get amountMinor => real()().map(const _DecimalConverter());
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
  RealColumn get principalMinor => real().map(const _DecimalConverter())();
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  RealColumn get interestRate => real()(); // percent
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  IntColumn get profileId => integer()();
}

/// Converter for storing Decimal amounts in a real column
class _DecimalConverter extends TypeConverter<double, double> {
  const _DecimalConverter();
  @override
  double mapToDart(double fromDb) => fromDb / 100; // e.g. cents→dollars
  @override
  double mapToSql(double value) => value * 100; // dollars→cents
}

@DriftDatabase(tables: [Transactions, Goals, Loans])
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

  // Add DAOs or helper methods here
  Future<int> insertTransaction(TransactionsCompanion companion) => into(transactions).insert(companion);
  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
}

/// Opens a SQLCipher encrypted database, generating or retrieving a key from secure storage.
LazyDatabase _openEncryptedConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'fedha.sqlite'));
    const storage = FlutterSecureStorage();
    // Retrieve or generate encryption key
    var key = await storage.read(key: 'sqlcipher_key');
    if (key == null) {
      final rnd = Random.secure();
      final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
      key = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await storage.write(key: 'sqlcipher_key', value: key);
    }
    // Open SQLite database with SQLCipher key
    return NativeDatabase(
      file,
      setup: (db) async {
        await db.execute('PRAGMA key = "${key}"');
      },
    );
  });
}
