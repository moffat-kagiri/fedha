// ============================================================================
// lib/screens/asset_protection_tabs_screen.dart
// FIXED: Added missing imports and corrected widget references
// ENHANCED: Better Material 3 design with improved headers
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'health_cover_screen.dart';
import 'vehicle_cover_screen.dart';
import 'home_cover_screen.dart';
import '../widgets/insurance_widgets.dart';

class AssetProtectionTabsScreen extends StatelessWidget {
  const AssetProtectionTabsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                backgroundColor: FedhaColors.primaryGreen,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Insurance Quotes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          FedhaColors.primaryGreen,
                          FedhaColors.primaryGreenDark,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 60,
                        top: 80,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield,
                            color: Colors.white70,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Get instant quotes for health, vehicle, and home insurance',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: FedhaColors.primaryGreen,
                    child: TabBar(
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.favorite, size: 20),
                          text: 'Health',
                        ),
                        Tab(
                          icon: Icon(Icons.directions_car, size: 20),
                          text: 'Vehicle',
                        ),
                        Tab(
                          icon: Icon(Icons.home, size: 20),
                          text: 'Home',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: const TabBarView(
            children: [
              HealthCoverScreen(),
              VehicleCoverScreen(),
              HomeCoverScreen(),
            ],
          ),
        ),
      ),
    );
  }
}