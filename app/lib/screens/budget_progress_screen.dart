// lib/screens/budget_progress_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../services/transaction_event_service.dart';
import '../screens/budget_review_screen.dart';
import '../services/currency_service.dart';

class BudgetProgressScreen extends StatefulWidget {
  const BudgetProgressScreen({super.key});

  @override
  State<BudgetProgressScreen> createState() => _BudgetProgressScreenState();
}

class _BudgetProgressScreenState extends State<BudgetProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Budget> _allBudgets = [];
  Map<String, double> _unbudgetedSpending = {};
  StreamSubscription<TransactionEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _setupEventListeners();
  }

  void _setupEventListeners() {
    final eventService = Provider.of<TransactionEventService>(context, listen: false);
    
    _eventSubscription = eventService.eventStream.listen((event) {
      if (event.transaction.type == Type.expense) {
        _loadData(); // Refresh when expenses change
      }
    });
  }

  /// ✅ FIX: Normalize category IDs to consistent format
  String _normalizeCategoryId(String category) {
    return category.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // ✅ FIX: Validate profile exists and is properly initialized
      if (!authService.hasActiveProfile) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a profile to view budgets'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final profileId = authService.currentProfile!.id; // ✅ Now safe to force unwrap

      final budgets = await offlineDataService.getAllBudgets(profileId);
      final unbudgeted = await _loadUnbudgetedSpending(profileId);

      setState(() {
        _allBudgets = budgets;
        _unbudgetedSpending = unbudgeted;
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

  Future<Map<String, double>> _loadUnbudgetedSpending(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, double> unbudgeted = {};
    
    // ✅ FIX: Use consistent category ID normalization
    final categories = ['food', 'transport', 'utilities', 'shopping', 
                       'entertainment', 'healthcare', 'education', 'savings', 'other'];

    for (final category in categories) {
      // ✅ FIX: Normalize category ID format (lowercase, underscores)
      final normalizedCategory = _normalizeCategoryId(category);
      final key = 'unbudgeted_${profileId}_$normalizedCategory';
      final amount = prefs.getDouble(key) ?? 0.0;
      if (amount > 0) {
        unbudgeted[normalizedCategory] = amount;
      }
    }

    return unbudgeted;
  }

  List<Budget> get _activeBudgets =>
      _allBudgets.where((b) => b.isCurrent && b.isActive).toList();

  List<Budget> get _completedBudgets =>
      _allBudgets.where((b) => b.isExpired).toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));

  List<Budget> get _upcomingBudgets =>
      _allBudgets.where((b) => b.isUpcoming && b.isActive).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Progress'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/create_budget').then((_) => _loadData());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: colorScheme.onPrimary,
          tabs: [
            Tab(text: 'Active (${_activeBudgets.length})'),
            Tab(text: 'History (${_completedBudgets.length})'),
            Tab(text: 'Upcoming (${_upcomingBudgets.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveBudgetsTab(),
                _buildHistoryTab(),
                _buildUpcomingTab(),
              ],
            ),
    );
  }

  Widget _buildActiveBudgetsTab() {
    if (_activeBudgets.isEmpty) {
      return _buildEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No Active Budgets',
        message: 'Create a budget to start tracking your spending!',
        actionLabel: 'Create Budget',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverallSummary(_activeBudgets),
          const SizedBox(height: 24),
          if (_unbudgetedSpending.isNotEmpty) ...[
            _buildUnbudgetedSpendingCard(),
            const SizedBox(height: 24),
          ],
          ..._activeBudgets.map((budget) => _buildBudgetCard(budget)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_completedBudgets.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Budget History',
        message: 'Complete your first budget cycle to see your progress here!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHistorySummary(),
          const SizedBox(height: 24),
          ..._completedBudgets.map((budget) => _buildHistoryBudgetCard(budget)),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingBudgets.isEmpty) {
      return _buildEmptyState(
        icon: Icons.upcoming,
        title: 'No Upcoming Budgets',
        message: 'Plan ahead by creating budgets for future periods!',
        actionLabel: 'Create Budget',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _upcomingBudgets.map((budget) => _buildUpcomingBudgetCard(budget)).toList(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              title,
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/create_budget').then((_) => _loadData());
                },
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSummary(List<Budget> budgets) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.budgetAmount);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
    final remaining = totalBudget - totalSpent;
    final progress = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;

    final color = progress > 0.9
        ? FedhaColors.errorRed
        : progress > 0.75
            ? FedhaColors.warningOrange
            : FedhaColors.successGreen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Progress',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Budget', totalBudget, colorScheme.onSurface),
                _buildSummaryItem('Spent', totalSpent, color),
                _buildSummaryItem('Remaining', remaining, 
                    remaining >= 0 ? FedhaColors.successGreen : FedhaColors.errorRed),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: colorScheme.surfaceVariant,
              color: color,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% used',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                if (progress < 1.0)
                  Text(
                    '${((1 - progress) * 100).toStringAsFixed(1)}% remaining',
                    style: textTheme.bodySmall?.copyWith(
                      color: FedhaColors.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          'KSh ${amount.toStringAsFixed(0)}',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildUnbudgetedSpendingCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = _unbudgetedSpending.values.fold(0.0, (sum, amt) => sum + amt);

    return Card(
      color: colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: colorScheme.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unbudgeted Spending',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
                Text(
                  'KSh ${total.toStringAsFixed(0)}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You\'ve spent in categories without budgets. Consider adding budgets for these to track better!',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            ..._unbudgetedSpending.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                    Text(
                      'KSh ${entry.value.toStringAsFixed(0)}',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final currencyService = context.read<CurrencyService>();
    final isOverBudget = budget.isOverBudget;
    final statusColor = isOverBudget 
        ? Colors.red 
        : budget.spentPercentage >= 80 
            ? Colors.orange 
            : FedhaColors.primaryGreen;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = budget.budgetAmount > 0 ? (budget.spentAmount / budget.budgetAmount) : 0.0;
    final remaining = budget.budgetAmount - budget.spentAmount;
    final daysLeft = budget.endDate.difference(DateTime.now()).inDays;
    
    final color = progress > 0.9
        ? FedhaColors.errorRed
        : progress > 0.75
            ? FedhaColors.warningOrange
            : FedhaColors.successGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            const SizedBox(height: 16),
            
            // Add Review Button at the bottom
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/budget_review',
                    arguments: budget,
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('Review Budget Performance'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FedhaColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySummary() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final totalBudgets = _completedBudgets.length;
    final completedOnBudget = _completedBudgets
        .where((b) => b.spentAmount <= b.budgetAmount)
        .length;
    final successRate = totalBudgets > 0 ? (completedOnBudget / totalBudgets) * 100 : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget History Summary',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHistorySummaryItem('Total Periods', totalBudgets.toString(), colorScheme.onSurface),
                _buildHistorySummaryItem('On Budget', completedOnBudget.toString(), FedhaColors.successGreen),
                _buildHistorySummaryItem('Success Rate', '${successRate.toStringAsFixed(0)}%', 
                    successRate >= 70 ? FedhaColors.successGreen : FedhaColors.warningOrange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySummaryItem(String label, String value, Color color) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryBudgetCard(Budget budget) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = budget.budgetAmount > 0 ? (budget.spentAmount / budget.budgetAmount) : 0.0;
    final wasSuccessful = budget.spentAmount <= budget.budgetAmount;
    
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
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: wasSuccessful 
                        ? FedhaColors.successGreen.withOpacity(0.1)
                        : FedhaColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    wasSuccessful ? 'On Budget' : 'Over Budget',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: wasSuccessful ? FedhaColors.successGreen : FedhaColors.errorRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(budget.startDate)} - ${_formatDate(budget.endDate)}',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'KSh ${budget.spentAmount.toStringAsFixed(0)}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: wasSuccessful ? FedhaColors.successGreen : FedhaColors.errorRed,
                  ),
                ),
                Text(
                  'of KSh ${budget.budgetAmount.toStringAsFixed(0)}',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: colorScheme.surfaceVariant,
              color: wasSuccessful ? FedhaColors.successGreen : FedhaColors.errorRed,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            if (!wasSuccessful) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FedhaColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates, color: FedhaColors.errorRed, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You exceeded by KSh ${(budget.spentAmount - budget.budgetAmount).toStringAsFixed(0)}. '
                        'Consider allocating more to this category next time.',
                        style: textTheme.bodySmall?.copyWith(color: FedhaColors.errorRed),
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

  Widget _buildUpcomingBudgetCard(Budget budget) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final daysUntilStart = budget.startDate.difference(DateTime.now()).inDays;

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
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FedhaColors.infoBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Starts in $daysUntilStart days',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: FedhaColors.infoBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(budget.startDate)} - ${_formatDate(budget.endDate)}',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (budget.description != null && budget.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                budget.description!,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Planned Budget:',
                  style: textTheme.bodyMedium,
                ),
                Text(
                  'KSh ${budget.budgetAmount.toStringAsFixed(0)}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: FedhaColors.infoBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}