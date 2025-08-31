import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import '../data/app_database.dart';
import '../services/currency_service.dart';
import 'transaction_dialog.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final Function(Transaction)? onEdit;
  final Function(Transaction)? onDelete;
  final bool showEditOptions;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
    this.showEditOptions = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyService>(
      builder: (context, currencyService, child) {
        final (icon, color) = _getTransactionIconAndColor(transaction.isExpense);
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: InkWell(
            onTap: onTap ?? () => _showTransactionDetails(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Transaction Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Transaction Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description ?? 'No description',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StreamBuilder<Category?>(
                          stream: Provider.of<AppDatabase>(context, listen: false)
                              .select(Provider.of<AppDatabase>(context, listen: false).categories)
                              .watchSingleWhere((cat) => cat.id.equals(transaction.categoryId)),
                          builder: (context, snapshot) {
                            final category = snapshot.data;
                            return Row(
                              children: [
                                if (category != null)
                                  Icon(
                                    Icons.folder_outlined,  // Use a default icon
                                    size: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                else
                                  Icon(
                                    Icons.category_outlined,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  snapshot.data?.name ?? 'No category',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: snapshot.data != null 
                                      ? Color(snapshot.data!.colorValue)
                                      : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(transaction.date),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Amount and Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyService.formatCurrency(transaction.amountMinor / 100),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (showEditOptions) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _editTransaction(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _deleteTransaction(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  (IconData, Color) _getTransactionIconAndColor(bool isExpense) {
    if (isExpense) {
      return (Icons.remove_circle, Colors.red);
    } else {
      return (Icons.add_circle, Colors.green);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showTransactionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transaction Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Amount:', Provider.of<CurrencyService>(context, listen: false)
                .formatCurrency(transaction.amountMinor / 100)),
              _buildDetailRow('Type:', transaction.isExpense ? 'EXPENSE' : 'INCOME'),
              _buildDetailRow('Category:', transaction.categoryId.toString()),
              _buildDetailRow('Description:', transaction.description),
              _buildDetailRow('Date:', '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editTransaction(context);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _editTransaction(BuildContext context) {
    TransactionDialog.showEditDialog(
      context,
      transaction: transaction,
      onTransactionSaved: (updatedTransaction) {
        onEdit?.call(updatedTransaction);
      },
    );
  }

  void _deleteTransaction(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call(transaction);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
