import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/property.dart';
import '../models/user.dart';

class AdminProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  // Dashboard
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => _stats;

  // Users
  List<User> _users = [];
  List<User> get users => _users;
  int _usersTotal = 0;
  int get usersTotal => _usersTotal;

  // Properties
  List<Property> _properties = [];
  List<Property> get properties => _properties;
  int _propsTotal = 0;
  int get propsTotal => _propsTotal;

  bool _loading = false;
  bool get loading => _loading;

  // ── Dashboard ──

  Future<void> loadDashboard() async {
    _loading = true;
    notifyListeners();
    try {
      _stats = await _api.adminDashboard();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Users ──

  Future<void> loadUsers({String? search, String? role, int page = 1}) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _api.adminListUsers(search: search, role: role, page: page);
      final list = (result['data'] as List?)?.map((e) => User.fromJson(e)).toList() ?? [];
      _usersTotal = result['total'] ?? 0;
      _users = list;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _api.adminUpdateUserRole(userId, role);
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _users[idx] = User(
        id: _users[idx].id,
        phone: _users[idx].phone,
        role: role,
        language: _users[idx].language,
        fullName: _users[idx].fullName,
        avatarUrl: _users[idx].avatarUrl,
        createdAt: _users[idx].createdAt,
        updatedAt: _users[idx].updatedAt,
      );
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    await _api.adminDeleteUser(userId);
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  // ── Properties ──

  Future<void> loadProperties({String? search, String? category, String? status, bool? isActive, int page = 1}) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _api.adminListProperties(
        search: search, category: category, status: status, isActive: isActive, page: page);
      final list = (result['data'] as List?)?.map((e) => Property.fromJson(e)).toList() ?? [];
      _propsTotal = result['total'] ?? 0;
      _properties = list;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleProperty(String propertyId, bool isActive) async {
    await _api.adminToggleProperty(propertyId, isActive);
    final idx = _properties.indexWhere((p) => p.id == propertyId);
    if (idx != -1) {
      loadProperties();
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    await _api.adminDeleteProperty(propertyId);
    _properties.removeWhere((p) => p.id == propertyId);
    notifyListeners();
  }

  Future<void> updatePropertyStatus(String propertyId, String status) async {
    await _api.adminUpdatePropertyStatus(propertyId, status);
    loadProperties();
  }
}
