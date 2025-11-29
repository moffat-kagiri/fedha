import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../models/enums.dart';
import '../services/offline_data_service.dart';

class CreateBudgetScreen extends StatefulWidget {
  const CreateBudgetScreen({Key? key}) : super(key: key);

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // Budget data
  String _budgetName = '';
  double _totalIncome = 0.0;
  BudgetPeriod _budgetPeriod = BudgetPeriod.monthly;
  Map<String, double> _categoryBudgets = {};
  bool _isCreating = false;

  final List<String> _budgetCategories = [
    'Food & Dining',
    'Transportation', 
    'Housing & Utilities',
    'Shopping',
    'Entertainment',
    'Healthcare',
    'Education',
    'Savings',
    'Emergency Fund',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize category budgets with zero
    for (String category in _budgetCategories) {
      _categoryBudgets[category] = 0.0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createBudget() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      
      final budget = Budget(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _budgetName,
        budgetAmount: _categoryBudgets.values.fold(0.0, (sum, amount) => sum + amount),
        categoryId: 'general', // Default category ID
        startDate: DateTime.now(),
        endDate: _getEndDate(),
        isActive: true,
      );

      dataService.addBudget(budget);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎉 Budget created successfully! You\'re on your way to better financial control.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating budget: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  DateTime _getEndDate() {
    final now = DateTime.now();
    switch (_budgetPeriod) {
      case BudgetPeriod.daily:
        return now.add(const Duration(days: 1));
      case BudgetPeriod.weekly:
        return now.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case BudgetPeriod.quarterly:
        return DateTime(now.year, now.month + 3, now.day);
      case BudgetPeriod.yearly:
        return DateTime(now.year + 1, now.month, now.day);
    }
  }

  double get _totalAllocated => _categoryBudgets.values.fold(0.0, (sum, amount) => sum + amount);
  double get _remainingBudget => _totalIncome - _totalAllocated;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Budget'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Step ${_currentPage + 1} of $_totalPages',
                      style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8), fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      '${((_currentPage + 1) / _totalPages * 100).round()}% Complete',
                      style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_currentPage + 1) / _totalPages,
                  backgroundColor: colorScheme.onPrimary.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildWelcomePage(context),
                _buildIncomeSetupPage(context),
                _buildCategoryBudgetPage(context),
                _buildReviewPage(context),
              ],
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _previousPage,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _currentPage == _totalPages - 1 
                        ? (_isCreating ? null : _createBudget)
                        : _nextPage,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isCreating
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Creating...'),
                            ],
                          )
                        : Text(_currentPage == _totalPages - 1 ? 'Create Budget' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Great Choice! 🎉',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re taking a fantastic step toward financial wellness! Creating a budget is one of the most powerful tools for achieving your financial goals.',
            style: textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What you\'ll accomplish:',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem('📊', 'Track spending across categories'),
                  _buildBenefitItem('🎯', 'Set realistic financial goals'),
                  _buildBenefitItem('📱', 'Get progress notifications'),
                  _buildBenefitItem('💰', 'Build healthy money habits'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Budget Name',
              hintText: 'e.g., "January 2025 Budget" or "Monthly Expenses"',
              prefixIcon: Icon(Icons.edit_outlined, color: colorScheme.primary),
            ),
            onChanged: (value) {
              setState(() {
                _budgetName = value.trim();
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<BudgetPeriod>(
            value: _budgetPeriod,
            decoration: InputDecoration(
              labelText: 'Budget Period',
              prefixIcon: Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
            ),
            items: BudgetPeriod.values.map((period) {
              return DropdownMenuItem(
                value: period,
                child: Text(period.name.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _budgetPeriod = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSetupPage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.attach_money_outlined,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Your Income 💚',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s start with your ${_budgetPeriod.name} income. This will help us suggest realistic budget amounts for each category.',
            style: textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 32),
          TextFormField(
            decoration: InputDecoration(
              labelText: '${_budgetPeriod.name.toUpperCase()} Income (Ksh)',
              hintText: 'Enter your total income for this period',
              prefixIcon: Icon(Icons.account_balance_outlined, color: colorScheme.primary),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: (value) {
              setState(() {
                _totalIncome = double.tryParse(value) ?? 0.0;
              });
            },
          ),
          const SizedBox(height: 24),
          if (_totalIncome > 0) ...[
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.lightbulb_outline, color: colorScheme.primary, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Smart Budgeting Tip',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Follow the 50/30/20 rule:\n• 50% for needs (housing, food, utilities)\n• 30% for wants (entertainment, dining out)\n• 20% for savings and debt payment',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'For Ksh ${_totalIncome.toStringAsFixed(2)}:\n• Needs: Ksh ${(_totalIncome * 0.5).toStringAsFixed(2)}\n• Wants: Ksh ${(_totalIncome * 0.3).toStringAsFixed(2)}\n• Savings: Ksh ${(_totalIncome * 0.2).toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetPage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.category_outlined,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Allocate Your Budget 📊',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Now let\'s allocate your income across different spending categories. You can adjust these amounts as needed.',
            style: textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          
          // Budget summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Income:', style: textTheme.bodyLarge),
                      Text('Ksh ${_totalIncome.toStringAsFixed(2)}', 
                           style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Allocated:', style: textTheme.bodyLarge),
                      Text('Ksh ${_totalAllocated.toStringAsFixed(2)}', 
                           style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Remaining:', style: textTheme.bodyLarge),
                      Text('Ksh ${_remainingBudget.toStringAsFixed(2)}', 
                           style: textTheme.bodyLarge?.copyWith(
                             fontWeight: FontWeight.bold,
                             color: _remainingBudget >= 0 ? colorScheme.primary : colorScheme.error,
                           )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _totalIncome > 0 ? (_totalAllocated / _totalIncome).clamp(0.0, 1.0) : 0.0,
                    backgroundColor: colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remainingBudget >= 0 ? colorScheme.primary : colorScheme.error,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Category budget inputs
          Column(
            children: _budgetCategories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: '$category (Ksh)',
                    prefixIcon: Icon(_getCategoryIcon(category), color: colorScheme.primary),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _categoryBudgets[category] = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
              );
            }).toList(),
          ),
          
          if (_remainingBudget < 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You\'ve allocated more than your income! Please reduce some category amounts by Ksh ${(-_remainingBudget).toStringAsFixed(2)}',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewPage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Review Your Budget ✨',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Perfect! Here\'s a summary of your budget. You can always adjust it later from the budget management screen.',
            style: textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          
          // Budget summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _budgetName.isEmpty ? 'Your Budget' : _budgetName,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Period: ${_budgetPeriod.name.toUpperCase()}',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  
                  // Income
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Income:',
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Ksh ${_totalIncome.toStringAsFixed(2)}',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Categories
                  Text(
                    'Budget Allocation:',
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category budget allocation
                  if (_categoryBudgets.entries.where((entry) => entry.value > 0).isNotEmpty)
                    Column(
                      children: _categoryBudgets.entries
                          .where((entry) => entry.value > 0)
                          .map((entry) {
                        final percentage = _totalIncome > 0 ? (entry.value / _totalIncome * 100) : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(_getCategoryIcon(entry.key), 
                                   size: 18, color: colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(entry.key, style: textTheme.bodyMedium),
                              ),
                              Text(
                                'Ksh ${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Allocated:',
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Ksh ${_totalAllocated.toStringAsFixed(2)}',
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining:',
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Ksh ${_remainingBudget.toStringAsFixed(2)}',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _remainingBudget >= 0 ? colorScheme.primary : colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Encouragement message
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.emoji_events_outlined, color: colorScheme.primary, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'You\'re on your way to financial success! 🎉',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll send you helpful notifications to keep you on track and celebrate your progress along the way.',
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String emoji, String text) {
    final textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return Icons.restaurant_outlined;
      case 'Transportation':
        return Icons.directions_car_outlined;
      case 'Housing & Utilities':
        return Icons.home_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Entertainment':
        return Icons.movie_outlined;
      case 'Healthcare':
        return Icons.local_hospital_outlined;
      case 'Education':
        return Icons.school_outlined;
      case 'Savings':
        return Icons.savings_outlined;
      case 'Emergency Fund':
        return Icons.shield_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}