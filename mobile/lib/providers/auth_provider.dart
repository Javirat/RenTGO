import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  User? _user;
  String? _token;
  bool _loading = false;
  String _language = 'uz';

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get loading => _loading;
  String get language => _language;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _language = prefs.getString('language') ?? 'uz';
    if (_token != null) {
      try {
        _user = await _api.getProfile();
      } catch (_) {
        _token = null;
        await prefs.remove('token');
      }
    }
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  String? _devOtpCode;
  String? get devOtpCode => _devOtpCode;

  Future<void> sendOtp(String phone) async {
    _loading = true;
    notifyListeners();
    try {
      _devOtpCode = await _api.sendOtp(phone);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp({
    required String phone,
    required String code,
    String role = 'renter',
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _api.verifyOtp(
        phone: phone,
        code: code,
        role: role,
        language: _language,
      );
      _token = result['token'];
      _user = User.fromJson(result['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      notifyListeners();
      return result['is_new'] ?? false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (_token == null) return;
    _user = await _api.getProfile();
    notifyListeners();
  }

  Future<void> updateProfile({String? fullName, String? role}) async {
    final newToken = await _api.updateProfile(fullName: fullName, language: _language, role: role);
    if (newToken != null) {
      _token = newToken;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
    }
    await refreshProfile();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
