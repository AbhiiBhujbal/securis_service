
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class AuthService {
  static const String _loggedInKey = 'is_logged_in';
  static const String _roleKey = 'user_role';
  static const String _technicianNameKey = 'technician_name';
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';

  // ==========================================
  // LOGIN API
  // ==========================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.loginUrl);

      debugPrint('========== LOGIN API DEBUG ==========');
      debugPrint('LOGIN URL: $url');
      debugPrint('LOGIN EMAIL: $email');

      final response = await http
          .post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(const Duration(seconds: 20));

      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('RESPONSE BODY: ${response.body}');
      debugPrint('=====================================');

      // Decode JSON response
      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (e) {
        debugPrint('JSON DECODE ERROR: $e');
        throw Exception(
          'Server returned an invalid response. Check PHP API.',
        );
      }

      if (decoded is! Map) {
        throw Exception('Server response format is incorrect.');
      }

      final Map<String, dynamic> data =
      Map<String, dynamic>.from(decoded);

      // Check HTTP status
      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          data['message']?.toString() ??
              data['error']?.toString() ??
              'Login failed.',
        );
      }

      // Extract token and user

// Extract nested API response
      final responseData = data['data'];

      if (responseData is! Map) {
        throw Exception('Login data not received from server.');
      }

      final nestedData = Map<String, dynamic>.from(responseData);

      final token = nestedData['token']?.toString();
      final userData = nestedData['user'];

      debugPrint(
        'TOKEN STATUS: ${token == null ? "NULL" : "RECEIVED"}',
      );
      debugPrint('USER DATA: $userData');

      if (token == null || token.isEmpty) {
        throw Exception('Login token not received from server.');
      }

      if (userData is! Map) {
        throw Exception('User details not received from server.');
      }

      final user = Map<String, dynamic>.from(userData);


      final role = user['role']?.toString() ?? '';
      final name = user['name']?.toString() ?? '';
      final id = user['id'];
      final userEmail = user['email']?.toString() ?? email;

      // Validate role
      if (role != 'Admin' && role != 'Technician') {
        throw Exception('Unsupported user role: $role');
      }

      // Save session
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_loggedInKey, true);
      await prefs.setString(_roleKey, role);
      await prefs.setString(_technicianNameKey, name);
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_emailKey, userEmail);

      if (id != null) {
        await prefs.setString(_userIdKey, id.toString());
      }

      debugPrint('LOGIN SUCCESS');
      debugPrint('USER ROLE: $role');
      debugPrint('USER NAME: $name');

      return {
        'role': role,
        'name': name,
        'email': userEmail,
        'id': id,
      };
    } on http.ClientException catch (e) {
      debugPrint('HTTP ERROR: $e');
      throw Exception('Unable to connect to server.');
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      rethrow;
    }
  }

  // ==========================================
  // SESSION MANAGEMENT
  // ==========================================

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final loggedIn = prefs.getBool(_loggedInKey) ?? false;
    final token = prefs.getString(_tokenKey) ?? '';

    return loggedIn && token.isNotEmpty;
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_roleKey) ?? '';
  }

  static Future<String> getTechnicianName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_technicianNameKey) ?? '';
  }

  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey) ?? '';
  }

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_userIdKey) ?? '';
  }

  static Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_emailKey) ?? '';
  }
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey) ?? '';

    if (token.isNotEmpty) {
      try {
        final response = await http
            .post(
          Uri.parse(
            '${ApiConfig.baseUrl}?route=auth/logout',
          ),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
            .timeout(const Duration(seconds: 10));

        debugPrint('LOGOUT STATUS: ${response.statusCode}');
      } catch (e) {
        debugPrint('LOGOUT API ERROR: $e');
      }
    }

    // Always clear local session
    await prefs.remove(_loggedInKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_technicianNameKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);

    debugPrint('LOCAL SESSION CLEARED');
  }
}
