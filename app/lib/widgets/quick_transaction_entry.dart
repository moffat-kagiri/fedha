import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/enums.dart';
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
  
  TransactionType _selectedType = TransactionType.expense;
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
    _amountController.text = transaction.amount.toString();
    _descriptionController.text = transaction.description ?? '';
    _selectedType = transaction.type;
    _selectedCategory = transaction.category?.toString() ?? 'Other';
    
    if (transaction.type == TransactionType.savings && transaction.goalId != null) {
      // Load the goal if it's a savings transaction
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
      
      final existingTransaction = widget.editingTransaction ?? widget.existingTransaction;
      final transaction = Transaction(
        id: existingTransaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        categoryId: _selectedType == TransactionType.savings ? 'savings' : _selectedCategory,
        category: _selectedType == TransactionType.savings ? TransactionCategory.other : null,
        date: existingTransaction?.date ?? DateTime.now(),
        goalId: _selectedType == TransactionType.savings ? _selectedGoal?.id : null,
        profileId: 'current_profile', // TODO: Get actual profile ID
      );

      if (existingTransaction != null) {
        dataService.saveTransaction(transaction);
      } else {
        dataService.saveTransaction(transaction);
      }

      // Update goal progress if it's a savings transaction
      if (_selectedType == TransactionType.savings && _selectedGoal != null) {
        final updatedGoal = Goal(
          id: _selectedGoal!.id,
          name: _selectedGoal!.name,
          description: _selectedGoal!.description,
          targetAmount: _selectedGoal!.targetAmount,
          currentAmount: _selectedGoal!.currentAmount + transaction.amount,
          targetDate: _selectedGoal!.targetDate,
          priority: _selectedGoal!.priority,
          status: _selectedGoal!.status,
          goalType: _selectedGoal!.goalType,
          profileId: _selectedGoal!.profileId,
          createdAt: _selectedGoal!.createdAt,
        );
        dataService.saveGoal(updatedGoal);
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
    switch (_selectedType) {
      case TransactionType.income:
        return _incomeCategories;
      case TransactionType.expense:
        return _expenseCategories;
      case TransactionType.savings:
        return ['Savings'];
    }
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
                          _buildTypeButton(TransactionType.income, 'Income', Icons.arrow_upward, Colors.green),
                          _buildTypeButton(TransactionType.expense, 'Expense', Icons.arrow_downward, Colors.red),
                          _buildTypeButton(TransactionType.savings, 'Savings', Icons.savings, const Color(0xFF007A39)),
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
                    
                    // Category Dropdown (only for income/expense)
                    if (_selectedType != TransactionType.savings)
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
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
                    
                    // Goal Selection (only for savings)
                    if (_selectedType == TransactionType.savings) ...[
                      Consumer<OfflineDataService>(
                        builder: (context, dataService, child) {
                          final goals = dataService.getAllGoals()
                              .where((goal) => goal.status != 'completed')
                              .toList();
                          
                          return DropdownButtonFormField<Goal?>(
                            value: _selectedGoal,
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
                                  child: Text('${goal.name} (Ksh ${goal.currentAmount.toStringAsFixed(2)} / Ksh ${goal.targetAmount.toStringAsFixed(2)})'),
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

  Widget _buildTypeButton(TransactionType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            if (_selectedType != TransactionType.savings) {
              _selectedGoal = null;
            }
            // Reset category to first available when switching types
            _selectedCategory = _currentCategories.first;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
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
