// lib/widgets/scan_activity_bar_chart.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';

/// The bar chart itself from Home's "Scan Activity" card and Profile's
/// "My Scan Activity" card — identical BarChartData wiring in both, only
/// ever differing in chart height and how the bottom-axis label for a
/// given bar is built (Home switches between day/week/month labels;
/// Profile always shows a month abbreviation).
class ScanActivityBarChart extends StatelessWidget {
  final List<int> counts;
  final Widget Function(int index) buildLabel;
  final double height;

  const ScanActivityBarChart({
    super.key,
    required this.counts,
    required this.buildLabel,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (counts.isEmpty ? 5 : (counts.reduce(math.max) * 1.3))
              .clamp(5, double.infinity)
              .toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => FlLine(color: kBorder, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= counts.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: buildLabel(i),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(counts.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i].toDouble(),
                  color: kGreen,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
