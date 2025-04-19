import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/swear_provider.dart';
import '../models/swear_count.dart';
import '../models/swear_category.dart';
import 'package:intl/intl.dart';

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
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxHeight * 0.25; // Responsive chart height
                
                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Text("📈 Weekly Trend", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 8),
                    _buildLineChart(swearProvider.weeklyCounts, chartHeight),

                    const SizedBox(height: 24),
                    Text("📊 Swears per Day", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 8),
                    _buildBarChart(swearProvider.dailyCounts, chartHeight),

                    const SizedBox(height: 24),
                    Text("🍰 Category Split", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 8),
                    _buildPieChart(swearProvider.categories, chartHeight + 30), // Slightly taller for pie chart
                    
                    // Legend for pie chart
                    _buildCategoryLegend(swearProvider.categories),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLineChart(List<WeeklySwearCount> weeklyCounts, double height) {
    final List<FlSpot> spots = weeklyCounts.map((count) => 
      FlSpot(count.day.toDouble(), count.count.toDouble())
    ).toList();

    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 5,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white24,
                  strokeWidth: 0.5,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.white24,
                  strokeWidth: 0.5,
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
              bottomTitles: AxisTitles(
                axisNameWidget: Text(
                  'Day of Week',
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < 0 || value.toInt() >= weekDays.length) {
                      return const SizedBox.shrink();
                    }
                    return SizedBox(
                      width: 30,
                      child: Text(
                        weekDays[value.toInt()],
                        style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.white24),
            ),
            minX: 0,
            maxX: 6,
            minY: 0,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B5876), Color(0xFF4E4376)],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => 
                    FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFFFA709A),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFA709A).withOpacity(0.3),
                      const Color(0xFF4E4376).withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<DailySwearCount> dailyCounts, double height) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.center,
            maxY: _calculateMaxY(dailyCounts),
            gridData: FlGridData(
              show: true,
              horizontalInterval: 5,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white24,
                  strokeWidth: 0.5,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                axisNameWidget: Text(
                  'Date',
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    if (value.toInt() >= 0 && value.toInt() < dailyCounts.length) {
                      final date = dailyCounts[value.toInt()].date;
                      return SizedBox(
                        width: 30,
                        child: Text(
                          '${date.day}/${date.month}',
                          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.white24),
            ),
            barGroups: _generateBarGroups(dailyCounts),
          ),
        ),
      ),
    );
  }

  double _calculateMaxY(List<DailySwearCount> dailyCounts) {
    if (dailyCounts.isEmpty) return 10;
    double maxCount = dailyCounts
        .map((count) => count.count.toDouble())
        .reduce((max, count) => count > max ? count : max);
    return maxCount < 10 ? 10 : (maxCount * 1.2).ceilToDouble(); // Add 20% padding
  }

  List<BarChartGroupData> _generateBarGroups(List<DailySwearCount> dailyCounts) {
    return dailyCounts.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.count.toDouble(),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2B5876),
                const Color(0xFFFA709A),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 14,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _calculateMaxY(dailyCounts),
              color: Colors.white10,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildPieChart(List<SwearCategory> categories, double height) {
    final colors = {
      'Insults': Colors.redAccent,
      'Profanity': Colors.orangeAccent,
      'Slurs': Colors.yellowAccent,
      'Mild Swears': Colors.greenAccent,
      'Other': Colors.purpleAccent,
    };
    
    // If no categories, show empty state
    if (categories.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            "No swear categories recorded yet",
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
          ),
        ),
      );
    }

    // Total swear count across all categories
    final totalCount = categories.fold(0, (sum, category) => sum + category.count);

    // Create pie chart sections
    final sections = categories.map((category) {
      final percentage = totalCount > 0 ? (category.count / totalCount) * 100 : 0;
      
      return PieChartSectionData(
        value: category.count.toDouble(),
        color: colors[category.category] ?? Colors.grey,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80, // Reduced from 100 to 80 (20% decrease)
        titleStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1)),
          ],
        ),
        badgeWidget: percentage < 5 ? null : Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            category.count.toString(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        badgePositionPercentageOffset: 0.8,
      );
    }).toList();

    return SizedBox(
      height: height,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 24, // Reduced from 30 to 24 (20% decrease)
          sections: sections,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              // Could implement interaction here in the future
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryLegend(List<SwearCategory> categories) {
    final colors = {
      'Insults': Colors.redAccent,
      'Profanity': Colors.orangeAccent,
      'Slurs': Colors.yellowAccent,
      'Mild Swears': Colors.greenAccent,
      'Other': Colors.purpleAccent,
    };

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: categories.map((category) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[category.category] ?? Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              category.category,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}
