// lib/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionBox = Provider.of<Box<Transaction>>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: ValueListenableBuilder(
        valueListenable: transactionBox.listenable(),
        builder: (context, Box<Transaction> box, _) {
          final transactions = box.values.toList();

          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions yet'));
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return ListTile(
                title: Text('\$${transaction.amount.toStringAsFixed(2)}'),
                subtitle: Text(transaction.category.toString().split('.').last),
                trailing: Text(transaction.date.toString().split(' ')[0]),
              );
            },
          );
        },
      ),
    );
  }
}
