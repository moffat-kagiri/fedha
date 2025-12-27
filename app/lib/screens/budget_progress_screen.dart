// lib/screens/budget_progress_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../services/transaction_event_service.dart'; 

class BudgetProgressScreen extends StatefulWidget {
  const BudgetProgressScreen({super.key});

  @override
  State<BudgetProgressScreen> createState() => _BudgetProgressScreenState();
}

class _BudgetProgressScreenState extends State<BudgetProgressScreen> {
  bool _isLoading = true;
  List<Budget> _budgets = [];
  List<Transaction> _monthlyTransactions = [];
  StreamSubscription<TransactionEvent>? _eventSubscription; // ADD THIS

  @override
  void initState() {
    super.initState();
    _loadBudgets();
    _setupEventListeners(); // ADD THIS
  }

  // ADD: Setup event listeners
  void _setupEventListeners() {
    final eventService = Provider.of<TransactionEventService>(context, listen: false);
    
    _eventSubscription = eventService.eventStream.listen((event) {
      // Only refresh if it's an expense transaction (affects budgets)
      if (event.transaction.type == TransactionType.expense) {
        _loadBudgets();
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);

    try {
      final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = authService.currentProfile?.id ?? '';

      if (profileId.isEmpty) {
        throw Exception('No active profile');
      }

      final budgets = await offlineDataService.getAllBudgets(profileId);
      final transactions = await offlineDataService.getAllTransactions(profileId);

      // Get current month transactions
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthlyTx = transactions.where(
        (t) => t.date.isAfter(monthStart) && t.date.isBefore(now.add(const Duration(days: 1))),
      ).toList();

      setState(() {
        _budgets = budgets;
        _monthlyTransactions = monthlyTx;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load budgets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final activeBudgets = _budgets.where((b) => b.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Progress'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/create_budget').then((_) => _loadBudgets());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBudgets,
              child: activeBudgets.isEmpty
                  ? _buildEmptyState(context)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverallSummary(colorScheme, textTheme),
                          const SizedBox(height: 24),
                          ...activeBudgets.map((budget) =>
                              _buildBudgetCard(budget, colorScheme, textTheme)),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Budgets',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a budget to track your spending and stay on top of your finances.',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/create_budget').then((_) => _loadBudgets());
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSummary(ColorScheme colorScheme, TextTheme textTheme) {
    final totalBudget = _budgets.where((b) => b.isActive).fold(0.0, (sum, b) => sum + b.budgetAmount);
    final totalSpent = _budgets.where((b) => b.isActive).fold(0.0, (sum, b) => sum + b.spentAmount);
    final remaining = totalBudget - totalSpent;
    final progress = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;

    final color = progress > 0.9 ? FedhaColors.errorRed :
                  progress > 0.75 ? FedhaColors.warningOrange :
                  FedhaColors.successGreen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Budget',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Budget',
                  style: textTheme.bodyMedium,
                ),
                Text(
                  'KSh ${totalBudget.toStringAsFixed(0)}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Spent',
                  style: textTheme.bodyMedium,
                ),
                Text(
                  'KSh ${totalSpent.toStringAsFixed(0)}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'KSh ${remaining.toStringAsFixed(0)}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: remaining >= 0 ? FedhaColors.successGreen : FedhaColors.errorRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: colorScheme.surfaceVariant,
              color: color,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(1)}% of budget used',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget, ColorScheme colorScheme, TextTheme textTheme) {
    final progress = budget.budgetAmount > 0 ? (budget.spentAmount / budget.budgetAmount) : 0.0;
    final remaining = budget.budgetAmount - budget.spentAmount;
    final daysLeft = budget.endDate.difference(DateTime.now()).inDays;

    final color = progress > 0.9 ? FedhaColors.errorRed :
                  progress > 0.75 ? FedhaColors.warningOrange :
                  FedhaColors.successGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    budget.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$daysLeft days left',
                    style: textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (budget.description != null && budget.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                budget.description!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'KSh ${budget.spentAmount.toStringAsFixed(0)}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'of KSh ${budget.budgetAmount.toStringAsFixed(0)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: colorScheme.surfaceVariant,
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% used',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'KSh ${remaining.toStringAsFixed(0)} remaining',
                  style: textTheme.bodySmall?.copyWith(
                    color: remaining >= 0 ? FedhaColors.successGreen : FedhaColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (progress > 0.8) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        progress > 0.9
                            ? 'You\'ve exceeded or nearly reached your budget!'
                            : 'You\'re approaching your budget limit. Consider reducing spending.',
                        style: textTheme.bodySmall?.copyWith(
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}