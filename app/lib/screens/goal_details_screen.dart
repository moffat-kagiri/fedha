import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../services/goal_transaction_service.dart';
import '../theme/app_theme.dart';
import '../services/offline_data_service.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/enums.dart';

class GoalDetailsScreen extends StatefulWidget {
  final Goal goal;
  
  const GoalDetailsScreen({Key? key, required this.goal}) : super(key: key);

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.goal.name,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
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
                        widget.goal.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.goal.description ?? 'No description provided',
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
                              value: widget.goal.targetAmount > 0 
                                  ? (widget.goal.currentAmount / widget.goal.targetAmount).clamp(0.0, 1.0)
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
                                      'KSh ${widget.goal.currentAmount.toStringAsFixed(2)}',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
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
                                      'KSh ${widget.goal.targetAmount.toStringAsFixed(2)}',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              // In the amounts row, you could add:
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
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
                                        'KSh ${widget.goal.currentAmount.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                        'KSh ${(widget.goal.targetAmount - widget.goal.currentAmount).toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                        'KSh ${widget.goal.targetAmount.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Progress Percentage
                            if (widget.goal.targetAmount > 0) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  '${((widget.goal.currentAmount / widget.goal.targetAmount) * 100).toStringAsFixed(1)}% Complete',
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
                      
                      // Goal Type
                      _buildDetailRow(
                        context,
                        icon: Icons.category_outlined,
                        label: 'Type',
                        value: _getGoalTypeText(widget.goal.type),
                      ),
                      const SizedBox(height: 12),
                      
                      // Priority
                      _buildDetailRow(
                        context,
                        icon: Icons.flag_outlined,
                        label: 'Priority',
                        value: _getPriorityText(widget.goal.priority),
                      ),
                      const SizedBox(height: 12),
                      
                      // Deadline (if available)
                      if (widget.goal.deadline != null)
                        _buildDetailRow(
                          context,
                          icon: Icons.calendar_today_outlined,
                          label: 'Deadline',
                          value: _formatDate(widget.goal.deadline!),
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
                      onPressed: () {
                        // TODO: Implement edit goal
                        
                      },
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
  final formKey = GlobalKey<FormState>(); // Add form key
  
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add Contribution'),
      content: Form( // Wrap in Form
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
            if (!formKey.currentState!.validate()) return; // Add validation check
            
            final amount = double.tryParse(amountController.text);
            if (amount == null || amount <= 0) return;
            
            try {
                // Get the service instance
                final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
                final transactionService = GoalTransactionService(offlineDataService);
                
                await transactionService.createSavingsTransaction(
                  amount: amount,
                  goalId: widget.goal.id,
                  description: descriptionController.text.isNotEmpty 
                      ? descriptionController.text 
                      : 'Manual contribution to ${widget.goal.name}',
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully added KSh ${amount.toStringAsFixed(2)} to ${widget.goal.name}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Refresh the screen to show updated progress
                  setState(() {});
                }
              } catch (e) {
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
      case GoalType.debt:
        return 'Debt Repayment';
      case GoalType.emergency:
        return 'Emergency Fund';
      case GoalType.other:
        return 'Other';
      default:
        return 'Unknown';
    }
  }
  
  String _getPriorityText(GoalPriority priority) {
    switch (priority) {
      case GoalPriority.low:
        return 'Low';
      case GoalPriority.medium:
        return 'Medium';
      case GoalPriority.high:
        return 'High';
      case GoalPriority.critical:
        return 'Critical';
      default:
        return 'Not Set';
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}