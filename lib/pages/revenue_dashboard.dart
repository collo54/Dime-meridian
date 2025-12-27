import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/revenue_cat_event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/revenue_chart_widget.dart';
import '../providers/providers.dart';

class RevenueDashboard extends ConsumerWidget {
  const RevenueDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModel = ref.read(userModelProvider);
    final firestoreService = FirestoreService(uid: userModel.uid);

    // Watch the filter state
    final selectedEventType = ref.watch(eventTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Analytics Dashboard"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: TOTAL REVENUE (Existing) ---
            const Text(
              "Total Revenue",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 350, // Fixed height for chart container
              child: StreamBuilder<List<RevenueCatEventModel>>(
                stream: firestoreService.revenueEventsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState("No total revenue data found.");
                  }
                  return RevenueChartWidget(events: snapshot.data!);
                },
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // --- SECTION 2: EVENT TYPE BREAKDOWN (New) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Event Breakdown",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                // Dropdown to switch filter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedEventType,
                      icon: const Icon(Icons.filter_list, size: 20),
                      items: const [
                        DropdownMenuItem(
                          value: 'INITIAL_PURCHASE',
                          child: Text("New Sales"),
                        ),
                        DropdownMenuItem(
                          value: 'RENEWAL',
                          child: Text("Renewals"),
                        ),
                        DropdownMenuItem(
                          value: 'CANCELLATION',
                          child: Text("Cancellations"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(eventTypeFilterProvider.notifier).state =
                              value;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dynamic Stream Builder based on Dropdown
            SizedBox(
              height: 350,
              child: StreamBuilder<List<RevenueCatEventModel>>(
                key: ValueKey(selectedEventType), // Force rebuild on change
                stream: firestoreService.revenuecatRenenwalEventsStream(
                  selectedEventType,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 2. Handle Errors (Crucial for missing index)
                  if (snapshot.hasError) {
                    debugPrint(
                      "Firestore Error: ${snapshot.error}",
                    ); // Check this log!
                    return _buildEmptyState(
                      "Error loading data. Check console.",
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState("No data for $selectedEventType");
                  }

                  return RevenueChartWidget(events: snapshot.data!);
                },
              ),
            ),

            const SizedBox(height: 50), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
