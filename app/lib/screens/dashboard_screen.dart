// app/lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../widgets/summary_card.dart';
import '../widgets/cash_flow_chart.dart';
import '../widgets/transaction_list.dart';
import 'add_transaction.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final syncService = Provider.of<SyncService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => syncService.syncTransactions(authService.currentProfileId!),
          ),
        ],
      ),
      body: Consumer<Box<Transaction>>(
        builder: (context, transactionBox, _) {
          final transactions = transactionBox.values.toList().cast<Transaction>();
          
          // Calculate totals
          double income = transactions
              .where((t) => t.type == 'IN')
              .fold(0, (sum, t) => sum + t.amount);
          
          double expense = transactions
              .where((t) => t.type == 'EX')
              .fold(0, (sum, t) => sum + t.amount);

          return Column(
            children: [
              // Summary Cards
              Row(
                children: [
                  SummaryCard(title: 'Income', amount: income),
                  SummaryCard(title: 'Expense', amount: expense),
                  SummaryCard(title: 'Balance', amount: income - expense),
                ],
              ),

              // Chart
              Expanded(
                child: CashFlowChart(transactions: transactions),
              ),

              // Recent Transactions
              const Expanded(
                child: TransactionList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}