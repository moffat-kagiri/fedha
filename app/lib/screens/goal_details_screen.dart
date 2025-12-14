// lib/screens/goal_details_screen.dart
import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/goal_transaction_service.dart';
import '../theme/app_theme.dart';
import '../services/offline_data_service.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../models/transaction.dart';

class GoalDetailsScreen extends StatefulWidget {
  final Goal goal;
  
  const GoalDetailsScreen({Key? key, required this.goal}) : super(key: key);

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  late Goal _currentGoal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.goal;
    _refreshGoal();
  }

  // Refresh goal data from database
  Future<void> _refreshGoal() async {
    setState(() => _isLoading = true);
    
    try {
      final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = authService.currentProfile?.id ?? '';
      
      print('🔄 Refreshing goal ${_currentGoal.id} for profile $profileId');
      
      // Fetch updated goal
      final updatedGoal = await offlineDataService.getGoal(_currentGoal.id);
      
      if (updatedGoal != null) {
        print('✅ Goal refreshed - Current: ${updatedGoal.currentAmount}, Target: ${updatedGoal.targetAmount}');
        setState(() {
          _currentGoal = updatedGoal;
          _isLoading = false;
        });
      } else {
        print('⚠️ Goal not found after refresh');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error refreshing goal: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentGoal.name,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Icon(Icons.refresh, color: colorScheme.onPrimary),
            onPressed: _isLoading ? null : _refreshGoal,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal Overview Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentGoal.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentGoal.description ?? 'No description provided',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Progress Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Progress Bar
                            LinearProgressIndicator(
                              value: _currentGoal.targetAmount > 0 
                                  ? (_currentGoal.currentAmount / _currentGoal.targetAmount).clamp(0.0, 1.0)
                                  : 0.0,
                              backgroundColor: colorScheme.outline.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                FedhaColors.primaryGreen,
                              ),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 16),
                            
                            // Amounts Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Current Amount
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      'KSh ${_currentGoal.currentAmount.toStringAsFixed(2)}',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                // Remaining Amount
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Remaining',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      'KSh ${(_currentGoal.targetAmount - _currentGoal.currentAmount).toStringAsFixed(2)}',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: FedhaColors.warningOrange,
                                      ),
                                    ),
                                  ],
                                ),
                                // Target Amount
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Target',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      'KSh ${_currentGoal.targetAmount.toStringAsFixed(2)}',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // Progress Percentage
                            if (_currentGoal.targetAmount > 0) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  '${((_currentGoal.currentAmount / _currentGoal.targetAmount) * 100).toStringAsFixed(1)}% Complete',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: FedhaColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Goal Details Section
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goal Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDetailRow(
                        context,
                        icon: Icons.category_outlined,
                        label: 'Type',
                        value: _getGoalTypeText(_currentGoal.goalType),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildDetailRow(
                        context,
                        icon: Icons.flag_outlined,
                        label: 'Status',
                        value: _getStatusText(_currentGoal.status),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildDetailRow(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: 'Target Date',
                        value: _formatDate(_currentGoal.targetDate),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddContributionDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Contribution'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditGoalDialog(context),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Goal'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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

  Future<void> _showAddContributionDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contribution'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'KSh ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter amount';
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) return 'Please enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;
              
              try {
                print('💰 Adding contribution of $amount to goal ${_currentGoal.id}');
                
                final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
                final authService = Provider.of<AuthService>(context, listen: false);
                final profileId = authService.currentProfile?.id ?? '';
                
                final transactionService = GoalTransactionService(offlineDataService);
                
                // Create savings transaction linked to goal
                await transactionService.createSavingsTransaction(
                  amount: amount,
                  goalId: _currentGoal.id,
                  description: descriptionController.text.isNotEmpty 
                      ? descriptionController.text 
                      : 'Contribution to ${_currentGoal.name}',
                );
                
                print('✅ Transaction created successfully');
                
                if (mounted) {
                  Navigator.pop(context);
                  
                  // Refresh goal data
                  await _refreshGoal();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully added KSh ${amount.toStringAsFixed(2)} to ${_currentGoal.name}'),
                      backgroundColor: FedhaColors.successGreen,
                    ),
                  );
                }
              } catch (e) {
                print('❌ Error adding contribution: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add contribution: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditGoalDialog(BuildContext context) async {
    final nameController = TextEditingController(text: _currentGoal.name);
    final descriptionController = TextEditingController(text: _currentGoal.description ?? '');
    final targetAmountController = TextEditingController(text: _currentGoal.targetAmount.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();
    
    GoalType selectedType = _currentGoal.goalType;
    GoalStatus selectedStatus = _currentGoal.status;
    DateTime selectedDate = _currentGoal.targetDate;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Goal'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Name',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter goal name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: targetAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Amount',
                      prefixText: 'KSh ',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter target amount';
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) return 'Please enter valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<GoalType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Goal Type',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: GoalType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getGoalTypeText(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<GoalStatus>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.info),
                    ),
                    items: GoalStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusText(status)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Target Date'),
                    subtitle: Text(_formatDate(selectedDate)),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (pickedDate != null) {
                        setDialogState(() => selectedDate = pickedDate);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final targetAmount = double.tryParse(targetAmountController.text);
                if (targetAmount == null || targetAmount <= 0) return;
                
                try {
                  print('📝 Updating goal ${_currentGoal.id}');
                  
                  final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
                  
                  // Create updated goal
                  final updatedGoal = _currentGoal.copyWith(
                    name: nameController.text,
                    description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                    targetAmount: targetAmount,
                    goalType: selectedType,
                    status: selectedStatus,
                    targetDate: selectedDate,
                    updatedAt: DateTime.now(),
                  );
                  
                  await offlineDataService.updateGoal(updatedGoal);
                  
                  print('✅ Goal updated successfully');
                  
                  if (mounted) {
                    Navigator.pop(context);
                    
                    // Refresh goal data
                    await _refreshGoal();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Goal updated successfully'),
                        backgroundColor: FedhaColors.successGreen,
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Error updating goal: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update goal: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getGoalTypeText(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return 'Savings';
      case GoalType.investment:
        return 'Investment';
      case GoalType.emergencyFund:
        return 'Emergency Fund';
      case GoalType.debtReduction:
        return 'Debt Repayment';
      case GoalType.insurance:
        return 'Insurance';
      case GoalType.other:
        return 'Other';
    }
  }
  
  String _getStatusText(GoalStatus status) {
    switch (status) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.completed:
        return 'Completed';
      case GoalStatus.paused:
        return 'Paused';
      case GoalStatus.cancelled:
        return 'Cancelled';
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}