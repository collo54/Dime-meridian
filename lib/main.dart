import 'package:dime_meridian/custom/auth_state.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform, PlatformDispatcher;
import 'package:firebase_core/firebase_core.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:myapp/services/notifications_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'firebase_options.dart';
import 'providers/analytics_service_provider.dart';
import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';

void main() async {
  //WidgetsBinding widgetsBinding =
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  //FirebaseFirestore.setLoggingEnabled(true);
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await _configureSDK();

  //AppUpdateService.checkForUpdate();
  // FlutterNativeSplash.remove();
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _configureSDK() async {
  if (kIsWeb) {
    return;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      PurchasesConfiguration configuration;
      await Purchases.setLogLevel(LogLevel.debug);
      configuration = PurchasesConfiguration(
        'test_MijiWvbgJLjyZKXcGHZgbBcOQif',
      );
      await Purchases.configure(configuration);
      return;
    case TargetPlatform.iOS:
      return;
    case TargetPlatform.macOS:
      return;
    case TargetPlatform.windows:
      return;
    case TargetPlatform.linux:
      return;
    default:
      return;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsObserver = ref.watch(firebaseAnalyticsObserverProvider);
    return MaterialApp(
      title: 'Dime meridian',
      navigatorObservers: [analyticsObserver],
      debugShowCheckedModeBanner: false,
      theme: oneChatTheme,
      darkTheme: oneChatDarkTheme,
      themeMode: ThemeMode.system,
      home: AuthState(),
    );
  }
}
