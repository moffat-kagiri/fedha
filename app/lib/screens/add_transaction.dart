// lib/screens/add_transaction.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../services/offline_data_service.dart';
import '../services/goal_transaction_service.dart';
import '../services/auth_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  TransactionCategory _selectedCategory = TransactionCategory.other;
  DateTime _selectedDate = DateTime.now();
  Goal? _selectedGoal;
  List<Goal> _availableGoals = [];
  List<Goal> _suggestedGoals = [];
  late GoalTransactionService _goalService;

  @override
  void initState() {
    super.initState();
    _goalService = GoalTransactionService(
      Provider.of<OfflineDataService>(context, listen: false),
    );
    _loadGoals();

    // Listen for description changes to suggest goals
    _descriptionController.addListener(_onDescriptionChanged);
  }

  void _onDescriptionChanged() {
    if (_selectedType == TransactionType.savings &&
        _descriptionController.text.isNotEmpty) {
      _updateSuggestedGoals();
    }
  }

  Future<void> _loadGoals() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileId = authService.currentProfile?.id;

    if (profileId != null) {
      final dataService = Provider.of<OfflineDataService>(
        context,
        listen: false,
      );
      final goals = await dataService.getActiveGoals(profileId);
      setState(() {
        _availableGoals = goals;
      });
    }
  }

  Future<void> _updateSuggestedGoals() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileId = authService.currentProfile?.id;

    if (profileId != null) {
      final suggested = await _goalService.getSuggestedGoals(
        profileId,
        _descriptionController.text,
      );
      setState(() {
        _suggestedGoals = suggested;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Type selector
              DropdownButtonFormField<TransactionType>(
                value: _selectedType,
                items:
                    TransactionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _selectedGoal = null; // Reset goal when type changes
                  });
                  if (value == TransactionType.savings) {
                    _loadGoals();
                  }
                },
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),

              // Category selector
              DropdownButtonFormField<TransactionCategory>(
                value: _selectedCategory,
                items:
                    TransactionCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.toString().split('.').last),
                      );
                    }).toList(),
                onChanged:
                    (value) => setState(() => _selectedCategory = value!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),

              // Amount input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'KSh ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description input
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What is this transaction for?',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Notes input
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional details...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Goal selection for savings transactions
              if (_selectedType == TransactionType.savings) ...[
                // Show suggested goals if available
                if (_suggestedGoals.isNotEmpty) ...[
                  const Text(
                    'Suggested Goals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        _suggestedGoals.map((goal) {
                          return ActionChip(
                            label: Text(goal.name),
                            onPressed: () {
                              setState(() {
                                _selectedGoal = goal;
                              });
                            },
                            backgroundColor:
                                _selectedGoal?.id == goal.id
                                    ? Colors.blue.shade100
                                    : null,
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Goal selector dropdown
                DropdownButtonFormField<Goal>(
                  value: _selectedGoal,
                  items:
                      _availableGoals.map((goal) {
                        final progress =
                            goal.currentAmount / goal.targetAmount * 100;
                        return DropdownMenuItem(
                          value: goal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(goal.name),
                              Text(
                                '${progress.toStringAsFixed(1)}% complete • \$${goal.currentAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (value) => setState(() => _selectedGoal = value),
                  decoration: const InputDecoration(
                    labelText: 'Assign to Goal (Optional)',
                    hintText: 'Select a goal to contribute to',
                  ),
                ),
                const SizedBox(height: 8),

                if (_selectedGoal != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contributing to: ${_selectedGoal!.name}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (_selectedGoal!.currentAmount /
                                  _selectedGoal!.targetAmount)
                              .clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current: \$${_selectedGoal!.currentAmount.toStringAsFixed(0)} / Target: \$${_selectedGoal!.targetAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // Date picker
              ListTile(
                title: const Text('Date'),
                subtitle: Text(_selectedDate.toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),

              // Save button
              ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = authService.currentProfile?.id;

      if (profileId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to add transactions')),
          );
        }
        return;
      }

      try {
        String? successMessage;

        if (_selectedType == TransactionType.savings) {
          // Use the goal transaction service for savings
          final transaction = await _goalService.createSavingsTransaction(
            profileId: profileId,
            amount: double.parse(_amountController.text),
            category: _selectedCategory,
            date: _selectedDate,
            description:
                _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            goalId: _selectedGoal?.id,
          );

          successMessage =
              _selectedGoal != null
                  ? 'Transaction saved and added to ${_selectedGoal!.name}'
                  : 'Transaction saved successfully';

          if (mounted) {
            Navigator.pop(context, transaction);
          }
        } else {
          // Regular transaction creation
          final transaction = Transaction(
            amount: double.parse(_amountController.text),
            type: _selectedType,
            category: _selectedCategory,
            date: _selectedDate,
            description:
                _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            profileId: profileId,
          );

          final dataService = Provider.of<OfflineDataService>(
            context,
            listen: false,
          );
          await dataService.saveTransaction(transaction);

          successMessage = 'Transaction saved successfully';

          if (mounted) {
            Navigator.pop(context, transaction);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving transaction: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
