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
              // Loss tolerance question
              Text('5. If your investment dropped 20% in a month, what would you do?', style: Theme.of(context).textTheme.titleMedium),
              ...RiskAssessmentService.lossToleranceOptions.asMap().entries.map<Widget>((entry) {
                final i = entry.key;
                final opt = entry.value;
                return RadioListTile<int>(
                  value: i,
                  groupValue: _lossToleranceIndex,
                  title: Text(opt['label'] as String),
                  onChanged: (v) => setState(() {
                    _lossToleranceIndex = v;
                    _computeScore();
                  }),
                );
              }),
              const SizedBox(height: 16),
              // Experience question
              Text('6. How experienced are you with investments?', style: Theme.of(context).textTheme.titleMedium),
              ...RiskAssessmentService.experienceOptions.asMap().entries.map<Widget>((entry) {
                final i = entry.key;
                final opt = entry.value;
                return RadioListTile<int>(
                  value: i,
                  groupValue: _experienceIndex,
                  title: Text(opt['label'] as String),
                  onChanged: (v) => setState(() {
                    _experienceIndex = v;
                    _computeScore();
                  }),
                );
              }),
              const SizedBox(height: 16),
              // Volatility reaction
              Text('7. Your reaction to market volatility:', style: Theme.of(context).textTheme.titleMedium),
              ...RiskAssessmentService.volatilityReactionOptions.asMap().entries.map<Widget>((entry) {
                final i = entry.key;
                final opt = entry.value;
                return RadioListTile<int>(
                  value: i,
                  groupValue: _volatilityReactionIndex,
                  title: Text(opt['label'] as String),
                  onChanged: (v) => setState(() {
                    _volatilityReactionIndex = v;
                    _computeScore();
                  }),
                );
              }),
              const SizedBox(height: 16),
              // Liquidity need
              Text('8. When do you need access to funds?', style: Theme.of(context).textTheme.titleMedium),
              ...RiskAssessmentService.liquidityNeedOptions.asMap().entries.map<Widget>((entry) {
                final i = entry.key;
                final opt = entry.value;
                return RadioListTile<int>(
                  value: i,
                  groupValue: _liquidityNeedIndex,
                  title: Text(opt['label'] as String),
                  onChanged: (v) => setState(() {
                    _liquidityNeedIndex = v;
                    _computeScore();
                  }),
                );
              }),
              const SizedBox(height: 16),
              // Emergency fund months
              Text('9. Emergency fund adequacy (months):', style: Theme.of(context).textTheme.titleMedium),
              DropdownButtonFormField<int>(
                value: _emergencyFundMonths,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [1,3,6,12].map((m) => DropdownMenuItem(value: m, child: Text('$m months'))).toList(),
                onChanged: (v) => setState(() {
                  _emergencyFundMonths = v!;
                  _computeScore();
                }),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate() || _lossToleranceIndex==null || _experienceIndex==null || _volatilityReactionIndex==null || _liquidityNeedIndex==null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please answer all questions before continuing')));
                    return;
                  }
                  // Calculate and save
                  final service = widget.service ?? Provider.of<RiskAssessmentService>(context, listen: false);
                  final score = RiskAssessmentService.computeScore(
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
                  setState(() => _riskScore = score);
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
                  // Navigate to recommendations
                  Navigator.pushNamed(context, '/investment_recommendations', arguments: _riskScore);
                },
                child: const Text('Compute Risk & View Recommendations'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
