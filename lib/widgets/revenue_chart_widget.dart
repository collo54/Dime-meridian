import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/revenue_cat_event_model.dart';

class RevenueChartWidget extends StatelessWidget {
  final List<RevenueCatEventModel> events;

  const RevenueChartWidget({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    // 1. Generate spots with "0" values filled in for missing days
    final List<FlSpot> spots = _generateFilledSpots(events);

    if (spots.isEmpty) {
      return const Center(child: Text("No revenue data available"));
    }

    // 2. Calculate Max Y to scale the graph height
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 50;

    // 3. Determine Y Interval (Increments of 10)
    double yInterval = 10;
    if (maxY > 100) {
      yInterval = (maxY / 5).roundToDouble();
    }

    // 4. Calculate X-Axis Interval (Time)
    const double dayMs = 86400000;
    double minX = spots.first.x;
    double maxX = spots.last.x;
    double totalDuration = maxX - minX;

    double xInterval;

    if (totalDuration <= dayMs * 5) {
      xInterval = dayMs; // Show every day if range is small
    } else {
      xInterval = totalDuration / 4; // Show ~4 labels if range is large
    }

    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 10);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Revenue Trends",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: 0,
                maxY: maxY + (yInterval / 2),

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.dividerColor.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),

                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  // --- BOTTOM TITLES (DATES) ---
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
                        // FIX: Prevent double rendering of the first date.
                        // If the current value is NOT the minX but is very close to it (within 5%), skip it.
                        // This handles cases where FLChart tries to draw a tick right next to the start.
                        if (value != minX &&
                            (value - minX).abs() < xInterval / 2) {
                          return const SizedBox.shrink();
                        }

                        final date = DateTime.fromMillisecondsSinceEpoch(
                          value.toInt(),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MMM d').format(date),
                            style: textStyle,
                          ),
                        );
                      },
                    ),
                  ),

                  // --- LEFT TITLES (AMOUNTS) ---
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        // Ensure we strictly show integers (0, 10, 20...)
                        if (value % 1 != 0) return const SizedBox.shrink();

                        return Text(value.toInt().toString(), style: textStyle);
                      },
                    ),
                  ),
                ),

                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withOpacity(0.2),
                    ),
                    left: BorderSide.none,
                    right: BorderSide.none,
                    top: BorderSide.none,
                  ),
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2196F3).withOpacity(0.2),
                          const Color(0xFF00BCD4).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],

                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          touchedSpot.x.toInt(),
                        );
                        return LineTooltipItem(
                          '${DateFormat('MMM d').format(date)}\n',
                          textStyle?.copyWith(fontWeight: FontWeight.bold) ??
                              const TextStyle(),
                          children: [
                            TextSpan(
                              text: '\$${touchedSpot.y.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper remains unchanged
  List<FlSpot> _generateFilledSpots(List<RevenueCatEventModel> data) {
    if (data.isEmpty) return [];

    Map<String, double> dailySums = {};
    for (var event in data) {
      String dayKey = DateFormat('yyyy-MM-dd').format(event.eventTimestamp);
      dailySums[dayKey] = (dailySums[dayKey] ?? 0) + event.amountUsd;
    }

    DateTime sortedFirst = data
        .map((e) => e.eventTimestamp)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime sortedLast = data
        .map((e) => e.eventTimestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    if (sortedLast.isBefore(DateTime.now())) {
      sortedLast = DateTime.now();
    }

    DateTime startDate = DateTime(
      sortedFirst.year,
      sortedFirst.month,
      sortedFirst.day,
    );
    DateTime endDate = DateTime(
      sortedLast.year,
      sortedLast.month,
      sortedLast.day,
    );

    List<FlSpot> spots = [];

    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      DateTime currentDate = startDate.add(Duration(days: i));
      String dayKey = DateFormat('yyyy-MM-dd').format(currentDate);

      double value = dailySums[dayKey] ?? 0.0;

      spots.add(FlSpot(currentDate.millisecondsSinceEpoch.toDouble(), value));
    }

    return spots;
  }
}
