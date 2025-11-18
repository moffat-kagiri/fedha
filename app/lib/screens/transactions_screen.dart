import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../services/offline_data_service.dart';
import 'transaction_entry_unified_screen.dart';
import '../widgets/transaction_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Income', 'Expense', 'Savings'];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionCategory? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  double? _minAmount;
  double? _maxAmount;
  String _sortBy = 'Date (Newest)';
  bool _showAdvancedFilters = false;
  Goal? _selectedGoalFilter;
  List<Goal> _availableGoals = [];

  late Future<List<Transaction>> _transactionsFuture;
  late Future<List<Goal>> _goalsFuture;

  bool _didLoadDependencies = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadDependencies) {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      final profileId = int.tryParse(
              Provider.of<AuthService>(context, listen: false).currentProfile?.id ?? '0') ??
          0;

      _transactionsFuture = dataService.getAllTransactions(profileId);
      _goalsFuture = dataService.getAllGoals(profileId);

      _goalsFuture.then((goals) {
        if (mounted) setState(() => _availableGoals = goals);
      });

      _didLoadDependencies = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    var filtered = transactions;

    if (_selectedFilter != 'All') {
      late final TransactionType type;
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
      }
      filtered = filtered.where((t) => t.type == type).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        final description = t.description?.toLowerCase() ?? '';
        final category = _categoryToString(t.category).toLowerCase();
        final notes = t.notes?.toLowerCase() ?? '';
        final amount = t.amount.toString();

        return description.contains(query) ||
            category.contains(query) ||
            notes.contains(query) ||
            amount.contains(query);
      }).toList();
    }

    if (_selectedCategory != null) {
      filtered = filtered.where((t) => t.category == _selectedCategory).toList();
    }

    if (_selectedDateRange != null) {
      final start = DateTime(
        _selectedDateRange!.start.year,
        _selectedDateRange!.start.month,
        _selectedDateRange!.start.day,
      );
      final end = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
      );

      filtered = filtered.where((t) {
        final txDate = DateTime(t.date.year, t.date.month, t.date.day);
        return (txDate.isAtSameMomentAs(start) ||
            txDate.isAtSameMomentAs(end) ||
            (txDate.isAfter(start) && txDate.isBefore(end)));
      }).toList();
    }

    if (_minAmount != null) filtered = filtered.where((t) => t.amount >= _minAmount!).toList();
    if (_maxAmount != null) filtered = filtered.where((t) => t.amount <= _maxAmount!).toList();
    if (_selectedGoalFilter != null) {
      filtered = filtered.where((t) => t.goalId == _selectedGoalFilter!.id).toList();
    }

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
    final today = DateTime.now();
    final txDate = DateTime(date.year, date.month, date.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));

    if (txDate == todayDate) return 'Today';
    if (txDate == yesterday) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _hasActiveFilters() =>
      _selectedCategory != null ||
      _selectedDateRange != null ||
      _minAmount != null ||
      _maxAmount != null ||
      _searchQuery.isNotEmpty ||
      _selectedFilter != 'All' ||
      _selectedGoalFilter != null;

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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: Text(
          'Transactions',
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: colorScheme.onPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const TransactionEntryUnifiedScreen()),
            ),
          )
        ],
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data ?? [];
          final filtered = _filterTransactions(transactions);

          return Column(
            children: [
              _buildSearchAndFilterSection(colorScheme),
              _buildSummaryCards(transactions, colorScheme),
              Expanded(child: _buildTransactionsList(filtered, colorScheme)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilterSection(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: _searchQuery.isNotEmpty
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
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter & Sort Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filterOptions.map((option) {
                        final isSelected = _selectedFilter == option;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(option),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedFilter = option;
                              });
                            },
                            selectedColor: colorScheme.primary.withOpacity(0.2),
                            checkmarkColor: colorScheme.primary,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showAdvancedFilters ? Icons.filter_list : Icons.filter_list_outlined,
                    color: _hasActiveFilters() ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() => _showAdvancedFilters = !_showAdvancedFilters);
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.sort, color: colorScheme.onSurfaceVariant),
                  onSelected: (value) => setState(() => _sortBy = value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'Date (Newest)', child: Text('Date (Newest)')),
                    const PopupMenuItem(value: 'Date (Oldest)', child: Text('Date (Oldest)')),
                    const PopupMenuItem(value: 'Amount (High)', child: Text('Amount (High)')),
                    const PopupMenuItem(value: 'Amount (Low)', child: Text('Amount (Low)')),
                  ],
                ),
              ],
            ),
          ),

          if (_showAdvancedFilters) _buildAdvancedFiltersPanel(colorScheme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAdvancedFiltersPanel(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Advanced Filters', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_hasActiveFilters())
                TextButton(onPressed: _clearAllFilters, child: const Text('Clear All')),
            ],
          ),
          const SizedBox(height: 16),
          _buildCategoryFilter(colorScheme),
          const SizedBox(height: 16),
          _buildDateRangeFilter(colorScheme),
          const SizedBox(height: 16),
          _buildAmountRangeFilter(colorScheme),
          const SizedBox(height: 16),
          _buildGoalFilter(colorScheme),
        ],
      ),
    );
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
  final cs = Theme.of(context).colorScheme;
  final txt = Theme.of(context).textTheme;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: txt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant, // subtle M3 secondary tone
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: txt.bodyMedium?.copyWith(
            color: cs.primary, // highlight value
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}


  Widget _buildCategoryFilter(ColorScheme colorScheme) {
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


  Widget _buildDateRangeFilter(ColorScheme colorScheme) {
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

  Widget _buildAmountRangeFilter(ColorScheme colorScheme) {
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

  Widget _buildGoalFilter(ColorScheme colorScheme) {
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

  Widget _buildSummaryCards(List<Transaction> transactions, ColorScheme colorScheme) {
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
      color: colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Income',
              'Ksh${income.toStringAsFixed(2)}',
              colorScheme.primary,
              Icons.trending_up,
              colorScheme,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Expenses',
              'Ksh${expenses.toStringAsFixed(2)}',
              colorScheme.error,
              Icons.trending_down,
              colorScheme,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Savings',
              'Ksh${savings.toStringAsFixed(2)}',
              colorScheme.secondary,
              Icons.savings,
              colorScheme,
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
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions, ColorScheme colorScheme) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
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
        return _buildTransactionCard(transaction, colorScheme);
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction, ColorScheme colorScheme) {
    late Color color;
    late IconData icon;
    late String prefix;

    switch (transaction.type) {
      case TransactionType.income:
        color = colorScheme.primary;
        icon = Icons.trending_up;
        prefix = '+';
        break;
      case TransactionType.expense:
        color = colorScheme.error;
        icon = Icons.trending_down;
        prefix = '-';
        break;
      case TransactionType.savings:
        color = colorScheme.secondary;
        icon = Icons.savings;
        prefix = '-';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              transaction.description ?? 'No description',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(transaction.date),
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        trailing: Text(
          '$prefix${transaction.amount.toStringAsFixed(2)}',
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

  void _showEditTransactionDialog(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (ctx) => TransactionDialog(
        transaction: transaction,
        onSave: (updatedTransaction) {
          // Handle saving the updated transaction
          setState(() {
            // Update the transaction in the list or refresh the data
            _transactionsFuture = Provider.of<OfflineDataService>(context, listen: false)
                .getAllTransactions(int.parse(
                    Provider.of<AuthService>(context, listen: false).currentProfile?.id ?? '0'));
          });
        },
      ),
    );
  }
}

class TransactionDialog extends StatelessWidget {
  final Transaction transaction;

  const TransactionDialog({
    super.key,
    required this.transaction,
    required this.onSave,
  });

  String _prettyEnum(Object? value) {
    if (value == null) return 'Unknown';
    final raw = value.toString().split('.').last;
    return raw[0].toUpperCase() + raw.substring(1);
  }
  
  final void Function(Transaction) onSave;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Transaction Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 20),

          _buildDetailRow('Amount', 'KSh ${transaction.amount.toStringAsFixed(2)}', colorScheme),
          _buildDetailRow('Category', _prettyEnum(transaction.category), colorScheme),
          _buildDetailRow('Date', transaction.date.toString(), colorScheme),
          _buildDetailRow('Type', _prettyEnum(transaction.type), colorScheme),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.7),
              )),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              )),
        ],
      ),
    );
  }
}
