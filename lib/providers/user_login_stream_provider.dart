// lib/providers/user_login_stream_provider.dart (or wherever this is)

// 1. Keep the provider SIMPLE. No async* logic here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'providers.dart';

final userProvider = StreamProvider<UserModel?>((ref) async* {
  debugPrint('streamProvider called   ***** ');
  final userDataStream = ref.watch(authenticate).onAuthStateChanged;

  await for (var userData in userDataStream) {
    if (userData != null) {
      debugPrint('login uid ${userData.uid}');
    }
    yield userData;
  }
});
