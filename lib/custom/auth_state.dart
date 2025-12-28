import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_meridian/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import '../providers/providers.dart';
import '../providers/user_login_stream_provider.dart';
import 'home_scaffold.dart';

class AuthState extends ConsumerStatefulWidget {
  const AuthState({super.key});

  @override
  ConsumerState<AuthState> createState() => _AuthStateState();
}

class _AuthStateState extends ConsumerState<AuthState> {
  bool _postLoginHandled = false;
  late final ProviderSubscription _authSub;

  @override
  void initState() {
    super.initState();

    _authSub = ref.listenManual<AsyncValue<UserModel?>>(userProvider, (
      previous,
      next,
    ) async {
      next.whenData((user) async {
        if (user != null && !_postLoginHandled) {
          _postLoginHandled = true;

          ref.read(userModelProvider.notifier).updateUserModel(user);

          if (mounted) {
            await _handleUserPostLogin(ref, user);
          }
        }

        if (user == null) {
          _postLoginHandled = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _authSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(userProvider);

    return authStateAsync.when(
      data: (user) {
        if (user != null || FirebaseAuth.instance.currentUser != null) {
          Fluttertoast.showToast(
            msg: "user found",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.greenAccent,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return const HomeScaffold();
        } else {
          Fluttertoast.showToast(
            msg: "empty user",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.redAccent,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return const LoginPage();
        }
      },
      loading: () {
        return _buildLoadingScreen(MediaQuery.platformBrightnessOf(context));
      },
      error: (e, _) => Scaffold(body: Center(child: Text("Auth error: $e"))),
    );
  }

  Widget _buildLoadingScreen(Brightness brightness) {
    return Scaffold(
      backgroundColor: brightness == Brightness.light
          ? Colors.white
          : Colors.black,
      body: Center(
        child: SizedBox(
          width: 150,
          height: 150,
          child: Image.asset(
            brightness == Brightness.light
                ? 'assets/images/transparent_logo1.png'
                : 'assets/images/logo1.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // --- LOGIC (Kept exactly as you had it) ---
  Future<void> _handleUserPostLogin(WidgetRef ref, UserModel userModel) async {
    try {
      debugPrint("Handling post-login logic for ${userModel.uid}");

      if (!kIsWeb) {
        await Purchases.logIn(userModel.uid);
      }

      FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
      final fcmToken = await firebaseMessaging.getToken();

      final firestoreservice = ref.read(cloudFirestoreServiceProvider);
      // Wrap docExist in try-catch to prevent crashing if offline
      bool docExist = false;
      try {
        docExist = await firestoreservice.docExist(userModel.uid);
      } catch (e) {
        debugPrint("Firestore check failed (offline?): $e");
        // Assume true or handle offline logic if critical,
        // but don't crash the auth flow.
      }

      final timestamp = DateTime.now();

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

        // await _saveUserProfileToSharedPref(model);
        await firestoreservice.setUserProfile(model);
      } else {
        final userProfile = UserProfileModel(
          id: userModel.uid,
          name: userModel.displayName ?? "User",
          profilePicUrl: userModel.photoUrl ?? '',
          email: userModel.email ?? '',
          fcmToken: fcmToken,
          revenue: 0,
          isVerified: false,
          createdAt: timestamp,
          updatedAt: timestamp,
        );

        // await _saveUserProfileToSharedPref(userProfile);
        await firestoreservice.setUserProfile(userProfile);
      }
    } catch (e) {
      debugPrint("Error in post-login logic: $e");
    }
  }
}
