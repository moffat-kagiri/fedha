// lib/screens/asset_protection_intro_screen.dart
// REDESIGNED: Compelling single-screen intro with high conversion focus

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'asset_protection_tabs_screen.dart';

class AssetProtectionIntroScreen extends StatelessWidget {
  const AssetProtectionIntroScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Dynamic colors based on theme
    final backgroundColor = colorScheme.primary;
    final surfaceColor = colorScheme.surface;
    final onPrimaryColor = colorScheme.onPrimary;
    final cardBackground = isDark 
        ? colorScheme.surface.withOpacity(0.95)
        : Colors.white.withOpacity(0.95);
    final cardTextColor = isDark 
        ? colorScheme.onSurface 
        : colorScheme.onSurface.withOpacity(0.8);
    final socialProofBg = isDark 
        ? colorScheme.onPrimary.withOpacity(0.15)
        : Colors.white.withOpacity(0.15);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: onPrimaryColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Hero Section
                    const SizedBox(height: 24),
                    
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: onPrimaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 64,
                        color: onPrimaryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Headline - Compelling and clear
                    Text(
                      'Protect What Matters',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: onPrimaryColor,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subheadline - Value proposition
                    Text(
                      'Get instant insurance quotes in 60 seconds.\nNo paperwork, no agents, just smart protection.',
                      style: TextStyle(
                        fontSize: 16,
                        color: onPrimaryColor.withOpacity(0.9),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Three compelling cards
                    _buildBenefitCard(
                      icon: Icons.favorite,
                      title: 'Health & Life',
                      description: 'Medical bills are the #1 cause of debt in Kenya. Protect your family from financial ruin.',
                      backgroundColor: cardBackground,
                      iconColor: colorScheme.primary,
                      titleColor: colorScheme.primary,
                      textColor: cardTextColor,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildBenefitCard(
                      icon: Icons.home,
                      title: 'Home & Property',
                      description: 'Your home is your biggest investment. One fire or flood shouldn\'t wipe out years of savings.',
                      backgroundColor: cardBackground,
                      iconColor: colorScheme.primary,
                      titleColor: colorScheme.primary,
                      textColor: cardTextColor,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildBenefitCard(
                      icon: Icons.directions_car,
                      title: 'Vehicle',
                      description: 'Accidents happen. Comprehensive cover means repairs won\'t drain your emergency fund.',
                      backgroundColor: cardBackground,
                      iconColor: colorScheme.primary,
                      titleColor: colorScheme.primary,
                      textColor: cardTextColor,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Social proof
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: socialProofBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (index) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"Got my quote in under a minute. So much easier than dealing with agents!"',
                            style: TextStyle(
                              fontSize: 14,
                              color: onPrimaryColor.withOpacity(0.9),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '— Sarah K., Nairobi',
                            style: TextStyle(
                              fontSize: 12,
                              color: onPrimaryColor.withOpacity(0.7),
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
            
            // CTA Section - Fixed at bottom
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AssetProtectionTabsScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Get My Free Quote',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Trust badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.security,
                        size: 16,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'No commitment required',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Data encrypted',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
    required Color backgroundColor,
    required Color iconColor,
    required Color titleColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: iconColor,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}