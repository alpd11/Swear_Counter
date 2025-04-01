import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

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
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text("📈 Weekly Trend", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
          const SizedBox(height: 12),
          _buildLineChart(),

          const SizedBox(height: 24),
          Text("📊 Swears per Day", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
          const SizedBox(height: 12),
          _buildBarChart(),

          const SizedBox(height: 24),
          Text("🍰 Category Split", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
          const SizedBox(height: 12),
          _buildPieChart(),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 1),
                FlSpot(1, 4),
                FlSpot(2, 3),
                FlSpot(3, 8),
                FlSpot(4, 6),
                FlSpot(5, 5),
                FlSpot(6, 2),
              ],
              isCurved: true,
              barWidth: 3,
              color: Colors.deepPurpleAccent,
              belowBarData: BarAreaData(show: true, color: Colors.deepPurpleAccent.withOpacity(0.3)),
            )
          ],
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: (i + 2).toDouble(), width: 16, color: Colors.pinkAccent),
            ]);
          }),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(value: 40, color: Colors.redAccent, title: 'Insults'),
            PieChartSectionData(value: 30, color: Colors.orangeAccent, title: 'Slang'),
            PieChartSectionData(value: 20, color: Colors.yellowAccent, title: 'Mild'),
            PieChartSectionData(value: 10, color: Colors.greenAccent, title: 'Other'),
          ],
        ),
      ),
    );
  }
}
