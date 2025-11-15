// lib/screens/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../services/notification_service.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'tools_screen.dart';
import 'profile_screen.dart';
import 'investment_calculator_screen.dart';
import 'investment_risk_assessment_screen.dart';
import 'investment_irr_calculator_screen.dart';
import 'investment_recommendations_screen.dart';

class MainNavigation extends StatefulWidget {
  final int currentIndex;
  final Widget? child;

  const MainNavigation({super.key, this.currentIndex = 0, this.child});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardWrapper(),
    const TransactionsScreen(),
    const ToolsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _initNotificationsIfNeeded();
  }

  Future<void> _initNotificationsIfNeeded() async {
    try {
      // Initialize notifications and register daily task only when user is logged in
      final notificationService = NotificationService.instance;
      await notificationService.initialize();

      // Ensure we only register the daily task once for the current app
      await Workmanager().cancelByUniqueName('daily_review');

      // Compute next 21:00 local time initial delay
      DateTime now = DateTime.now();
      DateTime target = DateTime(now.year, now.month, now.day, 21, 0);
      if (now.isAfter(target)) {
        target = target.add(const Duration(days: 1));
      }
      final initialDelay = target.difference(now);

      await Workmanager().registerPeriodicTask(
        'daily_review',
        'daily_review_task',
        frequency: const Duration(days: 1),
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
    } catch (e) {
      // Non-fatal; log in debug mode
      // print is avoided to keep release logs clean
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child ?? _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF007A39),
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Statements',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Tools'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Wrapper for dashboard screen to avoid circular dependency
class DashboardWrapper extends StatelessWidget {
  const DashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardContent();
  }
}

// Route settings for investment tools
final Map<String, WidgetBuilder> routes = {
  '/investment_calculator': (context) => const InvestmentCalculatorScreen(),
  '/investment_risk_assessment': (context) => const InvestmentRiskAssessmentScreen(),
  '/investment_irr_calculator': (context) => InvestmentIRRCalculatorScreen(),
  '/investment_recommendations': (context) {
    final double risk = ModalRoute.of(context)!.settings.arguments as double;
    return InvestmentRecommendationsScreen(riskScore: risk);
  },
};
