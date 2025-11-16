import 'package:cloud_firestore/cloud_firestore.dart';
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
  final double? averageRating;
  final int? totalRatings;

  final bool isTaxApplicable;

  //Stripe Connect Express
  final String? stripeConnectedAccountId;
  final bool stripeAccountOnboarded;
  final bool stripePayoutsEnabled;
  final String? stripeAccountStatus; // 'pending', 'active', 'restricted', 'incomplete'
  final DateTime? stripeOnboardingCompletedAt;
  final bool canCreateDeals; // Can create deals even without Stripe setup

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
    this.totalRatings = 0,

    this.stripeConnectedAccountId,
    this.stripeAccountOnboarded = false,
    this.stripePayoutsEnabled = false,
    this.stripeAccountStatus,
    this.stripeOnboardingCompletedAt,
    this.canCreateDeals = true, // Allow deal creation by default
    this.isTaxApplicable = true, // Default to including tax (safer assumption)
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
      createdAt : _parseTimestamp(map['createdAt']),
      updatedAt : _parseTimestamp(map['updatedAt']),
      businessHours: map['businessHours'],
      totalDeals: map['totalDeals'] ?? 0,
      activeDeals: map['activeDeals'] ?? 0,
      averageRating: map['averageRating'] != null 
        ? (map['averageRating'] as num).toDouble() 
        : null,
      totalRatings: map['totalRatings'] ?? 0,

      stripeConnectedAccountId: map['stripeConnectedAccountId'],
      stripeAccountOnboarded: map['stripeAccountOnboarded'] ?? false,
      stripePayoutsEnabled: map['stripePayoutsEnabled'] ?? false,
      stripeAccountStatus: map['stripeAccountStatus'],
      stripeOnboardingCompletedAt: map['stripeOnboardingCompletedAt'] != null
        ? _parseTimestamp(map['stripeOnboardingCompletedAt'])
          : null,
      canCreateDeals: map['canCreateDeals'] ?? true,
      // NEW: Default to true if field doesn't exist (backward compatibility)
      isTaxApplicable: map['isTaxApplicable'] ?? true,
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
      'createdAt': Timestamp.fromDate(createdAt), 
      'updatedAt': Timestamp.fromDate(updatedAt), 
      'businessHours': businessHours,
      'totalDeals': totalDeals,
      'activeDeals': activeDeals,
      'averageRating': averageRating,
      'totalRatings': totalRatings,

      'stripeConnectedAccountId': stripeConnectedAccountId,
      'stripeAccountOnboarded': stripeAccountOnboarded,
      'stripePayoutsEnabled': stripePayoutsEnabled,
      'stripeAccountStatus': stripeAccountStatus,
      'stripeOnboardingCompletedAt': stripeOnboardingCompletedAt != null 
        ? Timestamp.fromDate(stripeOnboardingCompletedAt!) 
        : null,
      'canCreateDeals': canCreateDeals,
      // NEW: Include tax field
      'isTaxApplicable': isTaxApplicable,
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
    int? totalRatings,

    String? stripeConnectedAccountId,
    bool? stripeAccountOnboarded,
    bool? stripePayoutsEnabled,
    String? stripeAccountStatus,
    DateTime? stripeOnboardingCompletedAt,
    bool? canCreateDeals,
    // NEW: Include in copyWith
    bool? isTaxApplicable,
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
      totalRatings: totalRatings ?? this.totalRatings,

      stripeConnectedAccountId: stripeConnectedAccountId ?? this.stripeConnectedAccountId,
      stripeAccountOnboarded: stripeAccountOnboarded ?? this.stripeAccountOnboarded,
      stripePayoutsEnabled: stripePayoutsEnabled ?? this.stripePayoutsEnabled,
      stripeAccountStatus: stripeAccountStatus ?? this.stripeAccountStatus,
      stripeOnboardingCompletedAt: stripeOnboardingCompletedAt ?? this.stripeOnboardingCompletedAt,
      canCreateDeals: canCreateDeals ?? this.canCreateDeals,

       // NEW: Include in copyWith
      isTaxApplicable: isTaxApplicable ?? this.isTaxApplicable,
    );
  }

   bool get needsPaymentSetup {
    return !stripeAccountOnboarded || !stripePayoutsEnabled;
  }

  bool get hasActiveStripeAccount {
    return stripeAccountOnboarded && 
           stripePayoutsEnabled && 
           stripeAccountStatus == 'active';
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) {
    return DateTime.now();
  }
  
  if (timestamp is Timestamp) {
    return timestamp.toDate();  // Firestore Timestamp
  }
  
  if (timestamp is int) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);  // Old format
  }
  
  if (timestamp is String) {
    return DateTime.tryParse(timestamp) ?? DateTime.now();
  }
  
  return DateTime.now();
}
}