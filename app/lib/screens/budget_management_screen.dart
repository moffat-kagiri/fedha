import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../theme/app_theme.dart';

class BudgetManagementScreen extends StatefulWidget {
  final Budget budget;
  
  const BudgetManagementScreen({Key? key, required this.budget}) : super(key: key);

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  late Budget _currentBudget;
  final TextEditingController _expenseController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final double totalSpent = 0.0; // ⭐ FIXED: Removed semicolon before =
  double _newExpenseAmount = 0.0;
  String _selectedCategory = 'Food';
  final List<String> _categories = [
    'Food', 'Transport', 'Entertainment', 'Utilities', 
    'Shopping', 'Healthcare', 'Education', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _currentBudget = widget.budget;
  }

  @override
  void dispose() {
    _expenseController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _addExpense() {
    if (_expenseController.text.isEmpty || _newExpenseAmount <= 0) return;

    setState(() {
      _currentBudget = _currentBudget.copyWith(
        totalSpent: _currentBudget.totalSpent + _newExpenseAmount,
      );
    });

    _expenseController.clear();
    _amountController.clear();
    Navigator.pop(context); // Close the dialog
  }

  void _resetBudget() {
    setState(() {
      _currentBudget = _currentBudget.copyWith(
        totalSpent: 0.0,
      );
    });
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _expenseController,
              decoration: const InputDecoration(
                labelText: 'Expense Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (KSh)',
                border: OutlineInputBorder(),
                prefixText: 'KSh ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _newExpenseAmount = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _addExpense,
            child: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  double get _remainingBudget => _currentBudget.totalBudget - _currentBudget.totalSpent;
  double get _usagePercentage => _currentBudget.totalBudget > 0 
      ? (_currentBudget.totalSpent / _currentBudget.totalBudget) * 100 
      : 0;

  Color _getProgressColor() {
    if (_usagePercentage < 60) return FedhaColors.successGreen;
    if (_usagePercentage < 85) return FedhaColors.warningOrange;
    return FedhaColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _resetBudget,
            tooltip: 'Reset Budget',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Overview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currentBudget.name,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Badge(
                          label: Text('${_currentBudget.daysRemaining}d left'),
                          backgroundColor: colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Budget Progress
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Budget Progress',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_usagePercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: _getProgressColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _usagePercentage / 100,
                          backgroundColor: colorScheme.surfaceVariant,
                          color: _getProgressColor(),
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'KSh ${_currentBudget.totalSpent.toStringAsFixed(0)}',
                              style: textTheme.bodySmall,
                            ),
                            Text(
                              'KSh ${_currentBudget.totalBudget.toStringAsFixed(0)}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Budget Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Remaining',
                            value: 'KSh ${_remainingBudget.toStringAsFixed(0)}',
                            color: _remainingBudget >= 0 
                                ? FedhaColors.successGreen 
                                : FedhaColors.errorRed,
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Spent',
                            value: 'KSh ${_currentBudget.totalSpent.toStringAsFixed(0)}',
                            color: colorScheme.primary,
                            icon: Icons.shopping_cart_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add_chart_rounded, size: 18),
                  label: const Text('Add Expense'),
                  onPressed: _showAddExpenseDialog,
                ),
                ActionChip(
                  avatar: const Icon(Icons.analytics_rounded, size: 18),
                  label: const Text('View Reports'),
                  onPressed: () {
                    // TODO: Implement reports navigation
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.notifications_rounded, size: 18),
                  label: const Text('Set Alert'),
                  onPressed: () {
                    // TODO: Implement alert setting
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Activity Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Budget Tips',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.lightbulb_rounded),
                        onPressed: () {},
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildTipCard(
                          icon: Icons.trending_up_rounded,
                          title: 'Track Daily Spending',
                          description: 'Monitor your daily expenses to stay within budget',
                          color: FedhaColors.infoBlue,
                        ),
                        _buildTipCard(
                          icon: Icons.savings_rounded,
                          title: 'Save 20% of Income',
                          description: 'Aim to save at least 20% of your monthly income',
                          color: FedhaColors.successGreen,
                        ),
                        _buildTipCard(
                          icon: Icons.warning_rounded,
                          title: 'Budget Warning',
                          description: 'You\'ve used ${_usagePercentage.toStringAsFixed(0)}% of your budget',
                          color: _usagePercentage > 80 ? FedhaColors.errorRed : FedhaColors.warningOrange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
}
