import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_meridian/pages/login_page.dart';

import '../providers/providers.dart';
import '../providers/user_login_stream_provider.dart';
import 'home_scaffold.dart';
// import 'connection_state_monitor.dart';
// import 'remote_config_app_version.dart';

class AuthState extends ConsumerWidget {
  const AuthState({super.key, this.page});
  final int? page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Brightness brightness = MediaQuery.platformBrightnessOf(context);
    debugPrint('authstate called ****');
    // ref.read(newModelUserNotifierProvider);
    ref.read(userModelProvider);
    final value = ref.watch(userProvider);
    return value.when(
      loading: () => Scaffold(
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : Colors.black,
        body: Center(
          child: SizedBox(
            width: 150,
            height: 150,
            child: Image.asset(
              brightness == Brightness.light
                  ? 'assets/images/transparent_logo1.jpg'
                  : 'assets/images/logo1.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text(error.toString()))),
      data: (user) {
        if (user != null) {
          Future(() {
            // ref
            //     .read(newModelUserNotifierProvider.notifier)
            //     .updateUserModel(user);
            ref.read(userModelProvider.notifier).updateUserModel(user);
          });

          return
          // const VersionCheckWrapper(
          //   child: ConnectionStateMonitor(),
          // );
          const HomeScaffold();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
