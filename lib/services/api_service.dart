
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'api_config.dart';

class ApiService {
  static Future<Map<String, dynamic>> get(
      String route,
      ) async {
    return _request('GET', route);
  }

  static Future<Map<String, dynamic>> post(
      String route, {
        Map<String, dynamic>? body,
      }) async {
    return _request('POST', route, body: body);
  }

  static Future<Map<String, dynamic>> patch(
      String route, {
        Map<String, dynamic>? body,
      }) async {
    return _request('PATCH', route, body: body);
  }

  // Upload one ticket photo using multipart/form-data.
  static Future<Map<String, dynamic>> uploadPhoto(
      String route, {
        required String filePath,
      }) async {
    final token = await AuthService.getToken();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}?route=$route',
    );

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      if (token.isNotEmpty)
        'Authorization': 'Bearer $token',
    });

    // PHP backend expects the multipart field name: photo
    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        filePath,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(
      streamedResponse,
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid server response');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        decoded['message'] ??
            decoded['error'] ??
            'Photo upload failed (${response.statusCode})',
      );
    }

    return decoded;
  }

  static Future<Map<String, dynamic>> _request(
      String method,
      String route, {
        Map<String, dynamic>? body,
      }) async {
    final token = await AuthService.getToken();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}?route=$route',
    );

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    late http.Response response;

    if (method == 'GET') {
      response = await http.get(uri, headers: headers);
    } else if (method == 'POST') {
      response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body ?? {}),
      );
    } else {
      response = await http.patch(
        uri,
        headers: headers,
        body: jsonEncode(body ?? {}),
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid server response');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        decoded['message'] ??
            decoded['error'] ??
            'API request failed (${response.statusCode})',
      );
    }

    return decoded;
  }
}
