// lib/screens/analytics_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/loan.dart';
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import '../services/auth_service.dart';
import '../services/currency_service.dart';
import '../models/loan.dart' as domain_loan;
import '../theme/app_theme.dart';
import '../services/transaction_event_service.dart'; 
import '../utils/logger.dart';
import '../screens/budget_management_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  AnalyticsData? _data;
  final _logger = AppLogger.getLogger('AnalyticsScreen');
  StreamSubscription<TransactionEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _setupEventListeners();
  }

  void _setupEventListeners() {
    final eventService = Provider.of<TransactionEventService>(context, listen: false);
    
    
    _eventSubscription = eventService.eventStream.listen((event) {

      _logger.info('Transaction event received: ${event.type}');
      _loadAnalytics();
    });
  }

  @override
  void dispose() {    _eventSubscription?.cancel();
    super.dispose();
  }

  // Update the _loadAnalytics method with better type checking and amount calculation
  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = authService.currentProfile?.id ?? '';

      if (profileId.isEmpty) {
        throw Exception('No active profile');
      }

      final goals = await offlineDataService.getAllGoals(profileId);
      final budgets = await offlineDataService.getAllBudgets(profileId);
      final loans = await offlineDataService.getAllLoans(profileId);
      final transactions = await offlineDataService.getAllTransactions(profileId);

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthlyTransactions = transactions.where(
        (t) => t.date.isAfter(monthStart) && t.date.isBefore(now.add(const Duration(days: 1))),
      ).toList();

      // Helper function to get transaction amount in major units
      double getTransactionAmount(Transaction transaction) {
        // Try amountMinor first (if available), then fall back to amount field
        try {
          // Check if amountMinor exists and is not null
          if (transaction.amountMinor != null) {
            return transaction.amountMinor! / 100.0;
          }
          // Fall back to amount field if it exists
          return transaction.amount ?? 0.0;
        } catch (e) {
          // If neither field exists or is accessible, return 0
          return 0.0;
        }
      }

      // Helper function to check transaction type
      bool isTransactionType(Transaction transaction, String typeToCheck) {
        final type = transaction.type?.toLowerCase() ?? '';
        return type == typeToCheck.toLowerCase() || 
              (typeToCheck == 'expense' && transaction.isExpense == true);
      }

      // Calculate monthly totals with proper amount conversion
      double monthlyIncome = 0.0;
      double monthlyExpenses = 0.0;
      double monthlySavings = 0.0;

      for (final transaction in monthlyTransactions) {
        final amount = getTransactionAmount(transaction);
        
        if (isTransactionType(transaction, 'income')) {
          monthlyIncome += amount;
        } else if (isTransactionType(transaction, 'expense')) {
          monthlyExpenses += amount;
        } else if (isTransactionType(transaction, 'savings')) {
          monthlySavings += amount;
        }
      }

      setState(() {
        _data = AnalyticsData(
          goals: goals,
          budgets: budgets,
          loans: loans,
          monthlyIncome: monthlyIncome,
          monthlyExpenses: monthlyExpenses,
          monthlySavings: monthlySavings,
        );
        _isLoading = false;
      });
      
      _logger.info('Analytics loaded: '
                  'Transactions this month: ${monthlyTransactions.length}, '
                  'Income: KSh ${monthlyIncome.toStringAsFixed(0)}, '
                  'Expenses: KSh ${monthlyExpenses.toStringAsFixed(0)}, '
                  'Savings: KSh ${monthlySavings.toStringAsFixed(0)}');
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      _logger.severe('Error loading analytics', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load analytics: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _monthsBetween(DateTime a, DateTime b) {
    var months = (b.year - a.year) * 12 + (b.month - a.month);
    if (b.day < a.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  double _computeMonthlyPayment(
      double principal, double annualRatePercent, int months) {
    if (months <= 0) return 0.0;
    final r = annualRatePercent / 100.0 / 12.0;
    if (r <= 0) return principal / months;
    final powFactor = math.pow(1 + r, months);
    return (principal * (r * powFactor) / (powFactor - 1)).toDouble();
  }

  double _computeOutstandingBalance(
    double principal,
    double annualRatePercent,
    int totalMonths,
    int remainingMonths,
  ) {
    if (remainingMonths <= 0) return 0.0;
    final r = annualRatePercent / 100.0 / 12.0;
    if (r <= 0) return principal * remainingMonths / totalMonths;
    final R = _computeMonthlyPayment(principal, annualRatePercent, totalMonths);
    final v = 1.0 / (1.0 + r);
    final ob = R * (1 - math.pow(v, remainingMonths)) / r;
    return ob.clamp(0.0, principal);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('No data available'))
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMonthlyOverview(colorScheme, textTheme),
                        const SizedBox(height: 24),
                        _buildGoalsSummary(colorScheme, textTheme),
                        const SizedBox(height: 24),
                        _buildBudgetsSummary(colorScheme, textTheme),
                        const SizedBox(height: 24),
                        _buildLoansSummary(colorScheme, textTheme),
                        const SizedBox(height: 24),
                        _buildInsights(colorScheme, textTheme),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMonthlyOverview(ColorScheme colorScheme, TextTheme textTheme) {
    final netCashFlow = _data!.monthlyIncome - _data!.monthlyExpenses;
    final savingsRate = _data!.monthlyIncome > 0
        ? (_data!.monthlySavings / _data!.monthlyIncome * 100)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Income',
                    'KSh ${_data!.monthlyIncome.toStringAsFixed(0)}',
                    FedhaColors.successGreen,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Expenses',
                    'KSh ${_data!.monthlyExpenses.toStringAsFixed(0)}',
                    FedhaColors.errorRed,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Savings',
                    'KSh ${_data!.monthlySavings.toStringAsFixed(0)}',
                    FedhaColors.primaryGreen,
                    Icons.savings,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Net Flow',
                    'KSh ${netCashFlow.toStringAsFixed(0)}',
                    netCashFlow >= 0 ? FedhaColors.successGreen : FedhaColors.errorRed,
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            if (_data!.monthlyIncome > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FedhaColors.infoBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: FedhaColors.infoBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Savings Rate: ${savingsRate.toStringAsFixed(1)}%',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: FedhaColors.infoBlue,
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

  Widget _buildGoalsSummary(ColorScheme colorScheme, TextTheme textTheme) {
    final activeGoals = _data!.goals.where((g) => g.status == GoalStatus.active).toList();
    final totalTarget = activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalProgress = activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final overallProgress = totalTarget > 0 ? (totalProgress / totalTarget * 100) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goals',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/goals'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeGoals.isEmpty)
              Text(
                'No active goals. Create one to start tracking!',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                '${activeGoals.length} active goals • ${overallProgress.toStringAsFixed(1)}% complete',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: overallProgress / 100,
                backgroundColor: colorScheme.surfaceVariant,
                color: FedhaColors.primaryGreen,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              ...activeGoals.take(3).map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildGoalRow(goal, textTheme, colorScheme),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetsSummary(ColorScheme colorScheme, TextTheme textTheme) {
    final activeBudgets = _data!.budgets.where((b) => b.isActive).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budgets',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/budget_management');
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeBudgets.isEmpty)
              Text(
                'No active budgets. Create one to track spending!',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...activeBudgets.map((budget) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBudgetRow(budget, textTheme, colorScheme),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildLoansSummary(ColorScheme colorScheme, TextTheme textTheme) {
    // Sum outstanding balances rather than principal amounts so the figure
    // reflects actual remaining debt after repayments already made.
    final totalDebt = _data!.loans.fold(0.0, (sum, l) {
      final now = DateTime.now();
      final totalMonths = _monthsBetween(l.startDate, l.endDate);
      final remainingMonths = l.endDate.isAfter(now)
          ? _monthsBetween(now, l.endDate)
          : 0;
      final outstanding = _computeOutstandingBalance(
        l.principalAmount,
        l.interestRate,
        totalMonths,
        remainingMonths,
      );
      return sum + outstanding;
    });
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loans & Debt',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/loans_tracker'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_data!.loans.isEmpty)
              Text(
                'No tracked loans',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                '${_data!.loans.length} active loans',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FedhaColors.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: FedhaColors.warningOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Total Debt: KSh ${totalDebt.toFormattedString()}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: FedhaColors.warningOrange,
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

  Widget _buildInsights(ColorScheme colorScheme, TextTheme textTheme) {
    final insights = <Map<String, dynamic>>[];

    // Spending vs Income
    if (_data!.monthlyExpenses > _data!.monthlyIncome * 0.8) {
      insights.add({
        'icon': Icons.warning_amber,
        'color': FedhaColors.warningOrange,
        'title': 'High Spending',
        'message': 'Your expenses are ${(_data!.monthlyExpenses / _data!.monthlyIncome * 100).toStringAsFixed(0)}% of your income. Consider reducing discretionary spending.',
      });
    }

    // Savings rate
    final savingsRate = _data!.monthlyIncome > 0
        ? (_data!.monthlySavings / _data!.monthlyIncome * 100)
        : 0.0;
    if (savingsRate < 10 && _data!.monthlyIncome > 0) {
      insights.add({
        'icon': Icons.savings,
        'color': FedhaColors.infoBlue,
        'title': 'Low Savings Rate',
        'message': 'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income. Aim for at least 20% for long-term financial health.',
      });
    }

    // Goals progress
    final behindGoals = _data!.goals.where((g) {
      if (g.status != GoalStatus.active) return false;
      final daysUntilTarget = g.targetDate.difference(DateTime.now()).inDays;
      final progress = g.currentAmount / g.targetAmount;
      final expectedProgress = 1 - (daysUntilTarget / 365);
      return progress < expectedProgress * 0.8;
    }).length;

    if (behindGoals > 0) {
      insights.add({
        'icon': Icons.flag,
        'color': FedhaColors.errorRed,
        'title': 'Goals Behind Schedule',
        'message': '$behindGoals goal(s) are behind schedule. Review your savings strategy to get back on track.',
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insights & Recommendations',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (insights.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FedhaColors.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: FedhaColors.successGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Great job! Your finances are on track.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: FedhaColors.successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (insight['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(insight['icon'] as IconData, color: insight['color'] as Color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight['title'] as String,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: insight['color'] as Color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              insight['message'] as String,
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow(Goal goal, TextTheme textTheme, ColorScheme colorScheme) {
    final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0.0;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.name,
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: colorScheme.surfaceVariant,
                color: FedhaColors.primaryGreen,
                minHeight: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: FedhaColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetRow(Budget budget, TextTheme textTheme, ColorScheme colorScheme) {
    final progress = budget.budgetAmount > 0 ? (budget.spentAmount / budget.budgetAmount) : 0.0;
    final color = progress > 0.9 ? FedhaColors.errorRed : 
                  progress > 0.75 ? FedhaColors.warningOrange : 
                  FedhaColors.successGreen;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                budget.name,
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: colorScheme.surfaceVariant,
                color: color,
                minHeight: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'KSh ${budget.spentAmount.toStringAsFixed(0)} / ${budget.budgetAmount.toStringAsFixed(0)}',
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class AnalyticsData {
  final List<Goal> goals;
  final List<Budget> budgets;
  final List<Loan> loans;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double monthlySavings;

  AnalyticsData({
    required this.goals,
    required this.budgets,
    required this.loans,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlySavings,
  });
}
