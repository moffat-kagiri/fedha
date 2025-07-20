import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Financial Tools',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF007A39),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF007A39)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007A39), Color(0xFF005A2B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Financial Toolkit 🛠️',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comprehensive tools to manage, analyze, and grow your finances',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatusIndicator('Available', Colors.white, true),
                      const SizedBox(width: 16),
                      _buildStatusIndicator('Coming Soon', Colors.white54, false),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            // Primary Tools (6 items)
            _buildSection(
              title: 'Primary Tools',
              subtitle: 'Essential financial tools',
              context: context,
              features: [
                _FeatureItem(
                  title: 'Quick Transaction Entry',
                  description: 'Fast manual transaction logging',
                  icon: Icons.add_card,
                  isAvailable: true,
                  route: '/detailed_transaction_entry',
                ),
                _FeatureItem(
                  title: 'Loans Tracker',
                  description: 'View and manage your loans',
                  icon: Icons.account_balance_wallet,
                  isAvailable: true,
                  route: '/loans_tracker',
                ),
                _FeatureItem(
                  title: 'Budget Creation',
                  description: '50/30/20 budgeting methodology',
                  icon: Icons.pie_chart,
                  isAvailable: true,
                  route: '/create_budget',
                ),
                _FeatureItem(
                  title: 'Goal Setting & Tracking',
                  description: 'SMART financial goal management',
                  icon: Icons.flag,
                  isAvailable: true,
                  route: '/goals',
                ),
                _FeatureItem(
                  title: 'Loan Calculator',
                  description: 'Newton-Raphson loan calculations',
                  icon: Icons.calculate,
                  isAvailable: true,
                  route: '/loan_calculator',
                ),
                _FeatureItem(
                  title: 'Spending Overview',
                  description: 'Analytics of your spending patterns',
                  icon: Icons.bar_chart,
                  isAvailable: true,
                  route: '/spending_overview',
                ),
              ],
            ),
            const SizedBox(height: 24),
            // More Tools (4 items)
            _buildSection(
              title: 'More Tools',
              subtitle: 'Additional financial utilities',
              context: context,
              features: [
                _FeatureItem(
                  title: 'SMS Transaction Import',
                  description: 'Real-time M-PESA & bank SMS parsing',
                  icon: Icons.sms,
                  isAvailable: true,
                  route: '/sms_review',
                ),
                _FeatureItem(
                  title: 'Expense Analytics',
                  description: 'AI-powered spending insights',
                  icon: Icons.analytics,
                  isAvailable: false,
                ),
                _FeatureItem(
                  title: 'Cash Flow Projections',
                  description: 'Predictive cash flow modeling',
                  icon: Icons.trending_up,
                  isAvailable: false,
                ),
                _FeatureItem(
                  title: 'Investment Calculator',
                  description: 'Compound interest & ROI analysis',
                  icon: Icons.trending_up,
                  isAvailable: false,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Development Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Development Roadmap',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'re actively developing new features! Coming soon features are planned for the next major releases. Check our roadmap for detailed timelines.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color color, bool isAvailable) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<_FeatureItem> features,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF007A39),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            return _buildFeatureCard(context, features[index]);
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureItem feature) {
    return GestureDetector(
      onTap: feature.isAvailable && feature.route != null
          ? () {
              if (feature.route!.startsWith('/')) {
                Navigator.pushNamed(context, feature.route!);
              }
            }
          : () {
              if (!feature.isAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${feature.title} is coming soon! 🚀'),
                    backgroundColor: const Color(0xFF007A39),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
      child: Container(
        decoration: BoxDecoration(
          color: feature.isAvailable ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: feature.isAvailable 
                ? const Color(0xFF007A39).withOpacity(0.2)
                : Colors.grey.shade300,
          ),
          boxShadow: feature.isAvailable 
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: feature.isAvailable 
                          ? const Color(0xFF007A39).withOpacity(0.1)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      feature.icon,
                      color: feature.isAvailable 
                          ? const Color(0xFF007A39)
                          : Colors.grey.shade500,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (!feature.isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Soon',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                feature.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: feature.isAvailable 
                      ? const Color(0xFF007A39)
                      : Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  feature.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: feature.isAvailable 
                        ? Colors.grey.shade600
                        : Colors.grey.shade500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (feature.isAvailable) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: const Color(0xFF007A39),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Open Tool',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF007A39),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String description;
  final IconData icon;
  final bool isAvailable;
  final String? route;

  _FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.isAvailable,
    this.route,
  });
}
