import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/risk_assessment_service.dart';

class InvestmentRiskAssessmentScreen extends StatefulWidget {
  final RiskAssessmentService? service;

  const InvestmentRiskAssessmentScreen({super.key, this.service});

  @override
  State<InvestmentRiskAssessmentScreen> createState() => _InvestmentRiskAssessmentScreenState();
}

class _InvestmentRiskAssessmentScreenState extends State<InvestmentRiskAssessmentScreen> {
  // Form state
  final _formKey = GlobalKey<FormState>();
  String? _selectedGoal;
  double _incomeRatio = 50;
  double _desiredReturnRatio = 50;
  double _timeHorizon = 5;
  int? _lossToleranceIndex;
  int? _experienceIndex;
  int? _volatilityReactionIndex;
  int? _liquidityNeedIndex;
  int _emergencyFundMonths = 3;
  double _riskScore = 0;
  late RiskAssessmentService? _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _computeScore();
  }

  // Recalculate risk score based on current answers
  void _computeScore() {
    _riskScore = RiskAssessmentService.computeScore(
      selectedGoal: _selectedGoal,
      incomeRatio: _incomeRatio,
      desiredReturnRatio: _desiredReturnRatio,
      timeHorizon: _timeHorizon,
      lossToleranceIndex: _lossToleranceIndex,
      experienceIndex: _experienceIndex,
      volatilityReactionIndex: _volatilityReactionIndex,
      liquidityNeedIndex: _liquidityNeedIndex,
      emergencyFundMonths: _emergencyFundMonths,
    );
    setState(() {});
  }

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
                onPressed: () async {
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
                  // Save assessment
                  final service = Provider.of<RiskAssessmentService>(context, listen: false);
                  await service.saveAssessment(
                    goal: _selectedGoal,
                    incomeRatio: _incomeRatio,
                    desiredReturnRatio: _desiredReturnRatio,
                    timeHorizon: _timeHorizon.toInt(),
                    lossToleranceIndex: _lossToleranceIndex,
                    experienceIndex: _experienceIndex,
                    volatilityReactionIndex: _volatilityReactionIndex,
                    liquidityNeedIndex: _liquidityNeedIndex,
                    emergencyFundMonths: _emergencyFundMonths,
                  );
                  // Show risk score confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Your risk appetite score is ${_riskScore.toStringAsFixed(0)}%'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  // Navigate to IRR calculator
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
