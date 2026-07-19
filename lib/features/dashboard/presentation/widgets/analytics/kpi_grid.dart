import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/visits_analytics_provider.dart';

class KpiGrid extends ConsumerWidget {
  const KpiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visitsAnalyticsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust column count based on width
        int crossAxisCount = 4;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 3;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2, // Adjust aspect ratio for card shape
          children: [
            _buildKpiCard('Total Visits', '\${state.totalVisits}', Icons.people_outline_rounded, Colors.blue),
            _buildKpiCard('Today\\'s Visits', '\${state.todayVisits}', Icons.today_rounded, Colors.orange),
            _buildKpiCard('Average Daily', '\${state.averageDaily}', Icons.show_chart_rounded, Colors.purple),
            _buildKpiCard('Growth', '+\${state.growthPercentage}%', Icons.trending_up_rounded, Colors.green),
            _buildKpiCard('Highest Day', state.highestDay, Icons.arrow_upward_rounded, Colors.teal),
            _buildKpiCard('Lowest Day', state.lowestDay, Icons.arrow_downward_rounded, Colors.red),
            _buildKpiCard('Pending Visits', '12', Icons.pending_actions_rounded, Colors.deepOrange), // Mock for UI
            _buildKpiCard('Completed', '\${state.totalVisits - 12 > 0 ? state.totalVisits - 12 : 0}', Icons.check_circle_outline_rounded, Colors.green.shade700), // Mock for UI
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
