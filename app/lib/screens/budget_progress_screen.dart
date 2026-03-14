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

// ── Data class for a group of budgets sharing the same period ─────────────
class _BudgetPeriodGroup {
  final DateTime startDate;
  final DateTime endDate;
  final List<Budget> budgets;

  _BudgetPeriodGroup({
    required this.startDate,
    required this.endDate,
    required this.budgets,
  });

  double get totalBudgeted =>
      budgets.fold(0.0, (sum, b) => sum + b.budgetAmount);

  double get totalSpent =>
      budgets.fold(0.0, (sum, b) => sum + b.spentAmount);

  bool get wasSuccessful => totalSpent <= totalBudgeted;
}

// ─────────────────────────────────────────────────────────────────────────────

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
    final eventService =
        Provider.of<TransactionEventService>(context, listen: false);

    _eventSubscription = eventService.eventStream.listen((event) {
      final type = event.transaction.type.toLowerCase();
      if (type == 'expense' || type == 'savings') {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final offlineDataService =
          Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

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

      final profileId = authService.currentProfile!.id;
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

  Future<Map<String, double>> _loadUnbudgetedSpending(
      String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, double> unbudgeted = {};
    final allKeys = prefs.getKeys();
    final unbudgetedPrefix = 'unbudgeted_${profileId}_';

    for (final key in allKeys) {
      if (key.startsWith(unbudgetedPrefix)) {
        final categoryKey = key.substring(unbudgetedPrefix.length);
        final amount = prefs.getDouble(key) ?? 0.0;
        if (amount > 0) {
          final displayCategory =
              categoryKey.replaceAll('_', ' ').toLowerCase();
          unbudgeted[displayCategory] = amount;
        }
      }
    }
    return unbudgeted;
  }

  // ── Derived lists ─────────────────────────────────────────────────────────

  List<Budget> get _activeBudgets =>
      _allBudgets.where((b) => b.isCurrent && b.isActive).toList();

  List<Budget> get _completedBudgets =>
      _allBudgets.where((b) => b.isExpired).toList()
        ..sort((a, b) => b.endDate.compareTo(a.endDate));

  List<Budget> get _upcomingBudgets =>
      _allBudgets.where((b) => b.isUpcoming && b.isActive).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

  // ── History grouping ──────────────────────────────────────────────────────

  List<_BudgetPeriodGroup> get _periodGroups {
    final Map<String, _BudgetPeriodGroup> groups = {};
    for (final budget in _completedBudgets) {
      final key =
          '${budget.startDate.toIso8601String()}_${budget.endDate.toIso8601String()}';
      if (groups.containsKey(key)) {
        groups[key]!.budgets.add(budget);
      } else {
        groups[key] = _BudgetPeriodGroup(
          startDate: budget.startDate,
          endDate: budget.endDate,
          budgets: [budget],
        );
      }
    }
    return groups.values.toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));
  }

  // ── Scaffold ──────────────────────────────────────────────────────────────

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
              Navigator.pushNamed(context, '/create_budget')
                  .then((_) => _loadData());
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

  // ── Active tab ────────────────────────────────────────────────────────────

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

  // ── History tab ───────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    if (_completedBudgets.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Budget History',
        message:
            'Complete your first budget cycle to see your progress here!',
      );
    }

    final groups = _periodGroups;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHistorySummary(),
          const SizedBox(height: 24),
          ...groups.map((group) => _buildPeriodGroupCard(group)),
        ],
      ),
    );
  }

  /// Collapsible card representing one time period, containing all budgets
  /// that share the same start and end dates.
  Widget _buildPeriodGroupCard(_BudgetPeriodGroup group) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final wasSuccessful = group.wasSuccessful;
    final progress = group.totalBudgeted > 0
        ? (group.totalSpent / group.totalBudgeted).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: wasSuccessful
              ? FedhaColors.successGreen.withOpacity(0.15)
              : FedhaColors.errorRed.withOpacity(0.15),
          child: Icon(
            wasSuccessful ? Icons.check_circle : Icons.warning_amber,
            color: wasSuccessful
                ? FedhaColors.successGreen
                : FedhaColors.errorRed,
            size: 20,
          ),
        ),
        title: Text(
          '${_formatDate(group.startDate)} – ${_formatDate(group.endDate)}',
          style:
              textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${group.budgets.length} '
                'budget${group.budgets.length == 1 ? '' : 's'} · '
                'KSh ${group.totalSpent.toStringAsFixed(0)} / '
                'KSh ${group.totalBudgeted.toStringAsFixed(0)}',
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: colorScheme.surfaceVariant,
                  color: wasSuccessful
                      ? FedhaColors.successGreen
                      : FedhaColors.errorRed,
                ),
              ),
            ],
          ),
        ),
        // Override the default trailing arrow so we can show the badge
        // alongside the expand icon in a Row.
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  color: wasSuccessful
                      ? FedhaColors.successGreen
                      : FedhaColors.errorRed,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          const Divider(height: 1),
          ...group.budgets.map(_buildHistoryBudgetRow),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Individual budget row rendered inside an expanded period group.
  Widget _buildHistoryBudgetRow(Budget budget) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final wasSuccessful = budget.spentAmount <= budget.budgetAmount;
    final progress = budget.budgetAmount > 0
        ? (budget.spentAmount / budget.budgetAmount).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/budget_review', arguments: budget),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    budget.name,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  wasSuccessful ? '✓' : '✗',
                  style: textTheme.bodyMedium?.copyWith(
                    color: wasSuccessful
                        ? FedhaColors.successGreen
                        : FedhaColors.errorRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'KSh ${budget.spentAmount.toStringAsFixed(0)} '
                  'of KSh ${budget.budgetAmount.toStringAsFixed(0)}',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: textTheme.bodySmall?.copyWith(
                    color: wasSuccessful
                        ? FedhaColors.successGreen
                        : FedhaColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: colorScheme.surfaceVariant,
                color: wasSuccessful
                    ? FedhaColors.successGreen
                    : FedhaColors.errorRed,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Tap to review →',
                  style: textTheme.bodySmall?.copyWith(
                    color: FedhaColors.primaryGreen,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Upcoming tab ──────────────────────────────────────────────────────────

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
      children: _upcomingBudgets
          .map((budget) => _buildUpcomingBudgetCard(budget))
          .toList(),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

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
              style: textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: textTheme.bodyLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/create_budget')
                      .then((_) => _loadData());
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

    final totalBudget =
        budgets.fold(0.0, (sum, b) => sum + b.budgetAmount);
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
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                    'Budget', totalBudget, colorScheme.onSurface),
                _buildSummaryItem('Spent', totalSpent, color),
                _buildSummaryItem(
                  'Remaining',
                  remaining,
                  remaining >= 0
                      ? FedhaColors.successGreen
                      : FedhaColors.errorRed,
                ),
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
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
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
    final total =
        _unbudgetedSpending.values.fold(0.0, (sum, amt) => sum + amt);

    return Card(
      color: colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights,
                    color: colorScheme.onTertiaryContainer),
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
              'You\'ve spent in categories without budgets. '
              'Consider adding budgets for these to track better!',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onTertiaryContainer),
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
                          color: colorScheme.onTertiaryContainer),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = budget.budgetAmount > 0
        ? (budget.spentAmount / budget.budgetAmount)
        : 0.0;
    final remaining = budget.budgetAmount - budget.spentAmount;
    final daysLeft =
        budget.endDate.difference(DateTime.now()).inDays;

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
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
            if (budget.description != null &&
                budget.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                budget.description!,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
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
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
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
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  'KSh ${remaining.toStringAsFixed(0)} remaining',
                  style: textTheme.bodySmall?.copyWith(
                    color: remaining >= 0
                        ? FedhaColors.successGreen
                        : FedhaColors.errorRed,
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
                            : 'You\'re approaching your budget limit. '
                                'Consider reducing spending.',
                        style:
                            textTheme.bodySmall?.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/budget_review',
                      arguments: budget);
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
    final successRate =
        totalBudgets > 0 ? (completedOnBudget / totalBudgets) * 100 : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget History Summary',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHistorySummaryItem(
                    'Total Periods',
                    totalBudgets.toString(),
                    colorScheme.onSurface),
                _buildHistorySummaryItem('On Budget',
                    completedOnBudget.toString(), FedhaColors.successGreen),
                _buildHistorySummaryItem(
                  'Success Rate',
                  '${successRate.toStringAsFixed(0)}%',
                  successRate >= 70
                      ? FedhaColors.successGreen
                      : FedhaColors.warningOrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySummaryItem(
      String label, String value, Color color) {
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

  Widget _buildUpcomingBudgetCard(Budget budget) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final daysUntilStart =
        budget.startDate.difference(DateTime.now()).inDays;

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
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (budget.description != null &&
                budget.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                budget.description!,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Planned Budget:', style: textTheme.bodyMedium),
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}