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
  final String currency;
  final int rooms;
  final int capacity;
  final String region;
  final String address;
  final double lat;
  final double lng;
  final String category;
  final bool hasCctv;
  // House features
  final int floor;
  final int totalFloors;
  final bool furnished;
  final String renovation;
  final bool balcony;
  final bool parking;
  final bool wifi;
  final bool washer;
  final bool conditioner;
  final bool fridge;
  final bool tv;
  // Car features
  final String carBrand;
  final int carYear;
  final String carTransmission;
  final String carFuel;
  final int carMileage;
  final String carColor;
  final bool carAc;
  final int carSeats;
  // Meta
  final int viewsCount;
  final bool isActive;
  final String status;
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
    this.currency = 'UZS',
    this.rooms = 0,
    this.capacity = 0,
    this.region = '',
    this.address = '',
    this.lat = 0,
    this.lng = 0,
    required this.category,
    this.hasCctv = false,
    this.floor = 0,
    this.totalFloors = 0,
    this.furnished = false,
    this.renovation = '',
    this.balcony = false,
    this.parking = false,
    this.wifi = false,
    this.washer = false,
    this.conditioner = false,
    this.fridge = false,
    this.tv = false,
    this.carBrand = '',
    this.carYear = 0,
    this.carTransmission = '',
    this.carFuel = '',
    this.carMileage = 0,
    this.carColor = '',
    this.carAc = false,
    this.carSeats = 0,
    this.viewsCount = 0,
    this.isActive = true,
    this.status = 'pending',
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
      currency: json['currency'] ?? 'UZS',
      rooms: json['rooms'] ?? 0,
      capacity: json['capacity'] ?? 0,
      region: json['region'] ?? '',
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      category: json['category'] ?? 'house',
      hasCctv: json['has_cctv'] ?? false,
      floor: json['floor'] ?? 0,
      totalFloors: json['total_floors'] ?? 0,
      furnished: json['furnished'] ?? false,
      renovation: json['renovation'] ?? '',
      balcony: json['balcony'] ?? false,
      parking: json['parking'] ?? false,
      wifi: json['wifi'] ?? false,
      washer: json['washer'] ?? false,
      conditioner: json['conditioner'] ?? false,
      fridge: json['fridge'] ?? false,
      tv: json['tv'] ?? false,
      carBrand: json['car_brand'] ?? '',
      carYear: json['car_year'] ?? 0,
      carTransmission: json['car_transmission'] ?? '',
      carFuel: json['car_fuel'] ?? '',
      carMileage: json['car_mileage'] ?? 0,
      carColor: json['car_color'] ?? '',
      carAc: json['car_ac'] ?? false,
      carSeats: json['car_seats'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      status: json['status'] ?? 'pending',
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
