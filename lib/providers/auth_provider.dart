import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = true;
  User? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      ApiService.setToken(token);
      try {
        final res = await ApiService.get('/auth/profile');
        _user = User.fromJson(res['user']);
      } catch (e) {
        await prefs.remove('token');
        await prefs.remove('user');
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final res = await ApiService.post('/auth/login', {'email': email, 'password': password});
    _user = User.fromJson(res['user']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', res['token']);
    await prefs.setString('user', res['token']);
    ApiService.setToken(res['token']);
    notifyListeners();
  }

  Future<void> register(String name, String email, String password, String phone, String role) async {
    final res = await ApiService.post('/auth/register', {'name': name, 'email': email, 'password': password, 'phone': phone, 'role': role});
    _user = User.fromJson(res['user']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', res['token']);
    ApiService.setToken(res['token']);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    ApiService.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}
