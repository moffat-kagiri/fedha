import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../utils/test_profile_creator.dart';

class TestProfilesScreen extends StatefulWidget {
  const TestProfilesScreen({Key? key}) : super(key: key);

  @override
  State<TestProfilesScreen> createState() => _TestProfilesScreenState();
}

class _TestProfilesScreenState extends State<TestProfilesScreen> {
  final List<String> _logs = [];
  bool _isCreatingProfiles = false;
  bool _profilesCreated = false;
  List<Profile> _profiles = [];

  void _log(String message) {
    setState(() {
      _logs.add("[${DateTime.now().toIso8601String()}] $message");
    });
  }

  Future<void> _createTestProfiles() async {
    setState(() {
      _isCreatingProfiles = true;
      _logs.clear();
    });

    _log("Starting creation of test profiles...");

    try {
      // Create both profiles using the utility class
      _log("Creating personal and business profiles...");
      final results = await TestProfileCreator.createBothProfiles();
      
      // Log results
      _log("Personal profile created: ${results['personal'] != null ? "Success (ID: ${results['personal']})" : "Failed"}");
      _log("Business profile created: ${results['business'] != null ? "Success (ID: ${results['business']})" : "Failed"}");

      // List all profiles
      _log("Listing all profiles:");
      _profiles = await TestProfileCreator.listAllProfiles();
      
      // Display each profile
      for (var i = 0; i < _profiles.length; i++) {
        final profile = _profiles[i];
        _log("\nProfile ${i + 1}:");
        _log("ID: ${profile.id}");
        _log("Name: ${profile.name}");
        _log("Email: ${profile.email}");
        _log("Type: ${profile.type.toString().split('.').last}");
        _log("Created: ${profile.createdAt}");
      }
      
      setState(() {
        _profilesCreated = true;
      });
    } catch (e) {
      _log("Error creating profiles: $e");
    } finally {
      setState(() {
        _isCreatingProfiles = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Profiles Creator'),
        backgroundColor: const Color(0xFF007A39),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isCreatingProfiles ? null : _createTestProfiles,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A39),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCreatingProfiles 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Create Test Profiles'),
            ),
            const SizedBox(height: 16),
            if (_profilesCreated && _profiles.isNotEmpty)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created Profiles',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._profiles.map((profile) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${profile.name} (${profile.type.toString().split('.').last})',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.green[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ).toList(),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Logs',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                                horizontal: 8.0,
                              ),
                              child: Text(
                                _logs[index],
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
