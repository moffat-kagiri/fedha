// ============================================================================
// lib/widgets/insurance_widgets.dart
// SHARED REUSABLE COMPONENTS for Insurance Screens
// Contains: PremiumScreenHeader, InsuranceResultCard
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// COMPONENT 1: Premium Header Widget
// ============================================================================
// Used at the top of individual insurance screens (Health, Vehicle, Home)
// Provides a consistent, premium-looking header with gradient background,
// icon, title, and subtitle.
//
// Usage Example:
// PremiumScreenHeader(
//   icon: Icons.favorite,
//   title: 'Health Insurance',
//   subtitle: 'Protect yourself and your family',
//   backgroundColor: FedhaColors.primaryGreen,
// )
// ============================================================================

class PremiumScreenHeader extends StatelessWidget {
  /// Icon displayed in the header (e.g., Icons.favorite, Icons.home)
  final IconData icon;
  
  /// Main title text (e.g., "Health Insurance")
  final String title;
  
  /// Subtitle/description text (e.g., "Protect yourself and your family")
  final String subtitle;
  
  /// Optional background color (defaults to FedhaColors.primaryGreen)
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
    // Use provided background color or default to primary green
    final bgColor = backgroundColor ?? FedhaColors.primaryGreen;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Gradient background for visual depth
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            bgColor.withOpacity(0.8),
          ],
        ),
        // Rounded bottom corners for modern look
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        // Subtle shadow for depth
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
          // Icon container with circular background
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
          
          // Main title
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
          
          // Subtitle/description
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
// COMPONENT 2: Insurance Result Card
// ============================================================================
// Displays insurance plan details in a consistent card format.
// Shows icon, title, subtitle, cover amount, premium, and optional action button.
//
// Usage Example:
// InsuranceResultCard(
//   icon: Icons.medical_services,
//   title: 'Standard Plan',
//   subtitle: 'Comprehensive outpatient & inpatient',
//   coverAmount: 'Ksh 500,000',
//   premium: 'Ksh 5,000/year',
//   onGetQuote: () => print('Get quote tapped'),
// )
// ============================================================================

class InsuranceResultCard extends StatelessWidget {
  /// Icon representing the insurance plan type
  final IconData icon;
  
  /// Plan name (e.g., "Basic Plan", "Comprehensive")
  final String title;
  
  /// Maximum coverage amount (e.g., "Ksh 1,000,000")
  final String coverAmount;
  
  /// Premium cost (e.g., "Ksh 5,000/year")
  final String premium;
  
  /// Optional subtitle/description (e.g., "Essential coverage")
  final String? subtitle;
  
  /// Optional callback when "Get Full Quote" button is tapped
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
            // Header row with icon and title
            Row(
              children: [
                // Icon container with background
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
                
                // Title and subtitle column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plan title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: FedhaColors.primaryGreen,
                        ),
                      ),
                      
                      // Optional subtitle
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
            
            // Coverage amount row
            _buildInfoRow('Cover Amount', coverAmount),
            const SizedBox(height: 8),
            
            // Premium amount row (highlighted)
            _buildInfoRow('Monthly Premium', premium, highlight: true),
            
            // Optional "Get Full Quote" button
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

  /// Helper method to build info rows (label + value)
  /// Set highlight=true to emphasize the value (e.g., for premium)
  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Label text
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        
        // Value text (optionally highlighted)
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