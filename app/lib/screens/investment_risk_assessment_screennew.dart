import 'package:flutter/material.dart';
import 'risk_assessment_service.dart';
import '../services/risk_assessment_service.dart';

class InvestmentRiskAssessmentScreen extends StatefulWidget {
  final RiskAssessmentService? service;

  const InvestmentRiskAssessmentScreen({super.key, this.service});

  @override
  State<InvestmentRiskAssessmentScreen> createState() => _InvestmentRiskAssessmentScreenState();
}

class _InvestmentRiskAssessmentScreenState extends State<InvestmentRiskAssessmentScreen> {
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

  bool get _isFormComplete =>
      _selectedGoal != null &&
      _lossToleranceIndex != null &&
      _experienceIndex != null &&
      _volatilityReactionIndex != null;

  Future<void> _onContinue() async {
    if (!_isFormComplete) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please answer all required questions (marked with *).')));
      return;
    }

    final profile = RiskAssessmentService.profileFromScore(_riskScore);
    final allocation = RiskAssessmentService.recommendedAllocation(profile);

    if (_service != null) {
      await _service!.saveAssessment(
        userId: null,
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
    }

    Navigator.pushNamed(
      context,
      '/investment_irr_calculator',
      arguments: {
        'riskScore': _riskScore,
        'profile': profile,
        'allocation': allocation,
        'answers': {
          'goal': _selectedGoal,
          'incomeRatio': _incomeRatio,
          'desiredReturnRatio': _desiredReturnRatio,
          'timeHorizon': _timeHorizon,
          'lossTolerance': _lossToleranceIndex,
          'experience': _experienceIndex,
          'volatilityReaction': _volatilityReactionIndex,
          'liquidityNeed': _liquidityNeedIndex,
          'emergencyFundMonths': _emergencyFundMonths,
        },
      },
    );
  }

  Widget _buildQuestionTitle(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
          if (required)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.star, size: 12, color: Colors.redAccent),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = RiskAssessmentService.profileFromScore(_riskScore);
    final allocation = RiskAssessmentService.recommendedAllocation(profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Appetite Assessment')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Risk Summary', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: _riskScore / 100.0,
                              minHeight: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('$_riskScore', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Profile: $profile', style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: allocation.entries.map((e) => Chip(label: Text('${e.key}: ${e.value}%'))).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _buildQuestionTitle('1. What is your primary investment goal?', required: true),
              DropdownButtonFormField<String>(
                value: _selectedGoal,
                items: RiskAssessmentService.goalScores.keys.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (v) => setState(() {
                  _selectedGoal = v;
                  _computeScore();
                }),
              ),

              const SizedBox(height: 16),

              _buildQuestionTitle('2. If your investment dropped 20% in a month, what would you do?', required: true),
              ...List.generate(RiskAssessmentService.lossToleranceOptions.length, (i) {
                return RadioListTile<int>(
                  value: i,
                  groupValue: _lossToleranceIndex,
                  title: Text(RiskAssessmentService.lossToleranceOptions[i]['label'] as String),
                  onChanged: (v) => setState(() {
                    _lossToleranceIndex = v;
                    _computeScore();
                  }),
                );
              }),

              const SizedBox(height: 8),

              _buildQuestionTitle('3. How experienced are you with investments?', required: true),
              ...List.generate(RiskAssessmentService.experienceOptions.length, (i) {
                return RadioListTile<int>(
                  value: i,
                  groupValue: _experienceIndex,
                  title: Text(RiskAssessmentService.experienceOptions[i]['label'] as String),
                  onChanged: (v) => setState(() {
                    _experienceIndex = v;
                    _computeScore();
                  }),
                );
              }),

              const SizedBox(height: 8),

              _buildQuestionTitle('4. How would you react to short-term market volatility?', required: true),
              ...List.generate(RiskAssessmentService.volatilityReactionOptions.length, (i) {
                return RadioListTile<int>(
                  value: i,
                  groupValue: _volatilityReactionIndex,
                  title: Text(RiskAssessmentService.volatilityReactionOptions[i]['label'] as String),
                  onChanged: (v) => setState(() {
                    _volatilityReactionIndex = v;
                    _computeScore();
                  }),
                );
              }),

              const SizedBox(height: 12),

              _buildQuestionTitle('5. Percentage of your income from employment/business:'),
              Text('${_incomeRatio.toStringAsFixed(0)}%'),
              Slider(
                min: 0,
                max: 100,
                divisions: 100,
                value: _incomeRatio,
                label: '${_incomeRatio.toStringAsFixed(0)}%',
                onChanged: (v) => setState(() {
                  _incomeRatio = v;
                  _computeScore();
                }),
              ),

              const SizedBox(height: 12),

              _buildQuestionTitle('6. Desired investment income as % of current income:'),
              Text('${_desiredReturnRatio.toStringAsFixed(0)}%'),
              Slider(
                min: 0,
                max: 100,
                divisions: 100,
                value: _desiredReturnRatio,
                label: '${_desiredReturnRatio.toStringAsFixed(0)}%',
                onChanged: (v) => setState(() {
                  _desiredReturnRatio = v;
                  _computeScore();
                }),
              ),

              const SizedBox(height: 12),

              _buildQuestionTitle('7. Investment time horizon (years):'),
              Text('${_timeHorizon.toInt()} yrs'),
              Slider(
                min: 1,
                max: 30,
                divisions: 29,
                value: _timeHorizon,
                label: '${_timeHorizon.toInt()} yrs',
                onChanged: (v) => setState(() {
                  _timeHorizon = v;
                  _computeScore();
                }),
              ),

              const SizedBox(height: 12),

              _buildQuestionTitle('8. When will you need to access the invested funds?'),
              ...List.generate(RiskAssessmentService.liquidityNeedOptions.length, (i) {
                return RadioListTile<int>(
                  value: i,
                  groupValue: _liquidityNeedIndex,
                  title: Text(RiskAssessmentService.liquidityNeedOptions[i]['label'] as String),
                  onChanged: (v) => setState(() {
                    _liquidityNeedIndex = v;
                    _computeScore();
                  }),
                );
              }),

              const SizedBox(height: 12),

              _buildQuestionTitle('9. How many months of living expenses do you have in emergency savings? (approx.)'),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: 24,
                      divisions: 24,
                      value: _emergencyFundMonths.toDouble(),
                      label: '$_emergencyFundMonths months',
                      onChanged: (v) => setState(() {
                        _emergencyFundMonths = v.toInt();
                        _computeScore();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 64, child: Text('$_emergencyFundMonths m')),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isFormComplete ? _onContinue : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.0),
                        child: Text('Calculate Risk & Continue'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('- Be honest: conservative answers -> conservative recommendations.'),
                      Text('- Review risk profile yearly or after major life events.'),
                      Text('- This is a suitability guide; final recommendations should consider tax and legal constraints.'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
