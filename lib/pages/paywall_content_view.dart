import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

// CustomerInfo customerInfo = await Purchases.getCustomerInfo();
// final hasPro = customerInfo.entitlements.active.containsKey('Dime meridian Pro');

class ContentView extends ConsumerWidget {
  const ContentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: PaywallView(
        onDismiss: () {
          // Dismiss the paywall, e.g. remove the view, navigate to another screen.
        },
      ),
    );
  }
}
