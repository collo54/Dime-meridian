import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/permissions_service.dart';
import 'new_user_model_notifier.dart';
import 'page_index_notifier.dart';
import 'previous_page_index_notifier.dart';
import 'user_model_notifier.dart';

final pageIndexProvider = NotifierProvider<PageIndex, int>(PageIndex.new);
final previousPageIndexProvider =
    NotifierProvider<PreviousPageIndex, List<int>>(PreviousPageIndex.new);

final userModelProvider =
    NotifierProvider<UserModelProviderListener, UserModel>(
      UserModelProviderListener.new,
    );
final newModelUserNotifierProvider =
    NotifierProvider<NewModelUserNotifier, List<UserModel>>(
      NewModelUserNotifier.new,
    );

final scaffoldScrimProvider = Provider((ref) {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  return scaffoldKey;
});

/// creates a provider for AuthService class
final authenticate = Provider((ref) => AuthService());
// final authenticate = Provider<AuthService>((ref) {
//   ref.keepAlive();
//   return AuthService();
// });

/// creates a provider for permission handler class
final permissionServiceProvider = Provider((ref) => PermissionService());

/// creates a provider for Firestore service class
final cloudFirestoreServiceProvider = Provider((ref) {
  UserModel? usermodel = ref.watch(userModelProvider);
  return FirestoreService(uid: usermodel!.uid);
});

// Tracks the selected event type for the filtered chart
final eventTypeFilterProvider = StateProvider<String>(
  (ref) => 'INITIAL_PURCHASE',
);

// Tracks the selected event type for the filtered chart
final eventTypeFilterProviderChartOne = StateProvider<String>(
  (ref) => 'INITIAL_PURCHASE',
);

enum TimeRange { days7, days30, allTime }

// Filter for Time Range (New)
final timeRangeFilterProvider = StateProvider<TimeRange>(
  (ref) => TimeRange.days30,
);
