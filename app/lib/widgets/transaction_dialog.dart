import 'package:flutter/material.dart';
import '../models/transaction.dart'    }).then((result) {
      if (result != null && result is Transaction) {
        onTransactionSaved?.call(result);
      }
    });
  }
}../screens/transaction_entry_unified_screen.dart';

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
    // Using Navigator.push for the unified screen instead of embedding in a dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context); // Close the dialog
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionEntryUnifiedScreen(
            editingTransaction: editingTransaction,
          ),
        ),
      ).then((result) {
        if (result != null && result is Transaction) {
          onTransactionSaved?.call(result);
        }
      });
    });
    
    // Return loading widget that will be quickly replaced
    return const Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Show transaction dialog for adding
  static Future<void> showAddDialog(
    BuildContext context, {
    Function(Transaction)? onTransactionSaved,
  }) {
    // Directly navigate to the unified screen instead
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionEntryUnifiedScreen(),
      ),
    ).then((result) {
      if (result != null && result is Transaction) {
        onTransactionSaved?.call(result);
      }
    });
  }

  /// Show transaction dialog for editing
  static Future<void> showEditDialog(
    BuildContext context, {
    required Transaction transaction,
    Function(Transaction)? onTransactionSaved,
  }) {
    // Directly navigate to the unified screen instead
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionEntryUnifiedScreen(
          editingTransaction: transaction,
        ),
      ),
    ).then((result) {
      if (result != null && result is Transaction) {
        onTransactionSaved?.call(result);
      }
    });
        title: 'Transaction',
        onTransactionSaved: onTransactionSaved,
      ),
    );
  }
}
