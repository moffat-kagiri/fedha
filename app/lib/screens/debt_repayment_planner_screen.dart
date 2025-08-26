import 'package:flutter/material.dart';
import 'loans_tracker_screen.dart';
import 'loan_calculator_screen.dart';

/// Debt Repayment Planner: combines loan tracker and calculator
class DebtRepaymentPlannerScreen extends StatelessWidget {
  const DebtRepaymentPlannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Debt Repayment Planner'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Loans', icon: Icon(Icons.account_balance)),
              Tab(text: 'Calculator', icon: Icon(Icons.calculate)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LoansTrackerScreen(),
            LoanCalculatorScreen(),
          ],
        ),
      ),
    );
  }
}
