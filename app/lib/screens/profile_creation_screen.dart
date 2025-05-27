// lib/screens/profile_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../services/api_client.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  ProfileType _selectedType = ProfileType.personal;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Profile Type Selection
              DropdownButtonFormField<ProfileType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Profile Type',
                  border: OutlineInputBorder(),
                ),
                items:
                    ProfileType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),

              const SizedBox(height: 20),

              // Profile Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Profile Name (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),

              const SizedBox(height: 20),

              // PIN Input
              TextFormField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '4-Digit PIN',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.length != 4 ||
                      !value.contains(RegExp(r'^[0-9]+$'))) {
                    return 'Please enter a valid 4-digit PIN';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // Confirm PIN
              TextFormField(
                controller: _confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != _pinController.text) {
                    return 'PINs do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _createProfile,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Create Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);
      final newProfile = await apiClient.createProfile(
        name: _nameController.text,
        profileType: _selectedType,
        pin: _pinController.text,
      );

      if (!mounted) return;
      Navigator.pop(context, newProfile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create profile: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}
