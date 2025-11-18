import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/sms_listener_service.dart';
import '../services/auth_service.dart';
import '../services/offline_data_service.dart';
import '../models/enums.dart'; // This should contain TransactionType

class SmsTransactionReviewScreen extends StatefulWidget {
  const SmsTransactionReviewScreen({Key? key}) : super(key: key);

  @override
  _SmsTransactionReviewScreenState createState() => _SmsTransactionReviewScreenState();
}

class _SmsTransactionReviewScreenState extends State<SmsTransactionReviewScreen> {
  List<Transaction> _pendingTransactions = [];
  bool _isLoading = true;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _loadPendingTransactions();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final smsService = SmsListenerService.instance;
    final hasPermissions = await smsService.checkAndRequestPermissions();
    
    setState(() {
      _hasPermissions = hasPermissions;
    });
    
    if (hasPermissions && !smsService.isListening) {
      await smsService.startListening();
    }
  }

  Future<void> _loadPendingTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = int.tryParse(authService.currentProfile?.id ?? '') ?? 0;
      final pending = await dataService.getPendingTransactions(profileId);
      setState(() {
        _pendingTransactions = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading pending transactions')),
      );
    }
  }

  Future<void> _approveTransaction(Transaction transaction) async {
    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      // Save to official transactions
      await dataService.approvePendingTransaction(transaction);
      // Remove from pending
  await dataService.deletePendingTransaction(transaction.id);
      // Refresh list
      await _loadPendingTransactions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction approved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving transaction: $e')),
      );
    }
  }
  
  Future<void> _rejectTransaction(Transaction transaction) async {
    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
  await dataService.deletePendingTransaction(transaction.id);
      await _loadPendingTransactions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting transaction: $e')),
      );
    }
  }
  
  Future<void> _refreshTransactions() async {
    await _loadPendingTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text('SMS Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_hasPermissions) {
            // Toggle SMS listener
            final smsService = SmsListenerService.instance;
            if (smsService.isListening) {
              await smsService.stopListening();
            } else {
              await smsService.startListening();
            }
            setState(() {}); // Refresh UI
          } else {
            // Request permissions
            await _checkPermissions();
          }
        },
        child: Icon(_hasPermissions && SmsListenerService.instance.isListening
            ? Icons.pause
            : Icons.play_arrow),
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasPermissions) {
      return _buildPermissionRequest();
    }
    
    if (_pendingTransactions.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildTransactionList();
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sms, size: 64, color: Theme.of(context).colorScheme.surface),
            const SizedBox(height: 16),
            const Text(
              'SMS Permission Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'To automatically detect financial transactions from SMS messages, '
              'Fedha needs permission to read your SMS messages.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkPermissions,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox, size: 64, color: Theme.of(context).colorScheme.surface),
            const SizedBox(height: 16),
            const Text(
              'No Pending Transactions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fedha will automatically detect financial transactions from your SMS messages.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              SmsListenerService.instance.isListening
                  ? 'SMS monitoring is active'
                  : 'SMS monitoring is paused',
              style: TextStyle(
                color: SmsListenerService.instance.isListening
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      itemCount: _pendingTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _pendingTransactions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${transaction.description ?? 'Transaction'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'KES ${transaction.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: transaction.type == TransactionType.expense
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(transaction.date),
                      style: const TextStyle(color: Theme.of(context).colorScheme.surface),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (transaction.smsSource != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.smsSource!,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.surface),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _rejectTransaction(transaction),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => _approveTransaction(transaction),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
