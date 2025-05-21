// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/main_navigation.dart'; // New file we'll create

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProfileAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TransactionAdapter());

  final transactionBox = await Hive.openBox<Transaction>('transactions');
  final profileBox = await Hive.openBox<Profile>('profiles');

  runApp(
    MultiProvider(
      providers: [
        Provider<Box<Transaction>>.value(value: transactionBox),
        Provider<Box<Profile>>.value(value: profileBox),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Tracker',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MainNavigationWrapper(), // Updated home
      debugShowCheckedModeBanner: false,
    );
  }
}
