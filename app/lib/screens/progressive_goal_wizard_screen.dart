import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import '../theme/app_theme.dart';

class ProgressiveGoalWizardScreen extends StatefulWidget {
  const ProgressiveGoalWizardScreen({Key? key}) : super(key: key);

  @override
  State<ProgressiveGoalWizardScreen> createState() => _ProgressiveGoalWizardScreenState();
}

class _ProgressiveGoalWizardScreenState extends State<ProgressiveGoalWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;

  // Goal data
  String _goalTitle = '';
  String _goalDescription = '';
  GoalType _goalType = GoalType.savings;
  double _targetAmount = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpenses = 0.0;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  String _actionPlan = '';
  bool _isCreating = false;

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

  Future<void> _createGoal() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      
      final goal = Goal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _goalTitle,
        description: _goalDescription,
        targetAmount: _targetAmount,
        currentAmount: 0.0,
        targetDate: _targetDate,
        goalType: _goalType,
        status: 'active',
      );

      dataService.addGoal(goal);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎯 SMART Goal created successfully! You\'re on the path to financial success.'),
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

  double get _discretionaryIncome => _monthlyIncome - _monthlyExpenses;
  double get _recommendedMonthlyContribution => _discretionaryIncome * 0.2; // 20% of discretionary income
  int get _monthsToTarget => _targetDate.difference(DateTime.now()).inDays ~/ 30;
  double get _requiredMonthlyContribution => _monthsToTarget > 0 ? _targetAmount / _monthsToTarget : _targetAmount;

  bool get _isGoalAchievable => _requiredMonthlyContribution <= _recommendedMonthlyContribution;
  bool get _isTimeFrameRealistic => _monthsToTarget >= 3; // At least 3 months

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Goal Wizard',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set your SMART goals',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Follow the steps below to refine your goals.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
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
                    backgroundColor: Colors.white.withValues(red: 255, green: 255, blue: 255, alpha: 0.3),
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
                  _buildSpecificPage(),
                  _buildFinancialProfilePage(),
                  _buildMeasurablePage(),
                  _buildAchievableRealisticPage(),
                  _buildTimeBoundPage(),
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
                          ? (_isCreating ? null : _createGoal)
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
                          : Text(_currentPage == _totalPages - 1 ? 'Create SMART Goal' : 'Next'),
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

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.flag,
            size: 80,
            color: Color(0xFF007A39),
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome to the Goal Wizard! 🎯',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A39),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Let\'s create a SMART goal that will guide you to financial success. SMART goals are:',
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
                _buildSmartItem('🎯', 'Specific', 'Clear and well-defined objectives'),
                _buildSmartItem('📊', 'Measurable', 'Track progress with numbers'),
                _buildSmartItem('✅', 'Achievable', 'Realistic within your means'),
                _buildSmartItem('🎨', 'Relevant', 'Aligned with your values'),
                _buildSmartItem('⏰', 'Time-bound', 'Has a clear deadline'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Column(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue, size: 32),
                SizedBox(height: 8),
                Text(
                  'Why SMART Goals Work',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Research shows that people who set SMART goals are 10x more likely to achieve them compared to vague goals like "save more money".',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.center_focus_strong,
            size: 80,
            color: Color(0xFF007A39),
          ),
          const SizedBox(height: 20),
          const Text(
            'Specific Goal 🎯',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A39),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Let\'s make your goal crystal clear. The more specific you are, the more likely you are to achieve it.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 32),
          
          // Goal Type Selection
          const Text(
            'What type of goal do you want to achieve?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ...GoalType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _goalType = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _goalType == type 
                        ? const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _goalType == type 
                          ? const Color(0xFF007A39)
                          : Colors.grey.shade300,
                      width: _goalType == type ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getGoalTypeIcon(type),
                        color: _goalType == type 
                            ? const Color(0xFF007A39)
                            : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGoalTypeName(type),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _goalType == type 
                                    ? const Color(0xFF007A39)
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              _getGoalTypeDescription(type),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_goalType == type)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF007A39),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Goal Title
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Goal Title',
              hintText: 'e.g., "Emergency Fund for 6 months"',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title, color: Color(0xFF007A39)),
            ),
            onChanged: (value) {
              setState(() {
                _goalTitle = value.trim();
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Goal Description
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Detailed Description',
              hintText: 'Why is this goal important to you?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description, color: Color(0xFF007A39)),
            ),
            maxLines: 3,
            onChanged: (value) {
              setState(() {
                _goalDescription = value.trim();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.account_balance,
            size: 80,
            color: Color(0xFF007A39),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Financial Profile 💰',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A39),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'To create an achievable goal, we need to understand your current financial situation.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 32),
          
          // Monthly Income
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Monthly Income (Ksh)',
              hintText: 'Your total monthly income',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money, color: Color(0xFF007A39)),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: (value) {
              setState(() {
                _monthlyIncome = double.tryParse(value) ?? 0.0;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Monthly Expenses
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Monthly Expenses (Ksh)',
              hintText: 'Your total monthly expenses',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.shopping_cart, color: Color(0xFF007A39)),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: (value) {
              setState(() {
                _monthlyExpenses = double.tryParse(value) ?? 0.0;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          if (_monthlyIncome > 0 && _monthlyExpenses > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _discretionaryIncome > 0 
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _discretionaryIncome > 0 
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _discretionaryIncome > 0 
                        ? Icons.trending_up
                        : Icons.warning,
                    color: _discretionaryIncome > 0 
                        ? Colors.green
                        : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discretionary Income',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _discretionaryIncome > 0 
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ksh ${_discretionaryIncome.toStringAsFixed(2)} per month',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _discretionaryIncome > 0 
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _discretionaryIncome > 0
                        ? 'Great! You have money available for goals.'
                        : 'You may need to reduce expenses or increase income first.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            if (_discretionaryIncome > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lightbulb, color: Color(0xFF007A39), size: 24),
                    const SizedBox(height: 8),
                    const Text(
                      'Recommended Goal Contribution',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A39),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ksh ${_recommendedMonthlyContribution.toStringAsFixed(2)} per month',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A39),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '(20% of your discretionary income)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurablePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.straighten,
            size: 80,
            color: Color(0xFF007A39),
          ),
          const SizedBox(height: 20),
          const Text(
            'Measurable Goal 📊',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A39),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Now let\'s put a number on your goal. How much money do you need to achieve it?',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 32),
          
          // Target Amount
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Target Amount (Ksh)',
              hintText: 'How much do you need?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.savings, color: Color(0xFF007A39)),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: (value) {
              setState(() {
                _targetAmount = double.tryParse(value) ?? 0.0;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          if (_targetAmount > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.calculate, color: Color(0xFF007A39), size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'Progress Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007A39),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProgressItem('Target Amount', 'Ksh ${_targetAmount.toStringAsFixed(2)}'),
                  if (_recommendedMonthlyContribution > 0) ...[
                    _buildProgressItem('Monthly Contribution', 'Ksh ${_recommendedMonthlyContribution.toStringAsFixed(2)}'),
                    _buildProgressItem('Weekly Target', 'Ksh ${(_recommendedMonthlyContribution / 4).toStringAsFixed(2)}'),
                    _buildProgressItem('Daily Target', 'Ksh ${(_recommendedMonthlyContribution / 30).toStringAsFixed(2)}'),
                  ],
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Goal type specific tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(_getGoalTypeIcon(_goalType), color: Colors.blue, size: 32),
                const SizedBox(height: 8),
                Text(
                  '${_getGoalTypeName(_goalType)} Tips',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getGoalTypeTips(_goalType),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievableRealisticPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Color(0xFF007A39),
          ),
          const SizedBox(height: 20),
          const Text(
            'Achievable & Realistic ✅',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A39),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Let\'s check if your goal is achievable within your current financial capacity.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 32),
          
          if (_targetAmount > 0 && _discretionaryIncome > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isGoalAchievable
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isGoalAchievable
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isGoalAchievable
                        ? Icons.thumb_up
                        : Icons.warning,
                    color: _isGoalAchievable
                        ? Colors.green
                        : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isGoalAchievable
                        ? 'Goal is Achievable! 🎉'
                        : 'Goal Needs Adjustment ⚠️',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isGoalAchievable
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAchievabilityItem('Your discretionary income', 'Ksh ${_discretionaryIncome.toStringAsFixed(2)}/month'),
                  _buildAchievabilityItem('Recommended contribution (20%)', 'Ksh ${_recommendedMonthlyContribution.toStringAsFixed(2)}/month'),
                  _buildAchievabilityItem('Required for this goal', 'Ksh ${_requiredMonthlyContribution.toStringAsFixed(2)}/month'),
                  
                  if (!_isGoalAchievable) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Consider:\n• Extending your timeline\n• Reducing the target amount\n• Increasing your income\n• Reducing your expenses',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Action Plan
          const Text(
            'Action Plan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'How will you achieve this goal? What specific actions will you take?',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Your Action Plan',
              hintText: 'e.g., "Set up automatic savings transfer every payday, reduce dining out by 50%, sell unused items"',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.list_alt, color: Color(0xFF007A39)),
            ),
            maxLines: 4,
            onChanged: (value) {
              setState(() {
                _actionPlan = value.trim();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBoundPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.schedule,
            size: 80,
            color: Color(0xFF007A39),
          ),
          const SizedBox(height: 20),
          const Text(
            'Time-Bound Goal ⏰',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A39),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'When do you want to achieve this goal? A deadline creates urgency and helps you stay focused.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 32),
          
          // Target Date Picker
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _targetDate,
                firstDate: DateTime.now().add(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
              );
              if (date != null) {
                setState(() {
                  _targetDate = date;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF007A39)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target Date',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_targetAmount > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isTimeFrameRealistic
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isTimeFrameRealistic
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isTimeFrameRealistic
                        ? Icons.check_circle
                        : Icons.warning,
                    color: _isTimeFrameRealistic
                        ? Colors.green
                        : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isTimeFrameRealistic
                        ? 'Timeline is Realistic! ✅'
                        : 'Timeline Too Aggressive ⚠️',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isTimeFrameRealistic
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTimelineItem('Months to target', '$_monthsToTarget months'),
                  _buildTimelineItem('Required monthly savings', 'Ksh ${_requiredMonthlyContribution.toStringAsFixed(2)}'),
                  if (_discretionaryIncome > 0)
                    _buildTimelineItem('% of discretionary income', '${(_requiredMonthlyContribution / _discretionaryIncome * 100).toStringAsFixed(1)}%'),
                  
                  if (!_isTimeFrameRealistic) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Consider extending your timeline by at least 3 months for better success.',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Goal Summary
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
                  'Your SMART Goal Summary 🎯',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A39),
                  ),
                ),
                const SizedBox(height: 12),
                if (_goalTitle.isNotEmpty)
                  _buildSummaryItem('Goal', _goalTitle),
                _buildSummaryItem('Type', _getGoalTypeName(_goalType)),
                if (_targetAmount > 0)
                  _buildSummaryItem('Target Amount', 'Ksh ${_targetAmount.toStringAsFixed(2)}'),
                _buildSummaryItem('Target Date', '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}'),
                if (_monthsToTarget > 0)
                  _buildSummaryItem('Time Frame', '$_monthsToTarget months'),
                if (_requiredMonthlyContribution > 0)
                  _buildSummaryItem('Monthly Contribution', 'Ksh ${_requiredMonthlyContribution.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A39),
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAchievabilityItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGoalTypeIcon(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return Icons.savings;
      case GoalType.debtReduction:
        return Icons.money_off;
      case GoalType.investment:
        return Icons.trending_up;
      case GoalType.emergencyFund:
        return Icons.security;
      case GoalType.insurance:
        return Icons.health_and_safety;
      case GoalType.other:
        return Icons.flag;
    }
  }

  String _getGoalTypeName(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return 'Savings Goal';
      case GoalType.debtReduction:
        return 'Debt Reduction';
      case GoalType.investment:
        return 'Investment Goal';
      case GoalType.emergencyFund:
        return 'Emergency Fund';
      case GoalType.insurance:
        return 'Insurance Goal';
      case GoalType.other:
        return 'Other Goal';
    }
  }

  String _getGoalTypeDescription(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return 'Build up savings for a specific purpose';
      case GoalType.debtReduction:
        return 'Pay off loans or credit card debt';
      case GoalType.investment:
        return 'Invest money for long-term growth';
      case GoalType.emergencyFund:
        return 'Build an emergency fund for unexpected expenses';
      case GoalType.insurance:
        return 'Save for insurance premiums or build a coverage reserve';
      case GoalType.other:
        return 'Any other financial goal';
    }
  }

  String _getGoalTypeTips(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return 'Consider 3-6 months of expenses for emergency savings, or specific amounts for purchases.';
      case GoalType.debtReduction:
        return 'Focus on high-interest debt first. Calculate total debt including interest.';
      case GoalType.investment:
        return 'Consider your risk tolerance and investment timeline for this amount.';
      case GoalType.emergencyFund:
        return 'Aim for 3-6 months of living expenses. Start with Ksh 50,000 if you\'re just beginning.';
      case GoalType.insurance:
        return 'Plan for annual premiums or future coverage needs; spread cost monthly.';
      case GoalType.other:
        return 'Make sure your goal amount is specific and well-researched.';
    }
  }
}
