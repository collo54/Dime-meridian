import 'dart:convert';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import 'providers.dart';

/// creates a streamProvider to listen to changes in User from firebase auth
/// Can be used to return homepage when user is signed in or login page when user is null
final userProvider = StreamProvider<UserModel?>((ref) async* {
  debugPrint('streamProvider called   ***** ');
  final userDataStream = ref.watch(authenticate).onAuthStateChanged;

  await for (var userData in userDataStream) {
    if (userData != null) {
      debugPrint('login uid 000 ${userData.uid}');
      await _saveUserProfileToFirestore(ref, userData);
      debugPrint('login uid ${userData.uid}');
      if (!kIsWeb) {
        await Purchases.logIn(userData.uid);
      }
    }
    yield userData;
  }
});

DateTime documentIdFromCurrentDate() => DateTime.now();

Future<void> _saveUserProfileToFirestore(
  // WidgetRef ref,
  StreamProviderRef<UserModel?> ref,
  UserModel userModel,
) async {
  try {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    await firebaseMessaging.requestPermission();
    final fcmToken = await firebaseMessaging.getToken();
    Fluttertoast.showToast(
      msg: "fcmToken: $fcmToken",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.greenAccent,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    final timestamp = documentIdFromCurrentDate();
    //  final userModel = ref.watch(userModelProvider);

    //final existingUserProfile = ref.watch(userProfileProvider);
    final firestoreservice = ref.read(cloudFirestoreServiceProvider);
    final docExist = await firestoreservice.docExist(userModel.uid);
    if (docExist) {
      UserProfileModel data = await firestoreservice.userProfileFuture(
        userModel.uid,
      );
      UserProfileModel model = UserProfileModel(
        id: data.id,
        name: data.name,
        profilePicUrl: data.profilePicUrl,

        email: data.email,

        fcmToken: fcmToken,
        revenue: data.revenue,

        isVerified: data.isVerified,

        createdAt: data.createdAt,
        updatedAt: timestamp,
      );
      // await _createClient(ref, model);
      await _saveUserProfileToSharedPref(model);

      await firestoreservice.setUserProfile(model);

      Fluttertoast.showToast(
        msg: "Called existing user",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else {
      var uuid = const Uuid();
      final userProfile = UserProfileModel(
        id: userModel.uid,
        name: userModel.displayName ?? getUserString(userModel.uid),
        profilePicUrl: userModel.photoUrl ?? '',
        email: userModel.email ?? '',
        fcmToken: fcmToken,
        revenue: 0,

        isVerified: false,

        createdAt: timestamp,
        updatedAt: timestamp,
      );
      // await _createClient(ref, userProfile);
      await _saveUserProfileToSharedPref(userProfile);
      await firestoreservice.setUserProfile(userProfile);
      Fluttertoast.showToast(
        msg: "Called new user",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  } on Exception catch (e) {
    // Fluttertoast.showToast(
    //   msg: "Error creating User Profile: $e",
    //   toastLength: Toast.LENGTH_LONG,
    //   gravity: ToastGravity.BOTTOM,
    //   timeInSecForIosWeb: 1,
    //   backgroundColor: Colors.redAccent,
    //   textColor: Colors.white,
    //   fontSize: 16.0,
    // );

    debugPrint('Error saving file cloud firestore: $e');
  }
}

String getUserString(String inputString) {
  String firstFiveChars = inputString.substring(0, min(inputString.length, 5));
  return "user$firstFiveChars";
}

Future<void> _saveUserProfileToSharedPref(UserProfileModel user) async {
  final prefs = await SharedPreferences.getInstance();

  // Convert the model to a map that uses Strings for dates instead of Timestamps
  final userMapForPrefs = {
    "id": user.id,
    "email": user.email,
    "name": user.name,
    "profilePicUrl": user.profilePicUrl,
    "fcmToken": user.fcmToken,
    "revenue": user.revenue,
    "isVerified": user.isVerified,
    // Convert Dates to ISO Strings so JSON can encode them
    "createdAt": user.createdAt.toIso8601String(),
    "updatedAt": user.updatedAt.toIso8601String(),
  };

  // Now jsonEncode will work perfectly
  final string = jsonEncode(userMapForPrefs);

  // Consider overwriting every time to keep local data fresh,
  // instead of checking if it exists.
  await prefs.setString('userProfile', string);
}
