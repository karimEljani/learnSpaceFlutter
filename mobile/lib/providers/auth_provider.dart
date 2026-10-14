import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? user;
  bool loading = true;

  bool get isLoggedIn => user != null;
  bool get isAdmin => user?.isAdmin ?? false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    ApiService.token = prefs.getString('token');
    if (ApiService.token != null) {
      try {
        user = await ApiService.me();
      } on ApiException catch (e) {
        // On ne déconnecte que si le jeton est invalide, pas si le réseau est coupé
        if (e.status == 401) await _clear();
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final res = await ApiService.login(email, password);
    await _save(res['token']);
    user = await ApiService.me();
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    final res = await ApiService.register(name, email, password);
    await _save(res['token']);
    user = await ApiService.me();
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      user = await ApiService.me();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateName(String name) async {
    await ApiService.updateProfile(name: name);
    await refreshUser();
  }

  Future<void> changePassword(String current, String next) async {
    await ApiService.updateProfile(currentPassword: current, newPassword: next);
  }

  Future<void> logout() async {
    await _clear();
    user = null;
    notifyListeners();
  }

  Future<void> _save(String token) async {
    ApiService.token = token;
    (await SharedPreferences.getInstance()).setString('token', token);
  }

  Future<void> _clear() async {
    ApiService.token = null;
    (await SharedPreferences.getInstance()).remove('token');
  }
}
