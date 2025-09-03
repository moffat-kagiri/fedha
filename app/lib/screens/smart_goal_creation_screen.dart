import 'package:flutter/material.dart';

class SmartGoalCreationScreen extends StatefulWidget {
  const SmartGoalCreationScreen({Key? key}) : super(key: key);

  @override
  State<SmartGoalCreationScreen> createState() => _SmartGoalCreationScreenState();
}

class _SmartGoalCreationScreenState extends State<SmartGoalCreationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Goal Creation'),
      ),
      body: const SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Smart Goal Creation',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Coming Soon',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
