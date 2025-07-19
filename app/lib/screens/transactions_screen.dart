// lib/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/transaction_candidate.dart';
import '../models/goal.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../services/offline_data_service.dart';
import '../utils/profile_transaction_utils.dart';
import 'add_transaction_screen.dart';
import '../widgets/quick_transaction_entry.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Income', 'Expense', 'Savings'];
  // Search and enhanced filtering
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionCategory? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  double? _minAmount;
  double? _maxAmount;
  String _sortBy =
      'Date (Newest)'; // Date (Newest), Date (Oldest), Amount (High), Amount (Low)
  bool _showAdvancedFilters = false;
  Goal? _selectedGoalFilter; // Add goal filtering
  List<Goal> _availableGoals = [];
  Future<List<Transaction>> _loadTransactions(
    OfflineDataService dataService,
    String profileId,
  ) async {
    return dataService.getAllTransactions();
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    List<Transaction> filtered = transactions;

    // Filter by type
    if (_selectedFilter != 'All') {
      TransactionType type;
      switch (_selectedFilter) {
        case 'Income':
          type = TransactionType.income;
          break;
        case 'Expense':
          type = TransactionType.expense;
          break;
        case 'Savings':
          type = TransactionType.savings;
          break;
        default:
          type = TransactionType.expense;
      }
      filtered = filtered.where((t) => t.type == type).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((t) {
            final description = t.description?.toLowerCase() ?? '';
            final category = _categoryToString(t.category).toLowerCase();
            final notes = t.notes?.toLowerCase() ?? '';
            final amount = t.amount.toString();

            return description.contains(_searchQuery.toLowerCase()) ||
                category.contains(_searchQuery.toLowerCase()) ||
                notes.contains(_searchQuery.toLowerCase()) ||
                amount.contains(_searchQuery);
          }).toList();
    }

    // Filter by category
    if (_selectedCategory != null) {
      filtered =
          filtered.where((t) => t.category == _selectedCategory).toList();
    }

    // Filter by date range
    if (_selectedDateRange != null) {
      filtered =
          filtered.where((t) {
            final transactionDate = DateTime(
              t.date.year,
              t.date.month,
              t.date.day,
            );
            final startDate = DateTime(
              _selectedDateRange!.start.year,
              _selectedDateRange!.start.month,
              _selectedDateRange!.start.day,
            );
            final endDate = DateTime(
              _selectedDateRange!.end.year,
              _selectedDateRange!.end.month,
              _selectedDateRange!.end.day,
            );
            return transactionDate.isAtSameMomentAs(startDate) ||
                transactionDate.isAtSameMomentAs(endDate) ||
                (transactionDate.isAfter(startDate) &&
                    transactionDate.isBefore(endDate));
          }).toList();
    } // Filter by amount range
    if (_minAmount != null) {
      filtered = filtered.where((t) => t.amount >= _minAmount!).toList();
    }
    if (_maxAmount != null) {
      filtered = filtered.where((t) => t.amount <= _maxAmount!).toList();
    }

    // Filter by goal assignment
    if (_selectedGoalFilter != null) {
      filtered =
          filtered.where((t) => t.goalId == _selectedGoalFilter!.id).toList();
    }

    // Sort transactions
    switch (_sortBy) {
      case 'Date (Newest)':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Date (Oldest)':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Amount (High)':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Amount (Low)':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return filtered;
  }

  String _categoryToString(TransactionCategory? category) {
    if (category == null) return 'Other';
    return category.name.toUpperCase();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Transaction Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  'Amount',
                  'KSh${transaction.amount.toStringAsFixed(2)}',
                ),
                _buildDetailRow(
                  'Type',
                  transaction.type.toString().split('.').last,
                ),
                _buildDetailRow(
                  'Category',
                  _categoryToString(transaction.category),
                ),
                _buildDetailRow(
                  'Description',
                  transaction.description ?? 'No description',
                ),
                _buildDetailRow('Date', _formatDate(transaction.date)),
                if (transaction.notes?.isNotEmpty == true)
                  _buildDetailRow('Notes', transaction.notes!),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditTransactionDialog(context, transaction);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007A39),
                        ),
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFilter = 'All';
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
      _selectedDateRange = null;
      _minAmount = null;
      _maxAmount = null;
      _sortBy = 'Date (Newest)';
      _selectedGoalFilter = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileId = authService.currentProfile?.id;

    if (profileId != null) {
      final dataService = Provider.of<OfflineDataService>(
        context,
        listen: false,
      );
      final goals = dataService.getAllGoals();
      setState(() {
        _availableGoals = goals;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransactionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, color: Color(0xFF007A39)),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            final profile = authService.currentProfile;
            if (profile == null) {
              return const Center(child: Text('Please log in'));
            }

            return Consumer<OfflineDataService>(
              builder: (context, dataService, child) {
                return FutureBuilder<List<Transaction>>(
                  future: _loadTransactions(dataService, profile.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final transactions = snapshot.data ?? [];
                    final filteredTransactions = _filterTransactions(
                      transactions,
                    );

                    return Column(
                      children: [
                        // Search and Filter Section
                        _buildSearchAndFilterSection(),

                        // Summary Cards
                        _buildSummaryCards(transactions),

                        // Transactions List
                        Expanded(
                          child: _buildTransactionsList(filteredTransactions),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF007A39)),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF007A39)),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter and Sort Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Type Filter Chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          _filterOptions.map((option) {
                            final isSelected = _selectedFilter == option;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(option),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = option;
                                  });
                                },
                                selectedColor: const Color(
                                  0xFF007A39,
                                ).withOpacity(0.2),
                                checkmarkColor: const Color(0xFF007A39),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Advanced Filters Button
                IconButton(
                  icon: Icon(
                    _showAdvancedFilters
                        ? Icons.filter_list
                        : Icons.filter_list_outlined,
                    color:
                        _hasActiveFilters()
                            ? const Color(0xFF007A39)
                            : Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _showAdvancedFilters = !_showAdvancedFilters;
                    });
                  },
                  tooltip: 'Advanced Filters',
                ),

                // Sort Button
                PopupMenuButton<String>(
                  icon: Icon(Icons.sort, color: Colors.grey.shade600),
                  tooltip: 'Sort',
                  onSelected: (value) {
                    setState(() {
                      _sortBy = value;
                    });
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'Date (Newest)',
                          child: Text('Date (Newest)'),
                        ),
                        const PopupMenuItem(
                          value: 'Date (Oldest)',
                          child: Text('Date (Oldest)'),
                        ),
                        const PopupMenuItem(
                          value: 'Amount (High)',
                          child: Text('Amount (High)'),
                        ),
                        const PopupMenuItem(
                          value: 'Amount (Low)',
                          child: Text('Amount (Low)'),
                        ),
                      ],
                ),
              ],
            ),
          ),

          // Advanced Filters Panel
          if (_showAdvancedFilters) _buildAdvancedFiltersPanel(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null ||
        _selectedDateRange != null ||
        _minAmount != null ||
        _maxAmount != null ||
        _searchQuery.isNotEmpty ||
        _selectedFilter != 'All' ||
        _selectedGoalFilter != null;
  }

  Widget _buildAdvancedFiltersPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Advanced Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_hasActiveFilters())
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear All'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Category Filter
          _buildCategoryFilter(),

          const SizedBox(height: 16),

          // Date Range Filter
          _buildDateRangeFilter(),

          const SizedBox(height: 16),
          // Amount Range Filter
          _buildAmountRangeFilter(),

          const SizedBox(height: 16),

          // Goal Filter
          _buildGoalFilter(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final availableCategories = TransactionCategory.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<TransactionCategory>(
          value: _selectedCategory,
          decoration: InputDecoration(
            hintText: 'Select category',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items:
              availableCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_categoryToString(category)),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: _selectedDateRange,
            );
            if (picked != null) {
              setState(() {
                _selectedDateRange = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedDateRange == null
                        ? 'Select date range'
                        : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                    style: TextStyle(
                      color:
                          _selectedDateRange == null
                              ? Colors.grey.shade600
                              : Colors.black87,
                    ),
                  ),
                ),
                if (_selectedDateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount Range',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'Min amount',
                  prefixText: 'KSh ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _minAmount = double.tryParse(value);
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'Max amount',
                  prefixText: 'KSh ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _maxAmount = double.tryParse(value);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Goal Assignment',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Goal>(
          value: _selectedGoalFilter,
          decoration: InputDecoration(
            hintText: 'Filter by goal',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: [
            const DropdownMenuItem<Goal>(
              value: null,
              child: Text('All transactions'),
            ),
            ..._availableGoals.map((goal) {
              return DropdownMenuItem<Goal>(
                value: goal,
                child: Text(goal.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGoalFilter = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCards(List<Transaction> transactions) {
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final savings = transactions
        .where((t) => t.type == TransactionType.savings)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Income',
              'Ksh${income.toStringAsFixed(2)}',
              Colors.green,
              Icons.trending_up,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Expenses',
              'Ksh${expenses.toStringAsFixed(2)}',
              Colors.red,
              Icons.trending_down,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Savings',
              'Ksh${savings.toStringAsFixed(2)}',
              Colors.blue,
              Icons.savings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    Color color;
    IconData icon;
    String prefix;

    switch (transaction.type) {
      case TransactionType.income:
        color = Colors.green;
        icon = Icons.trending_up;
        prefix = '+';
        break;
      case TransactionType.expense:
        color = Colors.red;
        icon = Icons.trending_down;
        prefix = '-';
        break;
      case TransactionType.savings:
        color = Colors.blue;
        icon = Icons.savings;
        prefix = '-';
        break;
      case TransactionType.transfer:
        color = Colors.orange;
        icon = Icons.swap_horiz;
        prefix = '';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          _categoryToString(transaction.category),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              transaction.description ?? 'No description',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(transaction.date),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: Text(
          '${prefix}Ksh${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  void _showEditTransactionDialog(
    BuildContext context,
    Transaction transaction,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Transaction',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: QuickTransactionEntry(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
