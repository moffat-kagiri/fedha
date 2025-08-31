import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../screens/transaction_entry_unified_screen.dart';

/// Provides static helpers to navigate to the unified transaction entry screen.
class TransactionDialog {
  /// Open add-transaction screen
  static Future<void> showAddDialog(
    BuildContext context, {
    Function(Transaction)? onTransactionSaved,
  }) {
    return Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (_) => const TransactionEntryUnifiedScreen(),
      ),
    ).then((transaction) {
      if (transaction != null) onTransactionSaved?.call(transaction);
    });
  }

  /// Open edit-transaction screen preloading an existing transaction.
  static Future<void> showEditDialog(
    BuildContext context, {
    required Transaction transaction,
    Function(Transaction)? onTransactionSaved,
  }) {
    return Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionEntryUnifiedScreen(
          editingTransaction: transaction,
        ),
      ),
    ).then((updated) {
      if (updated != null) onTransactionSaved?.call(updated);
    });
  }
}

