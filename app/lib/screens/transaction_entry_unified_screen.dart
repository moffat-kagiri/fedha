// lib/screens/transaction_entry_unified_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';  

import '../models/goal.dart' as dom_goal;
import '../models/goal.dart';
import '../models/enums.dart';
import '../models/transaction.dart';
import '../services/offline_data_service.dart';
import '../services/currency_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class TransactionEntryUnifiedScreen extends StatefulWidget {
  final Transaction? editingTransaction;

  const TransactionEntryUnifiedScreen({
    Key? key, 
    this.editingTransaction,
  }) : super(key: key);

  @override
  State<TransactionEntryUnifiedScreen> createState() => _TransactionEntryUnifiedScreenState();
}

class _TransactionEntryUnifiedScreenState extends State<TransactionEntryUnifiedScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _showAdvancedOptions = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TransactionCategory? _selectedCategory;
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedGoalId;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  dom_goal.Goal? _selectedGoal;
  List<dom_goal.Goal> _goals = [];
  List<Goal> _goalList = [];
  bool _isSaving = false;
  
  final Map<TransactionType, List<TransactionCategory>> _categories = {
    TransactionType.income: [
      TransactionCategory.salary,
      TransactionCategory.business,
      TransactionCategory.investment,
      TransactionCategory.gift,
      TransactionCategory.otherIncome,
    ],
    TransactionType.expense: [
      TransactionCategory.food,
      TransactionCategory.transport,
      TransactionCategory.utilities,
      TransactionCategory.entertainment,
      TransactionCategory.healthcare,
      TransactionCategory.shopping,
      TransactionCategory.education,
      TransactionCategory.otherExpense,
    ],
    TransactionType.savings: [
      TransactionCategory.emergencyFund,
      TransactionCategory.investment,
      TransactionCategory.retirement,
      TransactionCategory.otherSavings,
    ],
  };

  // 3. Add helper methods for enum-string conversion
  String _categoryToId(TransactionCategory? category) {
    if (category == null) return 'other';
    return category.name;
  }

  String _categoryToDisplayName(TransactionCategory? category) {
    if (category == null) return 'Other';
    final raw = category.toString().split('.').last;
    // Convert camelCase to Title Case with spaces
    return raw.replaceAllMapped(
      RegExp(r'^([a-z])|[A-Z]'),
      (Match m) => m[1] == null ? " ${m[0]}" : m[1]!.toUpperCase(),
    ).trim();
  }
  // 4. Fix the variable initialization (line 67)
  void _initializeCategory() {
    final availableCategories = _categories[_selectedType];
    if (availableCategories != null && availableCategories.isNotEmpty) {
      _selectedCategory = availableCategories.first;
    } else {
      _selectedCategory = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedGoalId = null;
    _loadGoals();
    
    if (widget.editingTransaction != null) {
      _loadTransactionData(widget.editingTransaction!);
    } else {
      _initializeCategory();
    }
  }

  Future<void> _loadGoals() async {
    try {
      final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final profileIdStr = authService.currentProfile?.id ?? '';
      final profileId = int.tryParse(profileIdStr) ?? 0;
      
      if (profileId > 0) {
        final goals = await offlineDataService.getAllGoals(profileId);
        setState(() {
          _goalList = goals;
        });
      }
    } catch (e) {
      // Handle error
      print('Error loading goals: $e');
    }
  }

  Goal? _getDefaultGoal(List<Goal> availableGoals) {
    if (availableGoals.isEmpty) {
      return null;
    }
    
    // Try to find the first active goal
    try {
      final activeGoal = availableGoals.firstWhere(
        (goal) => goal.status == GoalStatus.active,
        orElse: () => availableGoals.first,
      );
      
      return activeGoal;
    } catch (e) {
      return availableGoals.isNotEmpty ? availableGoals.first : null;
    }
  }

  // In your goal selection widget, update _selectedGoalId when user selects a goal
  Widget _buildGoalSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedGoalId,
      decoration: const InputDecoration(
        labelText: 'Assign to Goal (Optional)',
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('No Goal'),
        ),
        ..._goalList.map((goal) {
          return DropdownMenuItem(
            value: goal.id,
            child: Text(goal.name),
          );
        }).toList(),
      ],
      onChanged: (String? newValue) {
        setState(() {
          _selectedGoalId = newValue;
        });
      },
    );
  }

  void _formatAmount() {
    // Only format when not currently editing (to avoid cursor issues)
    if (!_amountController.text.endsWith('.') && 
        !_amountController.text.endsWith('0')) {
      
      String text = _amountController.text.replaceAll(',', '');
      if (text.isEmpty) return;
      
      try {
        double value = double.parse(text);
        String formatted = NumberFormat("#,##0.00").format(value);
        
        // Only update if different to avoid infinite loops
        if (_amountController.text != formatted) {
          // Keep cursor position relative to the end when formatting
          int cursorPos = _amountController.selection.baseOffset;
          int oldLength = _amountController.text.length;
          
          _amountController.text = formatted;
          
          // Reset cursor position
          if (cursorPos != -1) {
            int newLength = formatted.length;
            int newPos = (cursorPos > newLength) ? newLength : cursorPos;
            _amountController.selection = TextSelection.fromPosition(
              TextPosition(offset: newPos),
            );
          }
        }
      } catch (e) {
        // If parsing fails, leave the text as is
      }
    }
  }

  void _loadTransactionData(Transaction transaction) {
    // Format the amount properly
    _amountController.text = transaction.amount.toStringAsFixed(2);
    _descriptionController.text = transaction.description ?? '';
    _selectedType = transaction.type;
    if (transaction.category != null) {
      _selectedCategory = transaction.category;
    } else {
      final defaultCategories = _categories[transaction.type];
      _selectedCategory = defaultCategories?.isNotEmpty == true ? defaultCategories?.first : null;
    }
    _selectedDate = transaction.date;
    
    // Extract time from the transaction date
    _selectedTime = TimeOfDay.fromDateTime(transaction.date);
    
    // Show advanced options if this transaction has non-default values
    if (transaction.goalId != null || 
        transaction.paymentMethod != null || 
        transaction.date.difference(DateTime.now()).inDays != 0) {
      _showAdvancedOptions = true;
    }
    
    // Set payment method if available
    if (transaction.paymentMethod != null) {
      _selectedPaymentMethod = transaction.paymentMethod!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  String _getAmountValue() {
    // Remove formatting characters for calculation
    String amountText = _amountController.text.replaceAll(',', '');
    if (amountText.isEmpty) return '0';
    
    try {
      return amountText;
    } catch (e) {
      return '0';
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = authService.currentProfile?.id ?? '0';
      
      // Format amount with two decimal points before parsing
      String raw = _getAmountValue();
      double amount = double.parse(raw);
      String formattedAmount = amount.toStringAsFixed(2);
      
      // Determine category and goal ID based on transaction type
      String? categoryId;
      String? categoryName;
      String? goalId;
      
      if (_selectedType == TransactionType.savings) {
        // For savings, use goal ID and name
        if (_selectedGoal != null) {
          goalId = _selectedGoal!.id;
          categoryId = _selectedGoal!.id;
          categoryName = _selectedGoal!.name;
        }
      } else {
        // For income/expense, use the selected category
        categoryId = _categoryToId(_selectedCategory);
        categoryName = _categoryToDisplayName(_selectedCategory);
      }
      
      final transaction = Transaction(
        id: widget.editingTransaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(formattedAmount),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        categoryId: categoryId ?? '',
        category: _selectedCategory,
        date: _selectedDate,
        goalId: goalId,
        paymentMethod: _selectedPaymentMethod,
        profileId: profileId,
      );

      await dataService.saveTransaction(transaction);
      
      if (mounted) {
        Navigator.pop(context, transaction);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingTransaction != null 
                ? 'Transaction updated successfully' 
                : 'Transaction saved successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteTransaction() async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isSaving = true; // Reuse saving indicator for deletion
    });
    
    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      
      if (widget.editingTransaction != null) {
        await dataService.deleteTransaction(widget.editingTransaction!.id);
        
        if (mounted) {
          Navigator.pop(context, 'deleted');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaction deleted'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<OfflineDataService, CurrencyService>(
      builder: (context, dataService, currencyService, child) {
        
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.editingTransaction != null 
              ? 'Edit Transaction' 
              : 'Add Transaction'),
            actions: [
              if (widget.editingTransaction != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete Transaction',
                  onPressed: _deleteTransaction,
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Type Selector
                  _buildTransactionTypeTabs(),
                  
                  const SizedBox(height: 24),
                  
                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: '0',
                      prefixText: '${currencyService.currentSymbol} ',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (value) {
                      // Format the amount as user types
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _formatAmount();
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      
                      String cleanValue = value.replaceAll(',', '');
                      try {
                        double amount = double.parse(cleanValue);
                        if (amount <= 0) {
                          return 'Amount must be greater than zero';
                        }
                      } catch (e) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Category or Goal Field
                  if (_selectedType == TransactionType.savings)
                    _buildGoalSelector()
                  else
                    _buildCategorySelector(),
                  
                  const SizedBox(height: 16),
                  
                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'What was this transaction for?',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Advanced Options Toggle
                  Card(
                    child: ListTile(
                      title: Text(
                        'Advanced Options',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Switch(
                        value: _showAdvancedOptions,
                        onChanged: (bool value) {
                          setState(() {
                            _showAdvancedOptions = value;
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _showAdvancedOptions = !_showAdvancedOptions;
                        });
                      },
                    ),
                  ),
                  
                  // Advanced Options Section
                  if (_showAdvancedOptions) _buildAdvancedOptions(),
                  
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveTransaction,
                      child: _isSaving 
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  widget.editingTransaction != null
                                      ? 'Update Transaction'
                                      : 'Save Transaction',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionTypeTabs() {
    return SegmentedButton<TransactionType>(
      segments: TransactionType.values.map((type) {
        String label;
        IconData icon;
        
        switch (type) {
          case TransactionType.income:
            label = 'Income';
            icon = Icons.arrow_downward;
            break;
          case TransactionType.expense:
            label = 'Expense';
            icon = Icons.arrow_upward;
            break;
          case TransactionType.savings:
            label = 'Savings';
            icon = Icons.savings;
            break;
          default:
            label = type.toString().split('.').last;
            icon = Icons.category;
        }
        
        return ButtonSegment<TransactionType>(
          value: type,
          label: Text(label),
          icon: Icon(icon),
        );
      }).toList(),
      selected: {_selectedType},
      onSelectionChanged: (Set<TransactionType> newSelection) {
        setState(() {
          _selectedType = newSelection.first;
          // Reset category to first in list when changing type
          if (_categories[_selectedType]!.isNotEmpty) {
            _initializeCategory();
          }
          // Reset goal when switching away from savings
          if (_selectedType != TransactionType.savings) {
            _selectedGoal = null;
          }
        });
      },
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<TransactionCategory>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: _selectedType == TransactionType.savings ? 'Goal' : 'Category',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _categories[_selectedType]!.map((TransactionCategory category) {
        return DropdownMenuItem<TransactionCategory>(
          value: category,
          child: Text(_categoryToDisplayName(category)),
        );
      }).toList(),
      onChanged: (TransactionCategory? value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
      validator: (value) {
        if (value == null) {
          return _selectedType == TransactionType.savings
              ? 'Please select a goal'
              : 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date and Time Selector
        Text(
          'Date & Time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => _selectDate(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => _selectTime(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('hh:mm a').format(_selectedDate),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Payment Method Selector
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PaymentMethod>(
      value: _selectedPaymentMethod,
      items: PaymentMethod.values.map((PaymentMethod method) {
        String label;
        
        switch (method) {
          case PaymentMethod.cash:
            label = 'Cash';
            break;
          case PaymentMethod.card:
            label = 'Card';
            break;
          case PaymentMethod.bank:
            label = 'Bank Transfer';
            break;
          case PaymentMethod.mobile:
            label = 'Mobile Money';
            break;
          default:
            label = method.toString().split('.').last;
        }
        
        return DropdownMenuItem<PaymentMethod>(
          value: method,
          child: Text(label),
        );
      }).toList(),
      onChanged: (PaymentMethod? value) {
        if (value != null) {
          setState(() {
            _selectedPaymentMethod = value;
          });
        }
      },
    ),
      ],
    );
  }
}