class PropertyImage {
  static const String _baseUrl = 'http://152.70.18.164:8080/images';

  final String id;
  final String propertyId;
  final String minioUrl;
  final bool isPrimary;

  PropertyImage({
    required this.id,
    required this.propertyId,
    required this.minioUrl,
    this.isPrimary = false,
  });

  /// Full URL accessible from the phone
  String get fullUrl {
    if (minioUrl.startsWith('http')) return minioUrl;
    return '$_baseUrl$minioUrl';
  }

  factory PropertyImage.fromJson(Map<String, dynamic> json) {
    return PropertyImage(
      id: json['id'] ?? '',
      propertyId: json['property_id'] ?? '',
      minioUrl: json['minio_url'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }
}

class Property {
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String title;
  final String description;
  final double price;
  final int rooms;
  final int capacity;
  final String region;
  final String address;
  final double lat;
  final double lng;
  final String category;
  final bool hasCctv;
  final int viewsCount;
  final bool isActive;
  final List<PropertyImage> images;
  final DateTime createdAt;

  Property({
    required this.id,
    required this.ownerId,
    this.ownerName = '',
    this.ownerPhone = '',
    required this.title,
    this.description = '',
    required this.price,
    this.rooms = 0,
    this.capacity = 0,
    this.region = '',
    this.address = '',
    this.lat = 0,
    this.lng = 0,
    required this.category,
    this.hasCctv = false,
    this.viewsCount = 0,
    this.isActive = true,
    this.images = const [],
    required this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      ownerName: json['owner_name'] ?? '',
      ownerPhone: json['owner_phone'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      rooms: json['rooms'] ?? 0,
      capacity: json['capacity'] ?? 0,
      region: json['region'] ?? '',
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      category: json['category'] ?? 'house',
      hasCctv: json['has_cctv'] ?? false,
      viewsCount: json['views_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => PropertyImage.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String? get primaryImageUrl {
    final primary = images.where((i) => i.isPrimary).firstOrNull;
    return primary?.fullUrl ?? images.firstOrNull?.fullUrl;
  }
}
