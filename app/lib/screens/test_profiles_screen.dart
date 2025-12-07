// lib/screens/test_profiles_screen.dart - FIXED VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/offline_data_service.dart';
import '../models/profile.dart';
import '../utils/test_profile_creator.dart';

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
      // FIXED: Use static method correctly
      final profiles = await TestProfileCreator.listAllProfiles();
      
      if (mounted) {
        setState(() {
          _profiles = profiles;
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
      _message = 'Creating test profiles...';
    });

    try {
      // FIXED: Use static method correctly
      final results = await TestProfileCreator.createBothProfiles();
      
      final personal = results['personal'];
      final business = results['business'];
      
      if (mounted) {
        setState(() {
          _message = 'Created profiles:\n'
              'Personal: ${personal?.email ?? "Failed"}\n'
              'Business: ${business?.email ?? "Failed"}';
          _isLoading = false;
        });
        
        // Reload profile list
        await _loadProfiles();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error creating profiles: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createSingleProfile(String type) async {
    setState(() {
      _isLoading = true;
      _message = 'Creating $type profile...';
    });

    try {
      final authService = context.read<AuthService>();
      final offlineDataService = context.read<OfflineDataService>();
      
      final creator = TestProfileCreator(
        authService: authService,
        offlineDataService: offlineDataService,
      );

      Profile? profile;
      
      if (type == 'personal') {
        profile = await creator.createTestProfile(
          firstName: 'Personal',
          lastName: 'User',
          email: 'personal.${DateTime.now().millisecondsSinceEpoch}@fedha.test',
        );
      } else {
        profile = await creator.createTestProfile(
          firstName: 'Business',
          lastName: 'Owner',
          email: 'business.${DateTime.now().millisecondsSinceEpoch}@fedha.test',
        );
      }

      if (mounted) {
        setState(() {
          _message = profile != null
              ? 'Created $type profile: ${profile.email}'
              : 'Failed to create $type profile';
          _isLoading = false;
        });
        
        await _loadProfiles();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSampleData(Profile profile) async {
    setState(() {
      _isLoading = true;
      _message = 'Loading sample data for ${profile.name}...';
    });

    try {
      final authService = context.read<AuthService>();
      final offlineDataService = context.read<OfflineDataService>();
      
      final creator = TestProfileCreator(
        authService: authService,
        offlineDataService: offlineDataService,
      );

      await creator.loadSampleTransactions(profile.id);

      if (mounted) {
        setState(() {
          _message = 'Sample data loaded for ${profile.name}';
          _isLoading = false;
        });
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