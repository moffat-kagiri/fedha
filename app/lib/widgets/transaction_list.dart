// app/lib/widgets/transaction_list.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionBox = Hive.box<Transaction>('transactions');

    return ValueListenableBuilder<Box<Transaction>>(
      valueListenable: transactionBox.listenable(),
      builder: (context, box, _) {
        return ListView.builder(
          itemCount: box.length,
          itemBuilder: (context, index) {
            final transaction = box.getAt(index);
            return ListTile(
              leading: Icon(
                // ignore: unrelated_type_equality_checks
                transaction!.type == 'IN'
                    ? Icons.arrow_circle_up
                    : Icons.arrow_circle_down,
                color: transaction.type == 'IN' ? Colors.green : Colors.red,
              ),
              title: Text(transaction.category as String),
              subtitle: Text(transaction.date.toString()),
              trailing: Text('\$${transaction.amount.toStringAsFixed(2)}'),
            );
          },
        );
      },
    );
  }
}
