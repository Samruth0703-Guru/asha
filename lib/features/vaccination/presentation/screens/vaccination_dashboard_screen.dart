import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/database/sync_service.dart';

final vaccinationStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final db = ref.read(localDatabaseProvider);
  final allVacs = await db.select(db.vaccinations).get();
  final allPatients = await db.getAllPatients();
  
  int dueToday = 0;
  int upcoming = 0;
  int missed = 0;
  int completed = 0;
  
  List<Map<String, dynamic>> recentRecords = [];
  final now = DateTime.now();
  
  for (final vac in allVacs) {
    final patient = allPatients.where((p) => p.id == vac.patientId).firstOrNull;
    if (vac.status == 'Completed') {
      completed++;
    } else {
      final diff = vac.dueDate.difference(now).inDays;
      if (diff == 0) {
        dueToday++;
        if (patient != null) {
          recentRecords.add({
            'name': patient.name,
            'sub': vac.vaccineName,
            'badge': 'Due Today',
            'badgeColor': Colors.blue,
          });
        }
      } else if (diff < 0) {
        missed++;
        if (patient != null) {
          recentRecords.add({
            'name': patient.name,
            'sub': vac.vaccineName,
            'badge': 'Missed',
            'badgeColor': Colors.red,
          });
        }
      } else {
        upcoming++;
        if (patient != null) {
          recentRecords.add({
            'name': patient.name,
            'sub': vac.vaccineName,
            'badge': 'Upcoming',
            'badgeColor': Colors.indigo,
          });
        }
      }
    }
  }
  
  return {
    'dueToday': dueToday,
    'upcoming': upcoming,
    'missed': missed,
    'completed': completed,
    'records': recentRecords,
  };
});

class VaccinationDashboardScreen extends ConsumerStatefulWidget {
  const VaccinationDashboardScreen({super.key});

  @override
  ConsumerState<VaccinationDashboardScreen> createState() => _VaccinationDashboardScreenState();
}

class _VaccinationDashboardScreenState extends ConsumerState<VaccinationDashboardScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Village', 'Due Today', 'Upcoming', 'Missed', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff0f172a) : const Color(0xfff8fafc);
    final cardColor = isDark ? const Color(0xff1e293b) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xff0f172a);
    final mutedColor = isDark ? Colors.white60 : Colors.black54;

    final statsAsync = ref.watch(vaccinationStatsProvider);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Vaccination Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
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
                          selectedColor: Colors.blue.withOpacity(0.2),
                          labelStyle: TextStyle(color: _selectedFilter == f ? Colors.blue : mutedColor),
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
                              _buildStatCard('Due Today', '${stats['dueToday']}', Icons.today_rounded, Colors.blue, cardColor, textColor),
                              _buildStatCard('Upcoming', '${stats['upcoming']}', Icons.event, Colors.indigo, cardColor, textColor),
                              _buildStatCard('Missed', '${stats['missed']}', Icons.warning_amber_rounded, Colors.red, cardColor, textColor),
                              _buildStatCard('Completed', '${stats['completed']}', Icons.verified, AppTheme.secondaryColor, cardColor, textColor),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text('Due Vaccines', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                          const SizedBox(height: 12),
                          if (records.isEmpty) Text('No pending vaccines', style: TextStyle(color: mutedColor)),
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
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Text(name[0], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
