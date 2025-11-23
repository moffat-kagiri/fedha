import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import '../services/auth_service.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  GoalType _selectedType = GoalType.savings;
  int _selectedMonths = 3;
  bool _isCreating = false;

  final List<int> _quickMonthOptions = [1, 2, 3, 6, 9];
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _createQuickGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false); // Moved here
      
      final targetDate = DateTime.now().add(Duration(days: _selectedMonths * 30));
      final targetAmount = double.parse(_amountController.text);
      
      final goal = Goal(
        profileId: authService.currentProfile?.id ?? '0', // Fixed: Use authService
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        targetAmount: targetAmount,
        currentAmount: 0.0,
        targetDate: targetDate,
        goalType: _selectedType,
        status: GoalStatus.active, // Fixed: Use enum instead of string
      );

      await dataService.addGoal(goal);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar( // Fixed: Use theme color
            content: const Text('🎯 Quick Goal created! Start saving today.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating goal: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  double get _targetAmount => double.tryParse(_amountController.text) ?? 0.0;
  double get _monthlyContribution => _targetAmount > 0 ? _targetAmount / _selectedMonths : 0.0;
  double get _weeklyContribution => _monthlyContribution / 4;
  double get _dailyContribution => _monthlyContribution / 30;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Quick Goal'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.rocket_launch_rounded,
                    size: 60,
                    color: colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Quick Goal Creation ⚡',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create simple goals up to 9 months',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Form section
            Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal Type Selection
                    Text(
                      'Goal Type',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Card(
                      child: Column(
                        children: [
                          _buildGoalTypeOption(
                            GoalType.savings,
                            Icons.savings_rounded,
                            'Savings',
                            'Save for something special',
                            colorScheme,
                          ),
                          _buildGoalTypeOption(
                            GoalType.emergencyFund,
                            Icons.shield_rounded,
                            'Emergency Fund',
                            'Build your safety net',
                            colorScheme,
                          ),
                          _buildGoalTypeOption(
                            GoalType.debtReduction,
                            Icons.credit_card_off_rounded,
                            'Pay Off Debt',
                            'Reduce your debt burden',
                            colorScheme,
                          ),
                          _buildGoalTypeOption(
                            GoalType.other,
                            Icons.flag_rounded,
                            'Other',
                            'Any other financial goal',
                            colorScheme,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Goal Title
                    Text(
                      'Goal Title',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., "New Phone", "Emergency Fund"',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a goal title';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Goal Description (Optional)
                    Text(
                      'Description (Optional)',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Why is this goal important to you?',
                        prefixIcon: Icon(Icons.description_rounded),
                      ),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Target Amount
                    Text(
                      'Target Amount (Ksh)',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        hintText: 'How much do you need?',
                        prefixIcon: Icon(Icons.savings_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the target amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        if (amount > 1000000) {
                          return 'For large goals, use the SMART Goal Wizard';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Time Frame Selection
                    Text(
                      'Time Frame',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quick goals are limited to 9 months maximum',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Card(
                      child: Column(
                        children: _quickMonthOptions.map((months) {
                          return _buildTimeFrameOption(months, colorScheme);
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Calculation Summary
                    if (_targetAmount > 0) ...[
                      Card(
                        color: colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calculate_rounded, color: colorScheme.onPrimaryContainer),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Savings Breakdown',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildCalculationRow('Target Amount', 'Ksh ${_targetAmount.toStringAsFixed(2)}', textTheme),
                              _buildCalculationRow('Time Frame', '$_selectedMonths months', textTheme),
                              _buildCalculationRow('Monthly Savings', 'Ksh ${_monthlyContribution.toStringAsFixed(2)}', textTheme),
                              _buildCalculationRow('Weekly Savings', 'Ksh ${_weeklyContribution.toStringAsFixed(2)}', textTheme),
                              _buildCalculationRow('Daily Savings', 'Ksh ${_dailyContribution.toStringAsFixed(2)}', textTheme),
                              
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lightbulb_rounded, color: colorScheme.onSecondaryContainer, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Pro tip: Set up automatic savings of Ksh ${_monthlyContribution.toStringAsFixed(0)} per month!',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                    
                    // Create Goal Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isCreating ? null : _createQuickGoal,
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
                                  Text('Creating Goal...'),
                                ],
                              )
                            : const Text(
                                'Create Quick Goal 🚀',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Advanced Option
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/progressive-goal-wizard');
                        },
                        child: Text(
                          'Need a more detailed goal? Try the SMART Goal Wizard',
                          style: TextStyle(
                            color: colorScheme.primary,
                          ),
                        ),
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

  Widget _buildGoalTypeOption(GoalType type, IconData icon, String title, String subtitle, ColorScheme colorScheme) {
    final isSelected = _selectedType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          border: type != GoalType.other ? Border(
            bottom: BorderSide(color: colorScheme.outline),
          ) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFrameOption(int months, ColorScheme colorScheme) {
    final isSelected = _selectedMonths == months;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMonths = months;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          border: months != 9 ? Border(
            bottom: BorderSide(color: colorScheme.outline),
          ) : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$months ${months == 1 ? 'Month' : 'Months'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _getTimeFrameDescription(months),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium,
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeFrameDescription(int months) {
    switch (months) {
      case 1:
        return 'Very short-term goal';
      case 2:
        return 'Quick achievement';
      case 3:
        return 'Short-term commitment';
      case 6:
        return 'Medium-term goal';
      case 9:
        return 'Extended commitment';
      default:
        return 'Custom timeframe';
    }
  }
}