import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/property.dart';

class PropertyProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<Property> _properties = [];
  List<Property> _myProperties = [];
  int _total = 0;
  int _page = 1;
  bool _loading = false;
  bool _myLoading = false;
  String? _categoryFilter;
  String? _regionFilter;
  String? _searchQuery;

  List<Property> get properties => _properties;
  List<Property> get myProperties => _myProperties;
  int get total => _total;
  bool get loading => _loading;
  bool get myLoading => _myLoading;
  String? get categoryFilter => _categoryFilter;
  String? get regionFilter => _regionFilter;

  void setFilters({String? category, String? region}) {
    _categoryFilter = category;
    _regionFilter = region;
    _page = 1;
    _properties = [];
    notifyListeners();
  }

  void setSearch(String? query) {
    _searchQuery = (query != null && query.isEmpty) ? null : query;
    _page = 1;
    _properties = [];
    notifyListeners();
  }

  Future<void> loadProperties({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _page = 1;
      _properties = [];
    }

    _loading = true;
    notifyListeners();

    try {
      final result = await _api.listProperties(
        search: _searchQuery,
        category: _categoryFilter,
        region: _regionFilter,
        page: _page,
      );
      final list = (result['data'] as List?)
              ?.map((e) => Property.fromJson(e))
              .toList() ??
          [];
      _total = result['total'] ?? 0;

      if (refresh) {
        _properties = list;
      } else {
        _properties.addAll(list);
      }
      _page++;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Property> getProperty(String id) async {
    return await _api.getProperty(id);
  }

  Future<void> loadMyProperties() async {
    _myLoading = true;
    notifyListeners();
    try {
      _myProperties = await _api.myProperties();
    } finally {
      _myLoading = false;
      notifyListeners();
    }
  }

  Future<Property> createProperty(Map<String, dynamic> data) async {
    final p = await _api.createProperty(data);
    _myProperties.insert(0, p);
    // Refresh feed to show new listing
    loadProperties(refresh: true);
    return p;
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    await _api.updateProperty(id, data);
    // Reload both lists to reflect changes
    await Future.wait([loadProperties(refresh: true), loadMyProperties()]);
  }

  Future<void> deleteProperty(String id) async {
    await _api.deleteProperty(id);
    _myProperties.removeWhere((p) => p.id == id);
    _properties.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<PropertyImage> uploadImage(String propertyId, String filePath, {bool isPrimary = false}) async {
    return await _api.uploadImage(propertyId, filePath, isPrimary: isPrimary);
  }

  Future<void> deleteImage(String propertyId, String imageId) async {
    await _api.deleteImage(propertyId, imageId);
  }
}
