import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/currency_service.dart';
import '../utils/loan_calculator.dart';
import 'dart:math' as math;
import '../models/enums.dart';
import '../theme/app_theme.dart';

class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen>
    with TickerProviderStateMixin {
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
    final theme = Theme.of(context);
    // Let appBar pick colors from theme (avoid forcing backgroundColor unless needed)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Calculator'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor:
              theme.colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: theme.colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'Payment Calculator', icon: Icon(Icons.calculate)),
            Tab(text: 'Interest Solver', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PaymentCalculatorTab(),
          InterestSolverTab(),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* --------------------------- Payment Calculator Tab ------------------------ */
/* -------------------------------------------------------------------------- */

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
  final List<String> _frequencyOptions = [
    'Monthly',
    'Quarterly',
    'Semi-annually',
    'Annually'
  ];
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
      final termYears = int.parse(_termYearsController.text);
      final paymentsPerYear = _getPaymentsPerYear(_paymentFrequency);

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
    final theme = Theme.of(context);
    final surfaceVariantColor = theme.colorScheme.surfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Payment Calculator',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter principal, interest rate, term, and payment frequency to calculate your periodic loan payment.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
                child: _isCalculating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Calculate Loan Payment'),
              ),
            ),
            const SizedBox(height: 20),

            // Results
            if (_result != null) ...[
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Loan Calculation Results',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Consumer<CurrencyService>(
                        builder: (context, currencyService, child) => Column(
                          children: [
                            _buildResultRow(
                              'Payment Amount',
                              currencyService.formatCurrency(_result!['payment']),
                              'Per ${_result!['paymentFrequency'].toString().toLowerCase()}',
                            ),
                            _buildResultRow(
                              'Total Interest',
                              currencyService.formatCurrency(_result!['totalInterest']),
                            ),
                            _buildResultRow(
                              'Total Amount',
                              currencyService.formatCurrency(_result!['totalAmount']),
                            ),
                            _buildResultRow(
                              'Number of Payments',
                              '${_result!['numberOfPayments'].round()}',
                            ),
                            _buildResultRow(
                              'Interest Model',
                              _interestModel.toString().split('.').last,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, [String? subValue]) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                if (subValue != null)
                  Text(subValue, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* ----------------------------- Interest Solver Tab ------------------------ */
/* -------------------------------------------------------------------------- */

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

  final List<String> _frequencyOptions = [
    'Monthly',
    'Quarterly',
    'Semi-annually',
    'Annually'
  ];
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating interest rate: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
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
                      'Interest Rate Solver',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter Loan Details and Repayment Schedule to Calculate the APR. \nTip: Use this to understand the true cost of your loan, and compare different lenders.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
                child: _isCalculating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Calculate Interest Rate'),
              ),
            ),

            // Results animated switcher
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _calculatedAPR == null
                  ? const SizedBox.shrink()
                  : Card(
                      key: const ValueKey('aprCard'),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Calculated Interest Rate',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_calculatedAPR!.toStringAsFixed(2)}% APR',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildResultsSummary(),
                          ],
                        ),
                      ),
                    ),
            ),
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
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.onSurface.withOpacity(0.03),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

