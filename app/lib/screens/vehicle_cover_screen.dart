import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VehicleCoverScreen extends StatefulWidget {
  const VehicleCoverScreen({Key? key}) : super(key: key);

  @override
  _VehicleCoverScreenState createState() => _VehicleCoverScreenState();
}

class _VehicleCoverScreenState extends State<VehicleCoverScreen> {
  final _formKey = GlobalKey<FormState>();
  double _vehicleValue = 0;
  bool _submitted = false;
  double _premium = 0;
  List<Map<String, dynamic>> _options = [];

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    _premium = _vehicleValue * 0.03;
    _options = [
      {'name': 'Comprehensive', 'premium': _premium},
      {'name': 'Third-Party', 'premium': _vehicleValue * 0.01},
      {'name': 'Third-Party Fire & Theft', 'premium': _vehicleValue * 0.02},
    ];
    _options.sort((a, b) => a['premium'].compareTo(b['premium']));
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FedhaColors.primaryGreen,
        title: const Text('Vehicle Insurance'),
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
                      labelText: 'Vehicle Value (Ksh)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || double.tryParse(v) == null)
                        ? 'Enter valid value'
                        : null,
                    onSaved: (v) => _vehicleValue = double.parse(v!),
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
                'Available Vehicle Plans:',
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
                    trailing: Text('Ksh ${opt['premium'].toStringAsFixed(0)}/yr'),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Contact an agent'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/asset_protection_home');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FedhaColors.primaryGreen,
                      ),
                      child: const Text('Next: Home'),
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
