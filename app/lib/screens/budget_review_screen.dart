// lib/screens/budget_review_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import '../services/currency_service.dart';
import '../theme/app_theme.dart';

/// Comprehensive budget review and analysis screen
/// Provides actionable insights on spending patterns, surpluses, and emergencies
class BudgetReviewScreen extends StatefulWidget {
  final Budget budget;

  const BudgetReviewScreen({
    super.key,
    required this.budget,
  });

  @override
  State<BudgetReviewScreen> createState() => _BudgetReviewScreenState();
}

class _BudgetReviewScreenState extends State<BudgetReviewScreen> {
  bool _isLoading = true;
  List<Transaction> _transactions = [];
  late BudgetAnalysis _analysis;

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);

    try {
      final offlineService = context.read<OfflineDataService>();
      
      // Get all transactions in budget period
      final allTransactions = await offlineService.getAllTransactions(widget.budget.profileId);

      _transactions = allTransactions.where((tx) {
        final isInPeriod = tx.date.isAfter(widget.budget.startDate.subtract(const Duration(days: 1))) &&
                          tx.date.isBefore(widget.budget.endDate.add(const Duration(days: 1)));
        
        // Handle type comparison safely
        final txType = tx.type?.toString().toLowerCase() ?? '';
        final isExpense = txType == 'expense' || txType.contains('expense');
        
        return isInPeriod && isExpense;
      }).toList();

      // Analyze the data
      _analysis = _analyzeBudget(_transactions);
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budget data: $e')),
        );
      }
    }
  }

  BudgetAnalysis _analyzeBudget(List<Transaction> transactions) {
    // Filter transactions by category
    final budgetCategoryTxs = transactions.where((tx) => 
      tx.category == widget.budget.category
    ).toList();
    
    final otherCategoryTxs = transactions.where((tx) => 
      tx.category != widget.budget.category
    ).toList();

    // Calculate spending
    final budgetedSpending = budgetCategoryTxs.fold<double>(
      0.0, (sum, tx) => sum + tx.amount
    );
    
    final unbudgetedSpending = otherCategoryTxs.fold<double>(
      0.0, (sum, tx) => sum + tx.amount
    );

    // Identify emergency transactions
    final emergencyTxs = transactions.where((tx) =>
      tx.description?.toLowerCase().contains('emergency') == true ||
      tx.notes?.toLowerCase().contains('emergency') == true
    ).toList();

    // Calculate surplus
    final surplus = widget.budget.budgetAmount - budgetedSpending;

    // Spending pattern analysis
    final dailySpending = _calculateDailySpending(budgetCategoryTxs);
    final spendingTrend = _calculateSpendingTrend(budgetCategoryTxs);

    // Category breakdown
    final categoryBreakdown = _calculateCategoryBreakdown(transactions);

    return BudgetAnalysis(
      budget: widget.budget,
      budgetedSpending: budgetedSpending,
      unbudgetedSpending: unbudgetedSpending,
      surplus: surplus,
      emergencyTransactions: emergencyTxs,
      dailyAverageSpending: dailySpending,
      spendingTrend: spendingTrend,
      categoryBreakdown: categoryBreakdown,
      totalTransactions: budgetCategoryTxs.length,
      largestTransaction: budgetCategoryTxs.isEmpty ? null : 
        budgetCategoryTxs.reduce((a, b) => a.amount > b.amount ? a : b),
    );
  }

  double _calculateDailySpending(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;
    
    final totalDays = widget.budget.endDate.difference(widget.budget.startDate).inDays;
    if (totalDays <= 0) return 0.0;
    
    final totalSpent = transactions.fold<double>(0.0, (sum, tx) => sum + tx.amount);
    return totalSpent / totalDays;
  }

  SpendingTrend _calculateSpendingTrend(List<Transaction> transactions) {
    if (transactions.length < 2) return SpendingTrend.stable;
    
    // Sort by date
    transactions.sort((a, b) => a.date.compareTo(b.date));
    
    // Split into first and second half
    final midPoint = transactions.length ~/ 2;
    final firstHalf = transactions.sublist(0, midPoint);
    final secondHalf = transactions.sublist(midPoint);
    
    final firstHalfAvg = firstHalf.fold<double>(0.0, (sum, tx) => sum + tx.amount) / firstHalf.length;
    final secondHalfAvg = secondHalf.fold<double>(0.0, (sum, tx) => sum + tx.amount) / secondHalf.length;
    
    final difference = secondHalfAvg - firstHalfAvg;
    final percentChange = (difference / firstHalfAvg * 100).abs();
    
    if (percentChange < 10) return SpendingTrend.stable;
    if (difference > 0) return SpendingTrend.increasing;
    return SpendingTrend.decreasing;
  }

  Map<String, double> _calculateCategoryBreakdown(List<Transaction> transactions) {
    final breakdown = <String, double>{};
    
    for (final tx in transactions) {
      breakdown[tx.category] = (breakdown[tx.category] ?? 0.0) + tx.amount;
    }
    
    return breakdown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Review: ${widget.budget.name}'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildReviewContent(),
    );
  }

  Widget _buildReviewContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget period info
          _buildPeriodCard(),
          const SizedBox(height: 16),
          
          // Overall performance
          _buildPerformanceCard(),
          const SizedBox(height: 16),
          
          // Spending visualization
          _buildSpendingChart(),
          const SizedBox(height: 16),
          
          // Category breakdown
          _buildCategoryBreakdown(),
          const SizedBox(height: 16),
          
          // Insights and recommendations
          _buildInsightsSection(),
          const SizedBox(height: 16),
          
          // Emergency fund recommendation
          if (_analysis.emergencyTransactions.isNotEmpty)
            _buildEmergencyRecommendation(),
        ],
      ),
    );
  }

  Widget _buildPeriodCard() {
    final daysInPeriod = widget.budget.endDate.difference(widget.budget.startDate).inDays;
    final daysRemaining = widget.budget.daysRemaining;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPeriodStat(
                  'Start Date',
                  _formatDate(widget.budget.startDate),
                  Icons.calendar_today,
                ),
                _buildPeriodStat(
                  'End Date',
                  _formatDate(widget.budget.endDate),
                  Icons.event,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPeriodStat(
                  'Total Days',
                  '$daysInPeriod days',
                  Icons.timelapse,
                ),
                _buildPeriodStat(
                  'Remaining',
                  '$daysRemaining days',
                  Icons.hourglass_bottom,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard() {
    final currencyService = context.read<CurrencyService>();
    final isOverBudget = _analysis.budgetedSpending > widget.budget.budgetAmount;
    final performanceColor = isOverBudget ? Colors.red : FedhaColors.primaryGreen;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Performance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Budget vs Actual
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPerformanceStat(
                  'Budgeted',
                  currencyService.formatCurrency(widget.budget.budgetAmount),
                  FedhaColors.primaryGreen,
                  Icons.account_balance_wallet,
                ),
                _buildPerformanceStat(
                  'Spent',
                  currencyService.formatCurrency(_analysis.budgetedSpending),
                  performanceColor,
                  Icons.shopping_cart,
                ),
                _buildPerformanceStat(
                  _analysis.surplus >= 0 ? 'Surplus' : 'Overspent',
                  currencyService.formatCurrency(_analysis.surplus.abs()),
                  _analysis.surplus >= 0 ? Colors.blue : Colors.red,
                  _analysis.surplus >= 0 ? Icons.savings : Icons.warning,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (widget.budget.spentPercentage / 100).clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(performanceColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.budget.spentPercentage.toStringAsFixed(1)}% of budget used',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStat(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingChart() {
    if (_transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No transactions to display',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    // Group transactions by week
    final weeklyData = _groupTransactionsByWeek(_transactions);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Over Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyData,
                      isCurved: true,
                      color: FedhaColors.primaryGreen,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: FedhaColors.primaryGreen.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _groupTransactionsByWeek(List<Transaction> transactions) {
    transactions.sort((a, b) => a.date.compareTo(b.date));
    
    final Map<int, double> weeklyTotals = {};
    
    for (final tx in transactions) {
      final weekNumber = tx.date.difference(widget.budget.startDate).inDays ~/ 7;
      weeklyTotals[weekNumber] = (weeklyTotals[weekNumber] ?? 0.0) + tx.amount;
    }
    
    return weeklyTotals.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
  }

  Widget _buildCategoryBreakdown() {
    if (_analysis.categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = _analysis.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.take(5).map((entry) => _buildCategoryItem(
              entry.key,
              entry.value,
              _transactions.fold<double>(0.0, (sum, tx) => sum + tx.amount),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, double total) {
    final currencyService = context.read<CurrencyService>();
    final percentage = (amount / total * 100).clamp(0.0, 100.0);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.toUpperCase(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                currencyService.formatCurrency(amount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(FedhaColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    final insights = _generateInsights();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Insights & Recommendations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => _buildInsightItem(insight)),
          ],
        ),
      ),
    );
  }

  List<BudgetInsight> _generateInsights() {
    final insights = <BudgetInsight>[];
    final currencyService = context.read<CurrencyService>();

    // Surplus insight
    if (_analysis.surplus > 0) {
      insights.add(BudgetInsight(
        title: 'Great Job! You Have a Surplus',
        description: 'You have ${currencyService.formatCurrency(_analysis.surplus)} remaining. '
            'Consider saving it or allocating it to other goals.',
        type: InsightType.positive,
        icon: Icons.check_circle,
      ));
    }

    // Overspending insight
    if (_analysis.surplus < 0) {
      insights.add(BudgetInsight(
        title: 'Budget Exceeded',
        description: 'You\'ve overspent by ${currencyService.formatCurrency(_analysis.surplus.abs())}. '
            'Review your transactions and adjust spending for next period.',
        type: InsightType.warning,
        icon: Icons.warning,
      ));
    }

    // Unbudgeted spending insight
    if (_analysis.unbudgetedSpending > 0) {
      insights.add(BudgetInsight(
        title: 'Unbudgeted Spending Detected',
        description: '${currencyService.formatCurrency(_analysis.unbudgetedSpending)} was spent '
            'in other categories. Consider creating budgets for these areas.',
        type: InsightType.info,
        icon: Icons.info,
      ));
    }

    // Spending trend insight
    if (_analysis.spendingTrend == SpendingTrend.increasing) {
      insights.add(BudgetInsight(
        title: 'Spending is Increasing',
        description: 'Your spending has increased over this period. '
            'Review recent transactions to identify areas to cut back.',
        type: InsightType.warning,
        icon: Icons.trending_up,
      ));
    } else if (_analysis.spendingTrend == SpendingTrend.decreasing) {
      insights.add(BudgetInsight(
        title: 'Spending is Decreasing',
        description: 'Great! Your spending is trending downward. '
            'Keep up the good habits.',
        type: InsightType.positive,
        icon: Icons.trending_down,
      ));
    }

    // Daily spending insight
    final dailyBudget = widget.budget.budgetAmount / 
        widget.budget.endDate.difference(widget.budget.startDate).inDays;
    
    if (_analysis.dailyAverageSpending > dailyBudget * 1.2) {
      insights.add(BudgetInsight(
        title: 'Daily Spending Too High',
        description: 'Your daily average of ${currencyService.formatCurrency(_analysis.dailyAverageSpending)} '
            'exceeds your daily budget of ${currencyService.formatCurrency(dailyBudget)}.',
        type: InsightType.warning,
        icon: Icons.calendar_today,
      ));
    }

    return insights;
  }

  Widget _buildInsightItem(BudgetInsight insight) {
    Color color;
    switch (insight.type) {
      case InsightType.positive:
        color = Colors.green;
        break;
      case InsightType.warning:
        color = Colors.orange;
        break;
      case InsightType.info:
        color = Colors.blue;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyRecommendation() {
    final currencyService = context.read<CurrencyService>();
    final emergencyTotal = _analysis.emergencyTransactions.fold<double>(
      0.0, (sum, tx) => sum + tx.amount
    );
    
    // Recommend 3-6 months of emergency spending
    final recommendedFund = _analysis.dailyAverageSpending * 30 * 3;

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Emergency Fund Recommendation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You had ${_analysis.emergencyTransactions.length} emergency expense(s) '
              'totaling ${currencyService.formatCurrency(emergencyTotal)} without a budget.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Emergency Fund',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyService.formatCurrency(recommendedFund),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: FedhaColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on 3 months of your average spending',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to emergency fund screen
                Navigator.pushNamed(context, '/emergency-fund');
              },
              icon: const Icon(Icons.shield),
              label: const Text('Create Emergency Fund'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
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

// ==================== DATA MODELS ====================

class BudgetAnalysis {
  final Budget budget;
  final double budgetedSpending;
  final double unbudgetedSpending;
  final double surplus;
  final List<Transaction> emergencyTransactions;
  final double dailyAverageSpending;
  final SpendingTrend spendingTrend;
  final Map<String, double> categoryBreakdown;
  final int totalTransactions;
  final Transaction? largestTransaction;

  BudgetAnalysis({
    required this.budget,
    required this.budgetedSpending,
    required this.unbudgetedSpending,
    required this.surplus,
    required this.emergencyTransactions,
    required this.dailyAverageSpending,
    required this.spendingTrend,
    required this.categoryBreakdown,
    required this.totalTransactions,
    this.largestTransaction,
  });
}

enum SpendingTrend {
  increasing,
  decreasing,
  stable,
}

class BudgetInsight {
  final String title;
  final String description;
  final InsightType type;
  final IconData icon;

  BudgetInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
  });
}

enum InsightType {
  positive,
  warning,
  info,
}