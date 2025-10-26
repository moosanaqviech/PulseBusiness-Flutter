import 'package:cloud_firestore/cloud_firestore.dart';

class Deal {
  final String? id;
  final String title;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final double originalPrice;
  final double dealPrice;
  final int totalQuantity;
  final int remainingQuantity;
  final String businessId;
  final String businessName;
  final String businessAddress;
  final DateTime createdAt;
  final DateTime expirationTime;
  final String? imageUrl;
  final List<String> imageUrls;
  final bool isActive;
  final int viewCount;
  final int claimCount;
  final String status;
  final String? termsAndConditions;
  final DateTime? startTime;  // null means start immediately
  final bool isScheduled;   

  Deal({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.originalPrice,
    required this.dealPrice,
    required this.totalQuantity,
    int? remainingQuantity,
    required this.businessId,
    required this.businessName,
    required this.businessAddress,
    DateTime? createdAt,
    required this.expirationTime,
    this.imageUrl,
    this.imageUrls = const [],
    this.isActive = true,
    this.viewCount = 0,
    this.claimCount = 0,
    this.status = 'active',
    this.termsAndConditions,
    this.startTime,
    this.isScheduled = false,
    
  }) : 
    remainingQuantity = remainingQuantity ?? totalQuantity,
    createdAt = createdAt ?? DateTime.now();
    String? get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : imageUrl;

  factory Deal.fromMap(Map<String, dynamic> map, {String? id}) {
    return Deal(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      dealPrice: (map['dealPrice'] ?? 0.0).toDouble(),
      totalQuantity: map['totalQuantity'] ?? 0,
      remainingQuantity: map['remainingQuantity'] ?? 0,
      businessId: map['businessId'] ?? '',
      businessName: map['businessName'] ?? '',
      businessAddress: map['businessAddress'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      expirationTime: DateTime.fromMillisecondsSinceEpoch(map['expirationTime'] ?? 0),
      imageUrl: map['imageUrl'],
      imageUrls: map['imageUrls'],
      isActive: map['isActive'] ?? true,
      viewCount: map['viewCount'] ?? 0,
      claimCount: map['claimCount'] ?? 0,
      status: map['status'] ?? 'active',
      termsAndConditions: map['termsAndConditions'],
       startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      isScheduled: map['isScheduled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'originalPrice': originalPrice,
      'dealPrice': dealPrice,
      'totalQuantity': totalQuantity,
      'remainingQuantity': remainingQuantity,
      'businessId': businessId,
      'businessName': businessName,
      'businessAddress' : businessAddress,
      'createdAt': Timestamp.fromDate(createdAt), 
      'expirationTime': Timestamp.fromDate(expirationTime), 
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'isActive': isActive,
      'viewCount': viewCount,
      'claimCount': claimCount,
      'status': status,
      'termsAndConditions': termsAndConditions,
      'startTime': startTime?.toIso8601String(),
      'isScheduled': isScheduled,
    };
  }

  // Utility methods
  int get discountPercentage {
    if (originalPrice <= 0) return 0;
    return (((originalPrice - dealPrice) / originalPrice) * 100).round();
  }

  bool get isExpired => DateTime.now().isAfter(expirationTime);

  bool get isSoldOut => remainingQuantity <= 0;

  String get formattedExpirationTime {
    return '${expirationTime.day}/${expirationTime.month}/${expirationTime.year} ${expirationTime.hour}:${expirationTime.minute.toString().padLeft(2, '0')}';
  }

  String get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expirationTime)) return 'Expired';
    
    final diff = expirationTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  double get conversionRate {
    if (viewCount == 0) return 0.0;
    return (claimCount / viewCount) * 100;
  }

 bool get shouldStartNow => startTime == null || DateTime.now().isAfter(startTime!);

  Deal copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? latitude,
    double? longitude,
    double? originalPrice,
    double? dealPrice,
    int? totalQuantity,
    int? remainingQuantity,
    String? businessId,
    String? businessName,
    DateTime? createdAt,
    DateTime? expirationTime,
    String? imageUrl,
    bool? isActive,
    int? viewCount,
    int? claimCount,
    String? status,
    String? termsAndConditions,
  }) {
    return Deal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      originalPrice: originalPrice ?? this.originalPrice,
      dealPrice: dealPrice ?? this.dealPrice,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      createdAt: createdAt ?? this.createdAt,
      expirationTime: expirationTime ?? this.expirationTime,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      viewCount: viewCount ?? this.viewCount,
      claimCount: claimCount ?? this.claimCount,
      status: status ?? this.status,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
    );
  }
}