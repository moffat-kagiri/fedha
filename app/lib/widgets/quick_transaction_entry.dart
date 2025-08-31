import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import '../data/app_database.dart';
import '../services/offline_data_service.dart';

class QuickTransactionEntry extends StatefulWidget {
  final Transaction? editingTransaction;
  final Transaction? existingTransaction;
  final Function(Transaction)? onTransactionSaved;
  
  const QuickTransactionEntry({
    super.key, 
    this.editingTransaction,
    this.existingTransaction,
    this.onTransactionSaved,
  });

  @override
  State<QuickTransactionEntry> createState() => _QuickTransactionEntryState();
}

class _QuickTransactionEntryState extends State<QuickTransactionEntry> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isExpense = true;
  String _selectedCategory = 'Other';
  Goal? _selectedGoal;
  bool _isSaving = false;
  
  final List<String> _expenseCategories = [
    'Food & Dining', 'Transportation', 'Shopping', 'Entertainment',
    'Bills & Utilities', 'Healthcare', 'Education', 'Other'
  ];
  
  final List<String> _incomeCategories = [
    'Salary', 'Business', 'Freelance', 'Investment', 'Gift', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    final existingTransaction = widget.editingTransaction ?? widget.existingTransaction;
    if (existingTransaction != null) {
      _loadTransactionData(existingTransaction);
    }
  }

  void _loadTransactionData(Transaction transaction) {
    _amountController.text = transaction.amountMinor.toString();
    _descriptionController.text = transaction.description;
    _isExpense = transaction.isExpense;
    _selectedCategory = transaction.categoryId;
    
    if (!transaction.isExpense) {
      // Load the goal if it's a savings transaction
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      int? goalId = int.tryParse(transaction.categoryId);
      if (goalId != null) {
        dataService.getGoal(goalId).then((goal) {
          if (mounted && goal != null) {
            setState(() => _selectedGoal = goal);
          }
        });
      }
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
      
      final existingTransaction = widget.editingTransaction ?? widget.existingTransaction;
      final transaction = Transaction(
        amountMinor: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        categoryId: _selectedGoal?.id.toString() ?? _selectedCategory,
        date: existingTransaction?.date ?? DateTime.now(),
        isExpense: _isExpense,
        profileId: 1, // TODO: Get actual profile ID
        currency: 'KES',
        rawSms: null,
        id: existingTransaction?.id ?? 0
      );

      final transactionCompanion = TransactionsCompanion(
        id: existingTransaction != null ? Value(existingTransaction.id) : const Value.absent(),
        amountMinor: Value(transaction.amountMinor),
        description: Value(transaction.description),
        categoryId: Value(transaction.categoryId),
        date: Value(transaction.date),
        isExpense: Value(transaction.isExpense),
        profileId: Value(transaction.profileId),
        currency: Value(transaction.currency),
        rawSms: Value(transaction.rawSms),
      );

      if (existingTransaction != null) {
        dataService.saveTransaction(transactionCompanion);
      } else {
        dataService.saveTransaction(transactionCompanion);
      }

      // Update goal progress if it's linked to a goal
      if (!_isExpense && _selectedGoal != null) {
        final updatedGoalCompanion = GoalsCompanion(
          id: Value(_selectedGoal!.id),
          title: Value(_selectedGoal!.title),
          targetMinor: Value(_selectedGoal!.targetMinor + double.parse(_amountController.text)),
          dueDate: Value(_selectedGoal!.dueDate),
          currency: Value(_selectedGoal!.currency),
          completed: Value(_selectedGoal!.completed),
          profileId: Value(_selectedGoal!.profileId),
        );
        dataService.saveGoal(updatedGoalCompanion);
      }

      if (mounted) {
        // Call the callback if provided
        widget.onTransactionSaved?.call(transaction);
        
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingTransaction != null 
                ? 'Transaction updated successfully!' 
                : 'Transaction added successfully!'),
            backgroundColor: const Color(0xFF007A39),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  List<String> get _currentCategories {
    return _isExpense ? _expenseCategories : _incomeCategories;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  widget.editingTransaction != null ? Icons.edit : Icons.add,
                  color: const Color(0xFF007A39),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.editingTransaction != null ? 'Edit Transaction' : 'Quick Transaction',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A39),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Transaction Type Selector
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _buildTypeButton(false, 'Income/Savings', Icons.arrow_upward, Colors.green),
                          _buildTypeButton(true, 'Expense', Icons.arrow_downward, Colors.red),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (Ksh)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money, color: Color(0xFF007A39)),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description, color: Color(0xFF007A39)),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category, color: Color(0xFF007A39)),
                      ),
                      items: _currentCategories.map((category) {
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
                    ),
                    
                    // Goal Selection (only for non-expenses)
                    if (!_isExpense) ...[
                      Consumer<OfflineDataService>(
                        builder: (context, dataService, child) {
                          return FutureBuilder<List<Goal>>(
                            future: dataService.getAllGoals(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator();
                              }
                              
                              final goals = snapshot.data!
                                  .where((goal) => !goal.completed)
                                  .toList();
                          
                              return DropdownButtonFormField<Goal?>(
                                initialValue: _selectedGoal,
                                decoration: const InputDecoration(
                                  labelText: 'Assign to Goal (Optional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.flag, color: Color(0xFF007A39)),
                                ),
                                items: [
                                  const DropdownMenuItem<Goal?>(
                                    value: null,
                                    child: Text('General Savings (No specific goal)'),
                                  ),
                                  ...goals.map((goal) {
                                    return DropdownMenuItem<Goal?>(
                                      value: goal,
                                      child: Text('${goal.title} (Ksh ${goal.targetMinor.toStringAsFixed(2)})'),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGoal = value;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007A39),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                              widget.editingTransaction != null ? 'Update Transaction' : 'Add Transaction',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(bool isExpenseType, String label, IconData icon, Color color) {
    final isSelected = _isExpense == isExpenseType;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpense = isExpenseType;
            if (_isExpense) {
              _selectedGoal = null;
            }
            // Reset category to first available when switching types
            _selectedCategory = _currentCategories.first;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 25) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: color, width: 2) : null,
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
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
