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
      
      // ✅ FIXED: Use string profileId directly
      final profileId = authService.currentProfile?.id ?? '';
      
      if (profileId.isEmpty) {
        throw Exception('No active profile found');
      }

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
          content: Text('Error loading pending transactions: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          content: const Text('Transaction approved successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving transaction: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting transaction: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
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
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
            Icon(
              Icons.sms_rounded, 
              size: 64, 
              color: colorScheme.primary.withOpacity(0.7)
            ),
            const SizedBox(height: 24),
            Text(
              'SMS Permission Required',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To automatically detect financial transactions from SMS messages, '
              'Fedha needs permission to read your SMS messages.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _checkPermissions,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Grant Permission'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
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
            Icon(
              Icons.inbox_rounded, 
              size: 64, 
              color: colorScheme.outline.withOpacity(0.5)
            ),
            const SizedBox(height: 24),
            Text(
              'No Pending Transactions',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fedha will automatically detect financial transactions from your SMS messages '
              'and show them here for review.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: SmsListenerService.instance.isListening
                        ? FedhaColors.successGreen
                        : FedhaColors.warningOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    SmsListenerService.instance.isListening
                        ? 'SMS monitoring is active'
                        : 'SMS monitoring is paused',
                    style: textTheme.bodyMedium?.copyWith(
                      color: SmsListenerService.instance.isListening
                          ? FedhaColors.successGreen
                          : FedhaColors.warningOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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

    return Column(
      children: [
        // Header with count
        Container(
          padding: const EdgeInsets.all(16),
          color: colorScheme.surfaceVariant,
          child: Row(
            children: [
              Icon(Icons.pending_actions_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                '${_pendingTransactions.length} Pending Transactions',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Transactions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pendingTransactions.length,
            itemBuilder: (context, index) {
              final transaction = _pendingTransactions[index];
              return _buildTransactionCard(transaction, colorScheme, textTheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction, ColorScheme colorScheme, TextTheme textTheme) {
    final isExpense = transaction.type == TransactionType.expense;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description ?? 'Transaction',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'KES ${transaction.amount.toStringAsFixed(2)}',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isExpense ? FedhaColors.errorRed : FedhaColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isExpense 
                        ? FedhaColors.errorRed.withOpacity(0.1)
                        : FedhaColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpense ? 'Expense' : 'Income',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isExpense ? FedhaColors.errorRed : FedhaColors.successGreen,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Date and source
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  _formatDate(transaction.date),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (transaction.smsSource != null) ...[
                  Icon(Icons.sms_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    transaction.smsSource!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _rejectTransaction(transaction),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _approveTransaction(transaction),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}