import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'health_cover_screen.dart';
import 'vehicle_cover_screen.dart';
import 'home_cover_screen.dart';

class AssetProtectionTabsScreen extends StatelessWidget {
  const AssetProtectionTabsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: FedhaColors.primaryGreen,
          title: const Text('Asset Protection'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Health'),
              Tab(text: 'Vehicle'),
              Tab(text: 'Home'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HealthCoverScreen(),
            VehicleCoverScreen(),
            HomeCoverScreen(),
          ],
        ),
      ),
    );
  }
}
