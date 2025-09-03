// lib/screens/add_transaction.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/enums.dart';
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
      // getActiveGoals returns List<Goal>, not Future<List<Goal>>
      final goals = dataService.getActiveGoals(profileId);
      setState(() {
        _availableGoals = goals;
      });
    }
  }

  Future<void> _updateSuggestedGoals() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileId = authService.currentProfile?.id;

    if (profileId != null) {
      // Create a temporary transaction object to find suggested goals
      final tempTransaction = Transaction(
        amount: double.tryParse(_amountController.text) ?? 0.0,
        type: _selectedType,
        categoryId: _selectedCategory.toString().split('.').last,
        profileId: profileId,
        description: _descriptionController.text,
        date: _selectedDate,
      );
      
      // getSuggestedGoals returns a List<Goal>, not a Future<List<Goal>>
      final suggested = _goalService.getSuggestedGoals(tempTransaction);
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Store services before any async operations
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileId = authService.currentProfile?.id;
    final dataService = Provider.of<OfflineDataService>(context, listen: false);

    if (profileId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add transactions')),
        );
      }
      return;
    }

    try {
      // Create the transaction object first
      Transaction transaction;

      if (_selectedType == TransactionType.savings && _selectedGoal?.id != null) {
        // Use the goal transaction service for savings
        transaction = await _goalService.createSavingsTransaction(
          amount: double.parse(_amountController.text),
          goalId: _selectedGoal!.id,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          categoryId: _selectedCategory.toString().split('.').last,
        );
      } else {
        // Regular transaction creation
        transaction = Transaction(
          amount: double.parse(_amountController.text),
          type: _selectedType,
          categoryId: _selectedCategory.toString().split('.').last,
          category: _selectedCategory,
          date: _selectedDate,
          description:
              _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          profileId: profileId,
        );

        await dataService.saveTransaction(transaction);
      }

      // Now handle the UI updates if still mounted
      if (mounted) {
        // Create the success message
        final successMessage = _selectedType == TransactionType.savings && _selectedGoal != null
            ? 'Transaction saved and added to ${_selectedGoal!.name}'
            : 'Transaction saved successfully';
            
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
        
        // Return to previous screen with the transaction
        Navigator.pop(context, transaction);
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

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
