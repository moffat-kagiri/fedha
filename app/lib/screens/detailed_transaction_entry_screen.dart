import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import '../services/currency_service.dart';
import '../services/auth_service.dart';

class DetailedTransactionEntryScreen extends StatefulWidget {
  final Transaction? editingTransaction;
  
  const DetailedTransactionEntryScreen({
    super.key,
    this.editingTransaction,
  });

  @override
  State<DetailedTransactionEntryScreen> createState() => _DetailedTransactionEntryScreenState();
}

class _DetailedTransactionEntryScreenState extends State<DetailedTransactionEntryScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _merchantController = TextEditingController();
  final _referenceController = TextEditingController();
  
  late TabController _tabController;
  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = '';
  String _selectedSubcategory = '';
  Goal? _selectedGoal;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isRecurring = false;
  String _recurringFrequency = 'Monthly';
  String _paymentMethod = 'Cash';
  bool _isBusinessExpense = false;
  List<String> _tags = [];
  
  final Map<TransactionType, Map<String, List<String>>> _categoryStructure = {
    TransactionType.income: {
      'Employment': ['Salary', 'Bonus', 'Commission', 'Tips', 'Overtime'],
      'Business': ['Revenue', 'Consulting', 'Freelance', 'Partnership'],
      'Investments': ['Dividends', 'Interest', 'Capital Gains', 'Rental Income'],
      'Government': ['Tax Refund', 'Benefits', 'Grants', 'Pension'],
      'Other': ['Gift', 'Loan Received', 'Miscellaneous']
    },
    TransactionType.expense: {
      'Housing': ['Rent', 'Mortgage', 'Property Tax', 'Home Insurance', 'Utilities'],
      'Transportation': ['Fuel', 'Public Transport', 'Car Payment', 'Insurance', 'Maintenance'],
      'Food': ['Groceries', 'Restaurants', 'Coffee', 'Snacks', 'Delivery'],
      'Healthcare': ['Doctor', 'Dentist', 'Pharmacy', 'Insurance', 'Therapy'],
      'Entertainment': ['Movies', 'Sports', 'Hobbies', 'Subscriptions', 'Games'],
      'Shopping': ['Clothing', 'Electronics', 'Home Goods', 'Books', 'Gifts'],
      'Education': ['Tuition', 'Books', 'Courses', 'Training', 'School Supplies'],
      'Personal Care': ['Haircut', 'Cosmetics', 'Gym', 'Spa', 'Clothing'],
      'Bills': ['Phone', 'Internet', 'Electricity', 'Water', 'Gas'],
      'Travel': ['Hotels', 'Flights', 'Car Rental', 'Activities', 'Meals'],
      'Financial': ['Bank Fees', 'Interest', 'Insurance', 'Taxes', 'Loans'],
      'Other': ['Charity', 'Gifts', 'Miscellaneous', 'Emergency']
    },
    TransactionType.savings: {
      'Goals': [], // Will be populated with user goals
    },
  };

  final List<String> _paymentMethods = [
    'Cash', 'Debit Card', 'Credit Card', 'Bank Transfer', 'Mobile Payment',
    'Check', 'PayPal', 'Cryptocurrency', 'Other'
  ];

  final List<String> _recurringOptions = [
    'Daily', 'Weekly', 'Bi-weekly', 'Monthly', 'Quarterly', 'Yearly'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
    
    if (widget.editingTransaction != null) {
      _loadTransactionData(widget.editingTransaction!);
    }
    
    // Set default category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDefaultCategory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    _merchantController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _loadTransactionData(Transaction transaction) {
    _amountController.text = transaction.amount.toString();
    _descriptionController.text = transaction.description ?? '';
    _notesController.text = transaction.notes ?? '';
    _selectedType = transaction.type;
    _selectedDate = transaction.date;
    _selectedTime = TimeOfDay.fromDateTime(transaction.date);
    _selectedCategory = transaction.categoryId;
  }

  void _updateDefaultCategory() {
    final categories = _categoryStructure[_selectedType];
    if (categories != null && categories.isNotEmpty) {
      setState(() {
        _selectedCategory = categories.keys.first;
        _selectedSubcategory = categories[_selectedCategory]?.first ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.editingTransaction != null ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: const Color(0xFF007A39),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.attach_money), text: 'Basic'),
            Tab(icon: Icon(Icons.category), text: 'Details'),
            Tab(icon: Icon(Icons.schedule), text: 'Advanced'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicTab(),
            _buildDetailsTab(),
            _buildAdvancedTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007A39),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(widget.editingTransaction != null ? 'Update' : 'Save Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Type Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: TransactionType.values.map((type) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = type;
                              _updateDefaultCategory();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedType == type
                                  ? const Color(0xFF007A39)
                                  : Colors.transparent,
                              border: Border.all(
                                color: _selectedType == type
                                    ? const Color(0xFF007A39)
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _getTransactionIcon(type),
                                  color: _selectedType == type
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getTransactionLabel(type),
                                  style: TextStyle(
                                    color: _selectedType == type
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    fontWeight: _selectedType == type
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Amount Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<CurrencyService>(
                    builder: (context, currencyService, child) {
                      return TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF007A39),
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          prefixText: '${currencyService.currentSymbol} ',
                          prefixStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: const Color(0xFF007A39),
                            fontWeight: FontWeight.bold,
                          ),
                          hintText: '0.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF007A39), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'What was this for?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF007A39), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Date and Time
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date & Time',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFF007A39)),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectTime,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Color(0xFF007A39)),
                                const SizedBox(width: 8),
                                Text(_selectedTime.format(context)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySelector(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Payment Method
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF007A39), width: 2),
                      ),
                    ),
                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Merchant/Location
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merchant/Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _merchantController,
                    decoration: InputDecoration(
                      hintText: 'Where was this transaction?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF007A39), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tags
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tags',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      hintText: 'Add tags separated by commas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF007A39), width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _tags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
                      });
                    },
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: const Color(0xFF007A39).withValues(alpha: 0.1),
                          labelStyle: const TextStyle(color: Color(0xFF007A39)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Additional Notes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Any additional details...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF007A39), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Reference Number
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reference Number',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _referenceController,
                    decoration: InputDecoration(
                      hintText: 'Receipt number, invoice, etc.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF007A39), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Business Expense Toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Expense',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Mark this as a business expense for tax purposes',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isBusinessExpense,
                    onChanged: (value) {
                      setState(() {
                        _isBusinessExpense = value;
                      });
                    },
                    activeColor: const Color(0xFF007A39),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Recurring Transaction
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recurring Transaction',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'This transaction repeats regularly',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                          });
                        },
                        activeColor: const Color(0xFF007A39),
                      ),
                    ],
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Frequency',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _recurringFrequency,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF007A39), width: 2),
                        ),
                      ),
                      items: _recurringOptions.map((frequency) {
                        return DropdownMenuItem(
                          value: frequency,
                          child: Text(frequency),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _recurringFrequency = value!;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = _categoryStructure[_selectedType] ?? {};
    
    return Column(
      children: categories.keys.map((category) {
        final subcategories = categories[category] ?? [];
        return ExpansionTile(
          title: Text(
            category,
            style: TextStyle(
              fontWeight: _selectedCategory == category ? FontWeight.bold : FontWeight.normal,
              color: _selectedCategory == category ? const Color(0xFF007A39) : null,
            ),
          ),
          children: subcategories.map((subcategory) {
            return ListTile(
              title: Text(subcategory),
              leading: Radio<String>(
                value: subcategory,
                groupValue: _selectedSubcategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = category;
                    _selectedSubcategory = value!;
                  });
                },
                activeColor: const Color(0xFF007A39),
              ),
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _selectedSubcategory = subcategory;
                });
              },
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.add_circle;
      case TransactionType.expense:
        return Icons.remove_circle;
      case TransactionType.savings:
        return Icons.savings;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  String _getTransactionLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.savings:
        return 'Savings';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF007A39),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF007A39),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final offlineDataService = Provider.of<OfflineDataService>(context, listen: false);
      
      if (authService.currentProfile == null) {
        throw Exception('No user profile found');
      }

      final transactionDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final transaction = Transaction(
        id: widget.editingTransaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        uuid: widget.editingTransaction?.uuid ?? DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(_amountController.text),
        type: _selectedType,
        categoryId: _selectedSubcategory.isNotEmpty ? _selectedSubcategory : _selectedCategory,
        date: transactionDate,
        description: _descriptionController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        profileId: authService.currentProfile!.id,
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      if (widget.editingTransaction != null) {
        await offlineDataService.updateTransaction(transaction);
      } else {
        await offlineDataService.saveTransaction(transaction);
      }

      if (mounted) {
        Navigator.pop(context, transaction);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingTransaction != null 
                ? 'Transaction updated successfully!' 
                : 'Transaction saved successfully!'),
            backgroundColor: const Color(0xFF007A39),
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
