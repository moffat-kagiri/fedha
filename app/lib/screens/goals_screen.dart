import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/offline_data_service.dart';
import '../services/auth_service.dart';
import '../models/goal.dart';
import 'add_goal_screen.dart';
import 'progressive_goal_wizard_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Financial Goals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF007A39),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF007A39)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, color: Color(0xFF007A39)),
            onSelected: (value) {
              if (value == 'quick') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddGoalScreen(),
                  ),
                );
              } else if (value == 'wizard') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProgressiveGoalWizardScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'quick',
                child: Row(
                  children: [
                    Icon(Icons.speed, color: Color(0xFF007A39)),
                    SizedBox(width: 8),
                    Text('Quick Goal (1-9 months)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'wizard',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF007A39)),
                    SizedBox(width: 8),
                    Text('Progressive Goal Wizard'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Goal>>(
        future: Provider.of<OfflineDataService>(context, listen: false)
            .getAllGoals(int.tryParse(Provider.of<AuthService>(context, listen: false)
                    .currentProfile?.id ?? '') ?? 0),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final goals = snapshot.data ?? [];
          
          if (goals.isEmpty) {
            return _buildEmptyState();
          }
          
          // Group goals by status
          final activeGoals = goals.where((g) => g.status == 'active').toList();
          final completedGoals = goals.where((g) => g.status == 'completed').toList();
          final pausedGoals = goals.where((g) => g.status == 'paused').toList();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                _buildSummarySection(goals),
                
                const SizedBox(height: 24),
                
                // Active Goals
                if (activeGoals.isNotEmpty) ...[
                  _buildSectionHeader('Active Goals', activeGoals.length),
                  const SizedBox(height: 12),
                  ...activeGoals.map((goal) => _buildGoalCard(goal)),
                  const SizedBox(height: 24),
                ],
                
                // Completed Goals
                if (completedGoals.isNotEmpty) ...[
                  _buildSectionHeader('Completed Goals', completedGoals.length),
                  const SizedBox(height: 12),
                  ...completedGoals.map((goal) => _buildGoalCard(goal)),
                  const SizedBox(height: 24),
                ],
                
                // Paused Goals
                if (pausedGoals.isNotEmpty) ...[
                  _buildSectionHeader('Paused Goals', pausedGoals.length),
                  const SizedBox(height: 12),
                  ...pausedGoals.map((goal) => _buildGoalCard(goal)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.flag,
                size: 60,
                color: Color(0xFF007A39),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Goals Yet! 🎯',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF007A39),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Start your financial journey by setting your first goal. Whether it\'s saving for an emergency fund or planning a major purchase, we\'ll help you get there!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddGoalScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.speed),
                    label: const Text('Quick Goal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A39),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgressiveGoalWizardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('SMART Wizard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF007A39),
                      side: const BorderSide(color: Color(0xFF007A39)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(List<Goal> goals) {
    final totalGoals = goals.length;
    final activeGoals = goals.where((g) => g.status == 'active').length;
    final completedGoals = goals.where((g) => g.status == 'completed').length;
    final totalTarget = goals.fold<double>(0, (sum, goal) => sum + goal.targetAmount);
    final totalSaved = goals.fold<double>(0, (sum, goal) => sum + goal.currentAmount);
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Goals',
            totalGoals.toString(),
            Icons.flag,
            const Color(0xFF007A39),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Active',
            activeGoals.toString(),
            Icons.trending_up,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Completed',
            completedGoals.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF007A39),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007A39),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final progress = goal.currentAmount / goal.targetAmount;
    final progressPercentage = (progress * 100).clamp(0, 100);
    final isCompleted = goal.status == 'completed';
    final isPaused = goal.status == 'paused';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.withValues(red: 76, green: 175, blue: 80, alpha: 0.3)
              : isPaused 
                  ? Colors.orange.withValues(red: 255, green: 152, blue: 0, alpha: 0.3)
                  : const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A39),
                      ),
                    ),
                    if (goal.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        goal.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.green.withValues(red: 76, green: 175, blue: 80, alpha: 0.1)
                      : isPaused 
                          ? Colors.orange.withValues(red: 255, green: 152, blue: 0, alpha: 0.1)
                          : const Color(0xFF007A39).withValues(red: 0, green: 122, blue: 57, alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  goal.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCompleted 
                        ? Colors.green
                        : isPaused 
                            ? Colors.orange
                            : const Color(0xFF007A39),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ksh ${goal.currentAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007A39),
                ),
              ),
              Text(
                'Ksh ${goal.targetAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted 
                  ? Colors.green
                  : isPaused 
                      ? Colors.orange
                      : const Color(0xFF007A39),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progressPercentage.toStringAsFixed(1)}% complete',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Due: ${goal.targetDate.day}/${goal.targetDate.month}/${goal.targetDate.year}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
