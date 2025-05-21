// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionBox = Provider.of<Box<Transaction>>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ValueListenableBuilder(
        valueListenable: transactionBox.listenable(),
        builder: (context, Box<Transaction> box, _) {
          final transactions = box.values.toList();

          // Calculate totals
          final income = transactions
              .where((t) => t.type == TransactionType.income)
              .fold(0.0, (sum, t) => sum + t.amount);

          final expenses = transactions
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (sum, t) => sum + t.amount);

          return Column(
            children: [
              // Summary Cards
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    _buildSummaryCard(context, 'Income', income, Colors.green),
                    _buildSummaryCard(
                      context,
                      'Expenses',
                      expenses,
                      Colors.red,
                    ),
                    _buildSummaryCard(
                      context,
                      'Balance',
                      income - expenses,
                      Colors.blue,
                    ),
                  ],
                ),
              ),

              // Recent Transactions
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.take(5).length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return ListTile(
                      title: Text('\$${transaction.amount.toStringAsFixed(2)}'),
                      subtitle: Text(
                        transaction.category.toString().split('.').last,
                      ),
                      trailing: Text(transaction.date.toString().split(' ')[0]),
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

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
  ) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
