import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/revenue_cat_event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/revenue_chart_widget.dart';
import '../widgets/smart_chart_widget.dart'; // Import the new chart
import '../providers/providers.dart';

class RevenueDashboard extends ConsumerWidget {
  const RevenueDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModel = ref.read(userModelProvider);
    final firestoreService = FirestoreService(uid: userModel.uid);

    final selectedEventType = ref.watch(eventTypeFilterProvider);
    final selectedEventTypeChartOne = ref.watch(
      eventTypeFilterProviderChartOne,
    );
    final selectedTimeRange = ref.watch(timeRangeFilterProvider);

    // Logic: If it's a cancellation or expiration, we show counts, not dollars.
    final bool isRevenueMetric =
        selectedEventType == 'INITIAL_PURCHASE' ||
        selectedEventType == 'RENEWAL';

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
                      value: selectedEventTypeChartOne,
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
                        // DropdownMenuItem(
                        //   value: 'CANCELLATION',
                        //   child: Text("Cancellations"),
                        // ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref
                                  .read(
                                    eventTypeFilterProviderChartOne.notifier,
                                  )
                                  .state =
                              value;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Dynamic Stream Builder based on Dropdown
            SizedBox(
              height: 350,
              child: StreamBuilder<List<RevenueCatEventModel>>(
                key: ValueKey(
                  selectedEventTypeChartOne,
                ), // Force rebuild on change
                stream: firestoreService.revenuecatRenenwalEventsStream(
                  selectedEventTypeChartOne,
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
                    return _buildEmptyState(
                      "No data for $selectedEventTypeChartOne",
                    );
                  }

                  return RevenueChartWidget(events: snapshot.data!);
                },
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            // --- HEADER & DROPDOWN ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Event Breakdown",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                _buildDropdown(context, ref, selectedEventType),
              ],
            ),
            const SizedBox(height: 16),

            // --- TIME RANGE CHIPS ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip(
                    ref,
                    TimeRange.days7,
                    "Last 7 Days",
                    selectedTimeRange,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    ref,
                    TimeRange.days30,
                    "Last 30 Days",
                    selectedTimeRange,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    ref,
                    TimeRange.allTime,
                    "All Time",
                    selectedTimeRange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- MAIN CONTENT STREAM ---
            StreamBuilder<List<RevenueCatEventModel>>(
              // Rebuild when filter changes
              key: ValueKey("$selectedEventType-$selectedTimeRange"),
              stream: firestoreService.revenuecatFilteredEventsStream(
                eventType: selectedEventType,
                timeRange: selectedTimeRange,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _buildEmptyState("Error: Check Firestore Indexes");
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState("No data for this period");
                }

                final data = snapshot.data!;

                // --- CALCULATE SUMMARY ---
                double totalValue = 0;
                for (var e in data) {
                  totalValue += isRevenueMetric ? e.amountUsd : 1;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SUMMARY CARD ---
                    _buildSummaryCard(context, totalValue, isRevenueMetric),
                    const SizedBox(height: 24),

                    // --- CHART ---
                    SizedBox(
                      height: 350,
                      child: SmartChartWidget(
                        events: data,
                        showCurrency: isRevenueMetric,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER: SUMMARY CARD ---
  Widget _buildSummaryCard(
    BuildContext context,
    double value,
    bool isCurrency,
  ) {
    final theme = Theme.of(context);
    String displayValue;
    String label;

    if (isCurrency) {
      displayValue = "\$${value.toStringAsFixed(2)}";
      label = "Total Revenue";
    } else {
      displayValue = value.toInt().toString();
      label = "Total Events";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            displayValue,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: isCurrency
                  ? const Color(0xFF2196F3)
                  : const Color(0xFFFF5252),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: DROPDOWN ---
  Widget _buildDropdown(
    BuildContext context,
    WidgetRef ref,
    String currentVal,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: const [
            DropdownMenuItem(
              value: 'INITIAL_PURCHASE',
              child: Text("New Sales"),
            ),
            DropdownMenuItem(value: 'RENEWAL', child: Text("Renewals")),
            DropdownMenuItem(
              value: 'CANCELLATION',
              child: Text("Cancellations"),
            ),
            DropdownMenuItem(value: 'EXPIRATION', child: Text("Expirations")),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(eventTypeFilterProvider.notifier).state = value;
            }
          },
        ),
      ),
    );
  }

  // --- WIDGET HELPER: TIME CHIP ---
  Widget _buildChip(
    WidgetRef ref,
    TimeRange range,
    String label,
    TimeRange selected,
  ) {
    final isSelected = range == selected;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          ref.read(timeRangeFilterProvider.notifier).state = range;
        }
      },
      selectedColor: const Color(0xFF2196F3),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../models/revenue_cat_event_model.dart';
// import '../services/firestore_service.dart';
// import '../widgets/revenue_chart_widget.dart';
// import '../providers/providers.dart';

// class RevenueDashboard extends ConsumerWidget {
//   const RevenueDashboard({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final userModel = ref.read(userModelProvider);
//     final firestoreService = FirestoreService(uid: userModel.uid);

//     // Watch the filter state
//     final selectedEventType = ref.watch(eventTypeFilterProvider);

//     return Scaffold(
//       appBar: AppBar(title: const Text("Analytics Dashboard"), elevation: 0),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // --- SECTION 1: TOTAL REVENUE (Existing) ---
//             const Text(
//               "Total Revenue",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               height: 350, // Fixed height for chart container
//               child: StreamBuilder<List<RevenueCatEventModel>>(
//                 stream: firestoreService.revenueEventsStream(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                     return _buildEmptyState("No total revenue data found.");
//                   }
//                   return RevenueChartWidget(events: snapshot.data!);
//                 },
//               ),
//             ),

//             const SizedBox(height: 32),
//             const Divider(),
//             const SizedBox(height: 16),

//             // --- SECTION 2: EVENT TYPE BREAKDOWN (New) ---
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   "Event Breakdown",
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 // Dropdown to switch filter
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).cardColor,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey.withOpacity(0.3)),
//                   ),
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<String>(
//                       value: selectedEventType,
//                       icon: const Icon(Icons.filter_list, size: 20),
//                       items: const [
//                         DropdownMenuItem(
//                           value: 'INITIAL_PURCHASE',
//                           child: Text("New Sales"),
//                         ),
//                         DropdownMenuItem(
//                           value: 'RENEWAL',
//                           child: Text("Renewals"),
//                         ),
//                         DropdownMenuItem(
//                           value: 'CANCELLATION',
//                           child: Text("Cancellations"),
//                         ),
//                       ],
//                       onChanged: (value) {
//                         if (value != null) {
//                           ref.read(eventTypeFilterProvider.notifier).state =
//                               value;
//                         }
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             // Dynamic Stream Builder based on Dropdown
//             SizedBox(
//               height: 350,
//               child: StreamBuilder<List<RevenueCatEventModel>>(
//                 key: ValueKey(selectedEventType), // Force rebuild on change
//                 stream: firestoreService.revenuecatRenenwalEventsStream(
//                   selectedEventType,
//                 ),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   // 2. Handle Errors (Crucial for missing index)
//                   if (snapshot.hasError) {
//                     debugPrint(
//                       "Firestore Error: ${snapshot.error}",
//                     ); // Check this log!
//                     return _buildEmptyState(
//                       "Error loading data. Check console.",
//                     );
//                   }

//                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                     return _buildEmptyState("No data for $selectedEventType");
//                   }

//                   return RevenueChartWidget(events: snapshot.data!);
//                 },
//               ),
//             ),

//             const SizedBox(height: 50), // Bottom padding
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState(String message) {
//     return Container(
//       height: 300,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.grey.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.withOpacity(0.2)),
//       ),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.bar_chart, size: 48, color: Colors.grey),
//             const SizedBox(height: 8),
//             Text(message, style: const TextStyle(color: Colors.grey)),
//           ],
//         ),
//       ),
//     );
//   }
// }
