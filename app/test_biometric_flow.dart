import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/biometric_auth_service.dart';

/// Test app to verify biometric authentication flow
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  runApp(const BiometricTestApp());
}

class BiometricTestApp extends StatelessWidget {
  const BiometricTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biometric Test',
      home: const BiometricTestScreen(),
    );
  }
}

class BiometricTestScreen extends StatefulWidget {
  const BiometricTestScreen({super.key});

  @override
  State<BiometricTestScreen> createState() => _BiometricTestScreenState();
}

class _BiometricTestScreenState extends State<BiometricTestScreen> {
  final BiometricAuthService _biometricService = BiometricAuthService.instance;
  String _status = 'Ready to test biometric authentication';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Authentication Test'),
        backgroundColor: const Color(0xFF007A39),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: $_status', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkCapabilities,
              child: const Text('Check Device Capabilities'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _enableBiometric,
              child: const Text('Enable Biometric'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAuthentication,
              child: const Text('Test Authentication'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkSession,
              child: const Text('Check Session Status'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _clearSession,
              child: const Text('Clear Session'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _disableBiometric,
              child: const Text('Disable Biometric'),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkCapabilities() async {
    setState(() => _isLoading = true);

    try {
      final isSupported = await _biometricService.isDeviceSupported();
      final isFingerPrintAvailable = await _biometricService
          .isFingerPrintAvailable();
      final types = await _biometricService.getAvailableBiometricTypes();
      final isEnabled = await _biometricService.isBiometricEnabled();

      setState(() {
        _status =
            'Device supported: $isSupported\n'
            'Fingerprint available: $isFingerPrintAvailable\n'
            'Available types: $types\n'
            'Currently enabled: $isEnabled';
      });
    } catch (e) {
      setState(() => _status = 'Error checking capabilities: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enableBiometric() async {
    setState(() => _isLoading = true);

    try {
      final success = await _biometricService.setBiometricEnabled(true);
      setState(
        () => _status = 'Enable biometric: ${success ? 'Success' : 'Failed'}',
      );
    } catch (e) {
      setState(() => _status = 'Error enabling biometric: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testAuthentication() async {
    setState(() => _isLoading = true);

    try {
      final success = await _biometricService.authenticateWithBiometric(
        reason: 'Test authentication',
      );
      setState(
        () => _status = 'Authentication: ${success ? 'Success' : 'Failed'}',
      );
    } catch (e) {
      setState(() => _status = 'Error during authentication: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkSession() async {
    setState(() => _isLoading = true);

    try {
      final hasValidSession = await _biometricService
          .hasValidBiometricSession();
      setState(() => _status = 'Has valid session: $hasValidSession');
    } catch (e) {
      setState(() => _status = 'Error checking session: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearSession() async {
    setState(() => _isLoading = true);

    try {
      await _biometricService.clearBiometricSession();
      setState(() => _status = 'Session cleared');
    } catch (e) {
      setState(() => _status = 'Error clearing session: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disableBiometric() async {
    setState(() => _isLoading = true);

    try {
      final success = await _biometricService.setBiometricEnabled(false);
      setState(
        () => _status = 'Disable biometric: ${success ? 'Success' : 'Failed'}',
      );
    } catch (e) {
      setState(() => _status = 'Error disabling biometric: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
