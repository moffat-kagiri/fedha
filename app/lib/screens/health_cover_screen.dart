// ============================================================================
// lib/screens/health_cover_screen.dart
// ENHANCED: Applied reusable components (PremiumScreenHeader, InsuranceResultCard)
// Material 3 design with smooth animations and consistent UI
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HealthCoverScreen extends StatefulWidget {
  const HealthCoverScreen({Key? key}) : super(key: key);

  @override
  _HealthCoverScreenState createState() => _HealthCoverScreenState();
}

class _HealthCoverScreenState extends State<HealthCoverScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  double _monthlyIncome = 0;
  bool _isMarried = false;
  bool _hasChildren = false;
  bool _submitted = false;

  double _healthcareMin = 0;
  double _healthcareMax = 0;
  List<Map<String, dynamic>> _options = [];

  // Animation controllers for smooth result reveal
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations for result cards
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuint,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    // Calculate annual income and healthcare budget (1-5% of annual income)
    final annualIncome = _monthlyIncome * 12;
    _healthcareMin = annualIncome * 0.01;
    _healthcareMax = annualIncome * 0.05;
    
    // Build sample insurance plan options sorted by premium
    _options = [
      {
        'name': 'Basic Plan',
        'subtitle': 'Essential coverage for emergencies',
        'coverage': _healthcareMin * 100,
        'premium': _healthcareMin,
      },
      {
        'name': 'Standard Plan',
        'subtitle': 'Comprehensive outpatient & inpatient',
        'coverage': _healthcareMax * 50,
        'premium': (_healthcareMin + _healthcareMax) / 2,
      },
      {
        'name': 'Premium Plan',
        'subtitle': 'Full coverage with no limits',
        'coverage': _healthcareMax * 100,
        'premium': _healthcareMax,
      },
    ];
    
    // Sort options by premium (lowest to highest)
    _options.sort((a, b) => a['premium'].compareTo(b['premium']));
    
    setState(() => _submitted = true);
    
    // Trigger animation when results appear
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================================
            // REUSABLE COMPONENT: PremiumScreenHeader
            // Provides consistent header design across all insurance screens
            // ============================================================================
            PremiumScreenHeader(
              icon: Icons.favorite,
              title: 'Health Insurance',
              subtitle: 'Protect yourself and your family with comprehensive medical coverage',
              backgroundColor: colorScheme.primary,
            ),
            
            const SizedBox(height: 24),
            
            // ============================================================================
            // INPUT FORM SECTION
            // Collects user income and family details for recommendation calculation
            // ============================================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form title
                        Text(
                          'Your Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help us recommend the right plan for you',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Monthly income input
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Monthly Income (Ksh)',
                            prefixIcon: Icon(Icons.attach_money),
                            helperText: 'Your gross monthly income',
                            labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => (v == null || double.tryParse(v) == null)
                              ? 'Enter valid income'
                              : null,
                          onSaved: (v) => _monthlyIncome = double.tryParse(v!) ?? 0,
                        ),
                        const SizedBox(height: 16),
                        
                        // Marital status switch
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? colorScheme.surfaceVariant : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              'Married?',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              'Include spouse in coverage',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            value: _isMarried,
                            activeColor: colorScheme.primary,
                            onChanged: (v) => setState(() => _isMarried = v),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Children status switch
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? colorScheme.surfaceVariant : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              'Do you have children?',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              'Include dependents in coverage',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            value: _hasChildren,
                            activeColor: colorScheme.primary,
                            onChanged: (v) => setState(() => _hasChildren = v),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Calculate button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _calculate,
                            icon: const Icon(Icons.calculate),
                            label: const Text('Calculate Recommendations'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // ============================================================================
            // RESULTS SECTION (Animated)
            // Shows recommended coverage range and available plan options
            // ============================================================================
            if (_submitted) ...[
              const SizedBox(height: 24),
              
              // Animated results container
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      // Recommended coverage range card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          elevation: 2,
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: colorScheme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: colorScheme.primary,
                                  size: 32,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Recommended Annual Coverage',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ksh ${_healthcareMin.toStringAsFixed(0)} - ${_healthcareMax.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Based on 1-5% of your annual income',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Section title for available plans
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.list_alt,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Available Plans',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // ============================================================================
                      // REUSABLE COMPONENT: InsuranceResultCard (Multiple instances)
                      // Display each plan option with consistent card design
                      // ============================================================================
                      ...List.generate(_options.length, (index) {
                        final opt = _options[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: InsuranceResultCard(
                            icon: _getIconForPlan(opt['name']),
                            title: opt['name'],
                            subtitle: opt['subtitle'],
                            coverAmount: 'Ksh ${opt['coverage'].toStringAsFixed(0)}',
                            premium: 'Ksh ${opt['premium'].toStringAsFixed(0)}/year',
                            onGetQuote: () {
                              // TODO: Navigate to detailed quote page or contact agent
                              _showQuoteDialog(context, opt);
                            },
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 24),
                      
                      // ============================================================================
                      // ACTION BUTTONS SECTION
                      // Navigation and contact options
                      // ============================================================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Contact agent button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: Integrate contact agent functionality
                                  _showContactDialog(context);
                                },
                                icon: const Icon(Icons.support_agent),
                                label: const Text('Contact Agent'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                  side: BorderSide(color: colorScheme.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Next screen button (Vehicle insurance)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to vehicle insurance screen
                                  Navigator.pushNamed(context, '/asset_protection_vehicle');
                                },
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Next: Vehicle'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Returns appropriate icon for each plan type
  IconData _getIconForPlan(String planName) {
    if (planName.contains('Basic')) return Icons.medical_services_outlined;
    if (planName.contains('Standard')) return Icons.medical_services;
    if (planName.contains('Premium')) return Icons.health_and_safety;
    return Icons.favorite;
  }

  /// Shows dialog with quote details
  void _showQuoteDialog(BuildContext context, Map<String, dynamic> plan) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          plan['name'],
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coverage: Ksh ${plan['coverage'].toStringAsFixed(0)}',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Annual Premium: Ksh ${plan['premium'].toStringAsFixed(0)}',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              plan['subtitle'],
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showContactDialog(context);
            },
            child: const Text('Get Quote'),
          ),
        ],
      ),
    );
  }

  /// Shows dialog for contacting an agent
  void _showContactDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Contact an Agent',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'An insurance agent will contact you shortly to discuss your coverage options and provide a detailed quote.',
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual contact functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Request submitted successfully!'),
                  backgroundColor: FedhaColors.successGreen,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// REUSABLE COMPONENT: PremiumScreenHeader
// (Include this if not already in a shared widgets file)
// ============================================================================

class PremiumScreenHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? backgroundColor;

  const PremiumScreenHeader({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.primary;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            bgColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onPrimary.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// REUSABLE COMPONENT: InsuranceResultCard
// (Include this if not already in a shared widgets file)
// ============================================================================

class InsuranceResultCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String coverAmount;
  final String premium;
  final String? subtitle;
  final VoidCallback? onGetQuote;

  const InsuranceResultCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.coverAmount,
    required this.premium,
    this.subtitle,
    this.onGetQuote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: colorScheme.outline.withOpacity(0.3)),
            const SizedBox(height: 12),
            _buildInfoRow('Cover Amount', coverAmount, colorScheme: colorScheme),
            const SizedBox(height: 8),
            _buildInfoRow('Annual Premium', premium, highlight: true, colorScheme: colorScheme),
            if (onGetQuote != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onGetQuote,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Get Full Quote'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {
    required ColorScheme colorScheme,
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 20 : 16,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color: highlight ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}