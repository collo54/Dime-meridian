import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/revenue_cat_event_model.dart';

class RevenueChartWidget extends StatelessWidget {
  final List<RevenueCatEventModel> events;

  const RevenueChartWidget({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    // 1. Generate spots filtered for the last 4 days (Today + 3 previous)
    final List<FlSpot> spots = _generateFilledSpots(events);

    if (spots.isEmpty) {
      return const Center(child: Text("No revenue data available"));
    }

    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 50;

    double yInterval = 10;
    if (maxY > 100) {
      yInterval = (maxY / 5).roundToDouble();
    }

    const double dayMs = 86400000;
    double minX = spots.first.x;
    double maxX = spots.last.x;

    // Force interval to be exactly 1 day since range is fixed to 4 days
    double xInterval = dayMs;

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
                // Add padding to prevent label cutoff
                minX: minX - (dayMs * 0.2),
                maxX: maxX + (dayMs * 0.2),
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

                  // --- BOTTOM TITLES ---
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
                        // Avoid showing labels between whole days
                        if (value % dayMs > 1000 &&
                            value % dayMs < dayMs - 1000) {
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

                  // --- LEFT TITLES ---
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
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
                    isCurved: false, // Flat lines for accuracy
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
                    ),
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

  // --- LOGIC CHANGE: Force Last 4 Days ---
  List<FlSpot> _generateFilledSpots(List<RevenueCatEventModel> data) {
    if (data.isEmpty) return [];

    Map<String, double> dailySums = {};
    for (var event in data) {
      String dayKey = DateFormat('yyyy-MM-dd').format(event.eventTimestamp);
      dailySums[dayKey] = (dailySums[dayKey] ?? 0) + event.amountUsd;
    }

    DateTime now = DateTime.now();
    DateTime endDate = DateTime(now.year, now.month, now.day); // Today midnight
    DateTime startDate = endDate.subtract(
      const Duration(days: 3),
    ); // Today + 3 previous = 4 days

    List<FlSpot> spots = [];

    for (int i = 0; i <= 3; i++) {
      DateTime currentDate = startDate.add(Duration(days: i));
      String dayKey = DateFormat('yyyy-MM-dd').format(currentDate);

      double value = dailySums[dayKey] ?? 0.0;

      spots.add(FlSpot(currentDate.millisecondsSinceEpoch.toDouble(), value));
    }

    return spots;
  }
}
