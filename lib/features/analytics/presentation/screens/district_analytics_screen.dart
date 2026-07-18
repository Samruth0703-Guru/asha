import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';

class DistrictAnalyticsScreen extends StatefulWidget {
  const DistrictAnalyticsScreen({super.key});

  @override
  State<DistrictAnalyticsScreen> createState() => _DistrictAnalyticsScreenState();
}

class _DistrictAnalyticsScreenState extends State<DistrictAnalyticsScreen> {
  int _touchedPieIndex = -1;
  int _touchedBarIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 750;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Maternal Analytics', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Analytics summaries row
            Row(
              children: [
                _buildSummaryWidget('Maternal Safety Ratio', '96.4%', AppTheme.secondaryColor, Icons.verified_user_outlined),
                const SizedBox(width: 16),
                _buildSummaryWidget('Immunization Target', '91.2%', AppTheme.primaryColor, Icons.check_circle_outline_rounded),
              ],
            ),
            const SizedBox(height: 24),

            if (isTablet) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildPieChartCard(isDark)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildLineChartCard(isDark)),
                ],
              )
            ] else ...[
              _buildPieChartCard(isDark),
              const SizedBox(height: 20),
              _buildLineChartCard(isDark),
            ],
            const SizedBox(height: 20),

            // Bar chart representing vaccination targets by village
            _buildBarChartCard(isDark),
            const SizedBox(height: 28),

            // Administrative report exporters
            Text(
              'Administrative Reports Dispatcher',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Generating District Health PDF Report... complete.'),
                          backgroundColor: AppTheme.secondaryColor,
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Export PDF'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Generating Health Excel Register... complete.'),
                          backgroundColor: AppTheme.secondaryColor,
                        ),
                      );
                    },
                    icon: const Icon(Icons.table_chart_rounded),
                    label: const Text('Export Excel'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maternal Risk Level Demographics',
            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedPieIndex = -1;
                              return;
                            }
                            _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: [
                        _buildPieSection(0, AppTheme.secondaryColor, 50, 'Low'),
                        _buildPieSection(1, AppTheme.warningColor, 25, 'Med'),
                        _buildPieSection(2, Colors.orange.shade700, 15, 'High'),
                        _buildPieSection(3, AppTheme.dangerColor, 10, 'Crit'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegend('🟢 Healthy Low', AppTheme.secondaryColor),
                    const SizedBox(height: 6),
                    _buildLegend('🟡 Moderate Risk', AppTheme.warningColor),
                    const SizedBox(height: 6),
                    _buildLegend('🟠 High Risk', Colors.orange.shade700),
                    const SizedBox(height: 6),
                    _buildLegend('🔴 Critical Emergency', AppTheme.dangerColor),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection(int index, Color color, double value, String label) {
    final isTouched = index == _touchedPieIndex;
    final radius = isTouched ? 48.0 : 38.0;
    return PieChartSectionData(
      color: color,
      value: value,
      title: '${value.toInt()}%',
      radius: radius,
      titleStyle: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChartCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maternal Registrations Growth (2026)',
            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 10),
                      FlSpot(1, 15),
                      FlSpot(2, 12),
                      FlSpot(3, 20),
                      FlSpot(4, 25),
                      FlSpot(5, 36),
                    ],
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Jan', style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('Feb', style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('Mar', style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('Apr', style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('May', style: TextStyle(fontSize: 9, color: Colors.grey)),
              Text('Jun', style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Village Vaccine Immunization Rates (%)',
            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        _touchedBarIndex = -1;
                        return;
                      }
                      _touchedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        switch (val.toInt()) {
                          case 0:
                            return const Text('Alanganallur', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold));
                          case 1:
                            return const Text('Kulamangalam', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold));
                          case 2:
                            return const Text('Paravai', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold));
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  _buildBarGroup(0, 94.0, AppTheme.secondaryColor),
                  _buildBarGroup(1, 88.0, AppTheme.primaryColor),
                  _buildBarGroup(2, 75.0, AppTheme.warningColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: color.withOpacity(0.08),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryWidget(String title, String val, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0), width: 1.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(val, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
