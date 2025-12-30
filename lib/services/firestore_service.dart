import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';
import '../models/revenue_cat_event_model.dart';
import '../models/user_profile_model.dart';
import '../providers/providers.dart';
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

  /// Reads a stream of RevenueCat events, ordered by date
  Stream<List<RevenueCatEventModel>> revenuecatRenenwalEventsStream(
    String eventType,
  ) {
    // Note: You might need to create a composite index in Firestore
    // if you add .where() clauses later.
    return FirebaseFirestore.instance
        .collection('RevenuecatEvents')
        .where('type', isEqualTo: eventType)
        .orderBy('eventTimestamp', descending: false) // Oldest first for charts
        .limit(100) // Optimization: Limit to recent 100 events for graph
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            debugPrint("Querying for type: $eventType");
            debugPrint("Docs found: ${snapshot.docs.length}");
            return RevenueCatEventModel.fromMap(doc.data());
          }).toList(),
        );
  }

  /// Reads a stream of events filtered by Type and Date Range
  Stream<List<RevenueCatEventModel>> revenuecatFilteredEventsStream({
    required String eventType,
    required TimeRange timeRange,
  }) {
    Query query = FirebaseFirestore.instance
        .collection('RevenuecatEvents')
        .where('type', isEqualTo: eventType)
        .orderBy('eventTimestamp', descending: false);

    // Apply Date Filtering
    DateTime now = DateTime.now();
    if (timeRange == TimeRange.days7) {
      DateTime start = now.subtract(const Duration(days: 7));
      query = query.where('eventTimestamp', isGreaterThanOrEqualTo: start);
    } else if (timeRange == TimeRange.days30) {
      DateTime start = now.subtract(const Duration(days: 30));
      query = query.where('eventTimestamp', isGreaterThanOrEqualTo: start);
    }
    // For 'allTime', we don't add a date filter, but you might want a higher limit

    // Safety limit to prevent reading 10k docs in one go
    // For "All Time" you might want to increase this or implement pagination logic
    int limit = timeRange == TimeRange.allTime ? 500 : 100;

    return query
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => RevenueCatEventModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  // --- AI CONVERSATION METHODS ---

  /// 1. Create or Update a Conversation Session (The "Folder")
  /// Call this when the FIRST message is sent in a new chat.
  Future<void> saveChatSession(ChatSessionModel session) async {
    try {
      await db
          .collection('UserProfiles')
          .doc(uid)
          .collection('conversations') // New Collection
          .doc(session.id)
          .set(session.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving chat session: $e");
    }
  }

  /// 2. Save a Message to a SPECIFIC Conversation
  Future<void> saveChatMessage({
    required String conversationId,
    required ChatMessageModel message,
  }) async {
    try {
      // A. Save the message in the sub-collection
      await db
          .collection('UserProfiles')
          .doc(uid)
          .collection('conversations')
          .doc(conversationId)
          .collection('messages') // Sub-collection
          .doc(message.id)
          .set(message.toMap());

      // B. Update the "Last Updated" time on the parent session
      // This ensures the most recent chat stays at the top of the history list
      await db
          .collection('UserProfiles')
          .doc(uid)
          .collection('conversations')
          .doc(conversationId)
          .update({'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint("Error saving chat message: $e");
    }
  }

  /// 3. Stream the LIST of conversations (For the History Sidebar/Drawer)
  Stream<List<ChatSessionModel>> chatSessionsStream() {
    return db
        .collection('UserProfiles')
        .doc(uid)
        .collection('conversations')
        .orderBy('updatedAt', descending: true) // Newest chats first
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatSessionModel.fromMap(doc.data()))
              .toList(),
        );
  }

  /// 4. Stream messages for ONE specific conversation
  Stream<List<ChatMessageModel>> chatMessagesStream(String conversationId) {
    return db
        .collection('UserProfiles')
        .doc(uid)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false) // Oldest first (bubble order)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessageModel.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Deletes a conversation and all its messages
  Future<void> deleteChatSession(String conversationId) async {
    try {
      final sessionRef = db
          .collection('UserProfiles')
          .doc(uid)
          .collection('conversations')
          .doc(conversationId);

      final messagesRef = sessionRef.collection('messages');

      // 1. Get all messages in the sub-collection
      final messagesSnapshot = await messagesRef.get();

      // 2. Create a batch to delete everything at once
      WriteBatch batch = db.batch();

      // 3. Queue up message deletions
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 4. Queue up the session document deletion
      batch.delete(sessionRef);

      // 5. Commit the delete
      await batch.commit();

      debugPrint("Successfully deleted session: $conversationId");
    } catch (e) {
      debugPrint("Error deleting chat session: $e");
      // Rethrow so UI can handle the error (show toast, etc)
      rethrow;
    }
  }

  // // --- AI CHAT HISTORY METHODS ---

  // /// Saves a single chat message to Firestore
  // Future<void> saveChatMessage(ChatMessageModel message) async {
  //   try {
  //     await db
  //         .collection('UserProfiles')
  //         .doc(uid)
  //         .collection('ai_conversations')
  //         .doc(message.id)
  //         .set(message.toMap());
  //   } catch (e) {
  //     debugPrint("Error saving chat message: $e");
  //   }
  // }

  // /// Streams the chat history for the current user, ordered by time
  // Stream<List<ChatMessageModel>> chatHistoryStream() {
  //   return db
  //       .collection('UserProfiles')
  //       .doc(uid)
  //       .collection('ai_conversations')
  //       .orderBy('createdAt', descending: false) // Oldest at top
  //       .snapshots()
  //       .map(
  //         (snapshot) => snapshot.docs
  //             .map((doc) => ChatMessageModel.fromMap(doc.data()))
  //             .toList(),
  //       );
  // }
}
