import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_candidate.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import '../services/sms_listener_service.dart';

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
      // Load pending transactions from Hive
      final pendingBox = await Hive.openBox<Transaction>('pending_transactions');
      
      // Convert transactions to candidates for review UI
      _pendingCandidates = pendingBox.values.map((transaction) {
        return TransactionCandidate(
          id: transaction.id,
          rawText: transaction.smsSource ?? 'No SMS source available',
          amount: transaction.amount,
          description: transaction.description,
          date: transaction.date,
          type: transaction.isExpense ? TransactionType.expense : TransactionType.income,
          confidence: 0.9, // Default confidence
          metadata: {
            'recipient': transaction.recipient,
            'reference': transaction.reference,
            'category_id': transaction.categoryId,
          },
        );
      }).toList();
      
      // Sort by date (newest first)
      _pendingCandidates.sort((a, b) => b.date.compareTo(a.date));
      
      // Load reviewed transactions (keep this sample data for now)
      _reviewedCandidates = [];
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading SMS data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TransactionCandidate> _createSampleCandidates() {
    final now = DateTime.now();
    return [
      TransactionCandidate(
        id: '1',
        rawText: 'MPESA: Ksh 1,200.00 sent to John Doe on 15/1/25 at 2:30 PM. New M-PESA balance is Ksh 8,500.00. Transaction cost Ksh 5.00.',
        amount: 1205.00, // Including transaction cost
        description: 'MPESA to John Doe',
        date: now.subtract(const Duration(hours: 2)),
        type: TransactionType.expense,
        confidence: 0.95,
        metadata: {
          'recipient': 'John Doe',
          'transaction_cost': 5.00,
          'balance_after': 8500.00,
          'platform': 'MPESA'
        },
      ),
      TransactionCandidate(
        id: '2',
        rawText: 'You have received Ksh 5,000.00 from Jane Smith. Your new account balance is Ksh 13,500.00.',
        amount: 5000.00,
        description: 'Payment from Jane Smith',
        date: now.subtract(const Duration(hours: 5)),
        type: TransactionType.income,
        confidence: 0.88,
        metadata: {
          'sender': 'Jane Smith',
          'balance_after': 13500.00,
          'platform': 'Bank Transfer'
        },
      ),
      TransactionCandidate(
        id: '3',
        rawText: 'Transaction Alert: Ksh 850 deducted from your account for grocery shopping at Nakumatt on 15/01/25.',
        amount: 850.00,
        description: 'Grocery shopping at Nakumatt',
        date: now.subtract(const Duration(hours: 8)),
        type: TransactionType.expense,
        confidence: 0.92,
        metadata: {
          'merchant': 'Nakumatt',
          'category_hint': 'groceries',
          'platform': 'Bank Card'
        },
      ),
      TransactionCandidate(
        id: '4',
        rawText: 'Airtime purchase: Ksh 100.00 for number 0722123456. Transaction successful.',
        amount: 100.00,
        description: 'Airtime purchase',
        date: now.subtract(const Duration(hours: 12)),
        type: TransactionType.expense,
        confidence: 0.90,
        metadata: {
          'phone_number': '0722123456',
          'category_hint': 'airtime',
          'platform': 'Mobile Money'
        },
      ),
      TransactionCandidate(
        id: '5',
        rawText: 'Salary credit: Your account has been credited with Ksh 45,000.00. Available balance: Ksh 58,500.00',
        amount: 45000.00,
        description: 'Salary payment',
        date: now.subtract(const Duration(days: 1)),
        type: TransactionType.income,
        confidence: 0.98,
        metadata: {
          'balance_after': 58500.00,
          'category_hint': 'salary',
          'platform': 'Bank Transfer'
        },
      ),
    ];
  }

  Future<void> _approveCandidate(TransactionCandidate candidate) async {
    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      
      // Get the pending transaction
      final pendingBox = await Hive.openBox<Transaction>('pending_transactions');
      final pendingTx = pendingBox.values.firstWhere((tx) => tx.id == candidate.id);
      
      // Move pending transaction to regular transactions box
      pendingTx.isPending = false;
      
      // Save to regular transactions
      await dataService.saveTransaction(pendingTx);
      
      // Remove from pending box
      final pendingKey = pendingBox.keys.firstWhere(
        (key) => pendingBox.get(key)?.id == candidate.id
      );
      await pendingBox.delete(pendingKey);
      
      // Update candidate status for UI
      final updatedCandidate = candidate.copyWith(
        status: TransactionStatus.completed,
        transactionId: pendingTx.id,
      );

      setState(() {
        _pendingCandidates.removeWhere((c) => c.id == candidate.id);
        _reviewedCandidates.add(updatedCandidate);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Transaction approved and added to your records'),
          backgroundColor: Color(0xFF007A39),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving transaction: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectCandidate(TransactionCandidate candidate) async {
    try {
      // Remove from pending transactions
      final pendingBox = await Hive.openBox<Transaction>('pending_transactions');
      final pendingKey = pendingBox.keys.firstWhere(
        (key) => pendingBox.get(key)?.id == candidate.id
      );
      await pendingBox.delete(pendingKey);
      
      // Update UI
      final updatedCandidate = candidate.copyWith(status: TransactionStatus.cancelled);
      
      setState(() {
        _pendingCandidates.removeWhere((c) => c.id == candidate.id);
        _reviewedCandidates.add(updatedCandidate);
      });
  
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Transaction rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting transaction: ${e.toString()}'),
          backgroundColor: Colors.red,
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('SMS Review'),
        backgroundColor: const Color(0xFF007A39),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Pending (${_pendingCandidates.length})',
              icon: const Icon(Icons.pending_actions),
            ),
            Tab(
              text: 'Reviewed (${_reviewedCandidates.length})',
              icon: const Icon(Icons.history),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007A39)),
              ),
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
        icon: Icons.check_circle_outline,
        title: 'All caught up! 🎉',
        subtitle: 'No pending SMS transactions to review',
        actionText: 'Refresh',
        onAction: _loadTransactionCandidates,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactionCandidates,
      color: const Color(0xFF007A39),
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
        icon: Icons.history,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A39),
                foregroundColor: Colors.white,
              ),
              child: Text(actionText),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCandidateCard(TransactionCandidate candidate, {required bool isPending}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(red: 158, green: 158, blue: 158, alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with confidence and status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getConfidenceColor(candidate.confidence).withValues(
                red: (_getConfidenceColor(candidate.confidence).red * 255.0).round() & 0xff,
                green: (_getConfidenceColor(candidate.confidence).green * 255.0).round() & 0xff,
                blue: (_getConfidenceColor(candidate.confidence).blue * 255.0).round() & 0xff,
                alpha: 0.1
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  candidate.type == TransactionType.income ? Icons.trending_up : Icons.trending_down,
                  color: candidate.type == TransactionType.income ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.description ?? 'SMS Transaction',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${candidate.date.day}/${candidate.date.month}/${candidate.date.year} at ${candidate.date.hour}:${candidate.date.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: candidate.type == TransactionType.income ? Colors.green : Colors.red,
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // SMS raw text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Original SMS:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    candidate.rawText ?? 'No raw text available',
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Metadata (if available)
          if (candidate.metadata != null && candidate.metadata!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Details:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: candidate.metadata!.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 122, 57, 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF007A39),
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
          
          // Action buttons
          if (isPending) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectCandidate(candidate),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editAndApprove(candidate),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveCandidate(candidate),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007A39),
                        foregroundColor: Colors.white,
                      ),
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
                    ? Colors.green.shade50 
                    : Colors.red.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    candidate.isApproved ? Icons.check_circle : Icons.cancel,
                    color: candidate.isApproved ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    candidate.isApproved ? 'Approved' : 'Rejected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: candidate.isApproved ? Colors.green : Colors.red,
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
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

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.candidate.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.candidate.description ?? '',
    );
    _selectedType = widget.candidate.type == TransactionType.income ? 'income' : 'expense';
    _selectedDate = widget.candidate.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (Ksh)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TransactionType>(
              value: _selectedType == 'income' ? TransactionType.income : TransactionType.expense,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: TransactionType.income, child: const Text('Income')),
                DropdownMenuItem(value: TransactionType.expense, child: const Text('Expense')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value == TransactionType.income ? 'income' : 'expense';
                });
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
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
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ],
                ),
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
        ElevatedButton(
          onPressed: () {
            final updatedCandidate = widget.candidate.copyWith(
              amount: double.tryParse(_amountController.text) ?? widget.candidate.amount,
              description: _descriptionController.text.trim(),
              type: _selectedType == 'income' ? TransactionType.income : TransactionType.expense,
              date: _selectedDate,
            );
            Navigator.pop(context, updatedCandidate);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007A39),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
