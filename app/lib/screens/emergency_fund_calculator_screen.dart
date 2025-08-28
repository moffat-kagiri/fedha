import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../services/offline_data_service.dart';

class EmergencyFundCalculatorScreen extends StatefulWidget {
  const EmergencyFundCalculatorScreen({Key? key}) : super(key: key);

  @override
  _EmergencyFundCalculatorScreenState createState() =>
      _EmergencyFundCalculatorScreenState();
}

class _EmergencyFundCalculatorScreenState
    extends State<EmergencyFundCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  double? _monthlySpending;
  int _monthsToSave = 3;
  bool _loading = true;
  bool _hasHistory = false;
  double? _averageSpending;
  double? _target;

  @override
  void initState() {
    super.initState();
    _initAverage();
  }

  Future<void> _initAverage() async {
    final svc = Provider.of<OfflineDataService>(context, listen: false);
    final profileId = svc.currentProfileId;
    final avg = await svc.getAverageMonthlySpending(profileId);
    setState(() {
      if (avg != null) {
        _hasHistory = true;
        _averageSpending = avg;
        _monthlySpending = avg;
      }
      _loading = false;
    });
  }

  void _calculate() {
    if (!_hasHistory) {
      if (!_formKey.currentState!.validate()) return;
      _formKey.currentState!.save();
    }
    setState(() {
      _target = (_monthlySpending ?? 0) * _monthsToSave;
    });
  }

  Future<void> _saveAsGoal() async {
    final svc = Provider.of<OfflineDataService>(context, listen: false);
    final profileId = svc.currentProfileId;
    final goal = Goal(
      id: null,
      name: 'Emergency Fund',
      description:
          'Save Ksh ${_target!.toStringAsFixed(2)} for emergencies',
      targetMinor: (_target! * 100).round(),
      dueDate: DateTime.now()
          .add(Duration(days: _monthsToSave * 30)),
      profileId: profileId,
    );
    await svc.addGoal(goal);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency Fund goal saved!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Fund Calculator'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_hasHistory) ...[
                    Text(
                      'Based on your last 3 months of spending,\n'
                      'average monthly expense is '
                      'Ksh ${_averageSpending!.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Monthly Spending (Ksh)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Enter your monthly spending';
                          }
                          return null;
                        },
                        onSaved: (v) => _monthlySpending =
                            double.tryParse(v!) ?? 0,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    children: [
                      const Text('Months to save:'),
                      const SizedBox(width: 16),
                      DropdownButton<int>(
                        value: _monthsToSave,
                        items: [3, 4, 5, 6]
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text('$m months'),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _monthsToSave = v!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _calculate,
                    child: const Text('Calculate Target'),
                  ),
                  if (_target != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'You need to save Ksh ${_target!.toStringAsFixed(2)} '
                      'in $_monthsToSave months.',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _saveAsGoal,
                      icon: const Icon(Icons.flag),
                      label: const Text('Set as Goal'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}