import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/swear_provider.dart';
import '../models/swear_count.dart';
import '../models/swear_category.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Swearing History",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Consumer<SwearProvider>(
        builder: (context, swearProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text("📈 Weekly Trend", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 12),
              _buildLineChart(swearProvider.weeklyCounts),

              const SizedBox(height: 24),
              Text("📊 Swears per Day", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 12),
              _buildBarChart(swearProvider.dailyCounts),

              const SizedBox(height: 24),
              Text("🍰 Category Split", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 12),
              _buildPieChart(swearProvider.categories),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLineChart(List<WeeklySwearCount> weeklyCounts) {
    final List<FlSpot> spots = weeklyCounts.map((count) => 
      FlSpot(count.day.toDouble(), count.count.toDouble())
    ).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<DailySwearCount> dailyCounts) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: dailyCounts.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.count.toDouble(),
                  color: Colors.blue,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPieChart(List<SwearCategory> categories) {
    final colors = {
      'Insults': Colors.redAccent,
      'Profanity': Colors.orangeAccent,
      'Slurs': Colors.yellowAccent,
      'Mild Swears': Colors.greenAccent,
      'Other': Colors.purpleAccent,
    };

    final sections = categories.map((category) {
      return PieChartSectionData(
        value: category.count.toDouble(),
        color: colors[category.category] ?? Colors.grey,
        title: '${category.category}\n${category.count}',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: sections,
        ),
      ),
    );
  }
}
