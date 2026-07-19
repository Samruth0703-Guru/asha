import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../data/visits_analytics_provider.dart';

import 'kpi_grid.dart';
import 'interactive_visits_chart.dart';
import 'time_filter_row.dart';
import 'ai_insights_panel.dart';
import 'export_menu.dart';

class AdvancedAnalyticsCard extends ConsumerWidget {
  const AdvancedAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visitsAnalyticsProvider);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA476FF).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xffF4F1FF).withOpacity(0.3),
            const Color(0xffEEE1FF).withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xffA476FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.show_chart_rounded, color: Color(0xffA476FF)),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Monthly Visits Analytics',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Real-time metrics & AI-driven insights',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const Row(
                children: [
                  TimeFilterRow(),
                  SizedBox(width: 16),
                  ExportMenu(),
                ],
              )
            ],
          ),
          
          const SizedBox(height: 32),
          
          // KPI Grid
          const KpiGrid(),
          
          const SizedBox(height: 32),
          
          // Chart & Insights Area
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                flex: 3,
                child: InteractiveVisitsChart(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: AiInsightsPanel(insights: state.insights),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
