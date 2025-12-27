// Consumer Widget Example
import 'package:dime_meridian/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/revenue_cat_event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/revenue_chart_widget.dart';

class RevenueDashboard extends ConsumerWidget {
  const RevenueDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Assuming you created a stream provider for the new service method
    // final revenueStream = ref.watch(revenueEventsStreamProvider);

    // For demo, let's assume we have the stream:
    final userModel = ref.read(userModelProvider);
    final firestoreService = FirestoreService(uid: userModel.uid);

    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),
      body: StreamBuilder<List<RevenueCatEventModel>>(
        stream: firestoreService.revenueEventsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Data"));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: RevenueChartWidget(events: snapshot.data!),
          );
        },
      ),
    );
  }
}
