import 'package:flutter/material.dart';

class AssetProtectionScreen extends StatefulWidget {
  const AssetProtectionScreen({Key? key}) : super(key: key);

  @override
  _AssetProtectionScreenState createState() => _AssetProtectionScreenState();
}

class _AssetProtectionScreenState extends State<AssetProtectionScreen> {
  final _formKey = GlobalKey<FormState>();
  double _monthlyIncome = 0;
  bool _hasChildren = false;
  double _vehicleValue = 0;
  double _homeValue = 0;
  bool _submitted = false;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() { _submitted = true; });
  }

  @override
  Widget build(BuildContext context) {
  // Calculations
  final annualIncome = _monthlyIncome * 12;
  // Healthcare spend recommendation: 1-5% of annual income, displayed monthly
  final healthcareMin = (annualIncome * 0.05) / 12;
  final healthcareMax = (annualIncome * 0.10) / 12;
    final coverMultiplier = _hasChildren ? 10 : 7;
    final lifeCover = annualIncome * coverMultiplier;
    final lifePremiumMonthly = lifeCover * 0.005 / 12;
    final motorPremiumMonthly = _vehicleValue * 0.03 / 12;
    final homePremiumMonthly = _homeValue * 0.0025 / 12;

    return Scaffold(
      appBar: AppBar(title: Text(
        'Coverage Recommendations',
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(color: Colors.white),
        )),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Monthly Income (Ksh)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || double.tryParse(v) == null)
                        ? 'Enter valid income'
                        : null,
                    onSaved: (v) => _monthlyIncome = double.tryParse(v!) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Do you have children?'),
                    value: _hasChildren,
                    onChanged: (v) {
                      setState(() { _hasChildren = v; });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Value (Ksh)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || double.tryParse(v) == null)
                        ? 'Enter valid value'
                        : null,
                    onSaved: (v) => _vehicleValue = double.tryParse(v!) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Home Sum Insured (Ksh)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || double.tryParse(v) == null)
                        ? 'Enter valid value'
                        : null,
                    onSaved: (v) => _homeValue = double.tryParse(v!) ?? 0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Show Recommendations'),
            ),
            if (_submitted) ...[
              const SizedBox(height: 24),
              Text(
                'Healthcare Insurance:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '1–5% of monthly income: Ksh ${healthcareMin.toStringAsFixed(2)} - ${healthcareMax.toStringAsFixed(2)}/mo',
              ),
              const SizedBox(height: 16),
              Text(
                'Life Assurance:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Cover: Ksh ${lifeCover.toStringAsFixed(0)} (x$coverMultiplier annual income)',
              ),
              Text(
                'Estimated premium: Ksh ${lifePremiumMonthly.toStringAsFixed(2)}/mo',
              ),
              const SizedBox(height: 16),
              Text(
                'Motor Insurance:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Estimated premium: Ksh ${motorPremiumMonthly.toStringAsFixed(2)}/mo',
              ),
              const SizedBox(height: 16),
              Text(
                'Home Insurance:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Estimated premium: Ksh ${homePremiumMonthly.toStringAsFixed(2)}/mo',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
