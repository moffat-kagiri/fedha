//lib/screens/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/offline_data_service.dart';
import '../services/auth_service.dart';
import '../models/goal.dart';
import '../theme/app_theme.dart';
import 'add_goal_screen.dart';
import 'progressive_goal_wizard_screen.dart';
import 'goal_details_screen.dart';
import '../models/enums.dart';
import '../services/goal_transaction_service.dart';
import '../models/transaction.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // Track if screen needs refresh
  bool _needsRefresh = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Financial Goals',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.add, color: colorScheme.onPrimary),
            onSelected: (value) async {
              if (value == 'quick') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddGoalScreen(),
                  ),
                );
                // Refresh if goal was added
                if (result == true) setState(() => _needsRefresh = true);
              } else if (value == 'wizard') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProgressiveGoalWizardScreen(),
                  ),
                );
                // Refresh if goal was added
                if (result == true) setState(() => _needsRefresh = true);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'quick',
                child: Row(
                  children: [
                    Icon(Icons.speed, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Quick Goal (1-9 months)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'wizard',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Progressive Goal Wizard'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Goal>>(
        // Use key to force rebuild when needed
        key: ValueKey(_needsRefresh),
        future: Provider.of<OfflineDataService>(context, listen: false)
            .getAllGoals(Provider.of<AuthService>(context, listen: false)
                    .currentProfile?.id ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            );
          }
          final goals = snapshot.data ?? [];
          
          if (goals.isEmpty) {
            return _buildEmptyState(context);
          }
          
          // Group goals by status
          final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList();
          final completedGoals = goals.where((g) => g.status == GoalStatus.completed).toList();
          final pausedGoals = goals.where((g) => g.status == GoalStatus.paused).toList();
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _needsRefresh = !_needsRefresh);
              // Wait a bit for the rebuild
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  _buildSummarySection(context, goals),
                  
                  const SizedBox(height: 24),
                  
                  // Active Goals
                  if (activeGoals.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Active Goals', activeGoals.length),
                    const SizedBox(height: 12),
                    ...activeGoals.map((goal) => _buildGoalCard(context, goal)),
                    const SizedBox(height: 24),
                  ],
                  
                  // Completed Goals
                  if (completedGoals.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Completed Goals', completedGoals.length),
                    const SizedBox(height: 12),
                    ...completedGoals.map((goal) => _buildGoalCard(context, goal)),
                    const SizedBox(height: 24),
                  ],
                  
                  // Paused Goals
                  if (pausedGoals.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Paused Goals', pausedGoals.length),
                    const SizedBox(height: 12),
                    ...pausedGoals.map((goal) => _buildGoalCard(context, goal)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.flag,
                size: 60,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Goals Yet! 🎯',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Start your financial journey by setting your first goal. Whether it\'s saving for an emergency fund or planning a major purchase, we\'ll help you get there!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddGoalScreen(),
                        ),
                      );
                      if (result == true) setState(() => _needsRefresh = true);
                    },
                    icon: const Icon(Icons.speed),
                    label: const Text('Quick Goal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
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
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgressiveGoalWizardScreen(),
                        ),
                      );
                      if (result == true) setState(() => _needsRefresh = true);
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('SMART Wizard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
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

  Widget _buildSummarySection(BuildContext context, List<Goal> goals) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final totalGoals = goals.length;
    final activeGoals = goals.where((g) => g.status == GoalStatus.active).length;
    final completedGoals = goals.where((g) => g.status == GoalStatus.completed).length;
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            'Total Goals',
            totalGoals.toString(),
            Icons.flag,
            colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Active',
            activeGoals.toString(),
            Icons.trending_up,
            colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Completed',
            completedGoals.toString(),
            Icons.check_circle,
            FedhaColors.successGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final progress = goal.currentAmount / goal.targetAmount;
    final progressPercentage = (progress * 100).clamp(0, 100);
    final isCompleted = goal.status == GoalStatus.completed;
    final isPaused = goal.status == GoalStatus.paused;
    
    // Determine colors based on goal status
    final statusColor = isCompleted 
        ? FedhaColors.successGreen
        : isPaused 
            ? FedhaColors.warningOrange
            : colorScheme.primary;
    
    final statusBackgroundColor = statusColor.withOpacity(0.1);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Navigate to goal details screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalDetailsScreen(goal: goal),
            ),
          );
          // Refresh if goal was updated
          if (result == true || result == null) {
            setState(() => _needsRefresh = !_needsRefresh);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (goal.description != null && goal.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            goal.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      goal.statusDisplay.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Ksh ${goal.targetAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: colorScheme.outline.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progressPercentage.toStringAsFixed(1)}% complete',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    'Due: ${_formatDate(goal.targetDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}