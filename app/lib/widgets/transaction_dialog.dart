import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'quick_transaction_entry.dart';

class TransactionDialog extends StatelessWidget {
  final Transaction? editingTransaction;
  final String title;
  final Function(Transaction)? onTransactionSaved;

  const TransactionDialog({
    super.key,
    this.editingTransaction,
    this.title = 'Transaction',
    this.onTransactionSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85,
        child: QuickTransactionEntry(
          editingTransaction: editingTransaction,
          onTransactionSaved: (transaction) {
            Navigator.pop(context);
            onTransactionSaved?.call(transaction);
          },
        ),
      ),
    );
  }

  /// Show transaction dialog for adding
  static Future<void> showAddDialog(
    BuildContext context, {
    Function(Transaction)? onTransactionSaved,
  }) {
    return showDialog(
      context: context,
      builder: (context) => TransactionDialog(
        title: 'Transaction',
        onTransactionSaved: onTransactionSaved,
      ),
    );
  }

  /// Show transaction dialog for editing
  static Future<void> showEditDialog(
    BuildContext context, {
    required Transaction transaction,
    Function(Transaction)? onTransactionSaved,
  }) {
    return showDialog(
      context: context,
      builder: (context) => TransactionDialog(
        editingTransaction: transaction,
        title: 'Transaction',
        onTransactionSaved: onTransactionSaved,
      ),
    );
  }
}
