import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/property.dart';

class ApiClient {
  static const String _baseUrl = 'http://10.0.2.2:8080/api/v1'; // Android emulator -> host
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final lang = prefs.getString('language') ?? 'uz';
        options.headers['Accept-Language'] = lang;
        handler.next(options);
      },
    ));
  }

  // ── Auth ──

  Future<String?> sendOtp(String phone) async {
    final res = await _dio.post('/auth/send-otp', data: {'phone': phone});
    // In dev mode, backend returns the OTP code in response
    return res.data['code']?.toString();
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    String role = 'renter',
    String language = 'uz',
  }) async {
    final res = await _dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'code': code,
      'role': role,
      'language': language,
    });
    return res.data;
  }

  Future<User> getProfile() async {
    final res = await _dio.get('/auth/profile');
    return User.fromJson(res.data);
  }

  Future<void> updateProfile({
    String? fullName,
    String? language,
    String? role,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (language != null) data['language'] = language;
    if (role != null) data['role'] = role;
    await _dio.put('/auth/profile', data: data);
  }

  // ── Properties ──

  Future<Map<String, dynamic>> listProperties({
    String? category,
    String? region,
    double? minPrice,
    double? maxPrice,
    int? rooms,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (category != null) params['category'] = category;
    if (region != null) params['region'] = region;
    if (minPrice != null) params['min_price'] = minPrice;
    if (maxPrice != null) params['max_price'] = maxPrice;
    if (rooms != null) params['rooms'] = rooms;

    final res = await _dio.get('/properties', queryParameters: params);
    return res.data;
  }

  Future<Property> getProperty(String id) async {
    final res = await _dio.get('/properties/$id');
    return Property.fromJson(res.data);
  }

  Future<Property> createProperty(Map<String, dynamic> data) async {
    final res = await _dio.post('/properties', data: data);
    return Property.fromJson(res.data);
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    await _dio.put('/properties/$id', data: data);
  }

  Future<void> deleteProperty(String id) async {
    await _dio.delete('/properties/$id');
  }

  Future<List<Property>> myProperties() async {
    final res = await _dio.get('/properties/my');
    return (res.data as List).map((e) => Property.fromJson(e)).toList();
  }

  Future<PropertyImage> uploadImage(String propertyId, String filePath, {bool isPrimary = false}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'is_primary': isPrimary.toString(),
    });
    final res = await _dio.post('/properties/$propertyId/images', data: formData);
    return PropertyImage.fromJson(res.data);
  }

  Future<void> deleteImage(String propertyId, String imageId) async {
    await _dio.delete('/properties/$propertyId/images/$imageId');
  }
}
