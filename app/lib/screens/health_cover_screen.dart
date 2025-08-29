import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HealthCoverScreen extends StatefulWidget {
  const HealthCoverScreen({Key? key}) : super(key: key);

  @override
  _HealthCoverScreenState createState() => _HealthCoverScreenState();
}

class _HealthCoverScreenState extends State<HealthCoverScreen> {
  final _formKey = GlobalKey<FormState>();
  double _monthlyIncome = 0;
  bool _isMarried = false;
  bool _hasChildren = false;
  bool _submitted = false;

  double _healthcareMin = 0;
  double _healthcareMax = 0;
  List<Map<String, dynamic>> _options = [];

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final annualIncome = _monthlyIncome * 12;
    _healthcareMin = annualIncome * 0.01;
    _healthcareMax = annualIncome * 0.05;
    // Build sample options sorted by premium (per year)
    _options = [
      {
        'name': 'Basic Plan',
        'coverage': _healthcareMin * 100,
        'premium': _healthcareMin,
      },
      {
        'name': 'Standard Plan',
        'coverage': _healthcareMax * 50,
        'premium': (_healthcareMin + _healthcareMax) / 2,
      },
      {
        'name': 'Premium Plan',
        'coverage': _healthcareMax * 100,
        'premium': _healthcareMax,
      },
    ];
    _options.sort((a, b) => a['premium'].compareTo(b['premium']));
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FedhaColors.primaryGreen,
        title: const Text('Health Insurance'),
      ),
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
                    title: const Text('Married?'),
                    value: _isMarried,
                    onChanged: (v) => setState(() => _isMarried = v),
                  ),
                  SwitchListTile(
                    title: const Text('Do you have children?'),
                    value: _hasChildren,
                    onChanged: (v) => setState(() => _hasChildren = v),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FedhaColors.primaryGreen,
                    ),
                    child: const Text('Calculate Recommendations'),
                  ),
                ],
              ),
            ),
            if (_submitted) ...[
              const SizedBox(height: 24),
              Text(
                'Recommended Annual Cover Range:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Ksh ${_healthcareMin.toStringAsFixed(0)} - ${_healthcareMax.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 16),
              Text(
                'Available Plans:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final opt = _options[index];
                  return ListTile(
                    title: Text(opt['name']),
                    subtitle: Text(
                        'Coverage: Ksh ${opt['coverage'].toStringAsFixed(0)}'),
                    trailing: Text(
                        'Ksh ${opt['premium'].toStringAsFixed(0)}/yr'),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: integrate contact agent
                      },
                      child: const Text('Contact an agent'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/asset_protection_vehicle');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FedhaColors.primaryGreen,
                      ),
                      child: const Text('Next: Vehicle'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
