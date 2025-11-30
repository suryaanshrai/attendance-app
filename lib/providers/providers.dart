import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class ConfigProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String _baseUrl = ApiService.defaultBaseUrl;

  String get baseUrl => _baseUrl;

  ConfigProvider() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _baseUrl = await _apiService.baseUrl;
    notifyListeners();
  }

  Future<void> updateBaseUrl(String url) async {
    await _apiService.setBaseUrl(url);
    _baseUrl = url;
    notifyListeners();
  }
}

class AdminProvider with ChangeNotifier {
  String? _token;
  DateTime? _tokenExpiry;

  bool get isAdminLoggedIn {
    if (_token == null || _tokenExpiry == null) return false;
    return DateTime.now().isBefore(_tokenExpiry!);
  }

  String? get token => _token;

  Future<void> login(String username, String password) async {
    final apiService = ApiService();
    _token = await apiService.adminLogin(username, password);
    _tokenExpiry = DateTime.now().add(const Duration(minutes: 30));
    await _saveToken();
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _tokenExpiry = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    await prefs.remove('token_expiry');
    notifyListeners();
  }

  Future<void> checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token');
    final expiryStr = prefs.getString('token_expiry');

    if (token != null && expiryStr != null) {
      final expiry = DateTime.parse(expiryStr);
      if (DateTime.now().isBefore(expiry)) {
        _token = token;
        _tokenExpiry = expiry;
        notifyListeners();
      }
    }
  }

  Future<void> _saveToken() async {
    if (_token != null && _tokenExpiry != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_token', _token!);
      await prefs.setString('token_expiry', _tokenExpiry!.toIso8601String());
    }
  }
}

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final apiService = ApiService();
      _users = await apiService.getUsers();
    } catch (e) {
      print('Error fetching users: $e');
      _users = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
