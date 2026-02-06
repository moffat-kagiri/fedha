import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../services/offline_data_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/unified_sync_service.dart';
import '../services/connectivity_service.dart';
import '../models/loan.dart' as domain_loan;

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
    _tabController = TabController(length: 2, vsync: this);
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
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active Loans'),
            Tab(text: 'Paid Off Loans'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active tab renders the persistent LoansTrackerTab
          const LoansTrackerTab(),
          _buildPaidLoansTab(),
        ],
      ),
    );
  }

  Widget _buildPaidLoansTab() {
    return Center(
      child: Text('No paid off loans yet', style: TextStyle(color: Colors.grey.shade700)),
    );
  }
}

// ========================= Loans Tracker Tab ================================

class LoansTrackerTab extends StatefulWidget {
  const LoansTrackerTab({super.key});

  @override
  State<LoansTrackerTab> createState() => _LoansTrackerTabState();
}

class _LoansTrackerTabState extends State<LoansTrackerTab> {
  final List<Loan> _loans = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);

    final profileId = AuthService.instance.profileId;
    if (profileId == null || profileId.isEmpty) {
      if (mounted) {
        setState(() {
          _loans.clear();
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final svc = Provider.of<OfflineDataService>(context, listen: false);
      final domainLoans = await svc.getAllLoans(profileId);

      // ✅ Explicit type and fixed constructor
      final List<Loan> mapped = domainLoans.map((d) {
        final principal = d.principalAmount;
        final start = d.startDate;
        final end = d.endDate;
        final totalMonths = _monthsBetween(start, end).clamp(1, 1000);
        final remainingMonths = (_monthsBetween(DateTime.now(), end)).clamp(0, totalMonths);
        final monthlyPayment = _computeMonthlyPayment(principal, d.interestRate, totalMonths);

        return Loan(
          id: int.tryParse(d.id) ?? 0,
          remoteId: d.remoteId,
          name: d.name,
          principal: principal,
          interestRate: d.interestRate,
          interestModel: d.interestModel,
          totalMonths: totalMonths,
          remainingMonths: remainingMonths,
          monthlyPayment: monthlyPayment,
          startDate: start,
          endDate: end,
          isSynced: d.isSynced,
          description: d.description,
          createdAt: d.createdAt,
          updatedAt: d.updatedAt,
          isDeleted: d.isDeleted,  // ✅ NEW: Include deletion status
          deletedAt: d.deletedAt,  // ✅ NEW: Include deletion timestamp
        );
      }).toList();

      // ✅ CRITICAL: Filter out soft-deleted loans
      final activeLoans = mapped.where((loan) => !loan.isDeleted).toList();

      if (mounted) {
        setState(() {
          _loans
            ..clear()
            ..addAll(activeLoans);  // ✅ Only add non-deleted loans
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load loans: $e')));
    }
  }

  int _monthsBetween(DateTime a, DateTime b) {
    final years = b.year - a.year;
    final months = b.month - a.month;
    var diff = years * 12 + months;
    if (b.day < a.day) diff -= 1;
    return diff < 0 ? 0 : diff;
  }

  double _computeMonthlyPayment(double principal, double annualRatePercent, int months) {
    if (months <= 0) return 0.0;
    final monthlyRate = annualRatePercent / 100.0 / 12.0;
    if (monthlyRate <= 0) return principal / months;
    final powFactor = math.pow(1 + monthlyRate, months);
    final payment = principal * (monthlyRate * powFactor) / (powFactor - 1);
    return payment.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileId = AuthService.instance.profileId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loans Tracker',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track and manage all your loans in one place.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Add Loan Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (profileId == null || profileId.isEmpty) {
                  Navigator.pushNamed(context, '/login');
                  return;
                }
                _showAddLoanDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Loan'),
            ),
          ),

          const SizedBox(height: 20),

          if (profileId == null || profileId.isEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 48),
                    const SizedBox(height: 12),
                    Text('Sign in to view and manage your loans', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            )
          else if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loans.isEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No loans tracked yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first loan to start tracking payments and balances',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _loans.length,
              itemBuilder: (context, index) {
                final loan = _loans[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                                    loan.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // ✅ NEW: Show interest model
                                  Text(
                                    '${loan.interestModel.capitalize()} Interest',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditLoanDialog(loan, index);
                                } else if (value == 'delete') {
                                  _deleteLoan(index);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                                      const SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildLoanInfo('Principal', 'KES ${loan.principal.toStringAsFixed(0)}'),
                            ),
                            Expanded(
                              child: _buildLoanInfo('Rate', '${loan.interestRate.toStringAsFixed(1)}%'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildLoanInfo('Monthly Payment', 'KES ${loan.monthlyPayment.toStringAsFixed(0)}'),
                            ),
                            Expanded(
                              child: _buildLoanInfo('Remaining', '${loan.remainingMonths} months'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (loan.totalMonths - loan.remainingMonths) / loan.totalMonths,
                          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            loan.isActive ? theme.colorScheme.primary : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress: ${((loan.totalMonths - loan.remainingMonths) / loan.totalMonths * 100).toStringAsFixed(1)}% completed',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            // ✅ NEW: Show active/overdue status
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: loan.isActive 
                                  ? (loan.isOverdue ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2))
                                  : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                loan.statusDisplay,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: loan.statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLoanInfo(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showAddLoanDialog() {
    _showLoanDialog();
  }

  void _showEditLoanDialog(Loan loan, int index) {
    _showLoanDialog(loan: loan, index: index);
  }

  void _showLoanDialog({Loan? loan, int? index}) {
    final nameController = TextEditingController(text: loan?.name ?? '');
    final principalController = TextEditingController(text: loan?.principal.toString() ?? '');
    final rateController = TextEditingController(text: loan?.interestRate.toString() ?? '');
    // ✅ NEW: Interest model dropdown value
    String interestModel = loan?.interestModel ?? 'simple';
    
    DateTime startDate = loan?.startDate ?? DateTime.now();
    DateTime endDate = loan?.endDate ?? DateTime.now().add(Duration(days: (loan?.totalMonths ?? 12) * 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(loan == null ? 'Add New Loan' : 'Edit Loan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Loan Name',
                    hintText: 'e.g., Car Loan, Mortgage',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: principalController,
                  decoration: const InputDecoration(
                    labelText: 'Principal Amount (KES)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rateController,
                  decoration: const InputDecoration(
                    labelText: 'Interest Rate (%)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                // ✅ NEW: Interest model dropdown
                DropdownButtonFormField<String>(
                  value: interestModel,
                  decoration: const InputDecoration(
                    labelText: 'Interest Model',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'simple',
                      child: Text('Simple Interest'),
                    ),
                    DropdownMenuItem(
                      value: 'compound',
                      child: Text('Compound Interest'),
                    ),
                    DropdownMenuItem(
                      value: 'reducingBalance',
                      child: Text('Reducing Balance'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => interestModel = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date'),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  startDate = DateTime(picked.year, picked.month, picked.day);
                                  if (endDate.isBefore(startDate)) {
                                    endDate = startDate.add(const Duration(days: 30));
                                  }
                                });
                              }
                            },
                            child: Text('${startDate.toLocal().toIso8601String().split('T').first}'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Date'),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  endDate = DateTime(picked.year, picked.month, picked.day);
                                  if (endDate.isBefore(startDate)) {
                                    startDate = endDate.subtract(const Duration(days: 30));
                                  }
                                });
                              }
                            },
                            child: Text('${endDate.toLocal().toIso8601String().split('T').first}'),
                          ),
                        ],
                      ),
                    ),
                  ],
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
              onPressed: () async {
                final name = nameController.text.trim();
                final principal = double.tryParse(principalController.text) ?? 0;
                final rate = double.tryParse(rateController.text) ?? 0;

                if (name.isEmpty || principal <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid loan details')),
                  );
                  return;
                }

                final profileId = AuthService.instance.profileId;
                if (profileId == null || profileId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please sign in to save loans')),
                  );
                  return;
                }

                try {
                  final svc = Provider.of<OfflineDataService>(context, listen: false);
                  final syncService = Provider.of<UnifiedSyncService>(context, listen: false);

                  // ✅ Use ApiClient helper method to prepare data
                  final loanData = ApiClient.prepareLoanData(
                    profileId: profileId,
                    name: name,
                    principalAmount: principal,
                    interestRate: rate,
                    interestModel: interestModel,
                    startDate: startDate,
                    endDate: endDate,
                    currency: 'KES',
                  );

                  // Create domain loan from prepared data
                  final domainLoan = domain_loan.Loan(
                    id: loan?.id?.toString(),
                    remoteId: loan?.remoteId,
                    name: name,
                    principalAmount: principal,
                    currency: 'KES',
                    interestRate: rate,
                    interestModel: interestModel,
                    startDate: startDate,
                    endDate: endDate,
                    profileId: profileId,
                    description: null,
                    isSynced: loan?.isSynced ?? false,
                    createdAt: loan?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  if (loan?.id != null) {
                    // Update: delete old loan and create new one (same as transactions)
                    if (loan!.remoteId != null && loan.remoteId!.isNotEmpty) {
                      // Old loan has been synced - mark it for deletion in next sync
                      await svc.deleteLoan(loan.id.toString());
                    } else {
                      // Old loan never reached backend - hard delete it
                      await svc.deleteLoan(loan.id.toString());
                    }
                    
                    // Save new loan with updated values
                    await svc.saveLoan(domainLoan);
                  } else {
                    await svc.saveLoan(domainLoan);
                  }

                  await _loadLoans();

                  if (mounted) Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loan == null ? 'Loan added successfully!' : 'Loan updated successfully!'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save loan: $e')),
                  );
                }
              },
              child: Text(loan == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteLoan(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan'),
        content: const Text('Are you sure you want to delete this loan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final loan = _loans[index];
                final offlineService = Provider.of<OfflineDataService>(context, listen: false);
                final authService = Provider.of<AuthService>(context, listen: false);
                final apiClient = Provider.of<ApiClient>(context, listen: false);
                
                final profileId = authService.currentProfile?.id ?? '';
                if (profileId.isEmpty) {
                  throw Exception('No active profile found');
                }
                
                if (loan.id != null) {
                  // ✅ ENHANCED: Use immediate sync to prevent restoration on biometric unlock
                  await offlineService.deleteLoanWithSync(
                    loanId: loan.id.toString(),
                    profileId: profileId,
                    deleteToBackend: apiClient.deleteLoans,
                  );
                }
                
                await _loadLoans(); // Reload to refresh the list
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Loan deleted successfully!'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete loan: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ================================= Models ===================================
class Loan {
  final int? id;
  final String? remoteId;
  final String name;
  final double principal;
  final double interestRate;
  final String interestModel;
  final int totalMonths;
  final int remainingMonths;
  final double monthlyPayment;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isSynced;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isDeleted;  // ✅ NEW: Track deletion status
  final DateTime? deletedAt;  // ✅ NEW: Track when deleted

  Loan({
    this.id,
    this.remoteId,
    required this.name,
    required this.principal,
    required this.interestRate,
    required this.interestModel,
    required this.totalMonths,
    required this.remainingMonths,
    required this.monthlyPayment,
    this.startDate,
    this.endDate,
    this.isSynced,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.isDeleted,  // ✅ NEW
    this.deletedAt,  // ✅ NEW
  });

  // Getters (not constructor parameters)
  bool get isActive {
    if (startDate == null || endDate == null) return false;
    final now = DateTime.now();
    return startDate!.isBefore(now) && endDate!.isAfter(now);
  }

  bool get isOverdue => endDate?.isBefore(DateTime.now()) ?? false;
  
  String get statusDisplay {
    if (isOverdue) return 'Overdue ⚠️';
    if (isActive) return 'Active 📍';
    return 'Completed ✅';
  }
  
  Color get statusColor {
    if (isOverdue) return Colors.orange;
    if (isActive) return Colors.green;
    return const Color(0xFF007A39);
  }
}
