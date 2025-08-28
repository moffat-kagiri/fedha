import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../models/enums.dart';
import '../services/offline_data_service.dart';

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
      
      final targetDate = DateTime.now().add(Duration(days: _selectedMonths * 30));
      final targetAmount = double.parse(_amountController.text);
      
      final goal = Goal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        targetAmount: targetAmount,
        currentAmount: 0.0,
        targetDate: targetDate,
        goalType: _selectedType,
        status: 'active',
      );

      dataService.addGoal(goal);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎯 Quick Goal created! Start saving today.'),
            backgroundColor: Color(0xFF007A39),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating goal: ${e.toString()}'),
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

  double get _targetAmount => double.tryParse(_amountController.text) ?? 0.0;
  double get _monthlyContribution => _targetAmount > 0 ? _targetAmount / _selectedMonths : 0.0;
  double get _weeklyContribution => _monthlyContribution / 4;
  double get _dailyContribution => _monthlyContribution / 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Quick Goal'),
        backgroundColor: const Color(0xFF007A39),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF007A39),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.rocket_launch,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Goal Creation ⚡',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create simple goals up to 9 months',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF007A39),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _buildGoalTypeOption(
                            GoalType.savings,
                            Icons.savings,
                            'Savings',
                            'Save for something special',
                          ),
                          _buildGoalTypeOption(
                            GoalType.emergencyFund,
                            Icons.security,
                            'Emergency Fund',
                            'Build your safety net',
                          ),
                          _buildGoalTypeOption(
                            GoalType.debtReduction,
                            Icons.money_off,
                            'Pay Off Debt',
                            'Reduce your debt burden',
                          ),
                          _buildGoalTypeOption(
                            GoalType.other,
                            Icons.flag,
                            'Other',
                            'Any other financial goal',
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Goal Title
                    Text(
                      'Goal Title',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF007A39),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g., "New Phone", "Emergency Fund"',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title, color: Color(0xFF007A39)),
                        filled: true,
                        fillColor: Colors.white,
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF007A39),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Why is this goal important to you?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description, color: Color(0xFF007A39)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Target Amount
                    const Text(
                      'Target Amount (Ksh)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A39),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        hintText: 'How much do you need?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.savings, color: Color(0xFF007A39)),
                        filled: true,
                        fillColor: Colors.white,
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
                        setState(() {
                          // Trigger rebuild to update calculations
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Time Frame Selection
                    const Text(
                      'Time Frame',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A39),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Quick goals are limited to 9 months maximum',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: _quickMonthOptions.map((months) {
                          return _buildTimeFrameOption(months);
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Calculation Summary
                    if (_targetAmount > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007A39).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF007A39).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calculate, color: Color(0xFF007A39)),
                                const SizedBox(width: 8),
                                const Text(
                                  'Savings Breakdown',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF007A39),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildCalculationRow('Target Amount', 'Ksh ${_targetAmount.toStringAsFixed(2)}'),
                            _buildCalculationRow('Time Frame', '$_selectedMonths months'),
                            _buildCalculationRow('Monthly Savings', 'Ksh ${_monthlyContribution.toStringAsFixed(2)}'),
                            _buildCalculationRow('Weekly Savings', 'Ksh ${_weeklyContribution.toStringAsFixed(2)}'),
                            _buildCalculationRow('Daily Savings', 'Ksh ${_dailyContribution.toStringAsFixed(2)}'),
                            
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Pro tip: Set up automatic savings of Ksh ${_monthlyContribution.toStringAsFixed(0)} per month!',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
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
                      
                      const SizedBox(height: 24),
                    ],
                    
                    // Create Goal Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _createQuickGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007A39),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                  Text('Creating Goal...'),
                                ],
                              )
                            : const Text(
                                'Create Quick Goal 🚀',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
                        child: const Text(
                          'Need a more detailed goal? Try the SMART Goal Wizard',
                          style: TextStyle(
                            color: Color(0xFF007A39),
                            decoration: TextDecoration.underline,
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

  Widget _buildGoalTypeOption(GoalType type, IconData icon, String title, String subtitle) {
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
          color: isSelected ? const Color(0xFF007A39).withValues(alpha: 0.1) : Colors.transparent,
          border: type != GoalType.other ? Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF007A39) : Colors.grey,
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
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF007A39) : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF007A39),
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFrameOption(int months) {
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
          color: isSelected ? const Color(0xFF007A39).withValues(alpha: 0.1) : Colors.transparent,
          border: months != 9 ? Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ) : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              color: isSelected ? const Color(0xFF007A39) : Colors.grey,
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
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF007A39) : Colors.black87,
                    ),
                  ),
                  Text(
                    _getTimeFrameDescription(months),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF007A39),
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A39),
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
