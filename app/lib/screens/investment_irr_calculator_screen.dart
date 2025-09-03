import 'package:flutter/material.dart';
import '../utils/investment_calculator.dart';

class InvestmentIRRCalculatorScreen extends StatefulWidget {
  const InvestmentIRRCalculatorScreen({super.key});

  @override
  State<InvestmentIRRCalculatorScreen> createState() => _InvestmentIRRCalculatorScreenState();
}

class _InvestmentIRRCalculatorScreenState extends State<InvestmentIRRCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _initialInvestmentController = TextEditingController();
  final _cashFlowsController = TextEditingController(); // comma-separated flows
  double? _irr;

  @override
  void dispose() {
    _initialInvestmentController.dispose();
    _cashFlowsController.dispose();
    super.dispose();
  }

  void _calculateIRR() {
    if (!_formKey.currentState!.validate()) return;
    final double initial = double.parse(_initialInvestmentController.text);
    final flows = _cashFlowsController.text
        .split(',')
        .map((e) => double.parse(e.trim()))
        .toList();
    // Prepend negative initial
    final cashFlows = [-initial, ...flows];
    final result = InvestmentCalculator.irr(cashFlows);
    setState(() {
      _irr = result;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IRR Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _initialInvestmentController,
                decoration: const InputDecoration(
                  labelText: 'Initial Investment',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter initial investment' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cashFlowsController,
                decoration: const InputDecoration(
                  labelText: 'Cash Flows (comma-separated)',
                ),
                keyboardType: TextInputType.text,
                validator: (v) => v == null || v.isEmpty ? 'Enter cash flows' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculateIRR,
                child: const Text('Calculate IRR'),
              ),
              if (_irr != null) ...[
                const SizedBox(height: 24),
                Text('Estimated IRR: ${(_irr! * 100).toStringAsFixed(2)}%',
                  style: Theme.of(context).textTheme.titleLarge),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
