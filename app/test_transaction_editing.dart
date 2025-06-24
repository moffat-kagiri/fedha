// test_transaction_editing.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fedha/models/transaction.dart';
import 'package:fedha/services/offline_data_service.dart';

void main() {
  group('Transaction Editing Tests', () {
    late OfflineDataService dataService;
    late String testProfileId;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();

      // Register required adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TransactionAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(TransactionCategoryAdapter());
      }
    });

    setUp(() async {
      // Open test boxes
      await Hive.openBox<Transaction>('test_transactions');

      dataService = OfflineDataService();
      testProfileId = 'test-profile-123';
    });

    tearDown(() async {
      // Clean up test data
      await Hive.box<Transaction>('test_transactions').clear();
    });

    test('should save and update transaction successfully', () async {
      // Create a test transaction
      final transaction = Transaction(
        amount: 100.0,
        type: TransactionType.expense,
        category: TransactionCategory.groceries,
        date: DateTime.now(),
        description: 'Original Description',
        profileId: testProfileId,
      );

      // Save the transaction
      await dataService.saveTransaction(transaction);

      // Verify it was saved
      final savedTransaction = await dataService.getTransaction(
        transaction.uuid,
      );
      expect(savedTransaction, isNotNull);
      expect(savedTransaction!.description, equals('Original Description'));

      // Update the transaction
      savedTransaction.description = 'Updated Description';
      savedTransaction.amount = 150.0;

      await dataService.updateTransaction(savedTransaction);

      // Verify the update
      final updatedTransaction = await dataService.getTransaction(
        transaction.uuid,
      );
      expect(updatedTransaction, isNotNull);
      expect(updatedTransaction!.description, equals('Updated Description'));
      expect(updatedTransaction.amount, equals(150.0));
    });

    test('should handle transaction list refresh', () async {
      // Create multiple transactions
      final transactions = [
        Transaction(
          amount: 50.0,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: DateTime.now(),
          description: 'Income 1',
          profileId: testProfileId,
        ),
        Transaction(
          amount: 30.0,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime.now(),
          description: 'Expense 1',
          profileId: testProfileId,
        ),
      ];

      // Save all transactions
      for (final transaction in transactions) {
        await dataService.saveTransaction(transaction);
      }

      // Get all transactions for profile
      final allTransactions = await dataService.getAllTransactions(
        testProfileId,
      );
      expect(allTransactions.length, equals(2));

      // Update one transaction
      allTransactions[0].description = 'Modified Income';
      await dataService.updateTransaction(allTransactions[0]);

      // Verify the list still contains the updated transaction
      final refreshedTransactions = await dataService.getAllTransactions(
        testProfileId,
      );
      expect(refreshedTransactions.length, equals(2));

      final updatedTransaction = refreshedTransactions.firstWhere(
        (t) => t.uuid == allTransactions[0].uuid,
      );
      expect(updatedTransaction.description, equals('Modified Income'));
    });
  });
}
