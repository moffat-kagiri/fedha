import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/offline_data_service.dart';
import '../models/transaction.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';

class SpendingOverviewScreen extends StatefulWidget {
  const SpendingOverviewScreen({Key? key}) : super(key: key);

  @override
  State<SpendingOverviewScreen> createState() => _SpendingOverviewScreenState();
}

class _SpendingOverviewScreenState extends State<SpendingOverviewScreen> {
  String _timeRange = 'Last 30 days';
  final List<String> _timeRanges = ['Last 7 days', 'Last 30 days', 'Last 3 months', 'Last 6 months', 'Last year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Overview'),
        backgroundColor: const Color(0xFF007A39),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Transaction>>(
        future: Provider.of<OfflineDataService>(context, listen: false)
            .getAllTransactions(Provider.of<AuthService>(context, listen: false)
                    .currentProfile?.id ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final txs = snapshot.data
                  ?.where((t) => t.type == TransactionType.expense)
                  .toList() ?? [];
           
          if (txs.isEmpty) {
            return _buildEmptyState();
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeRangeSelector(),
                const SizedBox(height: 24),
                _buildSummaryCard(txs),
                const SizedBox(height: 24),
                _buildCategoryBreakdown(txs),
                const SizedBox(height: 24),
                _buildRecentTransactions(txs),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).round())),
          const SizedBox(height: 16),
          Text(
            'No spending data yet',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding transactions to see your spending patterns',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round())),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/detailed_transaction_entry');
            },
            child: const Text('Add Transaction'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light 
            ? Colors.grey.shade100 
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _timeRange,
        icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
        isExpanded: true,
        underline: const SizedBox(),
        onChanged: (String? newValue) {
          setState(() {
            _timeRange = newValue!;
          });
        },
        items: _timeRanges.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildSummaryCard(List<Transaction> transactions) {
    double totalSpent = transactions.fold(0, (sum, tx) => sum + tx.amount);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Spent',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ksh ${totalSpent.toStringAsFixed(2)}',
                style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'During $_timeRange',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryBreakdown(List<Transaction> transactions) {
    // Placeholder for category breakdown visualization
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending by Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light 
                ? Colors.grey.shade100 
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            'Category breakdown chart coming soon',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round())),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentTransactions(List<Transaction> transactions) {
    final recentTransactions = transactions.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...recentTransactions.map((tx) => _buildTransactionItem(tx)),
      ],
    );
  }
  
  Widget _buildTransactionItem(Transaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF007A39).withAlpha((0.1 * 255).round()),
          child: Icon(
            Icons.shopping_bag,
            color: const Color(0xFF007A39),
          ),
        ),
        title: Text(transaction.description ?? 'Unknown'),
        subtitle: Text(
          transaction.category?.toString() ?? transaction.categoryId ?? 'Uncategorized',
        ),
        trailing: Text(
          'Ksh ${transaction.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
