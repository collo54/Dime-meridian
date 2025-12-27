import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/revenue_cat_event_model.dart';
import '../models/user_profile_model.dart';
import 'document_path.dart';

class FirestoreService {
  FirestoreService({required this.uid});
  final String uid;
  final FirebaseFirestore db =
      FirebaseFirestore.instance; // Add instance for direct reads
  // final FirebaseFunctions _functions =
  //     FirebaseFunctions.instance; // Add instance for functions

  // generic funtion creates a dcomcument and sets data in the document
  Future<void> _set({required String path, Map<String, dynamic>? data}) async {
    final DocumentReference<Map<String, dynamic>?> reference = FirebaseFirestore
        .instance
        .doc(path);
    if (kDebugMode) {
      debugPrint('$path: $data');
    }
    await reference.set(data);
  }

  Future<void> _update({
    required String path,
    required Map<Object, Object?> data,
  }) async {
    final DocumentReference<Map<String, dynamic>?> reference = FirebaseFirestore
        .instance
        .doc(path);
    if (kDebugMode) {
      debugPrint('$path: $data');
    }
    await reference.update(data);
  }

  /// creates a user profile in userProfiles/{id} path
  Future<void> setUserProfile(UserProfileModel dataModel) async {
    await _set(
      path: DocumentPath.userProfiles(dataModel.id),
      data: dataModel.toMap(),
    );
  }

  ///reads a stream of User profiles from userProfiles/{id} path
  Stream<List<UserProfileModel>> userProfilesStream() {
    final path = DocumentPath.streamUserProfiles();
    final reference = FirebaseFirestore.instance.collection(path);
    final snapshots = reference.snapshots();
    return snapshots.map(
      (snapshot) => snapshot.docs
          .map(
            (snapshot) =>
                UserProfileModel.fromMap(snapshot.data(), snapshot.id),
          )
          .toList(),
    );
  }

  Stream<UserProfileModel> currentUserProfilesStream(String uidString) {
    final path = DocumentPath.streamUserProfiles();
    final reference = FirebaseFirestore.instance.collection(path);
    final snapshotsA = reference.doc(uidString).snapshots();
    return snapshotsA.map((snapshot) {
      if (snapshot.exists) {
        return UserProfileModel.fromMap(snapshot.data()!, snapshot.id);
      } else {
        return UserProfileModel(
          id: '',

          name: '',
          profilePicUrl: '',

          email: '',

          fcmToken: '',

          isVerified: false,

          createdAt: DateTime.utc(1800, 1, 1),
          updatedAt: DateTime.utc(1800, 1, 1),
        );
      }
    });
  }

  ///reads a private user profile for users collection per user id
  Future<UserProfileModel> userProfileFuture(String uidString) async {
    final path = DocumentPath.streamUserProfiles();
    final reference = FirebaseFirestore.instance.collection(path);
    final snapshots = await reference.doc(uidString).get();
    if (snapshots.exists) {
      return UserProfileModel.fromMap(snapshots.data()!, snapshots.id);
    } else {
      return UserProfileModel(
        id: '',

        name: '',
        profilePicUrl: '',

        email: '',

        fcmToken: '',

        isVerified: false,

        createdAt: DateTime.utc(1800, 1, 1),
        updatedAt: DateTime.utc(1800, 1, 1),
      );
    }
  }

  Future<bool> docExist(String uidString) async {
    final path = DocumentPath.streamUserProfiles();
    final reference = FirebaseFirestore.instance.collection(path);
    final snapshots = await reference.doc(uidString).get();
    return snapshots.exists;
  }

  /// deletes a user profile in userProfiles/{id} path
  Future<void> deleteUserProfile(UserProfileModel dataModel) async {
    final path = DocumentPath.userProfiles(dataModel.id);
    final reference = FirebaseFirestore.instance.doc(path);
    if (kDebugMode) {
      debugPrint('delete: $path');
    }
    await reference.delete();
  }

  // Add this method to your existing FirestoreService class

  /// Reads a stream of RevenueCat events, ordered by date
  Stream<List<RevenueCatEventModel>> revenueEventsStream() {
    // Note: You might need to create a composite index in Firestore
    // if you add .where() clauses later.
    return FirebaseFirestore.instance
        .collection('RevenuecatEvents')
        .orderBy('eventTimestamp', descending: false) // Oldest first for charts
        .limit(100) // Optimization: Limit to recent 100 events for graph
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RevenueCatEventModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Alternative: Fetch Future (if you don't need real-time updates)
  Future<List<RevenueCatEventModel>> getRevenueEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('RevenuecatEvents')
        .orderBy('eventTimestamp', descending: false)
        .limit(100)
        .get();

    return snapshot.docs
        .map((doc) => RevenueCatEventModel.fromMap(doc.data()))
        .toList();
  }
}
