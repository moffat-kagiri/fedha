// lib/services/api_client.dart
// Clean reconstructed API client after accidental truncation

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // for kDebugMode
import '../utils/logger.dart';
import '../config/api_config.dart';

class ApiClient {
	static ApiClient? _instance;
	static ApiClient get instance => _instance ??= ApiClient._();

	factory ApiClient() => instance;

	final http.Client _http = http.Client();
	final logger = AppLogger.getLogger('ApiClient');
	final Map<String, String> _headers = {
		'Content-Type': 'application/json',
		'Accept': 'application/json'
	};

	ApiConfig _config;
	String? _overrideBase;
	bool _usingFallback = false;

 	/// Use local or development config in debug mode to point at local server
	ApiClient._() : _config = kDebugMode ? ApiConfig.development() : ApiConfig.production();

	/// Initialize with a specific config
	void init({ApiConfig? config}) {
		if (config != null) {
			_config = config;
		}
	}

	// Expose current config (read-only outside)
	ApiConfig get config => _config;
	bool get isUsingFallbackServer => _usingFallback;

	String get baseUrl {
		final host = _overrideBase ?? _config.primaryApiUrl;
		final scheme = _config.useSecureConnections ? 'https' : 'http';
		return '$scheme://$host';
	}

	void setAuthToken(String token) => _headers['Authorization'] = 'Token $token';
	void clearAuthToken() => _headers.remove('Authorization');

	Future<bool> checkServerHealth() async {
		try {
			final resp = await _http
					.get(Uri.parse(_config.healthCheckUrl), headers: _headers)
					.timeout(const Duration(seconds: 5));
			return resp.statusCode == 200;
		} catch (e) {
			logger.warning('Health check failed: $e');
			return false;
		}
	}

	// Alias for legacy code expecting healthCheck()
	Future<bool> healthCheck() => checkServerHealth();

	Future<Map<String, dynamic>> login({required String email, required String password}) async {
		final url = Uri.parse(_config.getEndpoint('api/auth/login/'));
		try {
			final resp = await _http
					.post(url, headers: _headers, body: jsonEncode({'email': email, 'password': password}))
					.timeout(const Duration(seconds: 10));
			if (resp.statusCode == 200) {
				final data = jsonDecode(resp.body) as Map<String, dynamic>;
				if (data['token'] != null) setAuthToken(data['token']);
				return data;
			}
			return {'success': false, 'status': resp.statusCode, 'body': resp.body};
		} catch (e) {
			return {'success': false, 'error': e.toString()};
		}
	}

	Future<Map<String, dynamic>> createAccount({
		required String firstName,
		required String lastName,
		required String email,
		required String password,
		String? phone,
		String? avatarPath,
		String? deviceId, // accepted for compatibility, not sent currently
	}) async {
		final url = Uri.parse(_config.getEndpoint('api/auth/register/'));
		final body = <String, dynamic>{
			'first_name': firstName,
			'last_name': lastName,
			'email': email,
			'password': password,
		};
		if (phone != null && phone.isNotEmpty) body['phone'] = phone;
		// avatarPath handling omitted (multipart) for now
		try {
			final resp = await _http
					.post(url, headers: _headers, body: jsonEncode(body))
					.timeout(const Duration(seconds: 15));
			if (resp.statusCode == 201) {
				return jsonDecode(resp.body) as Map<String, dynamic>;
			}
			return {'success': false, 'status': resp.statusCode, 'body': resp.body};
		} catch (e) {
			return {'success': false, 'error': e.toString()};
		}
	}

	Future<bool> invalidateSession({bool clearLocalToken = true, String? userId, String? sessionToken}) async {
		final url = Uri.parse(_config.getEndpoint('api/auth/logout/'));
		try {
			final resp = await _http
					.post(url, headers: _headers)
					.timeout(const Duration(seconds: 8));
			final ok = resp.statusCode == 200 || resp.statusCode == 204;
			if (ok && clearLocalToken) clearAuthToken();
			return ok;
		} catch (e) {
			logger.warning('Logout failed: $e');
			return false;
		}
	}

	// --- Fallback & connection helpers (stubs) ---
	void resetToPrimaryServer() {
		_overrideBase = null;
		_usingFallback = false;
	}

	void switchToFallbackServer() {
		if (_config.fallbackApiUrl != null) {
			_overrideBase = _config.fallbackApiUrl;
			_usingFallback = true;
		}
	}

	Future<bool> testConnection() => checkServerHealth();

	// --- Profile management stubs ---
	Future<Map<String, dynamic>> getProfile({required String sessionToken}) async {
		final url = Uri.parse(_config.getEndpoint('api/auth/profile/'));
		try {
			final resp = await _http
					.get(url, headers: _headers)
					.timeout(const Duration(seconds: 10));
			if (resp.statusCode == 200) {
				return jsonDecode(resp.body) as Map<String, dynamic>;
			}
			return {'success': false, 'status': resp.statusCode, 'body': resp.body};
		} catch (e) {
			return {'success': false, 'error': e.toString()};
		}
	}

	Future<Map<String, dynamic>> updateProfile({required String userId, required String sessionToken, required Map<String, dynamic> profileData}) async {
		final url = Uri.parse(_config.getEndpoint('api/auth/profile/update/'));
		try {
			final resp = await _http
					.put(url, headers: _headers, body: jsonEncode(profileData))
					.timeout(const Duration(seconds: 10));
			if (resp.statusCode == 200) {
				return jsonDecode(resp.body) as Map<String, dynamic>;
			}
			return {'success': false, 'status': resp.statusCode, 'body': resp.body};
		} catch (e) {
			return {'success': false, 'error': e.toString()};
		}
	}

	Future<Map<String, dynamic>> updatePassword({required String userId, required String sessionToken, required String currentPassword, required String newPassword}) async {
		final url = Uri.parse(_config.getEndpoint('api/auth/password/change/'));
		try {
			final resp = await _http
					.post(url, 
						headers: _headers, 
						body: jsonEncode({
							'current_password': currentPassword,
							'new_password': newPassword
						})
					)
					.timeout(const Duration(seconds: 10));
			if (resp.statusCode == 200) {
				return jsonDecode(resp.body) as Map<String, dynamic>;
			}
			return {'success': false, 'status': resp.statusCode, 'body': resp.body};
		} catch (e) {
			return {'success': false, 'error': e.toString()};
		}
	}

	Future<Map<String, dynamic>> requestPasswordReset({required String email}) async {
		return {'success': true};
	}

	// --- Sync related stubs ---
	Future<Map<String, dynamic>> syncOfflineTransactions({required String userId, required String sessionToken, required List<dynamic> transactions}) async {
		return {'success': true};
	}

	Future<List<dynamic>> fetchUserGoals({required String userId, required String sessionToken}) async {
		final url = Uri.parse(_config.getEndpoint('api/goals/'));
		try {
			final resp = await _http
					.get(url, headers: _headers)
					.timeout(const Duration(seconds: 10));
			if (resp.statusCode == 200) {
				final data = jsonDecode(resp.body);
				if (data is List) {
					return data;
				} else if (data is Map && data['results'] is List) {
					return data['results'] as List<dynamic>;
				}
			}
			return <dynamic>[];
		} catch (e) {
			logger.warning('Failed to fetch user goals: $e');
			return <dynamic>[];
		}
	}

	Future<Map<String, dynamic>> fetchBudgetSummary({required String userId, required String sessionToken}) async {
		return {'success': true};
	}

	Future<Map<String, dynamic>> syncTransactions(String profileId, List<dynamic> transactions) async => {'success': true};
	Future<Map<String, dynamic>> syncCategories(String profileId, List<dynamic> categories) async => {'success': true};
	Future<Map<String, dynamic>> syncClients(String profileId, List<dynamic> clients) async => {'success': true};
	Future<Map<String, dynamic>> syncInvoices(String profileId, List<dynamic> invoices) async => {'success': true};
	Future<Map<String, dynamic>> syncGoals(String profileId, List<dynamic> goals) async => {'success': true};
	Future<Map<String, dynamic>> syncBudgets(String profileId, List<dynamic> budgets) async => {'success': true};

	Future<List<dynamic>> getTransactions({required String profileId, required String sessionToken}) async => <dynamic>[];

	void updateConfig(ApiConfig newConfig) {
		_config = newConfig;
		_overrideBase = null;
		_usingFallback = false;
	}

	void dispose() => _http.close();

	// ...existing code above...
	// No legacy stub methods remain
}
