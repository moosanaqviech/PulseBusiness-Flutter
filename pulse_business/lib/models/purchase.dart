// pulse_flutter/lib/models/purchase.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Purchase {
  final String id;
  final String userId;
  final String dealId;
  final String dealTitle;
  final String businessName;
  final double amount;
  final String status; // 'pending', 'confirmed', 'redeemed', 'expired'
  final int purchaseTime;
  final int expirationTime;
  final String? qrCode;
  final String? imageUrl;
  final String? stripePaymentIntentId; // Added to match business model
  final Map<String, dynamic>? dealSnapshot;
  final DateTime? redeemedAt;
  final String? redeemedBy;

  Purchase({
    required this.id,
    required this.userId,
    required this.dealId,
    required this.dealTitle,
    required this.businessName,
    required this.amount,
    required this.status,
    required this.purchaseTime,
    required this.expirationTime,
    this.qrCode,
    this.imageUrl,
    this.stripePaymentIntentId,
    this.dealSnapshot,
    this.redeemedAt,
    this.redeemedBy,
  });

  // Check if purchase is expired
  bool get isExpired {
    return DateTime.now().millisecondsSinceEpoch > expirationTime;
  }

  // Check if purchase is redeemed
  bool get isRedeemed {
    return status == 'redeemed';
  }

  // Check if purchase is active (confirmed and not expired/redeemed)
  bool get isActive {
    return status == 'confirmed' && !isExpired && !isRedeemed;
  }

  // Check if has QR code
  bool get hasQRCode {
    return qrCode != null && qrCode!.isNotEmpty;
  }

  // Get purchase date
  DateTime get purchaseDate {
    return DateTime.fromMillisecondsSinceEpoch(purchaseTime);
  }

  // Get expiration date
  DateTime get expirationDate {
    return DateTime.fromMillisecondsSinceEpoch(expirationTime);
  }

  // Create Purchase from Firestore document
  factory Purchase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Purchase.fromMap(data, doc.id);
  }

  // Create Purchase from Map with optional ID
  // Create Purchase from Map with optional ID - FULL DEBUG VERSION
  factory Purchase.fromMap(Map<String, dynamic> data, [String? docId]) {
    print('🔍 DEBUG: Starting Purchase.fromMap');
    print('🔍 DEBUG: Full data: $data');
    
    try {
      // Debug each field individually
      print('🔍 DEBUG: Processing id...');
      final id = docId ?? data['id'] ?? '';
      print('✅ id: $id (${id.runtimeType})');

      print('🔍 DEBUG: Processing userId...');
      final userId = data['userId'] ?? '';
      print('✅ userId: $userId (${userId.runtimeType})');

      print('🔍 DEBUG: Processing dealId...');
      final dealId = data['dealId'] ?? '';
      print('✅ dealId: $dealId (${dealId.runtimeType})');

      print('🔍 DEBUG: Processing dealTitle...');
      final dealTitle = data['dealTitle'] ?? '';
      print('✅ dealTitle: $dealTitle (${dealTitle.runtimeType})');

      print('🔍 DEBUG: Processing businessName...');
      final businessName = data['businessName'] ?? '';
      print('✅ businessName: $businessName (${businessName.runtimeType})');

      print('🔍 DEBUG: Processing amount...');
      final amount = (data['amount'] ?? 0.0).toDouble();
      print('✅ amount: $amount (${amount.runtimeType})');

      print('🔍 DEBUG: Processing status...');
      final status = data['status'] ?? 'pending';
      print('✅ status: $status (${status.runtimeType})');

      

      print('🔍 DEBUG: Processing qrCode...');
      final qrCode = data['qrCode'];
      print('✅ qrCode: $qrCode (${qrCode.runtimeType})');

      print('🔍 DEBUG: Processing imageUrl...');
      final imageUrl = data['imageUrl'];
      print('✅ imageUrl: $imageUrl (${imageUrl.runtimeType})');

      print('🔍 DEBUG: Processing stripePaymentIntentId...');
      final stripePaymentIntentId = data['stripePaymentIntentId'];
      print('✅ stripePaymentIntentId: $stripePaymentIntentId (${stripePaymentIntentId.runtimeType})');

      print('🔍 DEBUG: Processing redeemedAt...');
      final redeemedAt = data['redeemedAt'] != null 
        ? _parseTimestamp(data['redeemedAt'])
        : null;
      print('✅ redeemedAt: $redeemedAt (${redeemedAt.runtimeType})');

      print('🔍 DEBUG: Processing redeemedBy...');
      final redeemedBy = data['redeemedBy'];
      print('✅ redeemedBy: $redeemedBy (${redeemedBy.runtimeType})');

      print('🔍 DEBUG: Creating Purchase object...');
      return Purchase(
        id: id,
        userId: userId,
        dealId: dealId,
        dealTitle: dealTitle,
        businessName: businessName,
        amount: amount,
        status: status,
        purchaseTime: _parseUniversalTimestamp(data['purchaseTime']),
        expirationTime: _parseUniversalTimestamp(data['expirationTime']),
        qrCode: qrCode,
        imageUrl: imageUrl,
        stripePaymentIntentId: stripePaymentIntentId,
        dealSnapshot: null, // Skip for now
        redeemedAt: redeemedAt,
        redeemedBy: redeemedBy,
      );
    } catch (e, stackTrace) {
      print('❌ ERROR in Purchase.fromMap: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ Data that caused error: $data');
      rethrow;
    }
  }

  // Helper method to parse timestamps from various formats
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }

    return DateTime.now();
  }

  // Convert Purchase to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dealId': dealId,
      'dealTitle': dealTitle,
      'businessName': businessName,
      'amount': amount,
      'status': status,
      'purchaseTime': purchaseTime,
      'expirationTime': expirationTime,
      'qrCode': qrCode,
      'imageUrl': imageUrl,
      'stripePaymentIntentId': stripePaymentIntentId,
      'dealSnapshot': dealSnapshot,
      'redeemedAt': redeemedAt?.millisecondsSinceEpoch,
      'redeemedBy': redeemedBy,
    };
  }

  // Create a copy with updated values
  Purchase copyWith({
    String? id,
    String? userId,
    String? dealId,
    String? dealTitle,
    String? businessName,
    double? amount,
    String? status,
    int? purchaseTime,
    int? expirationTime,
    String? qrCode,
    String? imageUrl,
    String? stripePaymentIntentId,
    Map<String, dynamic>? dealSnapshot,
    DateTime? redeemedAt,
    String? redeemedBy,
  }) {
    return Purchase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dealId: dealId ?? this.dealId,
      dealTitle: dealTitle ?? this.dealTitle,
      businessName: businessName ?? this.businessName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      purchaseTime: purchaseTime ?? this.purchaseTime,
      expirationTime: expirationTime ?? this.expirationTime,
      qrCode: qrCode ?? this.qrCode,
      imageUrl: imageUrl ?? this.imageUrl,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      dealSnapshot: dealSnapshot ?? this.dealSnapshot,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      redeemedBy: redeemedBy ?? this.redeemedBy,
    );
  }

  
  @override
  String toString() {
    return 'Purchase(id: $id, dealTitle: $dealTitle, status: $status, amount: $amount, isRedeemed: $isRedeemed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Purchase && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  static int _parseUniversalTimestamp(dynamic value) {
  if (value == null) {
    print('⚠️ Null timestamp, using current time');
    return DateTime.now().millisecondsSinceEpoch;
  }

  // Case 1: Already int (milliseconds) - expirationTime format
  if (value is int) {
    print('✅ Timestamp is int: $value');
    return value;
  }

  // Case 2: Firebase Timestamp - purchaseTime format  
  if (value is Timestamp) {
    final millis = value.toDate().millisecondsSinceEpoch;
    print('✅ Timestamp converted from Timestamp: $millis');
    return millis;
  }

  // Case 3: String datetime
  if (value is String) {
    try {
      final datetime = DateTime.parse(value);
      final millis = datetime.millisecondsSinceEpoch;
      print('✅ Timestamp parsed from string: $millis');
      return millis;
    } catch (e) {
      print('❌ Failed to parse string timestamp: $value');
    }
  }

  // Case 4: DateTime object
  if (value is DateTime) {
    final millis = value.millisecondsSinceEpoch;
    print('✅ Timestamp from DateTime: $millis');
    return millis;
  }

  // Case 5: Map (sometimes Firebase returns complex objects)
  if (value is Map) {
    print('⚠️ Complex timestamp object: $value');
    // Try to extract seconds and nanoseconds
    if (value.containsKey('_seconds')) {
      final seconds = value['_seconds'] as int? ?? 0;
      final nanoseconds = value['_nanoseconds'] as int? ?? 0;
      final millis = (seconds * 1000) + (nanoseconds ~/ 1000000);
      print('✅ Timestamp from complex object: $millis');
      return millis;
    }
  }

  print('❌ Unknown timestamp type: ${value.runtimeType} - $value');
  return DateTime.now().millisecondsSinceEpoch;
}



}