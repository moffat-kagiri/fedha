import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/risk_assessment_service.dart';
import 'package:drift/drift.dart' show OrderingTerm, OrderingMode;
import 'investment_irr_calculator_screen.dart';
import 'investment_recommendations_screen.dart';
import 'investment_risk_assessment_screen.dart';
import '../data/app_database.dart';
import '../utils/logger.dart';

class InvestmentCalculatorScreen extends StatefulWidget {
  const InvestmentCalculatorScreen({Key? key}) : super(key: key);

  @override
  _InvestmentCalculatorScreenState createState() => _InvestmentCalculatorScreenState();
}

class _InvestmentCalculatorScreenState extends State<InvestmentCalculatorScreen> {
  late Future<RiskAssessment?> _latestRiskFuture;

  @override
  void initState() {
    super.initState();
    _latestRiskFuture = _loadLatestAssessment();
  }

  Future<RiskAssessment?> _loadLatestAssessment() async {
    final service = Provider.of<RiskAssessmentService>(context, listen: false);
    final query = service.db.select(service.db.riskAssessments)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    final list = await query.get();
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Investment Calculator')),
      body: FutureBuilder<RiskAssessment?>(
        future: _latestRiskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final assessment = snapshot.data;
          if (assessment == null) {
            // No prior assessment
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InvestmentRiskAssessmentScreen()),
                  ).then((_) {
                    setState(() {
                      _latestRiskFuture = _loadLatestAssessment();
                    });
                  });
                },
                child: const Text('Start Investment Assessment'),
              ),
            );
          }
          // Has assessment: show profile and calculators
          final profile = RiskAssessmentService.profileFromScore(assessment.riskScore);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Your Risk Profile: $profile',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InvestmentRiskAssessmentScreen()),
                    ).then((_) {
                      setState(() {
                        _latestRiskFuture = _loadLatestAssessment();
                      });
                    });
                  },
                  icon: const Icon(Icons.assessment),
                  label: const Text('Re-assess Risk'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InvestmentIRRCalculatorScreen()),
                    );
                  },
                  icon: const Icon(Icons.show_chart),
                  label: const Text('IRR Calculator'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => InvestmentRecommendationsScreen(
                        riskScore: assessment.riskScore,
                      )),
                    );
                  },
                  icon: const Icon(Icons.lightbulb),
                  label: const Text('Recommendations'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
