// lib/screens/create_budget_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../models/enums.dart';
import '../services/budget_service.dart';
import '../services/offline_data_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class CreateBudgetScreen extends StatefulWidget {
  final Budget? editingBudget;
  const CreateBudgetScreen(
    {Key? key, this.editingBudget}
    ) : super(key: key);

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // Budget data
  String _budgetName = '';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  Map<String, double> _categoryBudgets = {};
  bool _isCreating = false;

  final List<Map<String, dynamic>> _budgetCategories = [
    {'id': 'food', 'name': 'Food & Dining', 'icon': Icons.restaurant_outlined},
    {'id': 'transport', 'name': 'Transportation', 'icon': Icons.directions_car_outlined},
    {'id': 'utilities', 'name': 'Housing & Utilities', 'icon': Icons.home_outlined},
    {'id': 'shopping', 'name': 'Shopping', 'icon': Icons.shopping_bag_outlined},
    {'id': 'entertainment', 'name': 'Entertainment', 'icon': Icons.movie_outlined},
    {'id': 'healthcare', 'name': 'Healthcare', 'icon': Icons.local_hospital_outlined},
    {'id': 'education', 'name': 'Education', 'icon': Icons.school_outlined},
    {'id': 'savings', 'name': 'Savings', 'icon': Icons.savings_outlined},
    {'id': 'other', 'name': 'Other', 'icon': Icons.category_outlined},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize category budgets
    for (var category in _budgetCategories) {
      _categoryBudgets[category['id']] = 0.0;
    }
    // Set default budget name
    _budgetName = 'Budget - ${_getMonthName(_startDate.month)} ${_startDate.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
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
    setState(() => _isCreating = true);

    try {
      final budgetService = Provider.of<BudgetService>(context, listen: false); // ✅ ADD THIS
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = authService.profileId ?? '';

      // ✅ VALIDATION: Ensure profile is selected
      if (profileId.isEmpty) {
        throw Exception('No active profile. Please select a profile first.');
      }

      // Ensure BudgetService has the current profile loaded
      await budgetService.loadBudgetsForProfile(profileId);

      // Create individual budget for each category with an allocation
      int budgetsCreated = 0;
      for (var categoryData in _budgetCategories) {
        final category = categoryData['id'] as String;
        final amount = _categoryBudgets[category] ?? 0.0;

        if (amount > 0) {
          final budget = Budget(
            id: const Uuid().v4(),
            remoteId: null,
            name: '$_budgetName - ${categoryData['name']}',
            description: 'Budget for ${categoryData['name']}',
            budgetAmount: amount,
            spentAmount: 0.0,
            category: category,
            profileId: profileId,
            startDate: _startDate,
            endDate: _endDate,
            isActive: true,
            isSynced: false,
            currency: 'KES', // ✅ ADD THIS - REQUIRED FIELD
            createdAt: DateTime.now(), // ✅ ADD THIS - required by model
            updatedAt: DateTime.now(), // ✅ ADD THIS - required by model
          );

          // ✅ FIX: Use BudgetService instead of direct database call
          final success = await budgetService.createBudget(budget);
          if (success) {
            budgetsCreated++;
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 $budgetsCreated budgets created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  double get _totalAllocated => _categoryBudgets.values.fold(0.0, (sum, amount) => sum + amount);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Budget'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(colorScheme),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildWelcomePage(context),
                _buildDateSelectionPage(context),
                _buildCategoryAllocationPage(context),
                _buildReviewPage(context),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    return Container(
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
                style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8)),
              ),
              const Spacer(),
              Text(
                '${((_currentPage + 1) / _totalPages * 100).round()}%',
                style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8)),
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
    );
  }

  Widget _buildNavigationButtons() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: FilledButton.tonal(
                onPressed: _previousPage,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              onPressed: _currentPage == _totalPages - 1
                  ? (_isCreating ? null : _createBudget)
                  : _nextPage,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isCreating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Welcome to Conscious Spending! 🌱',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Budgeting isn\'t about deprivation—it\'s about awareness. Track your spending, understand your habits, and make intentional choices with your money.',
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
                    'Your Journey:',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem('🎯', 'Set realistic spending targets'),
                  _buildBenefitItem('📊', 'Track progress, not perfection'),
                  _buildBenefitItem('💡', 'Learn from each budget cycle'),
                  _buildBenefitItem('🌟', 'Build better habits over time'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: _budgetName,
            decoration: InputDecoration(
              labelText: 'Budget Name',
              prefixIcon: Icon(Icons.edit_outlined, color: colorScheme.primary),
            ),
            onChanged: (value) => setState(() => _budgetName = value.trim()),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectionPage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.calendar_today_outlined, size: 80, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Budget Period 📅',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose when this budget starts and ends. Most people budget monthly, but you can customize it to match your income cycle.',
            style: textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 32),

          // Quick period presets
          Text('Quick Presets:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPeriodPreset('This Month', () {
                final now = DateTime.now();
                setState(() {
                  _startDate = DateTime(now.year, now.month, 1);
                  _endDate = DateTime(now.year, now.month + 1, 0);
                });
              }),
              _buildPeriodPreset('Next Month', () {
                final now = DateTime.now();
                setState(() {
                  _startDate = DateTime(now.year, now.month + 1, 1);
                  _endDate = DateTime(now.year, now.month + 2, 0);
                });
              }),
              _buildPeriodPreset('30 Days', () {
                final now = DateTime.now();
                setState(() {
                  _startDate = now;
                  _endDate = now.add(const Duration(days: 30));
                });
              }),
              _buildPeriodPreset('Bi-weekly', () {
                final now = DateTime.now();
                setState(() {
                  _startDate = now;
                  _endDate = now.add(const Duration(days: 14));
                });
              }),
            ],
          ),

          const SizedBox(height: 32),
          Text('Custom Dates:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Start date
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _startDate = date;
                  // Ensure end date is after start date
                  if (_endDate.isBefore(_startDate)) {
                    _endDate = _startDate.add(const Duration(days: 30));
                  }
                });
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Start Date',
                prefixIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
              ),
              child: Text(
                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                style: textTheme.bodyLarge,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // End date
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _endDate,
                firstDate: _startDate,
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (date != null) {
                setState(() => _endDate = date);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'End Date',
                prefixIcon: Icon(Icons.event, color: colorScheme.primary),
              ),
              child: Text(
                '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                style: textTheme.bodyLarge,
              ),
            ),
          ),

          const SizedBox(height: 24),
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Budget duration: ${_endDate.difference(_startDate).inDays} days',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodPreset(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }

  Widget _buildCategoryAllocationPage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.category_outlined, size: 80, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Allocate by Category 🎯',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Set spending targets for each category. Don\'t worry about being perfect—you can always adjust as you learn what works for you.',
            style: textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),

          // Total summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Budget:', style: textTheme.titleMedium),
                  Text(
                    'KSh ${_totalAllocated.toStringAsFixed(0)}',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Category inputs
          ..._budgetCategories.map((categoryData) { // ✅ FIX: Renamed to categoryData
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: '${categoryData['name']} (KSh)',
                  prefixIcon: Icon(categoryData['icon'] as IconData, color: colorScheme.primary),
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  setState(() {
                    _categoryBudgets[categoryData['id']] = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
            );
          }),

          const SizedBox(height: 16),
          Card(
            color: colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: colorScheme.onTertiaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: Start with categories you spend most on. You can skip categories you don\'t use.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final activeBudgets = _categoryBudgets.entries.where((e) => e.value > 0).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.check_circle_outline, size: 80, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'You\'re All Set! ✨',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Here\'s your budget summary. Remember: this is a guide, not a restriction. The goal is awareness and improvement, not perfection.',
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
                    _budgetName,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year} (${_endDate.difference(_startDate).inDays} days)',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Budget Allocation:',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (activeBudgets.isEmpty)
                    Text(
                      'No categories allocated yet',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    )
                  else
                    ...activeBudgets.map((entry) {
                      final categoryData = _budgetCategories.firstWhere(
                        (c) => c['id'] == entry.key,
                        orElse: () => {'name': entry.key, 'icon': Icons.category},
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              categoryData['icon'] as IconData,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(categoryData['name'] as String)),
                            Text(
                              'KSh ${entry.value.toStringAsFixed(0)}',
                              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),

                  const Divider(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'KSh ${_totalAllocated.toStringAsFixed(0)}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.trending_up, color: colorScheme.onPrimaryContainer, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Your journey begins! 🚀',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll track your progress and help you understand your spending patterns. Each budget cycle is a chance to improve!',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
