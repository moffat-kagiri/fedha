import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'health_cover_screen.dart';

class AssetProtectionIntroScreen extends StatelessWidget {
  const AssetProtectionIntroScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pages = [
      {
        'title': 'Health & Family',
        'description': 'Your health and loved ones are priceless. The right cover secures care and income when crisis hits—so healing, not bills, becomes the priority.'
      },
      {
        'title': 'Home & Sentimentals',
        'description': 'Home holds memories and stability. Insurance restores what can be replaced and protects what can’t, keeping your life’s foundation intact after loss.'
      },
      {
        'title': 'Vehicle & Functionals',
        'description': 'Vehicles and tools power daily life and work. Sufficient cover fixes damage, handles liability, and stops one accident from turning into long-term disruption.'
      },
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FedhaColors.primaryGreen,
        title: const Text('Asset Protection'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        page['title']!,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: FedhaColors.primaryGreen),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page['description']!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FedhaColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HealthCoverScreen()),
                );
              },
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}
