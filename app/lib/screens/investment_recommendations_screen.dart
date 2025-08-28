import 'package:flutter/material.dart';

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
    double expectedReturn;
    List<Map<String, dynamic>> vehicles;
    if (riskScore < 30) {
      expectedReturn = 4;
      vehicles = [
        {'icon': Icons.savings, 'name': 'Government Bonds', 'description': 'Low risk government securities.'},
        {'icon': Icons.account_balance, 'name': 'High-Yield Savings Account', 'description': 'Stable but lower yields.'},
      ];
    } else if (riskScore < 70) {
      expectedReturn = 8;
      vehicles = [
        {'icon': Icons.business, 'name': 'Index Funds', 'description': 'Diversified market index funds.'},
        {'icon': Icons.real_estate_agent, 'name': 'REITs', 'description': 'Real Estate Investment Trusts.'},
      ];
    } else {
      expectedReturn = 12;
      vehicles = [
        {'icon': Icons.show_chart, 'name': 'Stocks', 'description': 'High-growth equity investments.'},
        {'icon': Icons.trending_up, 'name': 'Cryptocurrency', 'description': 'High risk digital assets.'},
      ];
    }
    return {'expectedReturn': expectedReturn, 'vehicles': vehicles};
  }
}
