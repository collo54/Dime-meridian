import 'dart:async';

import 'package:dime_meridian/pages/revenue_dashboard.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../constants/colors.dart';

import '../pages/user_settings_page.dart';
import '../providers/providers.dart';

class HomeScaffold extends ConsumerStatefulWidget {
  const HomeScaffold({super.key});

  @override
  ConsumerState<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends ConsumerState<HomeScaffold> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    firebaseMessageRequestPermission();

    _observeFcmMessages();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Brightness brightness = MediaQuery.platformBrightnessOf(context);
    final Size size = MediaQuery.sizeOf(context);
    final currentTab = ref.watch(pageIndexProvider);
    ref.watch(previousPageIndexProvider);
    final permissionService = ref.watch(permissionServiceProvider);

    return DefaultTabController(
      length: 3,
      initialIndex: currentTab,
      child: Scaffold(
        // backgroundColor: kblack00005,
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [RevenueDashboard(), Placeholder(), UserSettingsPage()],
        ),
        extendBody: false,
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: SafeArea(
          child: Material(
            color: brightness == Brightness.light
                ? kwhite25525525510
                : kblack000010, // const Color.fromARGB(231, 0, 0, 0),
            child: TabBar(
              dividerHeight: 0,
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.focused)) {
                  return Colors.blue.withOpacity(0.2); // Focused color
                }
                if (states.contains(WidgetState.pressed)) {
                  return kdarkblue.withValues(alpha: 0.1); // Pressed color
                }
                if (states.contains(WidgetState.hovered)) {
                  return Colors.yellow.withOpacity(0.1); // Hover color
                }
                return const Color.fromARGB(
                  231,
                  0,
                  0,
                  0,
                ); // No overlay color in other states
              }),
              onTap: (value) async {
                ref.read(pageIndexProvider.notifier).currentIndex(value);
                ref
                    .read(previousPageIndexProvider.notifier)
                    .currentIndex(value);
              },
              indicator: const BoxDecoration(),
              // indicatorSize: TabBarIndicatorSize.label,
              // indicatorColor: kyellow255255010,
              tabs: [
                // Tab 0: Home / Buzz
                Tab(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedHome01,
                    color: _getTabColor(currentTab, 0, brightness),
                    size: 24.0,
                  ),
                ),
                // Tab 1: Shorts
                Tab(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedPlayList,
                    color: _getTabColor(currentTab, 1, brightness),
                    size: 24.0,
                  ),
                ),
                // Tab 2: Add (No badge needed)
                Tab(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    color: _getTabColor(currentTab, 2, brightness),
                    size: 24.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kdarkblue,
          foregroundColor: kwhite25525525510,
          onPressed: () async {
            // currentScaffold.currentState!.showBodyScrim(true, 0.5);

            // showBottomSheet(
            //   context: context,
            //   builder: (BuildContext context) {
            //     return CreateTweetBottomsheet(
            //       model: user,
            //     );
            //   },
            // );
            // currentScaffold.currentState!.showBodyScrim(false, 0.5);
          },
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedChatBot,
            color: kwhite25525525510,
            size: 24.0,
          ),
        ),
      ),
    );
  }

  // Helper method just to clean up the build method.
  // Copy your existing color logic into here.
  Color _getTabColor(int currentTab, int tabIndex, Brightness brightness) {
    return currentTab == tabIndex
        ? kdarkblue
        : brightness == Brightness.dark
        ? Colors.white
        : kblack000010;
  }

  void _observeFcmMessages() {
    // FirebaseMessaging.onBackgroundMessage();

    FirebaseMessaging.onMessage.listen(_handleRemoteMessage);
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    if (message.notification != null) {
      debugPrint(
        'Message also contained a notification: ${message.notification}',
      );

      // Check for our custom data payload to identify the notification type
      if (message.data['type'] == 'newsubscriber') {}
    }
    return;
  }

  void firebaseMessageRequestPermission() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }
}
