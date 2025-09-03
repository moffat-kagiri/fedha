import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/offline_data_service.dart';

class LoansTrackerScreen extends StatefulWidget {
  const LoansTrackerScreen({Key? key}) : super(key: key);

  @override
  State<LoansTrackerScreen> createState() => _LoansTrackerScreenState();
}

class _LoansTrackerScreenState extends State<LoansTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans Tracker'),
        backgroundColor: const Color(0xFF007A39),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'ACTIVE'),
            Tab(text: 'PAID OFF'),
            Tab(text: 'ADD NEW'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveLoansTab(),
          _buildPaidLoansTab(),
          _buildAddLoanTab(),
        ],
      ),
    );
  }
  
  Widget _buildActiveLoansTab() {
    return Consumer<OfflineDataService>(
      builder: (context, dataService, child) {
        // This would normally fetch loans from the service
        return _buildEmptyState(
          'No active loans',
          'You have no active loans at the moment',
          'Add a loan to start tracking it',
          () {
            _tabController.animateTo(2);
          },
        );
      },
    );
  }
  
  Widget _buildPaidLoansTab() {
    return _buildEmptyState(
      'No paid off loans',
      'You have no loans that have been fully paid off',
      'Your paid off loans will appear here',
      null,
    );
  }
  
  Widget _buildAddLoanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Loan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildLoanForm(),
        ],
      ),
    );
  }
  
  Widget _buildLoanForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Loan Name',
                hintText: 'e.g. Car Loan, Mortgage, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Principal Amount (Ksh)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Interest Rate (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Term (Months)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Monthly Payment (Ksh)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007A39),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  // Save loan logic would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loan tracking feature coming soon!'),
                      backgroundColor: Color(0xFF007A39),
                    ),
                  );
                  
                  // Navigate to loan calculator for now
                  Navigator.pushReplacementNamed(context, '/loan_calculator');
                },
                child: const Text(
                  'Save Loan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/loan_calculator');
              },
              child: const Text(
                'Use Loan Calculator Instead',
                style: TextStyle(color: Color(0xFF007A39)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(
    String title, 
    String subtitle, 
    String actionText, 
    VoidCallback? onAction,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined, 
            size: 80, 
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (onAction != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A39),
                foregroundColor: Colors.white,
              ),
              onPressed: onAction,
              child: Text(actionText),
            ),
        ],
      ),
    );
  }
}
