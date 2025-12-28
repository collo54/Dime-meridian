import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../providers/providers.dart';

class UserSettingsPage extends ConsumerWidget {
  UserSettingsPage({super.key});
  final _auth = AuthService();
  final GlobalKey<ScaffoldState> currentScaffold = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModel = ref.read(userModelProvider);
    final firestoreService = FirestoreService(uid: userModel.uid);
    Brightness brightness = MediaQuery.platformBrightnessOf(context);

    return Scaffold(
      key: currentScaffold,
      appBar: AppBar(
        title: const Text("User settings"),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              onPressed: () async {
                currentScaffold.currentState!.showBodyScrim(true, 0.5);
                if (!kIsWeb) {
                  await Purchases.logOut();
                }
                await _auth.signOut();
                final user = _auth.currentUser();

                currentScaffold.currentState!.showBodyScrim(false, 0.5);
              },
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedLogout01,
                color: brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                size: 24.0,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [],
        ),
      ),
    );
  }

  // Widget _buildEmptyState(String message) {
  //   return Container(
  //     height: 300,
  //     width: double.infinity,
  //     decoration: BoxDecoration(
  //       color: Colors.grey.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: Colors.grey.withOpacity(0.2)),
  //     ),
  //     child: Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           const Icon(Icons.bar_chart, size: 48, color: Colors.grey),
  //           const SizedBox(height: 8),
  //           Text(message, style: const TextStyle(color: Colors.grey)),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
