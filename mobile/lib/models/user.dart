class User {
  final String id;
  final String phone;
  final String role;
  final String language;
  final String fullName;
  final String avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.phone,
    required this.role,
    required this.language,
    this.fullName = '',
    this.avatarUrl = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      language: json['language'] ?? 'uz',
      fullName: json['full_name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isAdmin => role == 'admin';
}
