import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'health_cover_screen.dart';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'asset_protection_tabs_screen.dart';

class AssetProtectionIntroScreen extends StatefulWidget {
  const AssetProtectionIntroScreen({Key? key}) : super(key: key);

  @override
  State<AssetProtectionIntroScreen> createState() => _AssetProtectionIntroScreenState();
}

class _AssetProtectionIntroScreenState extends State<AssetProtectionIntroScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final List<Map<String, String>> _pages = [
    {
      'title': 'Health & Family',
      'description': 'Your health and loved ones are priceless. The right cover secures care and income when crisis hits—so healing, not bills, becomes the priority.',
    },
    {
      'title': 'Home & Sentimentals',
      'description': 'Home holds memories and stability. Insurance restores what can be replaced and protects what can’t, keeping your life’s foundation intact after loss.',
    },
    {
      'title': 'Vehicle & Functionals',
      'description': 'Vehicles and tools power daily life and work. Sufficient cover fixes damage, handles liability, and stops one accident from turning into long-term disruption.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FedhaColors.primaryGreen,
        title: const Text('Asset Protection'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          page['title']!,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(color: FedhaColors.primaryGreen),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page['description']!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FedhaColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_currentIndex < _pages.length - 1) {
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AssetProtectionTabsScreen()));
                  }
                },
                child: Text(_currentIndex < _pages.length - 1 ? 'Next' : 'Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
