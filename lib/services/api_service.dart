import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String defaultBaseUrl = 'http://localhost:8000';
  static const String _baseUrlKey = 'base_url';

  Future<String> get baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-Tunnel-Skip-Anti-Phishing-Page': '1',
    };
  }

  Future<bool> checkConnection(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(const Duration(seconds: 5)); // Short timeout for check

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['status'] == 'running';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<User>> getUsers() async {
    final url = await baseUrl;
    final response = await http.get(
      Uri.parse('$url/users'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to load users');
    }
  }

  Future<Map<String, dynamic>> punch(String username, String imagePath) async {
    final url = await baseUrl;
    // Use Uri constructor to handle encoding
    final uri = Uri.parse(
      '$url/punch',
    ).replace(queryParameters: {'username': username});

    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseBody);
    } else {
      final body = json.decode(responseBody);
      throw Exception(body['message'] ?? 'Punch failed');
    }
  }

  Future<String> adminLogin(String username, String password) async {
    final url = await baseUrl;
    final uri = Uri.parse(
      '$url/admin/login',
    ).replace(queryParameters: {'username': username, 'password': password});

    final response = await http.post(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      if (response.body.isEmpty)
        throw Exception('Server returned empty response');
      final data = json.decode(response.body);
      return data['token'];
    } else {
      if (response.body.isEmpty)
        throw Exception('Login failed: ${response.statusCode}');
      try {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Invalid credentials');
      } catch (e) {
        if (e is FormatException) {
          throw Exception(
            'Server error: ${response.statusCode} (Invalid JSON)',
          );
        }
        rethrow;
      }
    }
  }

  Future<String> addUser(
    String username,
    String imagePath,
    String token,
  ) async {
    final url = await baseUrl;
    final uri = Uri.parse(
      '$url/admin/user',
    ).replace(queryParameters: {'username': username, 'token': token});

    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(responseBody)['message'] ?? 'User added successfully';
    } else {
      final body = json.decode(responseBody);
      throw Exception(body['message'] ?? 'Failed to add user');
    }
  }

  Future<String> deleteUser(String username, String token) async {
    final url = await baseUrl;
    final uri = Uri.parse(
      '$url/admin/user',
    ).replace(queryParameters: {'username': username, 'token': token});

    final response = await http.delete(uri, headers: _getHeaders());
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      return responseBody['message'] ?? 'User deleted successfully';
    } else {
      throw Exception(responseBody['message'] ?? 'Failed to delete user');
    }
  }

  Future<Log> getLogs(
    String username,
    int year,
    int month,
    String token,
  ) async {
    final url = await baseUrl;
    final uri = Uri.parse('$url/admin/logs').replace(
      queryParameters: {
        'username': username,
        'year': year.toString(),
        'month': month.toString(),
        'token': token,
      },
    );

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      return Log.fromJson(json.decode(response.body));
    } else {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to fetch logs');
    }
  }
}
