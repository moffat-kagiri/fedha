import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../screens/transaction_entry_unified_screen.dart';
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import 'package:provider/provider.dart';

class TransactionDialog extends StatelessWidget {
  final Transaction transaction;
  final void Function(Transaction) onSave;

  const TransactionDialog({
    super.key,
    required this.transaction,
    required this.onSave,
  });

  String _prettyEnum(Object? value) {
    if (value == null) return 'Unknown';
    final raw = value.toString().split('.').last;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _categoryToString(TransactionCategory? category) {
    if (category == null) return 'Other';
    return category.name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Details',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Amount', 'KSh ${transaction.amount.toStringAsFixed(2)}', context),
            _buildDetailRow('Category', _categoryToString(transaction.category), context),
            _buildDetailRow('Date', _formatDate(transaction.date), context),
            _buildDetailRow('Type', _prettyEnum(transaction.type), context),
            if (transaction.description?.isNotEmpty == true)
              _buildDetailRow('Description', transaction.description!, context),
            if (transaction.notes?.isNotEmpty == true)
              _buildDetailRow('Notes', transaction.notes!, context),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to edit screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionEntryUnifiedScreen(
                            editingTransaction: transaction,
                          ),
                        ),
                      ).then((updatedTransaction) {
                        if (updatedTransaction != null) {
                          onSave(updatedTransaction);
                        }
                      });
                    },
                    child: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Static helper method to open add-transaction screen
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

  /// Static helper method to open edit-transaction screen
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