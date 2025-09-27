class Business {
  final String? id;
  final String name;
  final String description;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final String email;
  final String? website;
  final String? imageUrl;
  final String ownerId;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? businessHours;
  final int totalDeals;
  final int activeDeals;
  final double averageRating;

  Business({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.email,
    this.website,
    this.imageUrl,
    required this.ownerId,
    this.isVerified = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.businessHours,
    this.totalDeals = 0,
    this.activeDeals = 0,
    this.averageRating = 0.0,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory Business.fromMap(Map<String, dynamic> map, {String? id}) {
    return Business(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      website: map['website'],
      imageUrl: map['imageUrl'],
      ownerId: map['ownerId'] ?? '',
      isVerified: map['isVerified'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      businessHours: map['businessHours'],
      totalDeals: map['totalDeals'] ?? 0,
      activeDeals: map['activeDeals'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'isVerified': isVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'businessHours': businessHours,
      'totalDeals': totalDeals,
      'activeDeals': activeDeals,
      'averageRating': averageRating,
    };
  }

  Business copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? address,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    String? email,
    String? website,
    String? imageUrl,
    String? ownerId,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? businessHours,
    int? totalDeals,
    int? activeDeals,
    double? averageRating,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      businessHours: businessHours ?? this.businessHours,
      totalDeals: totalDeals ?? this.totalDeals,
      activeDeals: activeDeals ?? this.activeDeals,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}