//lib/screens/dashboard_screen.dart
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
import 'goal_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardContent();
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  // Track when to refresh dashboard data
  int _refreshKey = 0;

  void _triggerRefresh() {
    setState(() => _refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final profile = authService.currentProfile;
        
        if (profile == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please log in', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
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
                  // Use key to force refresh when needed
                  key: ValueKey(_refreshKey),
                  future: _loadDashboardData(dataService, profile.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Scaffold(
                        backgroundColor: colorScheme.background,
                        body: Center(
                          child: CircularProgressIndicator(color: colorScheme.primary),
                        ),
                      );
                    }

                    final data = snapshot.data ?? DashboardData.empty();

                    return Scaffold(
                      backgroundColor: colorScheme.background,
                      appBar: AppBar(
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        elevation: 0,
                      ),
                      body: RefreshIndicator(
                        onRefresh: () async {
                          _triggerRefresh();
                          await Future.delayed(const Duration(milliseconds: 300));
                        },
                        child: SafeArea(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
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

  // Load all dashboard data
  Future<DashboardData> _loadDashboardData(
    OfflineDataService dataService,
    String profileId,
  ) async {
    try {
      final goals = await dataService.getAllGoals(profileId);
      final allTransactions = await dataService.getAllTransactions(profileId);
      final budgets = await dataService.getAllBudgets(profileId);
      
      allTransactions.sort((a, b) => b.date.compareTo(a.date));
      final recentTransactions = allTransactions.take(5).toList();
      
      // Get most recent active budget
      final activeBudgets = budgets.where((b) => b.isActive).toList();
      activeBudgets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final currentBudget = activeBudgets.isNotEmpty ? activeBudgets.first : null;
      
      return DashboardData(
        goals: goals,
        recentTransactions: recentTransactions,
        allTransactions: allTransactions,
        currentBudget: currentBudget,
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
    
    // Select icon based on profile type
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

  Widget _buildFinancialPositionCard(
    BuildContext context,
    CurrencyService currencyService,
    DashboardData data,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    // Filter transactions for current month
    final monthlyTransactions = data.allTransactions.where(
      (t) => t.date.isAfter(monthStart) && 
             t.date.isBefore(now.add(const Duration(days: 1))),
    ).toList();

    // Calculate monthly income and savings
    final monthlyIncome = monthlyTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final monthlySavings = monthlyTransactions
        .where((t) => t.type == TransactionType.savings)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    // Calculate savings rate percentage
    final savingsRate = monthlyIncome > 0 ? (monthlySavings / monthlyIncome * 100) : 0.0;

    // Calculate budget health - updated to show percentage remaining like in budget progress screen
    double budgetHealthPercent = 0.0;
    double budgetRemainingPercent = 0.0;
    String budgetHealthLabel = 'No Budget';
    Color budgetHealthColor = Colors.grey;
    
    if (data.currentBudget != null && data.currentBudget!.isActive) {
      final budget = data.currentBudget!;
      final remaining = budget.budgetAmount - budget.spentAmount;
      budgetHealthPercent = budget.budgetAmount > 0
          ? (budget.spentAmount / budget.budgetAmount * 100)
          : 0.0;
      
      budgetRemainingPercent = budget.budgetAmount > 0
          ? (remaining / budget.budgetAmount * 100)
          : 0.0;
      
      // Color code based on budget health - similar to budget progress screen
      if (budgetHealthPercent >= 90) {
        budgetHealthColor = FedhaColors.errorRed;
        budgetHealthLabel = 'Budget Alert';
      } else if (budgetHealthPercent >= 75) {
        budgetHealthColor = FedhaColors.warningOrange;
        budgetHealthLabel = 'Budget Low';
      } else {
        budgetHealthColor = FedhaColors.successGreen;
        budgetHealthLabel = 'Budget Remaining';
      }
    }

    // Calculate overall goals progress
    final activeGoals = data.goals.where((g) => g.status == GoalStatus.active).toList();
    double overallGoalsProgress = 0.0;
    
    if (activeGoals.isNotEmpty) {
      final totalTarget = activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
      final totalProgress = activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
      overallGoalsProgress = totalTarget > 0 ? (totalProgress / totalTarget * 100) : 0.0;
    }

    // Build summary items - updated budget item to show percentage remaining
    final summaryItems = [
      FinancialSummaryItem(
        label: 'Savings Rate',
        value: '${savingsRate.toStringAsFixed(1)}%',
        color: savingsRate >= 20
            ? FedhaColors.successGreen
            : savingsRate >= 10
                ? FedhaColors.warningOrange
                : FedhaColors.errorRed,
        icon: Icons.savings,
      ),
      FinancialSummaryItem(
        label: budgetHealthLabel,
        value: data.currentBudget != null && data.currentBudget!.isActive
            ? '${budgetRemainingPercent.toStringAsFixed(1)}% left'
            : 'Not Set',
        color: budgetHealthColor,
        icon: Icons.account_balance_wallet,
      ),
      FinancialSummaryItem(
        label: 'Goals Progress',
        value: activeGoals.isEmpty
            ? 'No Goals'
            : '${overallGoalsProgress.toStringAsFixed(1)}%',
        color: activeGoals.isEmpty
            ? Colors.grey
            : overallGoalsProgress >= 75
                ? FedhaColors.successGreen
                : overallGoalsProgress >= 50
                    ? FedhaColors.warningOrange
                    : FedhaColors.errorRed,
        icon: Icons.flag,
      ),
    ];

    return FinancialSummaryCard(
      title: 'Financial Overview',
      items: summaryItems,
      onTap: () => Navigator.pushNamed(context, '/analytics'),
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
                  // Refresh dashboard after adding transaction
                  _triggerRefresh();
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
              
              final smsService = SmsListenerService.instance;
              final authService = Provider.of<AuthService>(context, listen: false);
              final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
              final profileId = authService.currentProfile?.id ?? '';
              
              if (!smsService.isListening) {
                await smsService.startListening(
                  offlineDataService: offlineDataService,
                  profileId: profileId,
                );
              }
              
              Navigator.of(context).pushNamed('/sms_review');
            },
          ),
          QuickActionItem(
            title: 'Budget Progress',
            icon: Icons.account_balance_wallet,
            color: Colors.purple,
            onTap: () => Navigator.of(context).pushNamed('/budget_progress'),
          ),
          QuickActionItem(
            title: 'Analytics',
            icon: Icons.analytics,
            color: Colors.orange,
            onTap: () => Navigator.of(context).pushNamed('/analytics'),
          ),
        ];

    return QuickActionsGrid(actions: actions);
  }

  Widget _buildGoalsSection(
    BuildContext context,
    CurrencyService currencyService,
    List<dom_goal.Goal> goals,
  ) {
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
              onPressed: () async {
                // Navigate to goals screen and refresh on return
                await Navigator.of(context).pushNamed('/goals');
                _triggerRefresh();
              },
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
                    onPressed: () async {
                      await Navigator.of(context).pushNamed('/add_goal');
                      _triggerRefresh();
                    },
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

  Widget _buildGoalCard(
    dom_goal.Goal goal,
    CurrencyService currencyService,
    BuildContext context,
  ) {
    final progress = goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Navigate to goal details and refresh on return
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalDetailsScreen(goal: goal),
            ),
          );
          _triggerRefresh();
        },
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

  Widget _buildRecentTransactions(
    BuildContext context,
    CurrencyService currencyService,
    List<dom_tx.Transaction> transactions,
  ) {
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
                        _triggerRefresh();
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
            showEditOptions: false,
            onTap: () {},
          )),
      ],
    );
  }
}

// Dashboard data model
class DashboardData {
  final List<dom_goal.Goal> goals;
  final List<dom_tx.Transaction> recentTransactions;
  final List<dom_tx.Transaction> allTransactions;
  final dom_budget.Budget? currentBudget;

  DashboardData({
    required this.goals,
    required this.recentTransactions,
    required this.allTransactions,
    this.currentBudget,
  });

  factory DashboardData.empty() {
    return DashboardData(
      goals: [],
      recentTransactions: [],
      allTransactions: [],
      currentBudget: null,
    );
  }
}