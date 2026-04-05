import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/property.dart';

class ApiClient {
  static const String _baseUrl = 'http://152.70.18.164:8080/api/v1';
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
    String role = 'user',
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

  Future<Map<String, dynamic>> firebaseLogin({
    required String firebaseToken,
    String language = 'uz',
  }) async {
    final res = await _dio.post('/auth/firebase-login', data: {
      'firebase_token': firebaseToken,
      'language': language,
    });
    return res.data;
  }

  Future<User> getProfile() async {
    final res = await _dio.get('/auth/profile');
    return User.fromJson(res.data);
  }

  Future<String?> updateProfile({
    String? fullName,
    String? language,
    String? role,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (language != null) data['language'] = language;
    if (role != null) data['role'] = role;
    final res = await _dio.put('/auth/profile', data: data);
    return res.data['token'];
  }

  // ── FCM ──

  Future<void> registerFcmToken(String fcmToken) async {
    await _dio.post('/auth/fcm-token', data: {'fcm_token': fcmToken});
  }

  // ── Properties ──

  Future<Map<String, dynamic>> listProperties({
    String? search,
    String? category,
    String? region,
    double? minPrice,
    double? maxPrice,
    int? rooms,
    String? ownerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (category != null) params['category'] = category;
    if (region != null) params['region'] = region;
    if (minPrice != null) params['min_price'] = minPrice;
    if (maxPrice != null) params['max_price'] = maxPrice;
    if (rooms != null) params['rooms'] = rooms;
    if (ownerId != null) params['owner_id'] = ownerId;

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

  // ── Chat ──

  Future<Map<String, dynamic>> startConversation(String propertyId, String landlordId) async {
    final res = await _dio.post('/chat/conversations', data: {
      'property_id': propertyId,
      'landlord_id': landlordId,
    });
    return res.data;
  }

  Future<List<dynamic>> listConversations() async {
    final res = await _dio.get('/chat/conversations');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage(String conversationId, String text) async {
    final res = await _dio.post('/chat/conversations/$conversationId/messages', data: {
      'text': text,
    });
    return res.data;
  }

  Future<List<dynamic>> getMessages(String conversationId, {int page = 1}) async {
    final res = await _dio.get('/chat/conversations/$conversationId/messages', queryParameters: {
      'page': page,
    });
    return res.data as List<dynamic>;
  }

  // ── Admin ──

  Future<Map<String, dynamic>> adminDashboard() async {
    final res = await _dio.get('/admin/dashboard');
    return res.data;
  }

  Future<Map<String, dynamic>> adminListUsers({String? search, String? role, int page = 1}) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (role != null && role.isNotEmpty) params['role'] = role;
    final res = await _dio.get('/admin/users', queryParameters: params);
    return res.data;
  }

  Future<void> adminUpdateUserRole(String userId, String role) async {
    await _dio.put('/admin/users/$userId/role', data: {'role': role});
  }

  Future<void> adminDeleteUser(String userId) async {
    await _dio.delete('/admin/users/$userId');
  }

  Future<Map<String, dynamic>> adminListProperties({String? search, String? category, String? status, bool? isActive, int page = 1}) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (isActive != null) params['is_active'] = isActive.toString();
    final res = await _dio.get('/admin/properties', queryParameters: params);
    return res.data;
  }

  Future<void> adminToggleProperty(String propertyId, bool isActive) async {
    await _dio.put('/admin/properties/$propertyId/active', data: {'is_active': isActive});
  }

  Future<void> adminDeleteProperty(String propertyId) async {
    await _dio.delete('/admin/properties/$propertyId');
  }

  Future<void> adminUpdatePropertyStatus(String propertyId, String status) async {
    await _dio.put('/admin/properties/$propertyId/status', data: {'status': status});
  }

  Future<List<dynamic>> adminListConversations() async {
    final res = await _dio.get('/admin/conversations');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> adminGetMessages(String conversationId) async {
    final res = await _dio.get('/admin/conversations/$conversationId/messages');
    return res.data as List<dynamic>;
  }

  // Directories
  Future<List<dynamic>> getDirectories(String type) async {
    final res = await _dio.get('/directories', queryParameters: {'type': type});
    return res.data as List<dynamic>;
  }

  Future<void> adminCreateDirectory(Map<String, dynamic> data) async {
    await _dio.post('/admin/directories', data: data);
  }

  Future<void> adminUpdateDirectory(String id, Map<String, dynamic> data) async {
    await _dio.put('/admin/directories/$id', data: data);
  }

  Future<void> adminDeleteDirectory(String id) async {
    await _dio.delete('/admin/directories/$id');
  }
}
