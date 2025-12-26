// lib/src/services/analytics_providers.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the FirebaseAnalytics instance
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

// Provider for the FirebaseAnalyticsObserver
// This observer is used by MaterialApp for automatic screen tracking
final firebaseAnalyticsObserverProvider = Provider<FirebaseAnalyticsObserver>((
  ref,
) {
  final analytics = ref.watch(
    firebaseAnalyticsProvider,
  ); // Depend on the analytics instance
  return FirebaseAnalyticsObserver(analytics: analytics);
});

// --- Optional: Create an Analytics Service Wrapper ---
// This abstraction can be useful for testing or if you want to add
// custom logic/formatting around your analytics calls.

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  // Automatic screen tracking is handled by FirebaseAnalyticsObserver

  // Manual screen view logging
  Future<void> logScreenView(
    String screenName, {
    String? screenClassOverride,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass:
          screenClassOverride ?? screenName, // Default class to screen name
    );
    debugPrint('Analytics: ScreenView - $screenName');
  }

  // Log a custom event
  Future<void> logCustomEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: eventName, parameters: parameters);
    debugPrint('Analytics: Event - $eventName, Params - $parameters');
  }

  // Log a login event
  Future<void> logLogin(String loginMethod) async {
    await _analytics.logLogin(loginMethod: loginMethod);
    debugPrint('Analytics: Login - Method: $loginMethod');
  }

  // Log a sign-up event
  Future<void> logSignUp(String signUpMethod) async {
    await _analytics.logSignUp(signUpMethod: signUpMethod);
    debugPrint('Analytics: SignUp - Method: $signUpMethod');
  }

  // Set user ID
  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
    debugPrint('Analytics: SetUserID - $id');
  }

  // Set a user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
    debugPrint('Analytics: SetUserProperty - Name: $name, Value: $value');
  }

  // Add more specific event logging methods as needed
  // e.g., logButtonPressed, logItemViewed, logPurchase
  Future<void> logButtonPressed(
    String buttonName, {
    String? screenContext,
  }) async {
    await logCustomEvent(
      'button_pressed',
      parameters: {
        'button_name': buttonName,
        if (screenContext != null) 'screen_context': screenContext,
      },
    );
  }

  // 1. Track Category Clicks
  Future<void> logCategoryClicked({
    required String categoryTitle,
    required bool isVip,
  }) async {
    await _analytics.logEvent(
      name: 'category_click',
      parameters: {
        'category_name': categoryTitle,
        'is_vip_category': isVip.toString(),
      },
    );
  }

  // 2. Track Paywall / Access Events
  Future<void> logVipAccessAttempt({
    required String featureName,
    required bool accessGranted,
    required String method, // e.g., 'proAccess'
  }) async {
    await _analytics.logEvent(
      name: 'vip_access_attempt',
      parameters: {
        'feature': featureName,
        'access_granted': accessGranted.toString(),
        'access_method': method,
      },
    );
  }

  // 3. Set User Properties (To track Paid Status)
  // This tags the user permanently (or until changed) so you can filter
  // audiences in Firebase by "All Access Users" vs "Free Users"
  Future<void> updateUserSubscriptionStatus({required bool isPro}) async {
    await _analytics.setUserProperty(
      name: 'subscriber_pro',
      value: isPro.toString(),
    );
  }
}

// Provider for your custom AnalyticsService
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final firebaseAnalytics = ref.watch(firebaseAnalyticsProvider);
  return AnalyticsService(firebaseAnalytics);
});
