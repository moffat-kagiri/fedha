// app/lib/widgets/transaction_list.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionBox = Hive.box<Transaction>('transactions');

    return ListView.builder(
      itemCount: transactionBox.length,
      itemBuilder: (context, index) {
        final transaction = transactionBox.getAt(index);
        return ListTile(
          leading: Icon(
            transaction!.type == 'IN' 
              ? Icons.arrow_circle_up 
              : Icons.arrow_circle_down,
            color: transaction.type == 'IN' ? Colors.green : Colors.red,
          ),
          title: Text(transaction.category),
          subtitle: Text(transaction.date.toString()),
          trailing: Text('\$${transaction.amount.toStringAsFixed(2)}'),
        );
      },
    );
  }
}