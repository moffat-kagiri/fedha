import 'package:flutter/material.dart';

class InvestmentRiskAssessmentScreen extends StatefulWidget {
  const InvestmentRiskAssessmentScreen({super.key});

  @override
  State<InvestmentRiskAssessmentScreen> createState() => _InvestmentRiskAssessmentScreenState();
}

class _InvestmentRiskAssessmentScreenState extends State<InvestmentRiskAssessmentScreen> {
  // Form state
  final _formKey = GlobalKey<FormState>();
  String? _selectedGoal;
  double _incomeRatio = 50; // % of income from business/employment
  double _desiredReturnRatio = 50; // desired investment income % of current income
  double _timeHorizon = 5; // in years
  double _riskScore = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Risk Appetite Assessment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('1. What is your primary investment goal?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGoal,
                items: [
                  'Wealth Preservation',
                  'Moderate Growth',
                  'Aggressive Growth',
                  'Retirement Planning',
                  'Short-term Income',
                ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: (v) => v == null ? 'Please select a goal' : null,
                onChanged: (v) => setState(() => _selectedGoal = v),
              ),
              const SizedBox(height: 16),
              Text('2. Percentage of your income from employment/business: ${_incomeRatio.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleMedium),
              Slider(
                min: 0, max: 100, divisions: 100,
                label: '${_incomeRatio.toStringAsFixed(0)}%',
                value: _incomeRatio,
                onChanged: (v) => setState(() => _incomeRatio = v),
              ),
              const SizedBox(height: 16),
              Text('3. Desired investment income as % of current income: ${_desiredReturnRatio.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleMedium),
              Slider(
                min: 0, max: 100, divisions: 100,
                label: '${_desiredReturnRatio.toStringAsFixed(0)}%',
                value: _desiredReturnRatio,
                onChanged: (v) => setState(() => _desiredReturnRatio = v),
              ),
              const SizedBox(height: 16),
              Text('4. Investment time horizon (years): ${_timeHorizon.toInt()}', style: Theme.of(context).textTheme.titleMedium),
              Slider(
                min: 1, max: 30, divisions: 29,
                label: '${_timeHorizon.toInt()} yrs',
                value: _timeHorizon,
                onChanged: (v) => setState(() => _timeHorizon = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  // Map goal to score
                  final goalMap = {
                    'Wealth Preservation': 20.0,
                    'Moderate Growth': 50.0,
                    'Aggressive Growth': 80.0,
                    'Retirement Planning': 60.0,
                    'Short-term Income': 30.0,
                  };
                  final goalScore = goalMap[_selectedGoal!]!;
                  final horizonScore = (_timeHorizon / 30.0) * 100.0;
                  final score = (goalScore + _incomeRatio + _desiredReturnRatio + horizonScore) / 4.0;
                  setState(() => _riskScore = score);
                  Navigator.pushNamed(
                    context,
                    '/investment_irr_calculator',
                    arguments: _riskScore,
                  );
                },
                child: const Text('Calculate Risk & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
