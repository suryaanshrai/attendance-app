import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://10.0.2.2:8000';
  static const String _baseUrlKey = 'base_url';

  Future<String> get baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  Future<List<User>> getUsers() async {
    final url = await baseUrl;
    final response = await http.get(Uri.parse('$url/users'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<Map<String, dynamic>> punch(String username, String imagePath) async {
    final url = await baseUrl;
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$url/punch?username=$username'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseBody);
    } else {
      throw Exception(json.decode(responseBody)['message'] ?? 'Punch failed');
    }
  }

  Future<String> adminLogin(String username, String password) async {
    final url = await baseUrl;
    final response = await http.post(
      Uri.parse('$url/admin/login?username=$username&password=$password'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['token'];
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<void> addUser(String username, String imagePath, String token) async {
    final url = await baseUrl;
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$url/admin/user?username=$username&token=$token'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
      final responseBody = await response.stream.bytesToString();
      throw Exception(
        json.decode(responseBody)['message'] ?? 'Failed to add user',
      );
    }
  }

  Future<void> deleteUser(String username, String token) async {
    final url = await baseUrl;
    final response = await http.delete(
      Uri.parse('$url/admin/user?username=$username&token=$token'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  Future<Log> getLogs(
    String username,
    int year,
    int month,
    String token,
  ) async {
    final url = await baseUrl;
    final response = await http.get(
      Uri.parse(
        '$url/admin/logs?username=$username&year=$year&month=$month&token=$token',
      ),
    );

    if (response.statusCode == 200) {
      return Log.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch logs');
    }
  }
}
