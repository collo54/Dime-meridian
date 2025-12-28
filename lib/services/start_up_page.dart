import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../custom/home_scaffold.dart';
import '../pages/login_page.dart';
import '../models/user_model.dart';
import '../providers/providers.dart'; // To update your Riverpod state

class StartupPage extends ConsumerStatefulWidget {
  const StartupPage({super.key});

  @override
  ConsumerState<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends ConsumerState<StartupPage> {
  @override
  void initState() {
    super.initState();
    _resolveAuthState();
  }

  Future<void> _resolveAuthState() async {
    // 1. Force Firebase to check the disk immediately
    // "userChanges" is more robust than "authStateChanges" for initial restoration
    // We await the FIRST event. This forces the app to wait until Firebase
    // has finished reading from Android KeyStore.
    final user = await FirebaseAuth.instance.userChanges().first;

    if (!mounted) return;

    if (user != null) {
      // 2. User found! Sync Riverpod state manually just in case
      ref
          .read(userModelProvider.notifier)
          .updateUserModel(
            UserModel(
              uid: user.uid,
              email: user.email ?? "",
              displayName: user.displayName ?? "",
              photoUrl: user.photoURL ?? "",
              phoneNumber: user.phoneNumber ?? "",
              isAnonymous: user.isAnonymous,
            ),
          );

      // 3. Navigate to Home (Remove Splash from back stack)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScaffold()),
      );
    } else {
      // 4. No user found on disk. Navigate to Login.
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is your Splash Screen
    final brightness = MediaQuery.platformBrightnessOf(context);
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
}
