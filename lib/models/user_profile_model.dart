import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String id;
  final String email;
  final String name;
  final String? profilePicUrl;
  final String? fcmToken;
  final int revenue;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfileModel({
    required this.id,
    required this.email,
    required this.name,
    this.profilePicUrl,
    this.fcmToken,
    this.revenue = 0,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory to parse data from Firestore
  factory UserProfileModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    // Helper to safely parse revenue (handle string or int from DB)
    int parserevenue(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    // Helper to safely parse Timestamps
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserProfileModel(
      id: documentId,
      email: data["email"] ?? '',
      name: data["name"] ?? '',
      profilePicUrl: data["profilePicUrl"],
      fcmToken: data["fcmToken"],
      revenue: parserevenue(data["revenue"]),
      isVerified: data["isVerified"] ?? false,
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
    );
  }

  // Convert model back to Map for Firestore writing
  Map<String, dynamic> toMap() {
    return {
      "email": email,
      "name": name,
      "profilePicUrl": profilePicUrl,
      "fcmToken": fcmToken,
      "revenue": revenue, // Storing as int is better for queries than String
      "isVerified": isVerified,
      "createdAt": Timestamp.fromDate(createdAt),
      "updatedAt": Timestamp.fromDate(updatedAt),
    };
  }

  // CopyWith for state updates (Riverpod)
  UserProfileModel copyWith({
    String? id,
    String? email,
    String? name,
    String? profilePicUrl,
    String? fcmToken,
    int? revenue,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      revenue: revenue ?? this.revenue,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
