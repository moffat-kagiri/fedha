import 'package:flutter/material.dart';
import '../services/risk_assessment_service.dart';

class InvestmentRecommendationsScreen extends StatelessWidget {
  final double riskScore;
  final double? calculatedIrr;

  const InvestmentRecommendationsScreen({
    super.key,
    required this.riskScore,
    this.calculatedIrr,
  });

  @override
  Widget build(BuildContext context) {
    final recommendations = _generateRecommendations();
    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Based on your risk appetite of ${riskScore.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'We suggest the following profit margin:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${recommendations['expectedReturn']}%',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Investment Vehicles:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...recommendations['vehicles'].map<Widget>((v) => ListTile(
              leading: Icon(v['icon']),
              title: Text(v['name']),
              subtitle: Text(v['description']),
            )),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _generateRecommendations() {
    // Determine allocation based on risk profile
    final profile = RiskAssessmentService.profileFromScore(riskScore);
    final allocation = RiskAssessmentService.recommendedAllocation(profile);
    // Determine expected return based on risk score
    double expectedReturn;
    if (riskScore < 30) {
      expectedReturn = 4;
    } else if (riskScore < 70) {
      expectedReturn = 8;
    } else {
      expectedReturn = 12;
    }
    // Build vehicle recommendations from asset allocation
    final vehicles = <Map<String, dynamic>>[];
    allocation.forEach((asset, percent) {
      if (percent > 0) {
        switch (asset) {
          case 'Bonds/Cash':
            vehicles.add({'icon': Icons.savings, 'name': 'Government Bonds', 'description': 'Low risk government securities.'});
            vehicles.add({'icon': Icons.account_balance, 'name': 'High-Yield Savings', 'description': 'Stable yield savings account.'});
            break;
          case 'Equities':
            vehicles.add({'icon': Icons.show_chart, 'name': 'Index Funds', 'description': 'Diversified market funds.'});
            vehicles.add({'icon': Icons.trending_up, 'name': 'Stocks', 'description': 'Equity investments.'});
            break;
          case 'Alternatives':
            vehicles.add({'icon': Icons.real_estate_agent, 'name': 'REITs', 'description': 'Real estate trusts.'});
            vehicles.add({'icon': Icons.currency_bitcoin, 'name': 'Alternative Assets', 'description': 'REITs, crypto, and more.'});
            break;
        }
      }
    });
    return {'expectedReturn': expectedReturn, 'vehicles': vehicles};
  }
}
