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
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF007A39),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    editingTransaction != null ? Icons.edit : Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      editingTransaction != null ? 'Edit $title' : 'Add $title',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: QuickTransactionEntry(
                  editingTransaction: editingTransaction,
                  onTransactionSaved: (transaction) {
                    Navigator.pop(context);
                    onTransactionSaved?.call(transaction);
                  },
                ),
              ),
            ),
          ],
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
