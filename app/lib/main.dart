//App entry point
import 'package:hive_flutter/hive_flutter.dart';
import 'models/profile.dart';
import 'models/transaction.dart';
import 'package:fedha/services/auth_service.dart';
import 'package:fedha/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/profile_selector.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fedha',
      home: ProfileSelectorScreen(),
    );
  }
}