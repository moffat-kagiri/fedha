import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/sms_listener_service.dart';
import '../services/auth_service.dart';
import '../services/offline_data_service.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';

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
        SnackBar(
          content: const Text('Error loading pending transactions'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _approveTransaction(Transaction transaction) async {
    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      await dataService.approvePendingTransaction(transaction);
      await dataService.deletePendingTransaction(transaction.id);
      await _loadPendingTransactions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaction approved'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving transaction: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  Future<void> _rejectTransaction(Transaction transaction) async {
    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      await dataService.deletePendingTransaction(transaction.id);
      await _loadPendingTransactions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaction rejected'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting transaction: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  Future<void> _refreshTransactions() async {
    await _loadPendingTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
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
            final smsService = SmsListenerService.instance;
            if (smsService.isListening) {
              await smsService.stopListening();
            } else {
              await smsService.startListening();
            }
            setState(() {});
          } else {
            await _checkPermissions();
          }
        },
        child: Icon(_hasPermissions && SmsListenerService.instance.isListening
            ? Icons.pause_rounded
            : Icons.play_arrow_rounded),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sms_rounded, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'SMS Permission Required',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To automatically detect financial transactions from SMS messages, '
              'Fedha needs permission to read your SMS messages.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _checkPermissions,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No Pending Transactions',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fedha will automatically detect financial transactions from your SMS messages.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              SmsListenerService.instance.isListening
                  ? 'SMS monitoring is active'
                  : 'SMS monitoring is paused',
              style: TextStyle(
                color: SmsListenerService.instance.isListening
                    ? FedhaColors.successGreen
                    : FedhaColors.warningOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'KES ${transaction.amount.toStringAsFixed(2)}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: transaction.type == TransactionType.expense
                                  ? FedhaColors.errorRed
                                  : FedhaColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(transaction.date),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (transaction.smsSource != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.smsSource!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
                    FilledButton(
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