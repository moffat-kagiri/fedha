import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import '../services/currency_service.dart';

class TransactionEntryScreen extends StatefulWidget {
  final Transaction? editingTransaction;
  
  const TransactionEntryScreen({
    super.key,
    this.editingTransaction,
  });

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final ThemeData theme;

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = '';
  Goal? _selectedGoal;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();
  
  final Map<TransactionType, List<String>> _categories = {
    TransactionType.income: [
      'Salary', 'Business Income', 'Freelance', 'Investment Returns', 
      'Rental Income', 'Bonus', 'Commission', 'Tips', 'Gift', 'Other'
    ],
    TransactionType.expense: [
      'Food & Dining', 'Transportation', 'Shopping', 'Entertainment',
      'Bills & Utilities', 'Healthcare', 'Education', 'Rent/Mortgage',
      'Insurance', 'Personal Care', 'Travel', 'Other'
    ],
    TransactionType.savings: [], // Will be populated with goals
  };

  @override
  void initState() {
    final theme = Theme.of(context);
    super.initState();
    if (widget.editingTransaction != null) {
      _loadTransactionData(widget.editingTransaction!);
    } else {
      _selectedCategory = _categories[_selectedType]!.first;
    }
  }

  void _loadTransactionData(Transaction transaction) {
    _amountController.text = transaction.amount.toString();
    _descriptionController.text = transaction.description ?? '';
    _selectedType = transaction.type;
    _selectedCategory = transaction.categoryId ?? _categories[transaction.type]!.first;
    _selectedDate = transaction.date;
    
    if (transaction.type == TransactionType.savings && transaction.goalId != null) {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      _selectedGoal = dataService.getGoal(transaction.goalId!);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      
      final transaction = Transaction(
        id: widget.editingTransaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        categoryId: _selectedType == TransactionType.savings ? (_selectedGoal?.name ?? '') : (_selectedCategory ?? ''),
        category: null,
        date: _selectedDate,
        goalId: _selectedType == TransactionType.savings ? _selectedGoal?.id : null,
        profileId: 'current_profile',
      );

      await dataService.saveTransaction(transaction);
      
      if (mounted) {
        Navigator.pop(context, transaction);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingTransaction != null 
                ? 'Transaction updated successfully' 
                : 'Transaction saved successfully'),
            backgroundColor: const Color(0xFF007A39),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingTransaction != null ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: const Color(0xFF007A39),
        foregroundColor: Colors.white,
        actions: [
          if (widget.editingTransaction != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: Consumer2<OfflineDataService, CurrencyService>(
        builder: (context, dataService, currencyService, child) {
          final goals = dataService.getActiveGoals();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Transaction Type Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transaction Type',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTypeButton(
                                  'Income',
                                  TransactionType.income,
                                  Colors.green,
                                  Icons.arrow_upward,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTypeButton(
                                  'Expense',
                                  TransactionType.expense,
                                  Colors.orange,
                                  Icons.arrow_downward,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTypeButton(
                                  'Savings',
                                  TransactionType.savings,
                                  Colors.blue,
                                  Icons.savings,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Amount Input
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Amount',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Enter amount',
                              prefixText: '${currencyService.currentSymbol} ',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an amount';
                              }
                              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                return 'Please enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Category/Goal Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedType == TransactionType.savings ? 'Goal' : 'Category',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (_selectedType == TransactionType.savings)
                            _buildGoalSelector(goals)
                          else
                            _buildCategorySelector(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Date Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade50,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Color(0xFF007A39)),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Description
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description (Optional)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: 'Add a note about this transaction',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Save Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A39),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
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
                              Text('Saving...'),
                            ],
                          )
                        : Text(
                            widget.editingTransaction != null ? 'Update Transaction' : 'Save Transaction',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeButton(String label, TransactionType type, Color color, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          if (type != TransactionType.savings) {
            _selectedCategory = _categories[type]!.first;
          }
          _selectedGoal = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: _categories[_selectedType]!.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildGoalSelector(List<Goal> goals) {
    if (goals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.orange.shade50,
        ),
        child: Column(
          children: [
            Icon(Icons.flag, color: Colors.orange.shade600, size: 32),
            const SizedBox(height: 8),
            const Text(
              'No active goals',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create a goal first to save towards it',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/progressive_goal_wizard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Goal'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<Goal>(
      value: _selectedGoal,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      hint: const Text('Select a goal'),
      items: goals.map((goal) {
        final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount * 100) : 0.0;
        return DropdownMenuItem(
          value: goal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${progress.toStringAsFixed(1)}% complete',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGoal = value;
        });
      },
      validator: (value) => value == null ? 'Please select a goal' : null,
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _deleteTransaction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final dataService = Provider.of<OfflineDataService>(context, listen: false);
              dataService.deleteTransaction(widget.editingTransaction!.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, 'deleted'); // Close screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
