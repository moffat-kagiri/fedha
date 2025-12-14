// ============================================================================
// lib/screens/home_cover_screen.dart
// ENHANCED: Applied reusable components (PremiumScreenHeader, InsuranceResultCard)
// Material 3 design with smooth animations and consistent UI
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeCoverScreen extends StatefulWidget {
  const HomeCoverScreen({Key? key}) : super(key: key);

  @override
  _HomeCoverScreenState createState() => _HomeCoverScreenState();
}

class _HomeCoverScreenState extends State<HomeCoverScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  double _homeValue = 0;
  bool _submitted = false;
  double _premium = 0;
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
    
    // Calculate comprehensive home insurance premium (0.25% of home value)
    _premium = _homeValue * 0.0025;
    
    // Build insurance coverage options sorted by premium
    _options = [
      {
        'name': 'Contents Only',
        'subtitle': 'Covers personal belongings and furniture',
        'premium': _homeValue * 0.0005,
        'icon': Icons.chair_outlined,
      },
      {
        'name': 'Fire & Theft',
        'subtitle': 'Protection against fire and burglary',
        'premium': _homeValue * 0.001,
        'icon': Icons.local_fire_department_outlined,
      },
      {
        'name': 'Comprehensive',
        'subtitle': 'Full coverage including structure and contents',
        'premium': _premium,
        'icon': Icons.home,
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
              icon: Icons.home,
              title: 'Home Insurance',
              subtitle: 'Protect your home and belongings with comprehensive coverage',
              backgroundColor: FedhaColors.primaryGreen,
            ),
            
            const SizedBox(height: 24),
            
            // ============================================================================
            // INPUT FORM SECTION
            // Collects home value for insurance premium calculation
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
                          'Property Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: FedhaColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your property details for accurate quotes',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Home value input
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Home Sum Insured (Ksh)',
                            prefixIcon: Icon(Icons.home_work),
                            helperText: 'Estimated replacement value of your home',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => (v == null || double.tryParse(v) == null)
                              ? 'Enter valid value'
                              : null,
                          onSaved: (v) => _homeValue = double.parse(v!),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Info box with coverage explanation
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: FedhaColors.infoBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: FedhaColors.infoBlue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: FedhaColors.infoBlue,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'What is Sum Insured?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: FedhaColors.infoBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This is the maximum amount your insurer will pay to rebuild or repair your home after a covered loss.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Calculate button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _calculate,
                            icon: const Icon(Icons.calculate),
                            label: const Text('Calculate Premiums'),
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
            // Shows available home insurance plan options
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
                      // Section title for available plans
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              color: FedhaColors.primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Available Coverage Plans',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
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
                            icon: opt['icon'] as IconData,
                            title: opt['name'],
                            subtitle: opt['subtitle'],
                            coverAmount: 'Ksh ${_homeValue.toStringAsFixed(0)}',
                            premium: 'Ksh ${opt['premium'].toStringAsFixed(0)}/year',
                            onGetQuote: () {
                              // Show detailed quote information
                              _showQuoteDialog(context, opt);
                            },
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 24),
                      
                      // Coverage comparison info box
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          color: Colors.amber[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.amber[200]!,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star_outline,
                                  color: Colors.amber[700],
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Recommendation',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Comprehensive coverage provides the best protection for your investment.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // ============================================================================
                      // ACTION BUTTONS SECTION
                      // Contact agent and completion options
                      // ============================================================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Contact agent button (full width)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: Integrate contact agent functionality
                                  _showContactDialog(context);
                                },
                                icon: const Icon(Icons.support_agent),
                                label: const Text('Contact an Agent'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Completion message with navigation
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: FedhaColors.successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: FedhaColors.successGreen.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: FedhaColors.successGreen,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'You\'ve completed all insurance quotes! Review your selections or contact an agent.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
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
  
  /// Shows dialog with detailed quote information
  void _showQuoteDialog(BuildContext context, Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              plan['icon'] as IconData,
              color: FedhaColors.primaryGreen,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(plan['name'])),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogRow('Coverage Type', plan['subtitle']),
            const SizedBox(height: 12),
            _buildDialogRow('Property Value', 'Ksh ${_homeValue.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            _buildDialogRow(
              'Annual Premium',
              'Ksh ${plan['premium'].toStringAsFixed(0)}',
              highlight: true,
            ),
            const SizedBox(height: 12),
            _buildDialogRow(
              'Monthly Premium',
              'Ksh ${(plan['premium'] / 12).toStringAsFixed(0)}',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getCoverageDescription(plan['name']),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showContactDialog(context);
            },
            child: const Text('Get This Quote'),
          ),
        ],
      ),
    );
  }

  /// Builds a row in the dialog for displaying information
  Widget _buildDialogRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 16 : 14,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color: highlight ? FedhaColors.primaryGreen : Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Returns detailed coverage description for each plan type
  String _getCoverageDescription(String planName) {
    switch (planName) {
      case 'Contents Only':
        return 'Covers personal belongings, furniture, and appliances inside your home against theft, fire, and other perils.';
      case 'Fire & Theft':
        return 'Protects your home structure and contents against fire damage and burglary. Does not cover water damage or natural disasters.';
      case 'Comprehensive':
        return 'Full coverage including structure, contents, fire, theft, water damage, natural disasters, and third-party liability.';
      default:
        return 'Contact an agent for detailed coverage information.';
    }
  }

  /// Shows dialog for contacting an insurance agent
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.support_agent, color: FedhaColors.primaryGreen),
            SizedBox(width: 8),
            Text('Contact an Agent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our insurance specialists are ready to help you find the perfect coverage for your home.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FedhaColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.phone, size: 18, color: FedhaColors.primaryGreen),
                      SizedBox(width: 8),
                      Text(
                        '+254 700 123 456',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.email, size: 18, color: FedhaColors.primaryGreen),
                      SizedBox(width: 8),
                      Text(
                        'insurance@fedha.com',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual contact functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Request submitted! An agent will contact you shortly.'),
                  backgroundColor: FedhaColors.successGreen,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Request Callback'),
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
    final bgColor = backgroundColor ?? FedhaColors.primaryGreen;
    
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
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
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
                    color: FedhaColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: FedhaColors.primaryGreen,
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: FedhaColors.primaryGreen,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _buildInfoRow('Cover Amount', coverAmount),
            const SizedBox(height: 8),
            _buildInfoRow('Annual Premium', premium, highlight: true),
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

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 20 : 16,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color: highlight ? FedhaColors.primaryGreen : Colors.black87,
          ),
        ),
      ],
    );
  }
}