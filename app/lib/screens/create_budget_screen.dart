import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;

import '../data/app_database.dart';
import '../data/extensions/budget_extensions.dart';
import '../services/offline_data_service.dart';
import '../services/auth_service.dart';
import '../models/enums.dart';

enum BudgetPeriod { daily, weekly, monthly, quarterly, yearly }

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
  double _limitAmount = 0.0;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isRecurring = false;
  Category? _selectedCategory;
  BudgetPeriod _budgetPeriod = BudgetPeriod.monthly;
  final Map<String, double> _categoryBudgets = {};
  final Map<String, double> _budgetCategories = {};
  bool _isCreating = false;
  List<Category> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final dataService = Provider.of<OfflineDataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileId = int.tryParse(authService.currentProfile?.id ?? '0') ?? 0;
    
    try {
      final List<dynamic> rawCategories = await dataService.getCategories(profileId);
      final List<Category> typedCategories = rawCategories.map((c) => c as Category).toList();
      if (mounted) {
        setState(() {
          _availableCategories = typedCategories;
          if (typedCategories.isNotEmpty) {
            _selectedCategory = typedCategories.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = int.tryParse(authService.currentProfile?.id ?? '0') ?? 0;
      
      final budget = Budget(
        name: _budgetName,
        limitMinor: _limitAmount * 100, // Convert to minor units
        currency: 'KES', // Default to KES
        categoryId: _selectedCategory?.id,
        startDate: _startDate,
        endDate: _endDate ?? _getEndDate(),
        isRecurring: _isRecurring,
        profileId: profileId,
      );

      await dataService.addBudget(budget);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Budget created successfully! You\'re on your way to better financial control.'),
            backgroundColor: Color(0xFF007A39),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating budget: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Create Budget'),
        backgroundColor: const Color(0xFF007A39),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF007A39),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Step ${_currentPage + 1} of $_totalPages',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      '${((_currentPage + 1) / _totalPages * 100).round()}% Complete',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentPage + 1) / _totalPages,
                  backgroundColor: Colors.white.withValues(red: 255, green: 255, blue: 255, alpha: 77),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                _buildWelcomePage(),
                _buildIncomeSetupPage(),
                _buildCategoryBudgetPage(),
                _buildReviewPage(),
              ],
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(red: 158, green: 158, blue: 158, alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF007A39),
                        side: const BorderSide(color: Color(0xFF007A39)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentPage == _totalPages - 1 
                        ? (_isCreating ? null : _createBudget)
                        : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A39),
                      foregroundColor: Colors.white,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Color(0xFF007A39),
          ),
          const SizedBox(height: 20),
          const Text(
            'Great Choice! 🎉',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A39),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You\'re taking a fantastic step toward financial wellness! Creating a budget is one of the most powerful tools for achieving your financial goals.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What you\'ll accomplish:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A39),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBenefitItem('📊', 'Track spending across categories'),
                _buildBenefitItem('🎯', 'Set realistic financial goals'),
                _buildBenefitItem('📱', 'Get progress notifications'),
                _buildBenefitItem('💰', 'Build healthy money habits'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Budget Name',
              hintText: 'e.g., "January 2025 Budget" or "Monthly Expenses"',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit, color: Color(0xFF007A39)),
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
            decoration: const InputDecoration(
              labelText: 'Budget Period',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF007A39)),
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

  Widget _buildIncomeSetupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.attach_money,
            size: 80,
            color: Color(0xFF007A39),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Income 💚',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A39),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s start with your ${_budgetPeriod.name} income. This will help us suggest realistic budget amounts for each category.',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 32),
          TextFormField(
            decoration: InputDecoration(
              labelText: '${_budgetPeriod.name.toUpperCase()} Income (Ksh)',
              hintText: 'Enter your total income for this period',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.account_balance, color: Color(0xFF007A39)),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lightbulb, color: Color(0xFF007A39), size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'Smart Budgeting Tip',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007A39),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Follow the 50/30/20 rule:\n• 50% for needs (housing, food, utilities)\n• 30% for wants (entertainment, dining out)\n• 20% for savings and debt payment',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'For Ksh ${_totalIncome.toStringAsFixed(2)}:\n• Needs: Ksh ${(_totalIncome * 0.5).toStringAsFixed(2)}\n• Wants: Ksh ${(_totalIncome * 0.3).toStringAsFixed(2)}\n• Savings: Ksh ${(_totalIncome * 0.2).toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007A39),
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

  Widget _buildCategoryBudgetPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.category,
            size: 80,
            color: Color(0xFF007A39),
          ),
          const SizedBox(height: 20),
          const Text(
            'Allocate Your Budget 📊',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A39),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Now let\'s allocate your income across different spending categories. You can adjust these amounts as needed.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 20),
          
          // Budget summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Income:', style: TextStyle(fontSize: 16)),
                    Text('Ksh ${_totalIncome.toStringAsFixed(2)}', 
                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Allocated:', style: TextStyle(fontSize: 16)),
                    Text('Ksh ${_totalAllocated.toStringAsFixed(2)}', 
                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remaining:', style: TextStyle(fontSize: 16)),
                    Text('Ksh ${_remainingBudget.toStringAsFixed(2)}', 
                         style: TextStyle(
                           fontSize: 16, 
                           fontWeight: FontWeight.bold,
                           color: _remainingBudget >= 0 ? const Color(0xFF007A39) : Colors.red,
                         )),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _totalIncome > 0 ? (_totalAllocated / _totalIncome).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _remainingBudget >= 0 ? const Color(0xFF007A39) : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Category budget inputs
          Column(
            children: _budgetCategories.entries.map((entry) {
              final category = entry.key;
              final amount = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: '$category (Ksh)',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(_getCategoryIcon(category), color: const Color(0xFF007A39)),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'ve allocated more than your income! Please reduce some category amounts by Ksh ${(-_remainingBudget).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.red, fontSize: 14),
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

  Widget _buildReviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Color(0xFF007A39),
          ),
          const SizedBox(height: 20),
          const Text(
            'Review Your Budget ✨',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A39),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Perfect! Here\'s a summary of your budget. You can always adjust it later from the budget management screen.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          
          // Budget summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(red: 158, green: 158, blue: 158, alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _budgetName.isEmpty ? 'Your Budget' : _budgetName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A39),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Period: ${_budgetPeriod.name.toUpperCase()}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const Divider(height: 24),
                
                // Income
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Income:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ksh ${_totalIncome.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A39),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Categories
                const Text(
                  'Budget Allocation:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Category budget allocation
                if (_categoryBudgets.entries.where((entry) => entry.value > 0).isNotEmpty)
                  Column(
                    children: _categoryBudgets.entries
                        .where((entry) => entry.value > 0)
                        .map((entry) {
                      final percentage = _totalIncome > 0 ? (entry.value / _totalIncome * 100) : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(_getCategoryIcon(entry.key), 
                                 size: 16, color: const Color(0xFF007A39)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(entry.key, style: const TextStyle(fontSize: 14)),
                            ),
                            Text(
                              'Ksh ${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Allocated:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ksh ${_totalAllocated.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Remaining:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ksh ${_remainingBudget.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _remainingBudget >= 0 ? const Color(0xFF007A39) : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Encouragement message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, color: Color(0xFF007A39), size: 32),
                const SizedBox(height: 8),
                const Text(
                  'You\'re on your way to financial success! 🎉',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A39),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'We\'ll send you helpful notifications to keep you on track and celebrate your progress along the way.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Housing & Utilities':
        return Icons.home;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Entertainment':
        return Icons.movie;
      case 'Healthcare':
        return Icons.local_hospital;
      case 'Education':
        return Icons.school;
      case 'Savings':
        return Icons.savings;
      case 'Emergency Fund':
        return Icons.security;
      default:
        return Icons.category;
    }
  }
}
