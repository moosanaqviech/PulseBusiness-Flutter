// pulse_business/lib/models/business_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'business.dart';

class BusinessProfile {
  final String id;
  final String ownerId;
  final String businessName;
  final String? category;
  final String? description;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? website;
  final String? logoUrl;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, String>? businessHours; // Day -> "09:00-17:00" format
  final double? latitude;
  final double? longitude;

  BusinessProfile({
    required this.id,
    required this.ownerId,
    required this.businessName,
    this.category,
    this.description,
    this.phoneNumber,
    this.email,
    this.address,
    this.website,
    this.logoUrl,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.businessHours,
    this.latitude,
    this.longitude,
  });

  // Create from Firestore document
  factory BusinessProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusinessProfile.fromMap(data, doc.id);
  }

  // Create from Map
  factory BusinessProfile.fromMap(Map<String, dynamic> data, [String? docId]) {
    return BusinessProfile(
      id: docId ?? data['id'] ?? '',
      ownerId: data['ownerId'] ?? '',
      businessName: data['businessName'] ?? '',
      category: data['category'],
      description: data['description'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      address: data['address'],
      website: data['website'],
      logoUrl: data['logoUrl'],
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
          : DateTime.now(),
      businessHours: data['businessHours'] != null
          ? Map<String, String>.from(data['businessHours'])
          : null,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'businessName': businessName,
      'category': category,
      'description': description,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'website': website,
      'logoUrl': logoUrl,
      'isVerified': isVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'businessHours': businessHours,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create a copy with updated fields
  BusinessProfile copyWith({
    String? id,
    String? ownerId,
    String? businessName,
    String? category,
    String? description,
    String? phoneNumber,
    String? email,
    String? address,
    String? website,
    String? logoUrl,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? businessHours,
    double? latitude,
    double? longitude,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      description: description ?? this.description,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      businessHours: businessHours ?? this.businessHours,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Convert from existing Business model
  factory BusinessProfile.fromBusiness(Business business) {
    return BusinessProfile(
      id: business.id ?? '',
      ownerId: business.ownerId,
      businessName: business.name,
      category: business.category,
      description: business.description,
      phoneNumber: business.phoneNumber,
      email: business.email,
      address: business.address,
      website: business.website,
      logoUrl: business.imageUrl,
      isVerified: business.isVerified ?? false,
      createdAt: business.createdAt ?? DateTime.now(),
      updatedAt: business.updatedAt ?? DateTime.now(),
      latitude: business.latitude,
      longitude: business.longitude,
      businessHours: business.businessHours != null 
          ? {'general': business.businessHours!} 
          : null,
    );
  }

  // Convert to Business model
  Business toBusiness() {
    return Business(
      id: id,
      ownerId: ownerId,
      name: businessName,
      category: category!,
      description: description!,
      phoneNumber: phoneNumber!,
      email: email!,
      address: address!,
      website: website,
      imageUrl: logoUrl,
      isVerified: isVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
      latitude: latitude!,
      longitude: longitude!,
      businessHours: businessHours?['general'],
      totalDeals: 0,
      activeDeals: 0,
      averageRating: 0.0,
    );
  }

  // Helper methods
  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;
  bool get hasAddress => address != null && address!.isNotEmpty;
  bool get hasPhone => phoneNumber != null && phoneNumber!.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;
  
  String get displayCategory {
    if (category == null) return 'Other';
    return category!.split('').first.toUpperCase() + category!.substring(1);
  }

  // Check if profile is complete enough for public listing
  bool get isComplete {
    return businessName.isNotEmpty &&
           category != null &&
           description != null &&
           description!.isNotEmpty &&
           hasAddress &&
           hasPhone;
  }
}