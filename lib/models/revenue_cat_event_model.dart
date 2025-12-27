import 'package:cloud_firestore/cloud_firestore.dart';

class RevenueCatEventModel {
  final String eventId;
  final String userId;
  final String productId;
  final double amountUsd;
  final String store;
  final String type;
  final DateTime eventTimestamp;
  final DateTime createdAt;

  RevenueCatEventModel({
    required this.eventId,
    required this.userId,
    required this.productId,
    required this.amountUsd,
    required this.store,
    required this.type,
    required this.eventTimestamp,
    required this.createdAt,
  });

  // Factory to safely parse from Firestore Map
  factory RevenueCatEventModel.fromMap(Map<String, dynamic> data) {
    // Helper to parse Doubles safely (handles int/double/string)
    double parseDouble(dynamic val) {
      if (val is int) return val.toDouble();
      if (val is double) return val;
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    // Helper to parse Timestamps safely
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return RevenueCatEventModel(
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      amountUsd: parseDouble(data['amountUsd']),
      store: data['store'] ?? 'UNKNOWN',
      type: data['type'] ?? 'UNKNOWN',
      // Prefer eventTimestamp (actual purchase time) over createdAt (database write time)
      eventTimestamp: parseTimestamp(data['eventTimestamp']),
      createdAt: parseTimestamp(data['createdAt']),
    );
  }
}
