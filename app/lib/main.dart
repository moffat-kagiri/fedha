// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'models/profile.dart';

Future<void> _initHive() async {
  await Hive.initFlutter();

  // Register adapters only once
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ProfileAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TransactionAdapter());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initHive();
    final transactionBox = await Hive.openBox<Transaction>('transactions');
    final profileBox = await Hive.openBox<Profile>('profiles');

    runApp(
      MultiProvider(
        providers: [
          Provider<Box<Transaction>>.value(value: transactionBox),
          Provider<Box<Profile>>.value(value: profileBox),
          // Add other providers
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Initialization failed: $e'))),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(child: Text('Welcome to your Budget Tracker!')),
    );
  }
}
