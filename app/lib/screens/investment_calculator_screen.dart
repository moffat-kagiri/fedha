import 'package:flutter/material.dart';
import 'investment_irr_calculator_screen.dart';
import 'investment_recommendations_screen.dart';
import 'investment_risk_assessment_screen.dart';

class InvestmentCalculatorScreen extends StatelessWidget {
  const InvestmentCalculatorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Investment Calculator')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InvestmentRiskAssessmentScreen(),
              ),
            );
          },
          child: const Text('Start Investment Assessment'),
        ),
      ),
    );
  }
}

class RiskAppetiteTab extends StatelessWidget {
  const RiskAppetiteTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.assessment, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Risk Appetite Assessment',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Assess your risk appetite to determine suitable investment strategies.',
              textAlign: TextAlign.center,
            ),
            // TODO: Implement questionnaire
          ],
        ),
      ),
    );
  }
}

class IRRCalculatorTab extends StatefulWidget {
  const IRRCalculatorTab({Key? key}) : super(key: key);

  @override
  State<IRRCalculatorTab> createState() => _IRRCalculatorTabState();
}

class _IRRCalculatorTabState extends State<IRRCalculatorTab> {
  // TODO: Implement IRR calculation logic with cash flow inputs
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Icon(Icons.show_chart, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'IRR Calculator',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Enter your cash flows to calculate the Internal Rate of Return.',
            textAlign: TextAlign.center,
          ),
          // TODO: Add input fields for cash flows and calculate IRR
        ],
      ),
    );
  }
}

class InvestmentResourcesTab extends StatelessWidget {
  const InvestmentResourcesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.info, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Investment Resources',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Based on your risk appetite, recommended profit margins and investment vehicles will be shown here.',
              textAlign: TextAlign.center,
            ),
            // TODO: Fetch and display resource recommendations
          ],
        ),
      ),
    );
  }
}
