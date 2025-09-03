import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeCoverScreen extends StatefulWidget {
  const HomeCoverScreen({Key? key}) : super(key: key);

  @override
  _HomeCoverScreenState createState() => _HomeCoverScreenState();
}

class _HomeCoverScreenState extends State<HomeCoverScreen> {
  final _formKey = GlobalKey<FormState>();
  double _homeValue = 0;
  bool _submitted = false;
  double _premium = 0;
  List<Map<String, dynamic>> _options = [];

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    _premium = _homeValue * 0.0025;
    _options = [
      {'name': 'Comprehensive', 'premium': _premium},
      {'name': 'Fire & Theft', 'premium': _homeValue * 0.001},
      {'name': 'Contents Only', 'premium': _homeValue * 0.0005},
    ];
    _options.sort((a, b) => a['premium'].compareTo(b['premium']));
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FedhaColors.primaryGreen,
        title: const Text('Home Insurance'),
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
                      labelText: 'Home Sum Insured (Ksh)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || double.tryParse(v) == null)
                        ? 'Enter valid value'
                        : null,
                    onSaved: (v) => _homeValue = double.parse(v!),
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
                'Available Home Plans:',
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
              OutlinedButton(
                onPressed: () {},
                child: const Text('Contact an agent'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
