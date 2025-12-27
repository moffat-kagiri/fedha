// app/lib/widgets/transaction_list.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get the box once - we know it exists because we open it in main()
    final transactionBox = Hive.box<Transaction>('transactions');

    return ValueListenableBuilder<Box<Transaction>>(
      valueListenable: transactionBox.listenable(),
      builder: (context, box, _) {
        // Since we know the box exists, we can safely use ! or cast
        final safeBox = box; // The builder receives a non-null box
        
        if (safeBox.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: theme.colorScheme.onBackground.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: safeBox.length, // Now definitely non-null
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final transaction = safeBox.getAt(index);
            if (transaction == null) return const SizedBox.shrink();

            final isIncome = transaction.type == 'IN';
            final iconColor = isIncome ? FedhaColors.successGreen : FedhaColors.errorRed;
            final amountColor = isIncome ? FedhaColors.successGreen : FedhaColors.errorRed;
            
            final formattedDate = _formatDate(transaction.date);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isIncome 
                      ? FedhaColors.successGreen.withOpacity(0.1)
                      : FedhaColors.errorRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                title: Text(
                  transaction.category,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) return 'Today';
    if (transactionDate == yesterday) return 'Yesterday';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}