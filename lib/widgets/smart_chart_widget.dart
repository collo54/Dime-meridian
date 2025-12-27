import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/revenue_cat_event_model.dart';

class SmartChartWidget extends StatelessWidget {
  final List<RevenueCatEventModel> events;
  final bool showCurrency; // Toggle between $ and Count

  const SmartChartWidget({
    super.key,
    required this.events,
    this.showCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Generate spots based on mode (Sum vs Count)
    final List<FlSpot> spots = _generateSmartSpots(events);

    if (spots.isEmpty) {
      return const Center(child: Text("No data available for this period"));
    }

    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = showCurrency ? 50 : 5; // Different defaults

    // 2. Determine Y Interval
    double yInterval = 10;
    if (maxY > 100) {
      yInterval = (maxY / 5).roundToDouble();
    } else if (!showCurrency && maxY < 10) {
      yInterval = 1; // For low counts (0, 1, 2), step by 1
    }

    // 3. Calculate X-Axis Interval
    const double dayMs = 86400000;
    double minX = spots.first.x;
    double maxX = spots.last.x;
    double totalDuration = maxX - minX;

    double xInterval;
    if (totalDuration <= dayMs * 5) {
      xInterval = dayMs;
    } else {
      xInterval = totalDuration / 4;
    }

    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 10);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
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
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: xInterval,
                getTitlesWidget: (value, meta) {
                  // Prevent label overlap on start edge
                  if (value != minX && (value - minX).abs() < xInterval / 2) {
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
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0)
                    return const SizedBox.shrink(); // Integer only

                  // Format value (e.g., $10 or 10)
                  String text = value.toInt().toString();
                  if (showCurrency && value > 0) text = "\$$text";

                  return Text(text, style: textStyle);
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              preventCurveOverShooting: true,
              gradient: LinearGradient(
                colors: showCurrency
                    ? [
                        const Color(0xFF2196F3),
                        const Color(0xFF00BCD4),
                      ] // Blue/Cyan for Revenue
                    : [
                        const Color(0xFFFF5252),
                        const Color(0xFFFFAB40),
                      ], // Red/Orange for Cancellations
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: showCurrency
                      ? [
                          const Color(0xFF2196F3).withOpacity(0.2),
                          const Color(0xFF00BCD4).withOpacity(0.0),
                        ]
                      : [
                          const Color(0xFFFF5252).withOpacity(0.2),
                          const Color(0xFFFFAB40).withOpacity(0.0),
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
                  final valStr = touchedSpot.y.toStringAsFixed(
                    showCurrency ? 2 : 0,
                  );
                  return LineTooltipItem(
                    '${DateFormat('MMM d').format(date)}\n',
                    textStyle?.copyWith(fontWeight: FontWeight.bold) ??
                        const TextStyle(),
                    children: [
                      TextSpan(
                        text: showCurrency ? '\$$valStr' : '$valStr events',
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
    );
  }

  List<FlSpot> _generateSmartSpots(List<RevenueCatEventModel> data) {
    if (data.isEmpty) return [];

    Map<String, double> dailyData = {};
    for (var event in data) {
      String dayKey = DateFormat('yyyy-MM-dd').format(event.eventTimestamp);
      if (showCurrency) {
        // Sum Revenue
        dailyData[dayKey] = (dailyData[dayKey] ?? 0) + event.amountUsd;
      } else {
        // Count Occurrences
        dailyData[dayKey] = (dailyData[dayKey] ?? 0) + 1;
      }
    }

    // Sort to find range
    DateTime sortedFirst = data
        .map((e) => e.eventTimestamp)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime sortedLast = data
        .map((e) => e.eventTimestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    if (sortedLast.isBefore(DateTime.now())) sortedLast = DateTime.now();

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
      double value = dailyData[dayKey] ?? 0.0;
      spots.add(FlSpot(currentDate.millisecondsSinceEpoch.toDouble(), value));
    }
    return spots;
  }
}
