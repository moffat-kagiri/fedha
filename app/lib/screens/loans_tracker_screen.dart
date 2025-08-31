import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;

import '../data/app_database.dart';
import '../services/offline_data_service.dart';
import '../services/auth_service.dart';
import '../widgets/loan_card.dart';
import 'loan_edit_screen.dart';

class LoansTrackerScreen extends StatefulWidget {
  const LoansTrackerScreen({super.key});

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
    return Consumer2<AppDatabase, AuthService>(
      builder: (context, db, auth, child) {
        final profileId = int.tryParse(auth.currentProfile?.id ?? '0') ?? 0;
        
        return StreamBuilder<List<Loan>>(
          stream: (db.select(db.loans)
            ..where((t) => t.profileId.equals(profileId))
            ..where((t) => t.endDate.isBiggerThan(Variable(DateTime.now())))
            ..orderBy([
              (t) => OrderingTerm(expression: t.endDate),
            ])
          ).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(
                'No active loans',
                'You have no active loans at the moment',
                'Add a loan to start tracking it',
                () {
                  _tabController.animateTo(2);
                },
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final loan = snapshot.data![index];
                return LoanCard(
                  loan: loan,
                  onEdit: () => _editLoan(loan),
                  onDelete: () => _deleteLoan(loan),
                );
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildPaidLoansTab() {
    return Consumer2<AppDatabase, AuthService>(
      builder: (context, db, auth, child) {
        final profileId = int.tryParse(auth.currentProfile?.id ?? '0') ?? 0;
        
        return StreamBuilder<List<Loan>>(
          stream: (db.select(db.loans)
            ..where((t) => t.profileId.equals(profileId))
            ..where((t) => t.endDate.isSmallerOrEqual(Variable(DateTime.now())))
            ..orderBy([
              (t) => OrderingTerm(expression: t.endDate, mode: OrderingMode.desc),
            ])
          ).watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(
                'No paid off loans',
                'You have no loans that have been fully paid off',
                'Your paid off loans will appear here',
                null,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final loan = snapshot.data![index];
                return LoanCard(
                  loan: loan,
                  onEdit: () => _editLoan(loan),
                  onDelete: () => _deleteLoan(loan),
                );
              },
            );
          },
        );
      },
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
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final principalController = TextEditingController();
    final interestController = TextEditingController();
    final termController = TextEditingController();

    return Form(
      key: formKey,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Loan Name',
                  hintText: 'e.g. Car Loan, Mortgage, etc.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a loan name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: principalController,
                decoration: const InputDecoration(
                  labelText: 'Principal Amount (KES)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the principal amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: interestController,
                decoration: const InputDecoration(
                  labelText: 'Annual Interest Rate (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the interest rate';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid rate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: termController,
                decoration: const InputDecoration(
                  labelText: 'Term (Months)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the loan term';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number of months';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final principal = double.parse(principalController.text);
                    final interestRate = double.parse(interestController.text);
                    final termMonths = int.parse(termController.text);
                    
                    final now = DateTime.now();
                    final startDate = now;
                    final endDate = now.add(Duration(days: termMonths * 30));
                    
                    final db = Provider.of<AppDatabase>(context, listen: false);
                    final auth = Provider.of<AuthService>(context, listen: false);
                    final profileId = int.tryParse(auth.currentProfile?.id ?? '0') ?? 0;
                    
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final theme = Theme.of(context);
                    
                    try {
                      await db.into(db.loans).insert(
                        LoansCompanion.insert(
                          name: nameController.text,
                          principalMinor: (principal * 100).toInt(),
                          currency: const Value('KES'),
                          interestRate: Value(interestRate),
                          startDate: startDate,
                          endDate: endDate,
                          profileId: profileId,
                        ),
                      );
                      
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: const Text('Loan added successfully'),
                            backgroundColor: theme.primaryColor,
                          ),
                        );
                        _tabController.animateTo(0); // Switch to active loans tab
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Error adding loan: ${e.toString()}'),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Add Loan'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/loan_calculator');
                },
                child: const Text(
                  'Use Loan Calculator',
                  style: TextStyle(color: Color(0xFF007A39)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _editLoan(Loan loan) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => LoanEditScreen(loan: loan),
      ),
    );
  }

  void _deleteLoan(Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan'),
        content: Text('Are you sure you want to delete "${loan.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final theme = Theme.of(context);
              final db = Provider.of<AppDatabase>(context, listen: false);
              
              try {
                await (db.delete(db.loans)..where((t) => t.id.equals(loan.id))).go();
                
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('${loan.name} deleted'),
                      backgroundColor: theme.primaryColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error deleting loan: ${e.toString()}'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
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
