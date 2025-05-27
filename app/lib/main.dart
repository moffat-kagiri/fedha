// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/profile.dart'; // Import file containing ProfileAdapter
import 'models/transaction.dart'; // Import file containing TransactionAdapter
import 'services/auth_service.dart'; // Import AuthService
import 'screens/dashboard_screen.dart'; // Import DashboardScreen
import 'screens/profile_screen.dart'; // Import ProfileScreen
import 'screens/profile_type_screen.dart'; // Import ProfileTypeScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ProfileAdapter());

  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TransactionAdapter());

  final profileBox = await Hive.openBox<Profile>('profiles');
  final transactionBox = await Hive.openBox<Transaction>('transactions');
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        Provider<Box<Profile>>.value(value: profileBox),
        Provider<Box<Transaction>>.value(value: transactionBox),
        ChangeNotifierProvider(create: (_) => authService),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      title: 'Fedha',
      theme: ThemeData(primaryColor: const Color.fromARGB(255, 0, 122, 57)),
      initialRoute: '/',
      routes: {
        '/':
            (context) =>
                authService.isLoggedIn
                    ? const DashboardScreen()
                    : const ProfileTypeScreen(),
        '/login':
            (context) =>
                const ProfileTypeScreen(), // Redirect to ProfileTypeScreen to select a profile type first
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
