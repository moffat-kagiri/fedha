// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the provided Hive box
    final transactionBox = Provider.of<Box<Transaction>>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ValueListenableBuilder(
        valueListenable: transactionBox.listenable(),
        builder: (context, Box<Transaction> box, _) {
          final transactions = box.values.toList();

          // Calculate totals
          double income = transactions
              .where((t) => t.type == TransactionType.income)
              .fold(0, (sum, t) => sum + t.amount);

          double expenses = transactions
              .where((t) => t.type == TransactionType.expense)
              .fold(0, (sum, t) => sum + t.amount);

          return Column(
            children: [
              // Summary cards
              Row(
                children: [
                  _buildSummaryCard('Income', income),
                  _buildSummaryCard('Expenses', expenses),
                  _buildSummaryCard('Balance', income - expenses),
                ],
              ),
              // Transaction list
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return ListTile(
                      title: Text(transaction.amount.toString()),
                      subtitle: Text(transaction.category.toString()),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [Text(title), Text(amount.toStringAsFixed(2))]),
      ),
    );
  }
}
// This widget builds a summary card for the dashboard.
// It takes a title and an amount as parameters and displays them.