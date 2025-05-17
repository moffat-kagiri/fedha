//App entry point
import 'package:hive_flutter/hive_flutter.dart';
import 'models/profile.dart';
import 'models/transaction.dart';
import 'package:fedha/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_selector.dart';
import 'widgets/transaction_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(ProfileAdapter());
  Hive.registerAdapter(TransactionAdapter());

  await Hive.openBox('profiles');
  await Hive.openBox('transactions');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: const MyApp(), // MyApp must be a child of MultiProvider
    ),
  );
}


// Update MyApp in main.dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fedha',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainNavigationWrapper(),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionList(), // Using existing TransactionList widget
    const ProfileSelectorScreen(), // Using existing ProfileSelectorScreen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
