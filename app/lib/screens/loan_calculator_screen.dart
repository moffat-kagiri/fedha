import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/currency_service.dart';
import '../utils/loan_calculator.dart';
import 'dart:math' as math;
import '../models/enums.dart';

class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen> with TickerProviderStateMixin {
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Calculator'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withAlpha((0.7 * 255).round()),
          indicatorColor: theme.colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'Payment Calculator', icon: Icon(Icons.calculate)),
            Tab(text: 'Interest Solver', icon: Icon(Icons.trending_up)),
            Tab(text: 'Loans Tracker', icon: Icon(Icons.account_balance_wallet)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PaymentCalculatorTab(),
          InterestSolverTab(),
          LoansTrackerTab(),
        ],
      ),
    );
  }
}

class PaymentCalculatorTab extends StatefulWidget {
  const PaymentCalculatorTab({super.key});

  @override
  State<PaymentCalculatorTab> createState() => _PaymentCalculatorTabState();
}

class _PaymentCalculatorTabState extends State<PaymentCalculatorTab> {
  final _formKey = GlobalKey<FormState>();
  final _principalController = TextEditingController();
  final _annualRateController = TextEditingController();
  final _termYearsController = TextEditingController();
  
  InterestModel _interestModel = InterestModel.reducingBalance;
  String _paymentFrequency = 'Monthly';
  bool _isCalculating = false;
  Map<String, dynamic>? _result;
  
  // Payment frequency options
  final List<String> _frequencyOptions = ['Monthly', 'Quarterly', 'Semi-annually', 'Annually'];
  final Map<String, int> _frequencyMap = {
    'Monthly': 12,
    'Quarterly': 4,
    'Semi-annually': 2,
    'Annually': 1
  };
  
  @override
  void dispose() {
    _principalController.dispose();
    _annualRateController.dispose();
    _termYearsController.dispose();
    super.dispose();
  }

  int _getPaymentsPerYear(String frequency) {
    return _frequencyMap[frequency] ?? 12;
  }

  Future<void> _calculateLoan() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isCalculating = true;
      _result = null;
    });

    try {
      final principal = double.parse(_principalController.text);
      final annualRate = double.parse(_annualRateController.text);
      // Loan term in whole years
      final termYears = int.parse(_termYearsController.text);
      final paymentsPerYear = _getPaymentsPerYear(_paymentFrequency);
      
      // Calculate payment using the LoanCalculator
      final payment = LoanCalculator.calculatePayment(
        principal: principal,
        annualInterestRate: annualRate,
        termInYears: termYears.toDouble(),
        paymentsPerYear: paymentsPerYear,
        interestModel: _interestModel,
      );
      
  final totalPayments = termYears * paymentsPerYear;
      final totalAmount = payment * totalPayments;
      final totalInterest = totalAmount - principal;
      
      setState(() {
        _result = {
          'payment': payment,
          'totalInterest': totalInterest,
          'totalAmount': totalAmount,
          'numberOfPayments': totalPayments,
          'paymentFrequency': _paymentFrequency,
        };
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating loan: $e')),
        );
      }
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Payment Calculator',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate your periodic loan payment based on principal, interest rate, term, and payment frequency.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Principal Amount
            TextFormField(
              controller: _principalController,
              decoration: const InputDecoration(
                labelText: 'Principal Amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter principal amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Annual Interest Rate
            TextFormField(
              controller: _annualRateController,
              decoration: const InputDecoration(
                labelText: 'Annual Interest Rate (%)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.percent),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter interest rate';
                }
                final rate = double.tryParse(value);
                if (rate == null || rate < 0 || rate > 100) {
                  return 'Please enter a valid rate (0-100%)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Term in Years
            TextFormField(
              controller: _termYearsController,
              decoration: const InputDecoration(
                labelText: 'Loan Term (Years)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter loan term';
                }
                final years = int.tryParse(value);
                if (years == null || years <= 0 || years > 50) {
                  return 'Please enter a valid term (1-50 years)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Payment Frequency
            DropdownButtonFormField<String>(
              value: _paymentFrequency,
              decoration: const InputDecoration(
                labelText: 'Payment Frequency',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_view_month),
              ),
              items: _frequencyOptions.map((freq) {
                return DropdownMenuItem(value: freq, child: Text(freq));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _paymentFrequency = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Interest Model selection
            DropdownButtonFormField<InterestModel>(
              value: _interestModel,
              decoration: const InputDecoration(
                labelText: 'Interest Model',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bar_chart),
              ),
              items: InterestModel.values.map((model) {
                String text;
                switch (model) {
                  case InterestModel.simple:
                    text = 'Simple Interest';
                    break;
                  case InterestModel.reducingBalance:
                    text = 'Reducing Balance (Amortized)';
                    break;
                  case InterestModel.compound:
                    text = 'Compound Interest';
                    break;
                }
                return DropdownMenuItem(value: model, child: Text(text));
              }).toList(),
              onChanged: (model) {
                setState(() {
                  _interestModel = model!;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCalculating ? null : _calculateLoan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isCalculating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Calculate Loan Payment', style: TextStyle(fontSize: 16)),
              ),
            ),
            
            // Results
            if (_result != null) ...[
              const SizedBox(height: 32),
              Card(
                color: Colors.green.shade50,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Loan Calculation Results',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Consumer<CurrencyService>(
                        builder: (context, currencyService, child) => Column(
                          children: [
                            _buildResultRow('Payment Amount', 
                                currencyService.formatCurrency(_result!['payment']), 
                                'Per ${_result!['paymentFrequency'].toString().toLowerCase()}'),
                            _buildResultRow('Total Interest', 
                                currencyService.formatCurrency(_result!['totalInterest'])),
                            _buildResultRow('Total Amount', 
                                currencyService.formatCurrency(_result!['totalAmount'])),
                            _buildResultRow('Number of Payments', 
                                '${_result!['numberOfPayments'].round()}'),
                            _buildResultRow('Interest Model', 
                                _interestModel.toString().split('.').last),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, [String? subValue]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (subValue != null)
                  Text(subValue, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InterestSolverTab extends StatefulWidget {
  const InterestSolverTab({super.key});

  @override
  State<InterestSolverTab> createState() => _InterestSolverTabState();
}

class _InterestSolverTabState extends State<InterestSolverTab> {
  final _formKey = GlobalKey<FormState>();
  final _principalController = TextEditingController();
  final _paymentController = TextEditingController();
  final _termYearsController = TextEditingController();
  
  String _paymentFrequency = 'Monthly';
  InterestModel _interestModel = InterestModel.reducingBalance;
  double? _calculatedAPR;
  bool _isCalculating = false;

  // Payment frequency options
  final List<String> _frequencyOptions = ['Monthly', 'Quarterly', 'Semi-annually', 'Annually'];
  final Map<String, int> _frequencyMap = {
    'Monthly': 12,
    'Quarterly': 4,
    'Semi-annually': 2,
    'Annually': 1
  };

  @override
  void dispose() {
    _principalController.dispose();
    _paymentController.dispose();
    _termYearsController.dispose();
    super.dispose();
  }

  int _getPaymentsPerYear(String frequency) {
    return _frequencyMap[frequency] ?? 12;
  }

  void _calculateInterestRate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final principal = double.parse(_principalController.text);
      final payment = double.parse(_paymentController.text);
      final termYears = double.parse(_termYearsController.text);
      final paymentsPerYear = _getPaymentsPerYear(_paymentFrequency);
      
      final apr = LoanCalculator.calculateApr(
        principal: principal,
        payment: payment,
        termInYears: termYears,
        paymentsPerYear: paymentsPerYear,
        interestModel: _interestModel,
      );
      
      setState(() {
        _calculatedAPR = apr;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating interest rate: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interest Rate Solver',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate the APR based on your loan terms and payment amount.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Principal Amount
            Consumer<CurrencyService>(
              builder: (context, currencyService, child) {
                return TextFormField(
                  controller: _principalController,
                  decoration: InputDecoration(
                    labelText: 'Principal Amount',
                    border: const OutlineInputBorder(),
                    prefixText: '${currencyService.currentSymbol} ',
                    prefixIcon: const Icon(Icons.account_balance),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter principal amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Payment Amount
            Consumer<CurrencyService>(
              builder: (context, currencyService, child) {
                return TextFormField(
                  controller: _paymentController,
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    border: const OutlineInputBorder(),
                    prefixText: '${currencyService.currentSymbol} ',
                    prefixIcon: const Icon(Icons.payment),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter payment amount';
                    }
                    final payment = double.tryParse(value);
                    if (payment == null || payment <= 0) {
                      return 'Please enter a valid payment amount';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Payment Frequency
            DropdownButtonFormField<String>(
              value: _paymentFrequency,
              decoration: const InputDecoration(
                labelText: 'Payment Frequency',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_view_month),
              ),
              items: _frequencyOptions.map((freq) {
                return DropdownMenuItem(value: freq, child: Text(freq));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _paymentFrequency = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Term in Years
            TextFormField(
              controller: _termYearsController,
              decoration: const InputDecoration(
                labelText: 'Loan Term (Years)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter loan term';
                }
                final years = double.tryParse(value);
                if (years == null || years <= 0) {
                  return 'Please enter a valid term';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Interest Model selection
            DropdownButtonFormField<InterestModel>(
              value: _interestModel,
              decoration: const InputDecoration(
                labelText: 'Interest Model',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bar_chart),
              ),
              items: InterestModel.values.map((model) {
                String text;
                switch (model) {
                  case InterestModel.simple:
                    text = 'Simple Interest';
                    break;
                  case InterestModel.reducingBalance:
                    text = 'Reducing Balance (Amortized)';
                    break;
                  case InterestModel.compound:
                    text = 'Compound Interest';
                    break;
                }
                return DropdownMenuItem(value: model, child: Text(text));
              }).toList(),
              onChanged: (model) {
                setState(() {
                  _interestModel = model!;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCalculating ? null : _calculateInterestRate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isCalculating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Calculate Interest Rate', style: TextStyle(fontSize: 16)),
              ),
            ),
            
            if (_calculatedAPR != null) ...[
              const SizedBox(height: 32),
              Card(
                color: Colors.blue.shade50,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Calculated Interest Rate',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_calculatedAPR!.toStringAsFixed(2)}% APR',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildResultsSummary(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary() {
    if (_calculatedAPR == null) return const SizedBox.shrink();
    
    final principal = double.parse(_principalController.text);
    final payment = double.parse(_paymentController.text);
    final years = double.parse(_termYearsController.text);
    final paymentsPerYear = _getPaymentsPerYear(_paymentFrequency);
    final totalPayments = (years * paymentsPerYear).round();
    final totalAmount = payment * totalPayments;
    final totalInterest = totalAmount - principal;
    
    return Consumer<CurrencyService>(
      builder: (context, currencyService, child) {
        return Column(
          children: [
            _buildSummaryRow('Principal Amount:', currencyService.formatCurrency(principal)),
            _buildSummaryRow('Payment Frequency:', _paymentFrequency),
            _buildSummaryRow('Total Payments:', totalPayments.toString()),
            _buildSummaryRow('Total Amount Paid:', currencyService.formatCurrency(totalAmount)),
            _buildSummaryRow('Total Interest:', currencyService.formatCurrency(totalInterest)),
            _buildSummaryRow('Interest as % of Principal:', '${(totalInterest / principal * 100).toStringAsFixed(1)}%'),
            _buildSummaryRow('Interest Model:', _interestModel.toString().split('.').last),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// LoansTrackerTab remains the same as in the original code
class LoansTrackerTab extends StatefulWidget {
  const LoansTrackerTab({super.key});

  @override
  State<LoansTrackerTab> createState() => _LoansTrackerTabState();
}

class _LoansTrackerTabState extends State<LoansTrackerTab> {
  final List<Loan> _loans = [];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loans Tracker',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track and manage all your loans in one place.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
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
              onPressed: _showAddLoanDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add New Loan', style: TextStyle(fontSize: 16)),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Loans List
          if (_loans.isEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No loans tracked yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first loan to start tracking payments and balances',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
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
                            Text(
                              loan.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditLoanDialog(loan, index);
                                } else if (value == 'delete') {
                                  _deleteLoan(index);
                                }
                              },
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
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Progress: ${((loan.totalMonths - loan.remainingMonths) / loan.totalMonths * 100).toStringAsFixed(1)}% completed',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
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
    final termController = TextEditingController(text: loan?.totalMonths.toString() ?? '');
    final remainingController = TextEditingController(text: loan?.remainingMonths.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              TextField(
                controller: termController,
                decoration: const InputDecoration(
                  labelText: 'Total Term (months)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: remainingController,
                decoration: const InputDecoration(
                  labelText: 'Remaining Months',
                ),
                keyboardType: TextInputType.number,
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
              final name = nameController.text.trim();
              final principal = double.tryParse(principalController.text) ?? 0;
              final rate = double.tryParse(rateController.text) ?? 0;
              final totalMonths = int.tryParse(termController.text) ?? 0;
              final remainingMonths = int.tryParse(remainingController.text) ?? 0;

              if (name.isNotEmpty && principal > 0 && rate > 0 && totalMonths > 0) {
                final monthlyRate = rate / 100 / 12;
                final monthlyPayment = principal * 
                    (monthlyRate * math.pow(1 + monthlyRate, totalMonths)) /
                    (math.pow(1 + monthlyRate, totalMonths) - 1);

                final newLoan = Loan(
                  name: name,
                  principal: principal,
                  interestRate: rate,
                  totalMonths: totalMonths,
                  remainingMonths: remainingMonths,
                  monthlyPayment: monthlyPayment,
                );

                setState(() {
                  if (index != null) {
                    _loans[index] = newLoan;
                  } else {
                    _loans.add(newLoan);
                  }
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loan == null ? 'Loan added successfully!' : 'Loan updated successfully!'),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                );
              }
            },
            child: Text(loan == null ? 'Add' : 'Update'),
          ),
        ],
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
            onPressed: () {
              setState(() {
                _loans.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Loan deleted successfully!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class Loan {
  final String name;
  final double principal;
  final double interestRate;
  final int totalMonths;
  final int remainingMonths;
  final double monthlyPayment;

  Loan({
    required this.name,
    required this.principal,
    required this.interestRate,
    required this.totalMonths,
    required this.remainingMonths,
    required this.monthlyPayment,
  });
}