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
import '../utils/transaction_operations_helper.dart'; 
import '../services/transaction_event_service.dart';

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
  String? _selectedCategory; // Changed from TransactionCategory? to String?
  String _selectedType = 'expense'; // Changed from Type to String
  String? _selectedGoalId;
  String _selectedPaymentMethod = 'cash'; // Changed from PaymentMethod to String
  dom_goal.Goal? _selectedGoal;
  List<dom_goal.Goal> _goals = [];
  List<Goal> _goalList = [];
  bool _isSaving = false;
  
  final Map<String, List<String>> _categories = { // Changed from Type to String keys
    'income': [
      'salary',
      'business',
      'investment',
      'gift',
      'otherIncome',
    ],
    'expense': [
      'food',
      'transport',
      'utilities',
      'entertainment',
      'healthcare',
      'shopping',
      'education',
      'otherExpense',
    ],
    'savings': [
      'emergencyFund',
      'investment',
      'retirement',
      'otherSavings',
    ],
  };

  // Helper methods for string conversions
  String _categoryToDisplayName(String? category) {
    if (category == null || category.isEmpty) return 'Other';
    
    // Convert snake_case or camelCase to Title Case with spaces
    String result = category.replaceAllMapped(
      RegExp(r'([A-Z])|_'),
      (Match m) => m[1] != null ? " ${m[1]}" : " ",
    ).trim();
    
    // Capitalize first letter of each word
    return result.split(' ').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return word;
    }).join(' ');
  }

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
      
      final profileId = authService.currentProfile?.id ?? '';
      
      if (profileId.isNotEmpty) {
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

  Widget _buildGoalSelector() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedGoalId,
          decoration: const InputDecoration(
            labelText: 'Assign to Goal (Optional)',
            helperText: 'Leave empty for general savings without a specific goal',
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('No Goal - General Savings'),
            ),
            ..._goalList.map((goal) {
              return DropdownMenuItem(
                value: goal.id,
                child: Text('${goal.name} (${goal.progressPercentage.toStringAsFixed(1)}%)'),
              );
            }).toList(),
          ],
          onChanged: (String? newValue) {
            setState(() {
              _selectedGoalId = newValue;
            });
          },
        ),
        // Show info hint for both goal-linked and general savings
        if (_selectedType == 'savings')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Card(
              color: FedhaColors.infoBlue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: FedhaColors.infoBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedGoalId != null
                            ? 'This amount will be added to your goal progress'
                            : 'General savings can be tracked separately or linked to a goal later',
                        style: TextStyle(color: FedhaColors.infoBlue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
    
    // FIXED: Use string values directly from transaction
    _selectedType = transaction.type; // Now matches (String = String)
    _selectedCategory = transaction.category; // Now matches (String? = String?)
    
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
      // FIXED: Use string directly
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
    
    // Validate that expense transactions aren't linked to goals
    if (_selectedType == 'expense' && _selectedGoalId != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Expense transactions cannot be linked to goals'),
            backgroundColor: FedhaColors.warningOrange,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isSaving = true;
    });

    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final eventService = Provider.of<TransactionEventService>(context, listen: false);
      final profileId = authService.currentProfile?.id ?? '0';
      
      // Format amount with two decimal points before parsing
      String raw = _getAmountValue();
      double amount = double.parse(raw);
      String formattedAmount = amount.toStringAsFixed(2);
      
      // FIXED: Create transaction with string values
      // Convert amount to minor units for Transaction model
      final amountMinor = (amount * 100).toInt();
      
      final transaction = Transaction(
        id: widget.editingTransaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        profileId: profileId,
        amount: (amountMinor/100).toDouble(), // Store as major units (double)
        type: _selectedType, // String
        isExpense: _selectedType == 'expense',
        category: _selectedCategory ?? '',
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        goalId: _selectedGoalId,
        budgetCategory: null, // Will be assigned by TransactionEventService
        currency: 'KES',
        isSynced: false,
        createdAt: widget.editingTransaction?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success = false;
      
      if (widget.editingTransaction != null) {
        // Update existing transaction:
        // 1. Delete old transaction from local storage
        // 2. Create new transaction with updated values
        success = await TransactionOperations.updateTransaction(
          transaction: transaction,
          offlineService: dataService,
          oldTransaction: widget.editingTransaction!,
        );
        if (success) {
          await eventService.onTransactionUpdated(transaction); 
        }
      } else {
        // Create new transaction with event emission
        success = await TransactionOperations.createTransaction(
          transaction: transaction,
          offlineService: dataService,
        );
        if (success) {
          await eventService.onTransactionCreated(transaction); 
        }
      }
      
      if (success) {
        if (mounted) {
          Navigator.pop(context, transaction);
          
          // Show success message with what was updated
          String updateMessage = widget.editingTransaction != null 
              ? 'Transaction updated successfully' 
              : 'Transaction saved successfully';
          
          if (_selectedType == 'expense') {
            updateMessage += ' • Budget updated';
          } else if (_selectedType == 'savings' && _selectedGoalId != null) {
            updateMessage += ' • Goal progress updated';
          } else if (_selectedType == 'savings') {
            updateMessage += ' • General savings recorded';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(updateMessage)),
                ],
              ),
              backgroundColor: FedhaColors.successGreen,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        throw Exception('Failed to save transaction');
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
    if (widget.editingTransaction == null) return;
    
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This will also update your budgets and goals.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FedhaColors.errorRed,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      
      // Delete with event emission
      final success = await TransactionOperations.deleteTransaction(
        transaction: widget.editingTransaction!,
        offlineService: dataService,
      );
      
      if (success) {
        if (mounted) {
          Navigator.pop(context, null);  // ✅ Return null, not 'deleted'
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Transaction deleted • Budgets and goals updated'),
                ],
              ),
              backgroundColor: FedhaColors.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        throw Exception('Failed to delete transaction');
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
                  if (_selectedType == 'savings')
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
    // Define the transaction type options
    final List<Map<String, dynamic>> typeOptions = [
      {
        'value': 'income',
        'label': 'Income',
        'icon': Icons.arrow_downward,
      },
      {
        'value': 'expense',
        'label': 'Expense',
        'icon': Icons.arrow_upward,
      },
      {
        'value': 'savings',
        'label': 'Savings',
        'icon': Icons.savings,
      },
    ];

    return SegmentedButton<String>(
      segments: typeOptions.map((option) {
        return ButtonSegment<String>(
          value: option['value'],
          label: Text(option['label']),
          icon: Icon(option['icon']),
        );
      }).toList(),
      selected: {_selectedType},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _selectedType = newSelection.first;
          // Reset category to first in list when changing type
          if (_categories[_selectedType]!.isNotEmpty) {
            _initializeCategory();
          }
          // Reset goal when switching away from savings
          if (_selectedType != 'savings') {
            _selectedGoalId = null;
          }
        });
      },
    );
  }

  Widget _buildCategorySelector() {
    final categories = _categories[_selectedType] ?? [];
    final uniqueCategories = categories.toSet().toList();
    
    // ✅ Ensure selected category exists in the list
    if (_selectedCategory != null && !uniqueCategories.contains(_selectedCategory)) {
      uniqueCategories.add(_selectedCategory!);
    }

    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: _selectedType == 'savings' ? 'Goal' : 'Category',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: uniqueCategories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return _selectedType == 'savings'
              ? 'Please select a goal'
              : 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildAdvancedOptions() {
    // Define payment method options
    final List<Map<String, dynamic>> paymentMethodOptions = [
      {'value': 'cash', 'label': 'Cash'},
      {'value': 'card', 'label': 'Card'},
      {'value': 'bank', 'label': 'Bank Transfer'},
      {'value': 'mobile', 'label': 'Mobile Money'},
    ];

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
        DropdownButtonFormField<String>(
          value: _selectedPaymentMethod,
          items: paymentMethodOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label']),
            );
          }).toList(),
          onChanged: (String? value) {
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