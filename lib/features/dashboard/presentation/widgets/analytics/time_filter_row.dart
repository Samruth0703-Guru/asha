import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/visits_analytics_provider.dart';

class TimeFilterRow extends ConsumerWidget {
  const TimeFilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visitsAnalyticsProvider);
    final notifier = ref.read(visitsAnalyticsProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TimeFilter.values.map((filter) {
          final isSelected = state.currentFilter == filter;
          String label = '';
          switch (filter) {
            case TimeFilter.today: label = 'Today'; break;
            case TimeFilter.days7: label = '7D'; break;
            case TimeFilter.days30: label = '30D'; break;
            case TimeFilter.months3: label = '3M'; break;
            case TimeFilter.months6: label = '6M'; break;
            case TimeFilter.year1: label = '1Y'; break;
          }

          return GestureDetector(
            onTap: () => notifier.setFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xffA476FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xffA476FF).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
