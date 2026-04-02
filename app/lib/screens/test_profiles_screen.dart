// lib/screens/test_profiles_screen.dart - FIXED VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/offline_data_service.dart';
import '../models/profile.dart';
// TestProfileCreator import removed - utility not available in offline-first build

class TestProfilesScreen extends StatefulWidget {
  const TestProfilesScreen({super.key});

  @override
  State<TestProfilesScreen> createState() => _TestProfilesScreenState();
}

class _TestProfilesScreenState extends State<TestProfilesScreen> {
  List<Profile> _profiles = [];
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final authService = context.read<AuthService>();
      final currentProfile = authService.currentProfile;
      
      if (currentProfile != null) {
        _profiles = [currentProfile];
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error loading profiles: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createTestProfiles() async {
    setState(() {
      _isLoading = true;
      _message = 'Test profile creation not available in offline-first mode';
      _isLoading = false;
    });
  }

  Future<void> _createSingleProfile(String type) async {
    setState(() {
      _isLoading = true;
      _message = 'Test profile creation not available in offline-first mode';
      _isLoading = false;
    });
  }

  Future<void> _loadSampleData(Profile profile) async {
    setState(() {
      _isLoading = true;
      _message = 'Sample data loading not available in offline-first mode';
      _isLoading = false;
    });
  }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error loading sample data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _switchToProfile(Profile profile) async {
    setState(() {
      _isLoading = true;
      _message = 'Switching to ${profile.name}...';
    });

    try {
      final authService = context.read<AuthService>();
      final success = await authService.setCurrentProfile(profile.id);

      if (mounted) {
        setState(() {
          _message = success
              ? 'Switched to ${profile.name}'
              : 'Failed to switch profile';
          _isLoading = false;
        });

        if (success) {
          // Navigate back to home
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error switching profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentProfile = authService.currentProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Profiles'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current Profile Card
                  if (currentProfile != null) ...[
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Profile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Name: ${currentProfile.name}'),
                            Text('Email: ${currentProfile.email ?? "N/A"}'),
                            Text('ID: ${currentProfile.id}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createTestProfiles,
                    icon: const Icon(Icons.people),
                    label: const Text('Create Both Test Profiles'),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading 
                              ? null 
                              : () => _createSingleProfile('personal'),
                          icon: const Icon(Icons.person),
                          label: const Text('Personal'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading 
                              ? null 
                              : () => _createSingleProfile('business'),
                          icon: const Icon(Icons.business),
                          label: const Text('Business'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Message Display
                  if (_message != null) ...[
                    Card(
                      color: _message!.contains('Error')
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_message!),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Stored Profiles List
                  const Text(
                    'Stored Profiles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_profiles.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No profiles found. Create some test profiles to get started.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._profiles.map((profile) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(profile.name[0].toUpperCase()),
                        ),
                        title: Text(profile.name),
                        subtitle: Text(profile.email ?? 'No email'),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'switch',
                              child: Text('Switch to this profile'),
                            ),
                            const PopupMenuItem(
                              value: 'load_data',
                              child: Text('Load sample data'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'switch') {
                              _switchToProfile(profile);
                            } else if (value == 'load_data') {
                              _loadSampleData(profile);
                            }
                          },
                        ),
                      ),
                    )),
                ],
              ),
            ),
    );
  }
}