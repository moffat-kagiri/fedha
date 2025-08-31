import 'package:flutter/material.dart';
import '../models/budget.dart';

class BudgetManagementScreen extends StatefulWidget {
  final Budget budget;
  
  const BudgetManagementScreen({Key? key, required this.budget}) : super(key: key);

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  late Category? _selectedCategory;
  late bool _isRecurring;
  late DateTime _startDate;
  late DateTime? _endDate;
  bool _isLoading = false;
  double _spentAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = null;
    _isRecurring = widget.budget.isRecurring ?? false;
    _startDate = widget.budget.startDate;
    _endDate = widget.budget.endDate;
    _loadBudgetDetails();
  }

  Future<void> _loadBudgetDetails() async {
    setState(() => _isLoading = true);
    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      
      // Load category if budget has one
      if (widget.budget.categoryId != null) {
        final category = await dataService.getCategoryById(widget.budget.categoryId!);
        if (mounted) {
          setState(() => _selectedCategory = category);
        }
      }

      // Calculate spent amount from transactions
      final transactions = await dataService.getTransactionsForPeriod(
        profileId: int.parse(widget.budget.profileId),
        startDate: widget.budget.startDate,
        endDate: widget.budget.endDate ?? DateTime.now(),
        categoryId: widget.budget.categoryId,
      );

      if (mounted) {
        setState(() {
          _spentAmount = transactions.fold(0.0, (sum, tx) => sum + (tx.isExpense ? tx.amount : 0));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budget details: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteBudget(),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget Overview Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.budget.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildProgressIndicator(),
                        const SizedBox(height: 16),
                        _buildBudgetDetails(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Period Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Budget Period',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildPeriodDetails(),
                      ],
                    ),
                  ),
                ),
                if (_selectedCategory != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildCategoryDetails(),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildProgressIndicator() {
    final percentSpent = widget.budget.limitAmount > 0 
      ? (_spentAmount / widget.budget.limitAmount * 100).clamp(0.0, 100.0)
      : 0.0;
    
    return Column(
      children: [
        LinearProgressIndicator(
          value: percentSpent / 100,
          minHeight: 8,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentSpent > 90 ? Colors.red 
            : percentSpent > 75 ? Colors.orange
            : Colors.green
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${percentSpent.toStringAsFixed(1)}% spent',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBudgetDetails() {
    final currencyService = Provider.of<CurrencyService>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Limit: ${currencyService.formatCurrency(widget.budget.limitAmount)}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          'Spent: ${currencyService.formatCurrency(_spentAmount)}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          'Remaining: ${currencyService.formatCurrency(widget.budget.limitAmount - _spentAmount)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPeriodDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start Date: ${DateFormat('MMM d, y').format(_startDate)}'),
        if (_endDate != null)
          Text('End Date: ${DateFormat('MMM d, y').format(_endDate!)}'),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Recurring: ${_isRecurring ? 'Yes' : 'No'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            TextButton(
              onPressed: _editPeriod,
              child: const Text('Edit Period'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryDetails() {
    if (_selectedCategory == null) return const SizedBox.shrink();
    
    return ListTile(
      leading: Icon(
        IconData(
          int.parse(_selectedCategory!.iconKey),
          fontFamily: 'MaterialIcons',
        ),
        color: Color(
          int.parse(_selectedCategory!.colorKey.replaceAll('#', '0xff'))
        ),
      ),
      title: Text(_selectedCategory!.name),
      trailing: TextButton(
        onPressed: _changeCategory,
        child: const Text('Change'),
      ),
    );
  }

  Future<void> _editPeriod() async {
    // Show date range picker
    DateTimeRange? range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate ?? _startDate.add(const Duration(days: 30)),
      ),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
      
      // Update budget in DB
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      await dataService.updateBudgetPeriod(
        widget.budget.id,
        startDate: range.start,
        endDate: range.end,
      );
    }
  }

  Future<void> _changeCategory() async {
    final dataService = Provider.of<OfflineDataService>(context, listen: false);
    final categories = await dataService.getCategories(
      int.parse(widget.budget.profileId)
    );
    
    if (!mounted) return;

    final Category? newCategory = await showDialog<Category>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) => ListTile(
              leading: Icon(
                IconData(
                  int.parse(categories[index].iconKey),
                  fontFamily: 'MaterialIcons',
                ),
                color: Color(
                  int.parse(categories[index].colorKey.replaceAll('#', '0xff'))
                ),
              ),
              title: Text(categories[index].name),
              onTap: () => Navigator.of(context).pop(categories[index]),
            ),
          ),
        ),
      ),
    );

    if (newCategory != null) {
      await dataService.updateBudgetCategory(
        widget.budget.id,
        newCategory.id,
      );
      setState(() => _selectedCategory = newCategory);
    }
  }

  Future<void> _deleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: const Text(
          'Are you sure you want to delete this budget? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      await dataService.deleteBudget(widget.budget.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
