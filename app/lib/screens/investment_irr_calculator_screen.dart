import 'package:flutter/material.dart';
import 'dart:math';

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
    final flows = _cashFlowsController.text.split(',').map((e) => double.parse(e.trim())).toList();

    double npv(double rate) {
      double sum = -initial;
      for (int i = 0; i < flows.length; i++) {
        sum += flows[i] / pow(1 + rate, i + 1);
      }
      return sum;
    }

    double x0 = 0.1;
    for (int i = 0; i < 20; i++) {
      final f = npv(x0);
      final df = (npv(x0 + 1e-6) - f) / 1e-6;
      x0 = x0 - f / df;
    }
    setState(() {
      _irr = x0;
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
