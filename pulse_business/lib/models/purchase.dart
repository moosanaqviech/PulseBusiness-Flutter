// pulse_business/lib/models/purchase.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Purchase {
  final String id;
  final String userId;
  final String dealId;
  final String dealTitle;
  final String businessName;
  final double amount;
  final String status; // 'pending', 'confirmed', 'redeemed'
  final DateTime purchaseDate;
  final DateTime expirationDate;
  final String imageUrl;
  final String? qrCode;
  final String? stripePaymentIntentId;
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
    required this.purchaseDate,
    required this.expirationDate,
    required this.imageUrl,
    this.qrCode,
    this.stripePaymentIntentId,
    this.redeemedAt,
    this.redeemedBy,
  });

  // Computed properties
  bool get isConfirmed => status == 'confirmed';
  bool get isRedeemed => status == 'redeemed';
  bool get isPending => status == 'pending';
  bool get isExpired => DateTime.now().isAfter(expirationDate);
  bool get isActive => isConfirmed && !isExpired && !isRedeemed;
  bool get hasQRCode => qrCode != null && qrCode!.isNotEmpty;

  // Create from Firestore document
  factory Purchase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Purchase.fromMap(data, doc.id);
  }

  // Create from Map with optional ID
  factory Purchase.fromMap(Map<String, dynamic> data, [String? docId]) {
    return Purchase(
      id: docId ?? data['id'] ?? '',
      userId: data['userId'] ?? '',
      dealId: data['dealId'] ?? '',
      dealTitle: data['dealTitle'] ?? '',
      businessName: data['businessName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      purchaseDate: _parseTimestamp(data['purchaseTime']),
      expirationDate: _parseTimestamp(data['expirationTime']),
      imageUrl: data['imageUrl'] ?? '',
      qrCode: data['qrCode'],
      stripePaymentIntentId: data['stripePaymentIntentId'],
      redeemedAt: data['redeemedAt'] != null ? _parseTimestamp(data['redeemedAt']) : null,
      redeemedBy: data['redeemedBy'],
    );
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

  @override
  String toString() {
    return 'Purchase(id: $id, dealTitle: $dealTitle, amount: $amount, status: $status, isExpired: $isExpired, isRedeemed: $isRedeemed)';
  }
}