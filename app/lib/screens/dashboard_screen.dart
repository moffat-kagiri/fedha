import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/offline_data_service.dart';
import '../services/currency_service.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/enums.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardContent();
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final profile = authService.currentProfile;
        if (profile == null) {
          return const Center(child: Text('Please log in'));
        }

        return Consumer<OfflineDataService>(
          builder: (context, dataService, child) {
            return Consumer<CurrencyService>(
              builder: (context, currencyService, child) {
                return FutureBuilder<DashboardData>(
                  future: _loadDashboardData(dataService, profile.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final data = snapshot.data ?? DashboardData.empty();

                    return Scaffold(
                      backgroundColor: Colors.grey.shade50,
                      body: SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWelcomeHeader(context, profile.type),
                              const SizedBox(height: 24),
                              _buildFinancialPositionCard(context, currencyService, data),
                              const SizedBox(height: 20),
                              _buildQuickActions(context),
                              const SizedBox(height: 20),
                              _buildGoalsSection(context, currencyService, data.goals),
                              const SizedBox(height: 20),
                              _buildRecentTransactions(context, currencyService, data.recentTransactions),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<DashboardData> _loadDashboardData(OfflineDataService dataService, String profileId) async {
    try {
      final goals = dataService.getAllGoals().where((goal) => goal.profileId == profileId).toList();
      final allTransactions = dataService.getAllTransactions().where((tx) => tx.profileId == profileId).toList();
      allTransactions.sort((a, b) => b.date.compareTo(a.date));
      final recentTransactions = allTransactions.take(5).toList();
      
      return DashboardData(
        goals: goals,
        recentTransactions: recentTransactions,
        currentBudget: null,
      );
    } catch (e) {
      return DashboardData.empty();
    }
  }

  Widget _buildWelcomeHeader(BuildContext context, ProfileType profileType) {
    final now = DateTime.now();
    final hour = now.hour;
    
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    IconData icon = Icons.person;
    switch (profileType) {
      case ProfileType.personal:
        icon = Icons.person;
        break;
      case ProfileType.business:
        icon = Icons.business;
        break;
      case ProfileType.student:
        icon = Icons.school;
        break;
      case ProfileType.family:
        icon = Icons.family_restroom;
        break;
    }

    return Card(
      color: const Color(0xFF007A39),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your finances effectively',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialPositionCard(BuildContext context, CurrencyService currencyService, DashboardData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Overview',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBalanceItem('Total Savings', currencyService.formatCurrency(0), Colors.green),
                _buildBalanceItem('Monthly Budget', currencyService.formatCurrency(0), Colors.blue),
                _buildBalanceItem('Goals Progress', '0%', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      QuickAction('Add Transaction', Icons.add, Colors.green, () {
        Navigator.of(context).pushNamed('/transaction_entry');
      }),
      QuickAction('View Goals', Icons.flag, Colors.blue, () {
        Navigator.of(context).pushNamed('/goals');
      }),
      QuickAction('Loan Calculator', Icons.calculate, Colors.orange, () {
        Navigator.of(context).pushNamed('/loan_calculator');
      }),
      QuickAction('Budget Planner', Icons.pie_chart, Colors.purple, () {
        Navigator.of(context).pushNamed('/create_budget');
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontWeight: FontWeight.bold),
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
          itemBuilder: (context, index) => _buildQuickActionCard(actions[index]),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(QuickAction action) {
    return Card(
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(action.icon, color: action.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsSection(BuildContext context, CurrencyService currencyService, List<Goal> goals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Goals',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/goals'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (goals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.flag_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No goals yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/add_goal'),
                    child: const Text('Create Your First Goal'),
                  ),
                ],
              ),
            ),
          )
        else
          ...goals.take(3).map((goal) => _buildGoalCard(goal, currencyService)),
      ],
    );
  }

  Widget _buildGoalCard(Goal goal, CurrencyService currencyService) {
    final progress = goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getGoalIcon(goal.goalType), color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyService.formatCurrency(goal.currentAmount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  currencyService.formatCurrency(goal.targetAmount),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGoalIcon(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return Icons.savings;
      case GoalType.investment:
        return Icons.trending_up;
      case GoalType.emergencyFund:
        return Icons.security;
      case GoalType.debtReduction:
        return Icons.money_off;
      case GoalType.expenseReduction:
        return Icons.trending_down;
      case GoalType.incomeIncrease:
        return Icons.attach_money;
      case GoalType.retirement:
        return Icons.elderly;
      case GoalType.other:
        return Icons.flag;
    }
  }

  Widget _buildRecentTransactions(BuildContext context, CurrencyService currencyService, List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // Navigate to transactions screen
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/transaction_entry'),
                    child: const Text('Add Your First Transaction'),
                  ),
                ],
              ),
            ),
          )
        else
          ...transactions.map((transaction) => _buildTransactionItem(transaction, currencyService)),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction, CurrencyService currencyService) {
    IconData icon;
    Color color;
    
    switch (transaction.type) {
      case TransactionType.income:
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case TransactionType.expense:
        icon = Icons.remove_circle;
        color = Colors.red;
        break;
      case TransactionType.savings:
        icon = Icons.savings;
        color = Colors.blue;
        break;
      case TransactionType.transfer:
        icon = Icons.swap_horiz;
        color = Colors.orange;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(transaction.description ?? 'No description'),
        subtitle: Text(transaction.categoryId.isNotEmpty ? transaction.categoryId : 'No category'),
        trailing: Text(
          currencyService.formatCurrency(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class DashboardData {
  final List<Goal> goals;
  final List<Transaction> recentTransactions;
  final Budget? currentBudget;

  DashboardData({
    required this.goals,
    required this.recentTransactions,
    this.currentBudget,
  });

  factory DashboardData.empty() {
    return DashboardData(
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
