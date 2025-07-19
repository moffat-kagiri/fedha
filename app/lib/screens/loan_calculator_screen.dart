import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/currency_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Calculator'),
        backgroundColor: const Color(0xFF007A39),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Payment Calculator', icon: Icon(Icons.calculate)),
            Tab(text: 'Interest Solver', icon: Icon(Icons.trending_up)),
            Tab(text: 'Affordability', icon: Icon(Icons.account_balance_wallet)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PaymentCalculatorTab(),
          InterestSolverTab(),
          AffordabilityTab(),
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
  
  String _interestType = 'REDUCING';
  String _paymentFrequency = 'MONTHLY';
  bool _isCalculating = false;
  Map<String, dynamic>? _result;
  
  @override
  void dispose() {
    _principalController.dispose();
    _annualRateController.dispose();
    _termYearsController.dispose();
    super.dispose();
  }

  Future<void> _calculateLoan() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isCalculating = true;
      _result = null;
    });

    try {
      // Simulate API call - replace with actual implementation
      await Future.delayed(const Duration(seconds: 1));
      
      final principal = double.parse(_principalController.text);
      final annualRate = double.parse(_annualRateController.text) / 100;
      final termYears = int.parse(_termYearsController.text);
      
      // Simple loan calculation
      final monthlyRate = annualRate / 12;
      final numberOfPayments = termYears * 12;
      final monthlyPayment = principal * 
          (monthlyRate * Math.pow(1 + monthlyRate, numberOfPayments)) /
          (Math.pow(1 + monthlyRate, numberOfPayments) - 1);
      
      final totalAmount = monthlyPayment * numberOfPayments;
      final totalInterest = totalAmount - principal;
      
      setState(() {
        _result = {
          'monthlyPayment': monthlyPayment,
          'totalInterest': totalInterest,
          'totalAmount': totalAmount,
          'numberOfPayments': numberOfPayments,
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
            const Text(
              'Loan Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Principal Amount
            TextFormField(
              controller: _principalController,
              decoration: const InputDecoration(
                labelText: 'Principal Amount (Ksh)',
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
            const SizedBox(height: 24),
            
            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCalculating ? null : _calculateLoan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007A39),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCalculating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Calculating...'),
                        ],
                      )
                    : const Text('Calculate Loan Payment'),
              ),
            ),
            
            // Results
            if (_result != null) ...[
              const SizedBox(height: 32),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Loan Calculation Results',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Consumer<CurrencyService>(
                        builder: (context, currencyService, child) => Column(
                          children: [
                            _buildResultRow('Monthly Payment', currencyService.formatCurrency(_result!['monthlyPayment'])),
                            _buildResultRow('Total Interest', currencyService.formatCurrency(_result!['totalInterest'])),
                            _buildResultRow('Total Amount', currencyService.formatCurrency(_result!['totalAmount'])),
                            _buildResultRow('Number of Payments', '${_result!['numberOfPayments'].round()}'),
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

  Widget _buildResultRow(String label, String value) {
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

class InterestSolverTab extends StatefulWidget {
  const InterestSolverTab({super.key});

  @override
  State<InterestSolverTab> createState() => _InterestSolverTabState();
}

class _InterestSolverTabState extends State<InterestSolverTab> {
  final _formKey = GlobalKey<FormState>();
  final _principalController = TextEditingController();
  final _paymentController = TextEditingController();
  final _termController = TextEditingController();
  
  String _paymentFrequency = 'Monthly';
  double? _calculatedAPR;
  bool _isCalculating = false;

  final List<String> _frequencies = ['Monthly', 'Quarterly', 'Semi-annually', 'Annually'];

  @override
  void dispose() {
    _principalController.dispose();
    _paymentController.dispose();
    _termController.dispose();
    super.dispose();
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interest Rate Solver',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF007A39),
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
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Principal Amount
                    Consumer<CurrencyService>(
                      builder: (context, currencyService, child) {
                        return TextFormField(
                          controller: _principalController,
                          decoration: InputDecoration(
                            labelText: 'Principal Amount',
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
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: _frequencies.map((freq) {
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
                      controller: _termController,
                      decoration: const InputDecoration(
                        labelText: 'Loan Term (Years)',
                        prefixIcon: Icon(Icons.schedule_outlined),
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
                    const SizedBox(height: 24),
                    
                    // Calculate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCalculating ? null : _calculateInterestRate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007A39),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isCalculating
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text('Calculate Interest Rate'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_calculatedAPR != null) ...[
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF007A39).withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Calculated Interest Rate',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF007A39),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_calculatedAPR!.toStringAsFixed(2)}% APR',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF007A39),
                        ),
                      ),
                      const SizedBox(height: 16),
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
    final years = double.parse(_termController.text);
    
    final paymentsPerYear = _getPaymentsPerYear(_paymentFrequency);
    final totalPayments = (years * paymentsPerYear).round();
    final totalAmount = payment * totalPayments;
    final totalInterest = totalAmount - principal;
    
    return Consumer<CurrencyService>(
      builder: (context, currencyService, child) {
        return Column(
          children: [
            _buildSummaryRow('Principal Amount:', currencyService.formatCurrency(principal)),
            _buildSummaryRow('Total Payments:', totalPayments.toString()),
            _buildSummaryRow('Total Amount Paid:', currencyService.formatCurrency(totalAmount)),
            _buildSummaryRow('Total Interest:', currencyService.formatCurrency(totalInterest)),
            _buildSummaryRow('Interest as % of Principal:', '${(totalInterest / principal * 100).toStringAsFixed(1)}%'),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  int _getPaymentsPerYear(String frequency) {
    switch (frequency) {
      case 'Monthly':
        return 12;
      case 'Quarterly':
        return 4;
      case 'Semi-annually':
        return 2;
      case 'Annually':
        return 1;
      default:
        return 12;
    }
  }

  void _calculateInterestRate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final principal = double.parse(_principalController.text);
      final payment = double.parse(_paymentController.text);
      final years = double.parse(_termController.text);
      final paymentsPerYear = _getPaymentsPerYear(_paymentFrequency);
      final totalPayments = years * paymentsPerYear;
      
      // Use Newton-Raphson method to solve for interest rate
      final apr = _solveForInterestRate(principal, payment, totalPayments, paymentsPerYear);
      
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

  double _solveForInterestRate(double principal, double payment, double totalPayments, int paymentsPerYear) {
    // If payment * totalPayments equals principal, interest rate is 0
    if ((payment * totalPayments - principal).abs() < 0.01) {
      return 0.0;
    }
    
    // Initial guess: 5% annual rate
    double rate = 0.05 / paymentsPerYear;
    double tolerance = 1e-8;
    int maxIterations = 100;
    
    for (int i = 0; i < maxIterations; i++) {
      double presentValue = _calculatePresentValue(payment, rate, totalPayments);
      double derivative = _calculateDerivative(payment, rate, totalPayments);
      
      if (derivative.abs() < tolerance) break;
      
      double newRate = rate - (presentValue - principal) / derivative;
      
      if ((newRate - rate).abs() < tolerance) {
        rate = newRate;
        break;
      }
      
      rate = newRate;
      
      // Ensure rate stays positive
      if (rate < 0) rate = 0.001 / paymentsPerYear;
      if (rate > 1) rate = 1.0; // Cap at 100% per period
    }
    
    // Convert to annual percentage rate
    return rate * paymentsPerYear * 100;
  }

  double _calculatePresentValue(double payment, double rate, double periods) {
    if (rate == 0) return payment * periods;
    return payment * (1 - Math.pow(1 + rate, -periods)) / rate;
  }

  double _calculateDerivative(double payment, double rate, double periods) {
    if (rate == 0) return 0;
    double factor1 = (1 - Math.pow(1 + rate, -periods)) / (rate * rate);
    double factor2 = periods * Math.pow(1 + rate, -periods - 1) / rate;
    return payment * (factor1 - factor2);
  }
}

class AffordabilityTab extends StatefulWidget {
  const AffordabilityTab({super.key});

  @override
  State<AffordabilityTab> createState() => _AffordabilityTabState();
}

class _AffordabilityTabState extends State<AffordabilityTab> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyIncomeController = TextEditingController();
  final _monthlyExpensesController = TextEditingController();
  final _existingDebtController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _loanTermController = TextEditingController();
  
  double? _monthlyPayment;
  double? _debtToIncomeRatio;
  bool? _canAfford;
  String _recommendation = '';
  bool _isCalculating = false;

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    _monthlyExpensesController.dispose();
    _existingDebtController.dispose();
    _downPaymentController.dispose();
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _loanTermController.dispose();
    super.dispose();
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Affordability Calculator',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF007A39),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Determine if you can afford the loan based on your financial situation.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Financial Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Financial Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Consumer<CurrencyService>(
                      builder: (context, currencyService, child) {
                        return Column(
                          children: [
                            TextFormField(
                              controller: _monthlyIncomeController,
                              decoration: InputDecoration(
                                labelText: 'Monthly Gross Income',
                                prefixText: '${currencyService.currentSymbol} ',
                                prefixIcon: const Icon(Icons.account_balance_wallet),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your monthly income';
                                }
                                final income = double.tryParse(value);
                                if (income == null || income <= 0) {
                                  return 'Please enter a valid income';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _monthlyExpensesController,
                              decoration: InputDecoration(
                                labelText: 'Monthly Expenses',
                                prefixText: '${currencyService.currentSymbol} ',
                                prefixIcon: const Icon(Icons.shopping_cart),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your monthly expenses';
                                }
                                final expenses = double.tryParse(value);
                                if (expenses == null || expenses < 0) {
                                  return 'Please enter valid expenses';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _existingDebtController,
                              decoration: InputDecoration(
                                labelText: 'Existing Monthly Debt Payments',
                                prefixText: '${currencyService.currentSymbol} ',
                                prefixIcon: const Icon(Icons.credit_card),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) return null;
                                final debt = double.tryParse(value);
                                if (debt == null || debt < 0) {
                                  return 'Please enter valid debt payments';
                                }
                                return null;
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Loan Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Consumer<CurrencyService>(
                      builder: (context, currencyService, child) {
                        return Column(
                          children: [
                            TextFormField(
                              controller: _loanAmountController,
                              decoration: InputDecoration(
                                labelText: 'Loan Amount',
                                prefixText: '${currencyService.currentSymbol} ',
                                prefixIcon: const Icon(Icons.account_balance),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter loan amount';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'Please enter a valid loan amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _interestRateController,
                              decoration: const InputDecoration(
                                labelText: 'Annual Interest Rate (%)',
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
                            
                            TextFormField(
                              controller: _loanTermController,
                              decoration: const InputDecoration(
                                labelText: 'Loan Term (Years)',
                                prefixIcon: Icon(Icons.schedule),
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
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Calculate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCalculating ? null : _calculateAffordability,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007A39),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isCalculating
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text('Check Affordability'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_canAfford != null) ...[
              const SizedBox(height: 16),
              _buildAffordabilityResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAffordabilityResult() {
    final color = _canAfford! ? Colors.green : Colors.red;
    final icon = _canAfford! ? Icons.check_circle : Icons.warning;
    
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _canAfford! ? 'Loan Appears Affordable' : 'Loan May Not Be Affordable',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Consumer<CurrencyService>(
              builder: (context, currencyService, child) {
                return Column(
                  children: [
                    _buildResultRow('Monthly Payment:', currencyService.formatCurrency(_monthlyPayment!)),
                    _buildResultRow('Debt-to-Income Ratio:', '${_debtToIncomeRatio!.toStringAsFixed(1)}%'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommendation:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _recommendation,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _calculateAffordability() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final monthlyIncome = double.parse(_monthlyIncomeController.text);
      final monthlyExpenses = double.parse(_monthlyExpensesController.text);
      final existingDebt = double.tryParse(_existingDebtController.text) ?? 0;
      final loanAmount = double.parse(_loanAmountController.text);
      final annualRate = double.parse(_interestRateController.text);
      final years = double.parse(_loanTermController.text);
      
      // Calculate monthly payment
      final monthlyRate = annualRate / 100 / 12;
      final numPayments = years * 12;
      
      double monthlyPayment;
      if (monthlyRate == 0) {
        monthlyPayment = loanAmount / numPayments;
      } else {
        monthlyPayment = loanAmount * 
            (monthlyRate * Math.pow(1 + monthlyRate, numPayments)) /
            (Math.pow(1 + monthlyRate, numPayments) - 1);
      }
      
      // Calculate debt-to-income ratio
      final totalMonthlyDebt = existingDebt + monthlyPayment;
      final debtToIncome = (totalMonthlyDebt / monthlyIncome) * 100;
      
      // Determine affordability
      final disposableIncome = monthlyIncome - monthlyExpenses - existingDebt;
      final canAfford = debtToIncome <= 36 && monthlyPayment <= disposableIncome * 0.8;
      
      // Generate recommendation
      String recommendation;
      if (canAfford) {
        recommendation = 'Based on your financial profile, this loan appears affordable. Your debt-to-income ratio is within acceptable limits, and you have sufficient disposable income to cover the payments comfortably.';
      } else if (debtToIncome > 36) {
        recommendation = 'Your debt-to-income ratio would be ${debtToIncome.toStringAsFixed(1)}%, which exceeds the recommended 36% limit. Consider reducing existing debt or choosing a smaller loan amount.';
      } else {
        recommendation = 'While your debt-to-income ratio is acceptable, the monthly payment would consume a large portion of your disposable income. Consider a longer loan term or larger down payment to reduce monthly payments.';
      }
      
      setState(() {
        _monthlyPayment = monthlyPayment;
        _debtToIncomeRatio = debtToIncome;
        _canAfford = canAfford;
        _recommendation = recommendation;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating affordability: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
