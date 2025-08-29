import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/offline_data_service.dart';
import '../models/goal.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'emergency_fund_calculator_screen.dart';

class EmergencyFundScreen extends StatefulWidget {
  const EmergencyFundScreen({Key? key}) : super(key: key);

  @override
  _EmergencyFundScreenState createState() => _EmergencyFundScreenState();
}

class _EmergencyFundScreenState extends State<EmergencyFundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _expenseController = TextEditingController();
  double _months = 3;
  double? _result;

  @override
  void dispose() {
    _expenseController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final expense = double.parse(_expenseController.text);
    setState(() {
      _result = expense * _months;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final svc = Provider.of<OfflineDataService>(context, listen: false);
    final profileId = int.tryParse(auth.currentProfile?.id ?? '') ?? 0;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Header section
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: FedhaColors.primaryGreen,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.security,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Emergency Fund',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Build your safety net for unexpected expenses',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Goal>>(
              future: svc.getAllGoals(profileId),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final goals = snapshot.data ?? [];
                final emergencyGoals =
                    goals.where((g) => g.name == 'Emergency Fund').toList();
                if (emergencyGoals.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: emergencyGoals.length,
                  itemBuilder: (context, index) {
                    return _buildGoalCard(emergencyGoals[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: SafeArea(
        minimum: const EdgeInsets.only(bottom: 24),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EmergencyFundCalculatorScreen(),
              ),
            );
          },
          icon: const Icon(Icons.calculate),
          label: const Text('Calculate'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.safety_divider, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Emergency Fund Goal Yet!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Protect yourself by building an emergency fund. '
              'Calculate how much you need and set it as a goal.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmergencyFundCalculatorScreen(),
                  ),
                );
              },
              child: const Text('Start Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final progress = goal.progressPercentage / 100;
    final isCompleted = goal.isCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.name,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${goal.progressPercentage.toStringAsFixed(1)}% complete',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Target: ${goal.targetAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Due: ${goal.targetDate.day}/${goal.targetDate.month}/${goal.targetDate.year}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
