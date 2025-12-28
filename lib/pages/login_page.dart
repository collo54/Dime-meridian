import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_meridian/providers/providers.dart';

import '../layouts/login_module/login_mobile_layout.dart';
//import '../painters/notebook_painter.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Size size = MediaQuery.sizeOf(context);
    final currentScaffold = ref.watch(scaffoldScrimProvider);
    return Scaffold(
      key: currentScaffold,
      // backgroundColor: Colors.white,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Center(
          child: LoginMobileLayout(
            //currentScaffold: currentScaffold
          ),
        ),
      ),
    );
  }
}
