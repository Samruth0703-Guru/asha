import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/database/sync_service.dart';
import '../../../../core/database/local_storage_helper.dart';

final patientsProvider = FutureProvider.autoDispose<List<Patient>>((ref) async {
  try {
    return await ref.watch(localDatabaseProvider).getAllPatients();
  } catch (e) {
    debugPrint('patientsProvider fetch error (\$e) — falling back to static list.');
    if (LocalDatabaseFallback.registeredPatients.isEmpty) {
      loadPatientsFromWeb();
    }
    return LocalDatabaseFallback.registeredPatients;
  }
});

class PatientListScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  const PatientListScreen({super.key, this.initialFilter});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'All';
  }

  final List<Map<String, dynamic>> _dummyPatients = [];

  List<Map<String, dynamic>> _filteredPatients(List<Patient> dbPatients) {
    final List<Map<String, dynamic>> allPatients = List.from(_dummyPatients);
    for (final p in dbPatients) {
      if (!allPatients.any((x) => x['id'] == p.id)) {
        allPatients.add({
          'id': p.id,
          'name': p.name,
          'village': p.village,
          'riskLevel': p.riskLevel,
          'status': p.isHighRisk ? 'Under Observation' : 'Routine Care',
          'age': DateTime.now().year - p.dob.year,
          'isPregnant': p.previousPregnancies > 0 || p.symptoms != null,
          'vaccineDue': p.isHighRisk,
        });
      }
    }

    return allPatients.where((p) {
      final matchesSearch = p['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            p['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            p['village'].toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'High Risk' && (p['riskLevel'] == 'High' || p['riskLevel'] == 'Critical')) return true;
      if (_selectedFilter == 'Pregnant' && p['isPregnant'] == true) return true;
      if (_selectedFilter == 'Vaccines Due' && p['vaccineDue'] == true) return true;
      return false;
    }).toList();
  }

  Color _getRiskColor(String level) {
    switch (level) {
      case 'Critical':
        return AppTheme.dangerColor;
      case 'High':
        return Colors.orange.shade700;
      case 'Medium':
        return AppTheme.warningColor;
      default:
        return AppTheme.secondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbPatientsAsync = ref.watch(patientsProvider);
    final List<Patient> dbPatients = dbPatientsAsync.value ?? [];
    final list = _filteredPatients(dbPatients);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('District Patients Directory', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => context.push('/register-patient'),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search patients by name, ID or village...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'High Risk', 'Pregnant', 'Vaccines Due'].map((filter) {
                      final selected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      'No matching patients found.',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final p = list[index];
                      final itemRiskColor = _getRiskColor(p['riskLevel']);

                      return FadeInUp(
                        duration: Duration(milliseconds: 300 + (index * 80)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => context.push('/patient-profile/${p['id']}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Leading Avatar with initial
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: itemRiskColor.withOpacity(0.1),
                                    child: Text(
                                      p['name'].substring(0, 1),
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: itemRiskColor, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Detail info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              p['name'],
                                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.5),
                                            ),
                                            const SizedBox(width: 8),
                                            if (p['isPregnant'])
                                              const Icon(Icons.pregnant_woman_rounded, color: Colors.pink, size: 16),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'ID: ${p['id']} • Age: ${p['age']} • ${p['village']}',
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Trailing action & Badge
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                        color: itemRiskColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          p['riskLevel'],
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: itemRiskColor),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
