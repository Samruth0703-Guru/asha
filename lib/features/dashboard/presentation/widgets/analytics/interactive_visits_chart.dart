import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/visits_analytics_provider.dart';
import '../../../../core/theme/app_theme.dart';

enum ChartType { line, area, bar }

class InteractiveVisitsChart extends ConsumerStatefulWidget {
  const InteractiveVisitsChart({super.key});

  @override
  ConsumerState<InteractiveVisitsChart> createState() => _InteractiveVisitsChartState();
}

class _InteractiveVisitsChartState extends ConsumerState<InteractiveVisitsChart> {
  ChartType _chartType = ChartType.area;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visitsAnalyticsProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.filteredVisits.isEmpty) {
      return Center(
        child: Text(
          'No data available for this period.',
          style: GoogleFonts.inter(color: Colors.grey.shade500),
        ),
      );
    }

    // Process data into spots
    final Map<int, int> counts = {};
    for (var v in state.filteredVisits) {
      // Group by day of the year for simplicity in this visual
      final day = v.timestamp.day; 
      counts[day] = (counts[day] ?? 0) + 1;
    }

    final spots = counts.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
    spots.sort((a, b) => a.x.compareTo(b.x));
    
    // Add a prediction spot (dashed line representation)
    final predictionSpots = [...spots];
    if (spots.isNotEmpty) {
      final last = spots.last;
      predictionSpots.add(FlSpot(last.x + 2, last.y + (state.growthPercentage > 0 ? 5 : -2)));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildChartToggle(ChartType.area, Icons.area_chart),
            const SizedBox(width: 8),
            _buildChartToggle(ChartType.line, Icons.show_chart),
            const SizedBox(width: 8),
            _buildChartToggle(ChartType.bar, Icons.bar_chart),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _chartType == ChartType.bar 
            ? _buildBarChart(spots) 
            : _buildLineChart(spots, predictionSpots),
        ),
      ],
    );
  }

  Widget _buildChartToggle(ChartType type, IconData icon) {
    final isSelected = _chartType == type;
    return GestureDetector(
      onTap: () => setState(() => _chartType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffA476FF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> spots, List<FlSpot> predictionSpots) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: spots.length > 10 ? (spots.length / 5).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text('\${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem('\${spot.y.toInt()} visits', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xffA476FF),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: _chartType == ChartType.area,
              gradient: LinearGradient(
                colors: [
                  const Color(0xffA476FF).withOpacity(0.3),
                  const Color(0xffA476FF).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Prediction Line
          LineChartBarData(
            spots: predictionSpots.length > 1 ? [predictionSpots[predictionSpots.length - 2], predictionSpots.last] : [],
            isCurved: false,
            color: const Color(0xffB892FF),
            barWidth: 3,
            isStrokeCapRound: true,
            dashArray: [5, 5],
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildBarChart(List<FlSpot> spots) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text('\${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: spots.map((spot) {
          return BarChartGroupData(
            x: spot.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: spot.y,
                color: const Color(0xffA476FF),
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }
}
