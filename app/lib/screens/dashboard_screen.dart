import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:fedha/services/auth_service.dart';
import 'package:fedha/services/offline_data_service.dart';
import 'package:fedha/models/goal.dart' as dom_goal;
import 'package:fedha/models/transaction.dart' as dom_tx;
import 'package:fedha/models/budget.dart' as dom_budget;
import '../services/currency_service.dart';
import '../services/sms_listener_service.dart';
import '../services/permissions_service.dart';
import '../models/enums.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/transaction_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/financial_summary_card.dart';

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
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  return Consumer<AuthService>(
      builder: (context, authService, child) {
        final profile = authService.currentProfile;
        if (profile == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please log in',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          );
        }

        return Consumer<OfflineDataService>(
          builder: (context, dataService, child) {
            return Consumer<CurrencyService>(
              builder: (context, currencyService, child) {
                return FutureBuilder<DashboardData>(
                  future: _loadDashboardData(dataService, profile.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                        return Scaffold(
                          backgroundColor: colorScheme.background,
                          body: Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          ),
                        );
                    }

                    final data = snapshot.data ?? DashboardData.empty();

                    return Scaffold(
                      backgroundColor: colorScheme.background,
                        appBar: AppBar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          title: Text('Dashboard', style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary)),
                          elevation: 0,
                          ),
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
      // No more int parsing!
      final goals = await dataService.getAllGoals(profileId);
      final allTransactions = await dataService.getAllTransactions(profileId);
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
            Icon(icon, color: Theme.of(context).colorScheme.surface, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your finances effectively',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
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
    final summaryItems = [
      FinancialSummaryItem(
        label: 'Total Savings',
        value: currencyService.formatCurrency(0),
        color: Colors.green,
        icon: Icons.savings,
      ),
      FinancialSummaryItem(
        label: 'Monthly Budget',
        value: currencyService.formatCurrency(0),
        color: Colors.blue,
        icon: Icons.account_balance_wallet,
      ),
      FinancialSummaryItem(
        label: 'Goals Progress',
        value: '0%',
        color: Colors.orange,
        icon: Icons.flag,
      ),
    ];

    return FinancialSummaryCard(
      title: 'Financial Overview',
      items: summaryItems,
      onTap: () {
        Navigator.pushNamed(context, '/create_budget');
      },
    );
  }

  Widget _buildBalanceItem(String label, String value, Color color, BuildContext context) {
    return Column(
      children: [
        Text(
          label, 
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      QuickActionItem(
        title: 'Add Transaction',
        icon: Icons.add,
        color: Colors.green,
        onTap: () {
          TransactionDialog.showAddDialog(
            context,
            onTransactionSaved: (transaction) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction added successfully'),
                  backgroundColor: Color(0xFF007A39),
                ),
              );
            },
          );
        },
      ),
      QuickActionItem(
        title: 'SMS Review',
        icon: Icons.sms,
        color: Colors.blue,
        onTap: () async {
          // Request SMS permission before starting listener
          final permissionsService = Provider.of<PermissionsService>(context, listen: false);
          final granted = await permissionsService.requestSmsPermission();
          if (!granted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SMS permission required to review messages'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          // Set current profile for SMS listener
          final smsService = SmsListenerService.instance;
          final authService = Provider.of<AuthService>(context, listen: false);
          final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
          final profileId = authService.currentProfile?.id ?? '';
          
          // Initialize SMS listener if not already running
          if (!smsService.isListening) {
            await smsService.startListening(
              offlineDataService: offlineDataService,
              profileId: profileId
            );
          }
          Navigator.of(context).pushNamed('/sms_review');
        },
      ),
      QuickActionItem(
        title: 'View Goals',
        icon: Icons.flag,
        color: Colors.purple,
        onTap: () => Navigator.of(context).pushNamed('/goals'),
      ),
      QuickActionItem(
        title: 'Loan Calculator',
        icon: Icons.calculate,
        color: Colors.orange,
        onTap: () => Navigator.of(context).pushNamed('/loan_calculator'),
      ),
    ];

    return QuickActionsGrid(actions: actions);
  }

  Widget _buildQuickActionCard(QuickAction action, BuildContext context) {
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsSection(BuildContext context, CurrencyService currencyService, List<dom_goal.Goal> goals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Goals',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
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
          ...goals.take(3).map((goal) => _buildGoalCard(goal, currencyService, context)),
      ],
    );
  }

  Widget _buildGoalCard(dom_goal.Goal goal, CurrencyService currencyService, BuildContext context) {
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  currencyService.formatCurrency(goal.targetAmount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
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
      case GoalType.insurance:
        return Icons.health_and_safety;
      case GoalType.other:
        return Icons.flag;
    }
  }

  Widget _buildRecentTransactions(BuildContext context, CurrencyService currencyService, List<dom_tx.Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/transactions'),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => TransactionDialog.showAddDialog(
                      context,
                      onTransactionSaved: (transaction) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaction added successfully'),
                            backgroundColor: Color(0xFF007A39),
                          ),
                        );
                      },
                    ),
                    child: const Text('Add Your First Transaction'),
                  ),
                ],
              ),
            ),
          )
        else
          ...transactions.map((transaction) => TransactionCard(
            transaction: transaction,
            showEditOptions: false, // Don't show edit options on dashboard
            onTap: () {
              // Navigate to full transactions screen or show details
            },
          )),
      ],
    );
  }

  Widget _buildTransactionItem(dom_tx.Transaction transaction, CurrencyService currencyService, BuildContext context) {
    IconData icon = Icons.remove_circle; // Default
    Color color = Colors.grey; // Default
    
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
      default:
        // Keep defaults
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class DashboardData {
  final List<dom_goal.Goal> goals;
  final List<dom_tx.Transaction> recentTransactions;
  final dom_budget.Budget? currentBudget;

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
