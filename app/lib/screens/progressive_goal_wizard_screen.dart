import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
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
  final int _totalPages = 4; // Reduced from 6 to 4

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
    if (!_validateCurrentPage()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final goal = Goal(
        profileId: authService.currentProfile?.id ?? '0',
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _goalTitle,
        description: _goalDescription,
        targetAmount: _targetAmount,
        currentAmount: 0.0,
        targetDate: _targetDate,
        goalType: _goalType,
        status: GoalStatus.active,
      );

      await dataService.addGoal(goal);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎯 SMART Goal created successfully!'),
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

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 1: // Goal Definition
        return _goalTitle.isNotEmpty && _goalDescription.isNotEmpty;
      case 2: // Financial & Measurable
        return _monthlyIncome > 0 && _targetAmount > 0;
      case 3: // Timeline & Action
        return _actionPlan.isNotEmpty;
      default:
        return true;
    }
  }

  double get _discretionaryIncome => _monthlyIncome - _monthlyExpenses;
  double get _recommendedMonthlyContribution => _discretionaryIncome * 0.2;
  int get _monthsToTarget => _targetDate.difference(DateTime.now()).inDays ~/ 30;
  double get _requiredMonthlyContribution => _monthsToTarget > 0 ? _targetAmount / _monthsToTarget : _targetAmount;
  bool get _isGoalAchievable => _requiredMonthlyContribution <= _recommendedMonthlyContribution;
  bool get _isTimeFrameRealistic => _monthsToTarget >= 3;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Wizard'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentPage + 1} of $_totalPages',
                      style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8)),
                    ),
                    Text(
                      '${((_currentPage + 1) / _totalPages * 100).round()}% Complete',
                      style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_currentPage + 1) / _totalPages,
                  backgroundColor: colorScheme.onPrimary.withOpacity(0.3),
                  color: colorScheme.onPrimary,
                ),
              ],
            ),
          ),
          
          // Page Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              physics: _isCreating ? const NeverScrollableScrollPhysics() : null,
              children: [
                _buildWelcomePage(),
                _buildGoalDefinitionPage(),
                _buildFinancialMeasurablePage(),
                _buildTimelineActionPage(),
              ],
            ),
          ),
          
          // Navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _currentPage == _totalPages - 1 
                        ? (_isCreating ? null : _createGoal)
                        : (_validateCurrentPage() ? _nextPage : null),
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentPage == _totalPages - 1 ? 'Create Goal' : 'Next'),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.flag_rounded, size: 80, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Create a SMART Goal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Follow this guided process to set clear, achievable financial goals using the SMART framework.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 40, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'SMART Goals Are:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSmartChip('🎯 Specific', 'Clear and well-defined'),
                  _buildSmartChip('📊 Measurable', 'Track progress with numbers'),
                  _buildSmartChip('✅ Achievable', 'Realistic within your means'),
                  _buildSmartChip('⏰ Time-bound', 'Has a clear deadline'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalDefinitionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Define Your Goal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What do you want to achieve? Be specific and clear.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Goal Type
          Text('Goal Type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GoalType.values.map((type) {
              final isSelected = _goalType == type;
              return FilterChip(
                label: Text(_getGoalTypeName(type)),
                selected: isSelected,
                onSelected: (selected) => setState(() => _goalType = type),
                avatar: Icon(_getGoalTypeIcon(type), size: 18),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Goal Title
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Goal Title',
              hintText: 'e.g., Emergency Fund for 6 months',
            ),
            onChanged: (value) => setState(() => _goalTitle = value),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Why is this goal important to you?',
            ),
            maxLines: 3,
            onChanged: (value) => setState(() => _goalDescription = value),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMeasurablePage() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s understand your financial capacity and set measurable targets.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Income & Expenses
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Monthly Income',
                    prefixText: 'Ksh ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  onChanged: (value) => setState(() => _monthlyIncome = double.tryParse(value) ?? 0.0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Monthly Expenses',
                    prefixText: 'Ksh ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  onChanged: (value) => setState(() => _monthlyExpenses = double.tryParse(value) ?? 0.0),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Target Amount
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Target Amount',
              hintText: 'How much do you need?',
              prefixText: 'Ksh ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            onChanged: (value) => setState(() => _targetAmount = double.tryParse(value) ?? 0.0),
          ),
          
          // Financial Insights
          if (_monthlyIncome > 0 && _targetAmount > 0) ...[
            const SizedBox(height: 24),
            Card(
              color: _discretionaryIncome > 0 
                  ? colorScheme.primaryContainer
                  : colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _discretionaryIncome > 0 ? Icons.trending_up : Icons.warning,
                      color: _discretionaryIncome > 0 ? colorScheme.primary : colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _discretionaryIncome > 0 ? 'Healthy Budget' : 'Review Needed',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ksh ${_discretionaryIncome.toStringAsFixed(0)} discretionary income per month',
                      textAlign: TextAlign.center,
                    ),
                    if (_discretionaryIncome > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Recommended: Ksh ${_recommendedMonthlyContribution.toStringAsFixed(0)}/month for goals',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineActionPage() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline & Action Plan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your deadline and create an action plan.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Target Date
          Text('Target Date', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _targetDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (date != null) setState(() => _targetDate = date);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_rounded),
                const SizedBox(width: 8),
                Text('${_targetDate.day}/${_targetDate.month}/${_targetDate.year}'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Plan
          Text('Action Plan', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'What specific steps will you take to achieve this goal?',
            ),
            maxLines: 4,
            onChanged: (value) => setState(() => _actionPlan = value),
          ),
          
          // Goal Summary & Feasibility
          if (_targetAmount > 0) ...[
            const SizedBox(height: 24),
            Card(
              color: _isGoalAchievable && _isTimeFrameRealistic
                  ? colorScheme.primaryContainer
                  : colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isGoalAchievable && _isTimeFrameRealistic 
                          ? Icons.check_circle_rounded 
                          : Icons.warning_rounded,
                      color: _isGoalAchievable && _isTimeFrameRealistic
                          ? colorScheme.primary
                          : colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isGoalAchievable && _isTimeFrameRealistic
                          ? 'Goal Looks Achievable!'
                          : 'Adjustments Recommended',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Monthly Required', 'Ksh ${_requiredMonthlyContribution.toStringAsFixed(0)}'),
                    _buildSummaryRow('Timeframe', '$_monthsToTarget months'),
                    if (!_isGoalAchievable || !_isTimeFrameRealistic) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Consider extending timeline or reducing target amount',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmartChip(String title, String subtitle) {
    return ListTile(
      leading: const CircleAvatar(backgroundColor: Colors.transparent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }

  // Helper methods for goal types
  IconData _getGoalTypeIcon(GoalType type) {
    switch (type) {
      case GoalType.savings: return Icons.savings_rounded;
      case GoalType.debtReduction: return Icons.credit_card_off_rounded;
      case GoalType.investment: return Icons.trending_up_rounded;
      case GoalType.emergencyFund: return Icons.shield_rounded;
      case GoalType.insurance: return Icons.health_and_safety_rounded;
      case GoalType.other: return Icons.flag_rounded;
    }
  }

  String _getGoalTypeName(GoalType type) {
    switch (type) {
      case GoalType.savings: return 'Savings';
      case GoalType.debtReduction: return 'Debt';
      case GoalType.investment: return 'Investment';
      case GoalType.emergencyFund: return 'Emergency';
      case GoalType.insurance: return 'Insurance';
      case GoalType.other: return 'Other';
    }
  }
}