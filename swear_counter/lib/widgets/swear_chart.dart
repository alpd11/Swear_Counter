import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SwearChart extends StatelessWidget {
  final int swearCount;

  const SwearChart({super.key, required this.swearCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(toY: swearCount.toDouble(), width: 20, color: Colors.red),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (context, _) => const Text('Today'),
              ),
            ),
            rightTitles: AxisTitles(),
            topTitles: AxisTitles(),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class SwearData {
  final String day;
  final int count;

  SwearData(this.day, this.count);
}
