// lib/screens/transaction_entry_unified_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';  // for FilteringTextInputFormatter

import '../models/transaction.dart';
import '../models/goal.dart' as dom_goal;
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import '../services/currency_service.dart';
import '../services/auth_service.dart';

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
  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = '';
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  dom_goal.Goal? _selectedGoal;
  List<dom_goal.Goal> _goals = [];
  bool _isSaving = false;
  
  final Map<TransactionType, List<String>> _categories = {
    TransactionType.income: [
      'Salary', 'Business Income', 'Freelance', 'Investment', 
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
    super.initState();
    
    if (widget.editingTransaction != null) {
      _loadTransactionData(widget.editingTransaction!);
    } else {
      _selectedCategory = _categories[_selectedType]!.first;
    }
    
    // Add listener to amount field for formatting
    _amountController.addListener(_formatAmount);
    
    // Load goals for savings - now using async/await pattern
    _loadGoals();
  }
  
  Future<void> _loadGoals() async {
    final dataService = Provider.of<OfflineDataService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileId = int.tryParse(authService.currentProfile?.id ?? '0') ?? 0;
    
    try {
      final loaded = await dataService.getAllGoals(profileId);
      
      if (mounted) {
        setState(() {
          _goals = loaded;
          
          // Populate savings category list with goal names
          _categories[TransactionType.savings] = loaded.map((g) => g.name).toList();
          
          // Default to first goal if in savings mode and none selected
          if (_selectedType == TransactionType.savings && _selectedGoal == null && loaded.isNotEmpty) {
            _selectedGoal = loaded.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading goals: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
            int newPos = max(0, cursorPos - (oldLength - newLength));
            _amountController.selection = TextSelection.fromPosition(
              TextPosition(offset: min(newPos, formatted.length)),
            );
          }
        }
      } catch (e) {
        // If parsing fails, leave the text as is
      }
    }
  }

  int max(int a, int b) => (a > b) ? a : b;
  int min(int a, int b) => (a < b) ? a : b;

  void _loadTransactionData(Transaction transaction) {
    // Format the amount properly
    _amountController.text = transaction.amount.toStringAsFixed(2);
    _descriptionController.text = transaction.description ?? '';
    _selectedType = transaction.type;
    _selectedCategory = transaction.categoryId ?? _categories[transaction.type]!.first;
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
    
    // Goal for savings transactions will be loaded when _goals are loaded
    // in _loadGoals() method which is called from initState
  }

  @override
  void dispose() {
    _amountController.removeListener(_formatAmount);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.primaryColor,
              onPrimary: theme.colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
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
    final theme = Theme.of(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.primaryColor,
              onPrimary: theme.colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
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
      
      final transaction = Transaction(
        id: widget.editingTransaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(_getAmountValue()),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        categoryId: _selectedType == TransactionType.savings && _selectedGoal != null 
            ? _selectedGoal!.id 
            : _selectedCategory,
        category: null, // This will be populated by the service
        date: _selectedDate,
        goalId: _selectedType == TransactionType.savings ? _selectedGoal?.id : null,
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
            backgroundColor: Theme.of(context).primaryColor,
            duration: const Duration(seconds: 2),
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
              backgroundColor: Theme.of(context).primaryColor,
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
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            actions: [
              if (widget.editingTransaction != null)
                IconButton(
                  icon: const Icon(Icons.delete),
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
                      hintText: '0.00',
                      prefixText: '${currencyService.currentSymbol} ',
                      border: const OutlineInputBorder(),
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
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Advanced Options Toggle
                  ListTile(
                    title: const Text(
                      'Advanced Options',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Switch(
                      value: _showAdvancedOptions,
                      onChanged: (bool value) {
                        setState(() {
                          _showAdvancedOptions = value;
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      setState(() {
                        _showAdvancedOptions = !_showAdvancedOptions;
                      });
                    },
                  ),
                  
                  // Advanced Options Section
                  if (_showAdvancedOptions) _buildAdvancedOptions(dataService),
                  
                  const SizedBox(height: 32),
                  
                  // Save Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32, 
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isSaving 
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2),
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onPrimary,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        widget.editingTransaction != null
                            ? 'Update Transaction'
                            : 'Save Transaction',
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
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light 
            ? Colors.grey.shade200 
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: TransactionType.values.map((type) {
          bool isSelected = _selectedType == type;
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
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type;
                  // Reset category to first in list when changing type
                  if (_categories[type]!.isNotEmpty) {
                    _selectedCategory = _categories[type]!.first;
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory.isEmpty && _categories[_selectedType]!.isNotEmpty 
          ? _categories[_selectedType]!.first 
          : _selectedCategory,
      decoration: InputDecoration(
        labelText: _selectedType == TransactionType.savings ? 'Goal' : 'Category',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _categories[_selectedType]!.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
            
            // If this is a savings transaction, update the selected goal
            if (_selectedType == TransactionType.savings) {
              final dataService = Provider.of<OfflineDataService>(context, listen: false);
              dataService.getAllGoals().then((goals) {
                  for (var goal in goals) {
                    if (goal.name == value) {
                      setState(() {
                        _selectedGoal = goal;
                      });
                      break;
                    }
                  }
              });
            }
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return _selectedType == TransactionType.savings
              ? 'Please select a goal'
              : 'Please select a category';
        }
        return null;
      },
    );
  }
  
  /// Build goal selector when type is savings
  Widget _buildGoalSelector() {
    if (_goals.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Loading goals...'),
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _loadGoals,
            child: const Text('Retry'),
          ),
        ],
      );
    }
    
    return DropdownButtonFormField<dom_goal.Goal>(
      value: _selectedGoal ?? (_goals.isNotEmpty ? _goals.first : null),
      decoration: const InputDecoration(
        labelText: 'Select Goal',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _goals.map((goal) {
        return DropdownMenuItem<dom_goal.Goal>(
          value: goal,
          child: Text(goal.name),
        );
      }).toList(),
      onChanged: (dom_goal.Goal? value) {
        setState(() {
          _selectedGoal = value;
        });
      },
      validator: (value) {
        if (value == null) return 'Please select a goal';
        return null;
      },
    );
  }

  Widget _buildAdvancedOptions(OfflineDataService dataService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date and Time Selector
        const Text(
          'Date & Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectTime(context),
                icon: const Icon(Icons.access_time, size: 16),
                label: Text(
                  DateFormat('hh:mm a').format(_selectedDate),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Payment Method Selector
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PaymentMethod>(
          value: _selectedPaymentMethod,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
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
        
        // Additional advanced fields can be added here
      ],
    );
  }
}

