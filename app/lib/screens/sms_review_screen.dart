// lib/screens/sms_review_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction_candidate.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import '../services/sms_listener_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/transaction_operations_helper.dart';
import '../services/transaction_event_service.dart'; 

class SmsReviewScreen extends StatefulWidget {
  const SmsReviewScreen({Key? key}) : super(key: key);

  @override
  State<SmsReviewScreen> createState() => _SmsReviewScreenState();
}

class _SmsReviewScreenState extends State<SmsReviewScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<TransactionCandidate> _pendingCandidates = [];
  List<TransactionCandidate> _reviewedCandidates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactionCandidates();
    SmsListenerService.instance.messageStream.listen((_) {
      _loadTransactionCandidates();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactionCandidates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = authService.currentProfile?.id ?? '';
      final pendingTxList = await dataService.getPendingTransactions(profileId);
      
      _pendingCandidates = pendingTxList.map((transaction) {
        final raw = transaction.smsSource ?? '';
        final lower = raw.toLowerCase();
        final txType = lower.contains('sent')
            ? Type.expense
            : lower.contains('received')
                ? Type.income
                : ((transaction.isExpense ?? false) ? Type.expense : Type.income);
        
        return TransactionCandidate(
          id: transaction.id!,
          rawText: raw.isNotEmpty ? raw : 'No SMS source available',
          amount: transaction.amount,
          description: transaction.description,
          date: transaction.date,
          type: txType,
          confidence: 0.9,
          metadata: {
            'recipient': transaction.recipient ?? 'Unknown',
            'reference': transaction.reference ?? 'N/A',
            'category': transaction.category ?? '',
            'merchantName': transaction.merchantName,
          },
        );
      }).toList();
      
      _pendingCandidates.sort((a, b) => b.date.compareTo(a.date));
      _reviewedCandidates = [];
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading SMS data: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveCandidate(TransactionCandidate candidate) async {
    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final eventService = Provider.of<TransactionEventService>(context, listen: false);
      final profileId = authService.currentProfile?.id ?? '';
      
      // Determine category from metadata or use default
      String category = candidate.category ?? '';
      if (category.isEmpty) {
        category = candidate.type == Type.income 
            ? 'other_income'
            : 'other_expense';
      }
      
      // Create transaction with all extracted fields
      final tx = Transaction(
        id: candidate.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        amount: candidate.amount,
        description: candidate.description ?? 'SMS Transaction',
        date: candidate.date,
        smsSource: candidate.rawText,
        category: category,
        type: candidate.type == Type.expense ? 'expense' : 'income',
        isExpense: candidate.type == Type.expense,
        profileId: profileId,
        paymentMethod: 'cash',
        recipient: candidate.metadata?['recipient'] as String?,
        reference: candidate.metadata?['reference'] as String?,
        merchantName: candidate.metadata?['merchantName'] as String?,
      );
      
      // USE TRANSACTION OPERATIONS HELPER FOR APPROVAL
      final success = await TransactionOperations.approvePendingTransaction(
        pendingTransaction: tx,
        offlineService: dataService,
      );
      
      if (success) {
        await dataService.saveTransaction(tx);
        await eventService.onTransactionApproved(tx);
        await eventService.onTransactionCreated(tx);
        
        // Delete from pending
        if (candidate.id != null) {
          await dataService.deletePendingTransaction(candidate.id!);
        }
        
        final updatedCandidate = candidate.copyWith(
          status: TransactionStatus.completed,
          transactionId: tx.id,
        );
        
        setState(() {
          _pendingCandidates.removeWhere((c) => c.id == candidate.id);
          _reviewedCandidates.add(updatedCandidate);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Transaction approved • ${tx.type == "expense" ? "Budget" : "Goal"} updated',
                ),
              ],
            ),
            backgroundColor: FedhaColors.successGreen,
          ),
        );
      } else {
        throw Exception('Failed to approve transaction');
      }
    } catch (e, stackTrace) {
      print('Error approving transaction: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving transaction: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _approveAllPendingTransactions() async {
    if (_pendingCandidates.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve All Transactions'),
        content: Text(
          'Are you sure you want to approve all ${_pendingCandidates.length} pending transactions?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                final dataService = Provider.of<OfflineDataService>(context, listen: false);
                final authService = Provider.of<AuthService>(context, listen: false);
                final profileId = authService.currentProfile?.id ?? '';
                
                // Convert candidates to transactions
                final List<Transaction> pendingTransactions = _pendingCandidates.map((candidate) {
                  String category = candidate.category ?? '';
                  if (category.isEmpty) {
                    category = candidate.type == Type.income 
                        ? 'other_income'
                        : 'other_expense';
                  }
                  
                  return Transaction(
                    id: candidate.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    amount: candidate.amount,
                    description: candidate.description ?? 'SMS Transaction',
                    date: candidate.date,
                    smsSource: candidate.rawText,
                    category: category,
                    type: candidate.type.toString().split('.').last,
                    isExpense: candidate.type == Type.expense,
                    profileId: profileId,
                    paymentMethod: 'cash',
                    recipient: candidate.metadata?['recipient'] as String?,
                    reference: candidate.metadata?['reference'] as String?,
                    merchantName: candidate.metadata?['merchantName'] as String?,
                  );
                }).toList();
                
                // Batch approve all transactions
                final approvedCount = await TransactionOperations.batchApprovePendingTransactions(
                  pendingTransactions: pendingTransactions,
                  offlineService: dataService,
                );
                
                // Delete all pending transactions
                for (final candidate in _pendingCandidates) {
                  if (candidate.id != null) {
                    await dataService.deletePendingTransaction(candidate.id!);
                  }
                }
                
                // Update reviewed candidates
                final updatedCandidates = _pendingCandidates.map((candidate) => candidate.copyWith(
                  status: TransactionStatus.completed,
                )).toList();
                
                // Reload lists
                setState(() {
                  _reviewedCandidates.addAll(updatedCandidates);
                  _pendingCandidates.clear();
                });
                
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Approved $approvedCount transactions • All budgets and goals updated'),
                        ],
                      ),
                      backgroundColor: FedhaColors.successGreen,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                print('Error approving all transactions: $e');
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Approve All'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectCandidate(TransactionCandidate candidate) async {
    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      await dataService.deletePendingTransaction(candidate.id);
      final updated = candidate.copyWith(status: TransactionStatus.cancelled);
      setState(() {
        _pendingCandidates.removeWhere((c) => c.id == candidate.id);
        _reviewedCandidates.add(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Transaction rejected'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting transaction: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _editAndApprove(TransactionCandidate candidate) async {
    final result = await showDialog<TransactionCandidate>(
      context: context,
      builder: (context) => _EditCandidateDialog(candidate: candidate),
    );

    if (result != null) {
      await _approveCandidate(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.message_rounded),
        tooltip: 'Enter SMS manually',
        onPressed: () async {
          final raw = await showDialog<String>(
            context: context,
            builder: (context) {
              String input = '';
              return AlertDialog(
                title: const Text('Manual SMS Entry'),
                content: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Paste SMS content here',
                  ),
                  onChanged: (v) => input = v,
                  maxLines: 5,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text('Cancel')
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, input), 
                    child: const Text('Submit')
                  ),
                ],
              );
            },
          );
          if (raw != null && raw.trim().isNotEmpty) {
            await SmsListenerService.instance.processManualSms(raw.trim());
            _loadTransactionCandidates();
          }
        },
      ),
      appBar: AppBar(
        title: const Text('SMS Review'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Pending (${_pendingCandidates.length})',
              icon: const Icon(Icons.pending_actions_rounded),
            ),
            Tab(
              text: 'Reviewed (${_reviewedCandidates.length})',
              icon: const Icon(Icons.history_rounded),
            ),
          ],
        ),
        actions: [
          if (_pendingCandidates.isNotEmpty)
            TextButton.icon(
              onPressed: _approveAllPendingTransactions,
              icon: const Icon(Icons.done_all, color: Colors.white),
              label: const Text('Approve All', style: TextStyle(color: Colors.white)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTransactionCandidates,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildReviewedTab(),
              ],
            ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingCandidates.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'All caught up! 🎉',
        subtitle: 'No pending SMS transactions to review',
        actionText: 'Refresh',
        onAction: _loadTransactionCandidates,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactionCandidates,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingCandidates.length,
        itemBuilder: (context, index) {
          final candidate = _pendingCandidates[index];
          return _buildCandidateCard(candidate, isPending: true);
        },
      ),
    );
  }

  Widget _buildReviewedTab() {
    if (_reviewedCandidates.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'No reviewed transactions',
        subtitle: 'Transactions you approve or reject will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviewedCandidates.length,
      itemBuilder: (context, index) {
        final candidate = _reviewedCandidates[index];
        return _buildCandidateCard(candidate, isPending: false);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCandidateCard(TransactionCandidate candidate, {required bool isPending}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getConfidenceColor(candidate.confidence).withAlpha(26),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  candidate.type == Type.income ? 
                    Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: candidate.type == Type.income ? 
                    FedhaColors.successGreen : FedhaColors.errorRed,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.description ?? 'SMS Transaction',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${candidate.date.day}/${candidate.date.month}/${candidate.date.year} at ${candidate.date.hour}:${candidate.date.minute.toString().padLeft(2, '0')}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Ksh ${candidate.amount.toStringAsFixed(2)}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: candidate.type == Type.income ? 
                          FedhaColors.successGreen : FedhaColors.errorRed,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(candidate.confidence),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(candidate.confidence * 100).round()}% sure',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original SMS:',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    candidate.rawText ?? 'No raw text available',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          
          if (candidate.metadata != null && candidate.metadata!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details:',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: candidate.metadata!.entries.where((entry) {
                      // Filter out empty or null values
                      return entry.value != null && 
                             entry.value.toString().isNotEmpty &&
                             entry.value.toString() != 'N/A';
                    }).map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_formatKey(entry.key)}: ${entry.value}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          if (isPending) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectCandidate(candidate),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editAndApprove(candidate),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _approveCandidate(candidate),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: candidate.isApproved 
                    ? FedhaColors.successGreen.withOpacity(0.1)
                    : FedhaColors.errorRed.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    candidate.isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: candidate.isApproved ? FedhaColors.successGreen : FedhaColors.errorRed,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    candidate.isApproved ? 'Approved' : 'Rejected',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: candidate.isApproved ? FedhaColors.successGreen : FedhaColors.errorRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatKey(String key) {
    // Format keys to be more readable
    switch (key) {
      case 'recipient':
        return 'Platform';
      case 'reference':
        return 'Ref';
      case 'merchantName':
        return 'Merchant';
      case 'category':
        return 'Category';
      default:
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return FedhaColors.successGreen;
    if (confidence >= 0.6) return FedhaColors.warningOrange;
    return FedhaColors.errorRed;
  }
}

class _EditCandidateDialog extends StatefulWidget {
  final TransactionCandidate candidate;

  const _EditCandidateDialog({required this.candidate});

  @override
  State<_EditCandidateDialog> createState() => _EditCandidateDialogState();
}

class _EditCandidateDialogState extends State<_EditCandidateDialog> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _selectedType;
  late DateTime _selectedDate;
  late String _selectedCategory;

  // Available categories
  final List<Map<String, dynamic>> _categories = [
    {'value': 'food', 'label': '🍽️ Food & Dining', 'isExpense': true},
    {'value': 'transport', 'label': '🚗 Transport', 'isExpense': true},
    {'value': 'utilities', 'label': '💡 Utilities', 'isExpense': true},
    {'value': 'shopping', 'label': '🛍️ Shopping', 'isExpense': true},
    {'value': 'entertainment', 'label': '🎬 Entertainment', 'isExpense': true},
    {'value': 'healthcare', 'label': '🏥 Healthcare', 'isExpense': true},
    {'value': 'education', 'label': '📚 Education', 'isExpense': true},
    {'value': 'savings', 'label': '💰 Savings', 'isExpense': false},
    {'value': 'salary', 'label': '💼 Salary', 'isExpense': false},
    {'value': 'business', 'label': '💼 Business Income', 'isExpense': false},
    {'value': 'investment', 'label': '📈 Investment', 'isExpense': false},
    {'value': 'other_expense', 'label': '📝 Other Expense', 'isExpense': true},
    {'value': 'other_income', 'label': '💵 Other Income', 'isExpense': false},
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.candidate.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.candidate.description ?? '',
    );
    _selectedType = widget.candidate.type == Type.income ? 'income' : 'expense';
    _selectedDate = widget.candidate.date;
    _selectedCategory = widget.candidate.category ?? 
        (_selectedType == 'income' ? 'other_income' : 'other_expense');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCategories {
    return _categories.where((cat) {
      return (_selectedType == 'expense' && cat['isExpense']) ||
             (_selectedType == 'income' && !cat['isExpense']);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Transaction'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (Ksh)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Type>(
              value: _selectedType == 'income' ? Type.income : Type.expense,
              decoration: const InputDecoration(
                labelText: 'Type',
              ),
              items: const [
                DropdownMenuItem(value: Type.income, child: Text('Income')),
                DropdownMenuItem(value: Type.expense, child: Text('Expense')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value == Type.income ? 'income' : 'expense';
                  // Reset category when type changes
                  _selectedCategory = _selectedType == 'income' ? 'other_income' : 'other_expense';
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              items: _filteredCategories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat['value'] as String,
                  child: Text(cat['label'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? _selectedCategory;
                });
              },
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 90)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded),
                  const SizedBox(width: 8),
                  Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final updatedCandidate = widget.candidate.copyWith(
              amount: double.tryParse(_amountController.text) ?? widget.candidate.amount,
              description: _descriptionController.text.trim(),
              type: _selectedType == 'income' ? Type.income : Type.expense,
              date: _selectedDate,
              category: _selectedCategory,
            );
            Navigator.pop(context, updatedCandidate);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
