import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../widgets/quick_transaction_entry.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existingTransaction;
  
  const AddTransactionScreen({
    super.key,
    this.existingTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  // Current tab is managed by TabController

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.existingTransaction == null ? 'Add Transaction' : 'Edit Transaction',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF007A39),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF007A39)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF007A39),
          labelColor: const Color(0xFF007A39),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              icon: Icon(Icons.speed),
              text: 'Quick Entry',
            ),
            Tab(
              icon: Icon(Icons.auto_awesome),
              text: 'Smart Entry',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Bulk Entry',
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          _tabController.animateTo(index);
        },
        children: [
          // Quick Entry Tab
          _buildQuickEntryTab(),
          
          // Smart Entry Tab
          _buildSmartEntryTab(),
          
          // Bulk Entry Tab
          _buildBulkEntryTab(),
        ],
      ),
    );
  }

  Widget _buildQuickEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 122, 57, 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.speed, color: Color(0xFF007A39)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Quick transaction entry for everyday expenses and income',
                    style: TextStyle(
                      color: Color(0xFF007A39),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          QuickTransactionEntry(
            existingTransaction: widget.existingTransaction,
            onTransactionSaved: (transaction) {
              Navigator.pop(context, transaction);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmartEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(33, 150, 243, 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI-powered transaction entry with automatic categorization and goal suggestions',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildSmartEntryForm(),
        ],
      ),
    );
  }

  Widget _buildBulkEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 152, 0, 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.analytics, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Import multiple transactions from bank statements or spreadsheets',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildBulkEntryForm(),
        ],
      ),
    );
  }

  Widget _buildSmartEntryForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.construction,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Smart Entry Coming Soon! 🚀',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'This feature will use AI to automatically categorize transactions, suggest goals to link to, and provide smart spending insights.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Switch to quick entry for now
              _tabController.animateTo(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Use Quick Entry Instead'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkEntryForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_upload,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bulk Import Coming Soon! 📊',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Import transactions from bank statements, CSV files, or connect directly to your bank accounts for automatic transaction syncing.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement CSV import
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('CSV import feature coming in next update!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.table_chart),
                  label: const Text('CSV Import'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Switch to quick entry for now
                    _tabController.animateTo(0);
                  },
                  icon: const Icon(Icons.speed),
                  label: const Text('Quick Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
