//App entry point
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fedha/services/auth_service.dart';
import 'package:fedha/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/profile_selector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Initialize Hive
  runApp(const MyApp());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
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
      title: 'Fedha',
      home: ProfileSelectorScreen(),
    );
  }
}