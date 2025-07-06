// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/enhanced_profile.dart' show ProfileType;
import '../services/auth_service.dart';
import '../services/offline_data_service.dart';
import '../services/currency_service.dart';
import '../widgets/quick_transaction_entry.dart';
import '../widgets/budget_card.dart';
import 'main_navigation.dart';
import 'goals_screen.dart';
import 'goal_details_screen.dart';
import 'transactions_screen.dart';
import 'budget_management_screen.dart';
import 'create_budget_screen.dart';
// Removed unused imports
import 'sms_review_screen.dart';
import 'sms_debug_screen.dart';
import 'loan_calculator_screen.dart';
import 'create_goal_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainNavigation(currentIndex: 0, child: const DashboardContent());
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final profileId = authService.currentProfileId;
        if (profileId == null) {
          return const Center(child: Text('Please log in'));
        }

        return Consumer<OfflineDataService>(
          builder: (context, dataService, child) {
            return FutureBuilder<DashboardData>(
              future: _loadDashboardData(dataService, profileId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data ?? DashboardData.empty();

                return RefreshIndicator(
                  onRefresh: () async {
                    // Trigger rebuild by calling setState equivalent
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Header
                        _buildWelcomeHeader(context, ProfileType.personal),

                        const SizedBox(height: 24),

                        // Financial Position Card
                        _buildFinancialPositionCard(context, data),

                        const SizedBox(height: 24), // Budget Section
                        _buildBudgetSection(context, data.currentBudget),

                        const SizedBox(height: 24),

                        // Goals Section
                        _buildGoalsSection(context, data.goals),

                        const SizedBox(height: 24), // Quick Actions
                        _buildQuickActions(
                          context,
                          ProfileType.personal,
                          data.currentBudget,
                        ),

                        const SizedBox(height: 24),

                        // Recent Transactions
                        _buildRecentTransactions(
                          context,
                          data.recentTransactions,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, ProfileType profileType) {
    final timeOfDay = DateTime.now().hour;
    String greeting = 'Good morning';
    if (timeOfDay >= 12 && timeOfDay < 17) greeting = 'Good afternoon';
    if (timeOfDay >= 17) greeting = 'Good evening';

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              profileType == ProfileType.business
                  ? 'Business Dashboard'
                  : 'Personal Dashboard',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF007A39).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              profileType == ProfileType.business
                  ? Icons.business
                  : Icons.person,
              color: const Color(0xFF007A39),
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialPositionCard(BuildContext context, DashboardData data) {
    final availableToSpend = data.availableToSpend;
    final isPositive = availableToSpend >= 0;
    final budgetExceeded =
        data.currentBudget != null &&
        data.totalExpenses > data.currentBudget!.budgetAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isPositive && !budgetExceeded
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPositive && !budgetExceeded ? Colors.green : Colors.red)
                .withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Available to Spend',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                isPositive && !budgetExceeded
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ksh ${availableToSpend.abs().toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            budgetExceeded
                ? 'Budget exceeded by Ksh ${(data.totalExpenses - data.currentBudget!.budgetAmount).toStringAsFixed(2)}'
                : isPositive
                ? 'After expenses and savings'
                : 'Over budget',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'Income',
                  data.totalIncome,
                  Icons.arrow_upward,
                  Colors.white70,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white30),
              Expanded(
                child: _buildBalanceItem(
                  'Expenses',
                  data.totalExpenses,
                  Icons.arrow_downward,
                  Colors.white70,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white30),
              Expanded(
                child: _buildBalanceItem(
                  'Savings',
                  data.totalSavings,
                  Icons.savings,
                  Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ksh ${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSection(BuildContext context, Budget? currentBudget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Budget',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            if (currentBudget != null)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BudgetManagementScreen(),
                    ),
                  );
                },
                child: const Text('View Details'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (currentBudget == null)
          _buildCreateBudgetCard(context)
        else
          _buildBudgetOverviewCard(context, currentBudget),
      ],
    );
  }

  Widget _buildCreateBudgetCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateBudgetScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF007A39).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFF007A39), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create Budget',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF007A39),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set spending limits and track your expenses',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverviewCard(BuildContext context, Budget budget) {
    // Reuse BudgetCard widget for overview
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: BudgetCard(
        budget: budget,
        onEdit: () {
          Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => CreateBudgetScreen(budget: budget),
            ),
          ).then((_) {
            // Optionally refresh dashboard data
          });
        },
        onDelete: null,
      ),
    );
  }

  Widget _buildGoalsSection(BuildContext context, List<Goal> goals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Your Goals',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GoalsScreen()),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: goals.length + 1, // +1 for add goal card
            itemBuilder: (context, index) {
              if (index == goals.length) {
                return _buildAddGoalCard(context);
              }
              return _buildGoalCard(context, goals[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    final progress =
        goal.progressPercentage / 100; // Using the computed property
    final timeRemaining = goal.timeRemaining;
    final daysLeft = timeRemaining.inDays;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GoalDetailsScreen(goal: goal),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getGoalIcon(goal.type),
                    color: Colors.blue.shade600,
                    size: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  daysLeft > 0 ? '$daysLeft days' : 'Due today',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              goal.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? Colors.green.shade600 : Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  CurrencyService.formatCurrency(
                    goal.currentAmount,
                    'USD', // Default currency since Goal doesn't have currency field
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  'Ksh ${goal.targetAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddGoalCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder:
              (context) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Create a New Goal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how you\'d like to create your financial goal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007A39).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF007A39),
                        ),
                      ),
                      title: const Text(
                        'Goal Wizard (Recommended)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Step-by-step guided goal creation with SMART analysis',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Show a dialog with SMART goal guidance before navigating to the create goal screen
                        _showSmartGoalGuidanceDialog(context);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.psychology, color: Colors.blue),
                      ),
                      title: const Text(
                        'SMART Goal',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Advanced goal creation with validation',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateGoalScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.grey,
                        ),
                      ),
                      title: const Text(
                        'Quick Goal',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Simple goal creation'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateGoalScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF007A39).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFF007A39), size: 24),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create Goal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF007A39),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start your journey',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    ProfileType profileType,
    Budget? currentBudget,
  ) {
    final actions =
        profileType == ProfileType.business
            ? [
              QuickAction('Add Transaction', Icons.add, Colors.green, () {
                _showQuickTransactionEntry(context);
              }),
              QuickAction('Create Invoice', Icons.receipt, Colors.blue, () {}),
              QuickAction(
                'View Reports',
                Icons.analytics,
                Colors.orange,
                () {},
              ),
              QuickAction('Manage Clients', Icons.people, Colors.purple, () {}),
            ]
            : [
              QuickAction('Add Transaction', Icons.add, Colors.green, () {
                _showQuickTransactionEntry(context);
              }),
              QuickAction(
                currentBudget != null ? 'View Budget' : 'Create Budget',
                Icons.pie_chart,
                Colors.blue,
                () {
                  if (currentBudget != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BudgetManagementScreen(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateBudgetScreen(),
                      ),
                    );
                  }
                },
              ),
              QuickAction('SMS Review', Icons.message, Colors.orange, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SmsReviewScreen(),
                  ),
                );
              }),
              QuickAction(
                'Loan Calculator',
                Icons.calculate,
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoanCalculatorScreen(),
                    ),
                  );
                },
              ),
              QuickAction('SMS Debug', Icons.bug_report, Colors.red, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SmsDebugScreen(),
                  ),
                );
              }),
            ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildQuickActionCard(context, action);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(BuildContext context, QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionsScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first transaction to get started',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.take(5).length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(context, transaction);
            },
          ),
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    Color color;
    IconData icon;
    String prefix;

    switch (transaction.type) {
      case TransactionType.income:
        color = Colors.green.shade600;
        icon = Icons.arrow_upward;
        prefix = '+';
        break;
      case TransactionType.expense:
        color = Colors.red.shade600;
        icon = Icons.arrow_downward;
        prefix = '-';
        break;
      case TransactionType.savings:
        color = Colors.blue.shade600;
        icon = Icons.savings;
        prefix = '-';
        break;
    }

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  transaction.category.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (transaction.type == TransactionType.savings &&
                  transaction.goalId != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: 12, color: Colors.blue.shade600),
                      const SizedBox(width: 2),
                      Text(
                        'Goal',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transaction.description != null &&
                  transaction.description!.isNotEmpty)
                Text(
                  transaction.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              Text(
                transaction.date.toString().split(' ')[0],
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (transaction.type == TransactionType.savings &&
                  transaction.goalId != null)
                FutureBuilder<Goal?>(
                  future: Provider.of<OfflineDataService>(
                    context,
                    listen: false,
                  ).getGoal(transaction.goalId!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Contributing to: ${snapshot.data!.name}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
          trailing: Text(
            '${prefix}Ksh ${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getGoalIcon(GoalType goalType) {
    switch (goalType) {
      case GoalType.savings:
        return Icons.savings;
      case GoalType.debtPayoff:
        return Icons.money_off;
      case GoalType.investment:
        return Icons.trending_up;
      case GoalType.purchase:
        return Icons.shopping_cart;
      case GoalType.emergency:
        return Icons.security;
    }
  }

  Future<DashboardData> _loadDashboardData(
    OfflineDataService dataService,
    String profileId,
  ) async {
    try {
      final transactions = await dataService.getAllTransactions();
      final goals = await dataService.getAllGoals(profileId);
      final budgets = await dataService.getAllBudgets();

      final currentBudget = budgets.isNotEmpty ? budgets.first : null;

      final totalIncome = transactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);

      final totalExpenses = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      final totalSavings = transactions
          .where((t) => t.type == TransactionType.savings)
          .fold(0.0, (sum, t) => sum + t.amount);

      return DashboardData(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        totalSavings: totalSavings,
        goals: goals,
        recentTransactions: transactions.take(5).toList(),
        currentBudget: currentBudget,
      );
    } catch (e) {
      return DashboardData.empty();
    }
  }

  void _showQuickTransactionEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: const QuickTransactionEntry(),
          ),
    );
  }

  static void _showSmartGoalGuidanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('SMART Goal Guidance'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Create a SMART financial goal:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('• Specific: Clearly define what you want to achieve'),
                Text('• Measurable: Set a specific amount to save'),
                Text('• Achievable: Make sure it\'s realistic for your income'),
                Text('• Relevant: Align with your financial priorities'),
                Text('• Time-bound: Set a target date for completion'),
                SizedBox(height: 15),
                Text(
                  'Examples:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('✓ "Save \$5,000 for a down payment by December 2023"'),
                Text('✓ "Build an emergency fund of \$3,000 in 6 months"'),
                Text('✓ "Pay off \$10,000 credit card debt by next year"'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create Goal'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGoalScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class DashboardData {
  final double totalIncome;
  final double totalExpenses;
  final double totalSavings;
  final List<Goal> goals;
  final List<Transaction> recentTransactions;
  final Budget? currentBudget;

  DashboardData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalSavings,
    required this.goals,
    required this.recentTransactions,
    this.currentBudget,
  });

  double get availableToSpend => totalIncome - totalExpenses - totalSavings;

  factory DashboardData.empty() {
    return DashboardData(
      totalIncome: 0.0,
      totalExpenses: 0.0,
      totalSavings: 0.0,
      goals: [],
      recentTransactions: [],
      currentBudget: null,
    );
  }
}

class QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  QuickAction(this.title, this.icon, this.color, this.onTap);
}
