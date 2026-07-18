import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/database/sync_service.dart';

final pregnancyStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final db = ref.read(localDatabaseProvider);
  final allPatients = await db.getAllPatients();
  
  int totalPregnant = 0;
  int highRisk = 0;
  List<Map<String, dynamic>> recentRecords = [];
  
  for (final p in allPatients) {
    if (p.isPregnant) {
      totalPregnant++;
      if (p.isHighRisk || p.riskLevel == 'High') {
        highRisk++;
      }
    }
  }
  
  final allAnc = await db.select(db.ancVisits).get();
  int upcomingAnc = 0;
  int missedVisits = 0;
  int completedAnc = 0;
  
  final now = DateTime.now();
  for (final anc in allAnc) {
    final patient = allPatients.where((p) => p.id == anc.patientId).firstOrNull;
    if (anc.status == 'Completed') {
      completedAnc++;
    } else {
      final target = anc.nextVisitDate ?? anc.visitDate;
      if (target.isBefore(now) && target.difference(now).inDays < 0) {
        missedVisits++;
        if (patient != null) {
          recentRecords.add({
            'name': patient.name,
            'sub': 'Missed ANC: ${target.toString().split(' ')[0]}',
            'badge': 'Missed',
            'badgeColor': Colors.red,
          });
        }
      } else {
        upcomingAnc++;
        if (patient != null) {
          recentRecords.add({
            'name': patient.name,
            'sub': 'Upcoming ANC: ${target.toString().split(' ')[0]}',
            'badge': 'Upcoming',
            'badgeColor': AppTheme.primaryColor,
          });
        }
      }
    }
  }
  
  return {
    'total': totalPregnant,
    'highRisk': highRisk,
    'upcoming': upcomingAnc,
    'missed': missedVisits,
    'completed': completedAnc,
    'records': recentRecords,
  };
});
class PregnancyDashboardScreen extends ConsumerStatefulWidget {
  const PregnancyDashboardScreen({super.key});

  @override
  ConsumerState<PregnancyDashboardScreen> createState() => _PregnancyDashboardScreenState();
}

class _PregnancyDashboardScreenState extends ConsumerState<PregnancyDashboardScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Village', 'ASHA Worker', 'EDD', 'High Risk', 'Status'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff0f172a) : const Color(0xfff8fafc);
    final cardColor = isDark ? const Color(0xff1e293b) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xff0f172a);
    final mutedColor = isDark ? Colors.white60 : Colors.black54;

    final statsAsync = ref.watch(pregnancyStatsProvider);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Pregnancy Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _selectedFilter == f,
                          onSelected: (val) {
                            if (val) setState(() => _selectedFilter = f);
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          labelStyle: TextStyle(color: _selectedFilter == f ? AppTheme.primaryColor : mutedColor),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  statsAsync.when(
                    data: (stats) {
                      final records = stats['records'] as List<Map<String, dynamic>>;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.2,
                            children: [
                              _buildStatCard('Total Pregnant', '${stats['total']}', Icons.pregnant_woman, Colors.pink, cardColor, textColor),
                              _buildStatCard('High Risk', '${stats['highRisk']}', Icons.warning_amber_rounded, Colors.red, cardColor, textColor),
                              _buildStatCard('Upcoming ANC', '${stats['upcoming']}', Icons.calendar_month, AppTheme.primaryColor, cardColor, textColor),
                              _buildStatCard('Missed Visits', '${stats['missed']}', Icons.history_rounded, Colors.orange, cardColor, textColor),
                              _buildStatCard('Completed ANC', '${stats['completed']}', Icons.check_circle_outline, AppTheme.secondaryColor, cardColor, textColor),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text('Recent Follow-ups', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                          const SizedBox(height: 12),
                          if (records.isEmpty) Text('No recent follow-ups', style: TextStyle(color: mutedColor)),
                          ...records.map((r) => _buildListTile(r['name'], r['sub'], r['badge'], r['badgeColor'], cardColor, textColor)),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error loading stats: $e', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(count, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: textColor.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildListTile(String name, String sub, String badge, Color badgeColor, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(name[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor)),
        subtitle: Text(sub, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
