import 'package:flutter/material.dart';

/// Debt Repayment Planner launcher: choose between Loans Tracker and Calculator
class DebtRepaymentPlannerScreen extends StatelessWidget {
  const DebtRepaymentPlannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF007A39);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Repayment Planner'),
        backgroundColor: brandGreen,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Manage your loans or run repayment calculations',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[800],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 1,
                childAspectRatio: 3,
                mainAxisSpacing: 16,
                children: [
                  _ActionCard(
                    title: 'My Loans',
                    subtitle: 'View and manage your tracked loans',
                    icon: Icons.account_balance,
                    color: brandGreen,
                    onTap: () => Navigator.pushNamed(context, '/loans_tracker'),
                  ),
                  _ActionCard(
                    title: 'Calculator',
                    subtitle: 'Estimate repayments and schedules',
                    icon: Icons.calculate,
                    color: brandGreen,
                    onTap: () => Navigator.pushNamed(context, '/loan_calculator'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
