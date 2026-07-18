import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/database/sync_service.dart';
import 'voice_assistant_overlay.dart';

class AiHealthAssistantDashboard extends ConsumerStatefulWidget {
  final String? patientId;
  const AiHealthAssistantDashboard({super.key, this.patientId});

  @override
  ConsumerState<AiHealthAssistantDashboard> createState() => _AiHealthAssistantDashboardState();
}

class _AiHealthAssistantDashboardState extends ConsumerState<AiHealthAssistantDashboard> {
  Patient? _patient;
  List<Patient> _patients = [];
  bool _isLoadingPatients = true;

  // Metrics from Firestore
  int _totalScans = 0;
  int _skinDiseases = 0;
  int _pregnancyRisks = 0;
  int _childIllnesses = 0;
  int _emergencyCases = 0;
  String _mostCommonDisease = "Loading...";
  List<Map<String, dynamic>> _recentReports = [];
  bool _isLoadingMetrics = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _fetchFirestoreMetrics();
  }

  void _loadPatients() async {
    final db = ref.read(localDatabaseProvider);
    final list = await db.getAllPatients();
    setState(() {
      _patients = list;
      _isLoadingPatients = false;
      if (widget.patientId != null) {
        final found = list.where((p) => p.id == widget.patientId).toList();
        if (found.isNotEmpty) {
          _patient = found.first;
        }
      }
    });
  }

  Future<void> _fetchFirestoreMetrics() async {
    try {
      final scansSnap = await FirebaseFirestore.instance.collection('health_scans').get();
      final risksSnap = await FirebaseFirestore.instance.collection('patient_risk_evaluations').get();

      int total = scansSnap.docs.length;
      int skinCount = 0;
      int childCount = 0;
      int emergency = 0;
      final Map<String, int> diseaseFrequency = {};

      for (var doc in scansSnap.docs) {
        final data = doc.data();
        final analysis = data['analysis'] as Map<String, dynamic>?;
        if (analysis != null) {
          final category = analysis['diseaseCategory']?.toString().toLowerCase() ?? '';
          if (category.contains('skin') || category.contains('fungal') || category.contains('allergy')) {
            skinCount++;
          }
          final severity = analysis['severity']?.toString().toLowerCase() ?? '';
          if (severity == 'high' || severity == 'critical') {
            emergency++;
          }
          final diseaseName = analysis['possibleDisease']?.toString() ?? '';
          if (diseaseName.isNotEmpty) {
            diseaseFrequency[diseaseName] = (diseaseFrequency[diseaseName] ?? 0) + 1;
          }
        }
      }

      // Check child illness indicators based on patient age (e.g. from evaluations or profiles)
      // For this dashboard, count cases of child conditions detected or risk assessments
      int maternalRisks = 0;
      for (var doc in risksSnap.docs) {
        final data = doc.data();
        final level = data['riskLevel']?.toString().toLowerCase() ?? '';
        if (level == 'high' || level == 'critical') {
          maternalRisks++;
        }
      }

      // Common disease selection
      String common = "None";
      int maxFreq = 0;
      diseaseFrequency.forEach((k, v) {
        if (v > maxFreq) {
          maxFreq = v;
          common = k;
        }
      });

      // Get recent reports
      final recentDocs = await FirebaseFirestore.instance
          .collection('health_scans')
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      final recentList = recentDocs.docs.map((doc) {
        final d = doc.data();
        d['id'] = doc.id;
        return d;
      }).toList();

      setState(() {
        _totalScans = total;
        _skinDiseases = skinCount;
        _pregnancyRisks = maternalRisks;
        _childIllnesses = childCount;
        _emergencyCases = emergency;
        _mostCommonDisease = common;
        _recentReports = recentList;
        _isLoadingMetrics = false;
      });
    } catch (e) {
      debugPrint('Error loading Firestore metrics: $e');
      setState(() {
        _isLoadingMetrics = false;
      });
    }
  }

  void _openVoiceAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceAssistantOverlay(
        patientContext: _patient != null ? {
          'id': _patient!.id,
          'name': _patient!.name,
          'age': DateTime.now().year - _patient!.dob.year,
          'gender': _patient!.gender,
          'pregnancyStatus': _patient!.isHighRisk ? 'High Risk' : 'Normal', // fallback profile mapping
          'village': _patient!.village,
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('🩺 AI Health Assistant', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _openVoiceAssistant,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Launch Voice Assistant',
        shape: const CircleBorder(),
        child: const Icon(Icons.mic_rounded, size: 36),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient selector context
            _buildPatientSelectorHeader(isDark),
            const SizedBox(height: 24),

            // Analytics metrics grid
            Text('Clinical AI Operations Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _isLoadingMetrics ? _buildSkeletonsGrid() : _buildMetricsGrid(isDark),
            const SizedBox(height: 32),

            // Action options Grid
            Text('AI Diagnostic Tools & Resources', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _buildToolsMenu(isDark),
            const SizedBox(height: 32),

            // Recent Logs Table
            Text('Recent Diagnostic Screening Reports', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _buildRecentReportsList(isDark),
            const SizedBox(height: 80), // extra padding for large floating action button
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelectorHeader(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_ind_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text('Active Patient Reference Context', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.patientId != null && _patient != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                title: Text(_patient!.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: ${_patient!.id} • ${_patient!.gender} • Age: ${DateTime.now().year - _patient!.dob.year} • ${_patient!.village}'),
                trailing: Chip(
                  label: const Text('Linked Context'),
                  backgroundColor: AppTheme.secondaryColor.withOpacity(0.12),
                  labelStyle: const TextStyle(color: AppTheme.secondaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            else
              _isLoadingPatients
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<Patient>(
                      value: _patient,
                      hint: const Text('Select active patient contextual reference (Optional)...'),
                      items: _patients.map((p) {
                        return DropdownMenuItem<Patient>(
                          value: p,
                          child: Text('${p.name} (ID: ${p.id} - ${p.village})'),
                        );
                      }).toList(),
                      onChanged: (selected) {
                        setState(() {
                          _patient = selected;
                        });
                      },
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossCount = constraints.maxWidth > 800 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.45,
          children: [
            _buildMetricCard('Total AI Scans', _totalScans.toString(), Icons.analytics_rounded, AppTheme.primaryColor, isDark),
            _buildMetricCard('Skin Pathology', _skinDiseases.toString(), Icons.vaccines_outlined, AppTheme.secondaryColor, isDark),
            _buildMetricCard('Pregnancy Risk Counts', _pregnancyRisks.toString(), Icons.pregnant_woman_rounded, Colors.purple, isDark),
            _buildMetricCard('Child Illnesses', _childIllnesses.toString(), Icons.child_care_rounded, Colors.teal, isDark),
            _buildMetricCard('Critical Warnings', _emergencyCases.toString(), Icons.notification_important_rounded, AppTheme.dangerColor, isDark),
            _buildMetricCard('Most Prevalent Issue', _mostCommonDisease, Icons.troubleshoot_rounded, Colors.orange, isDark, fontSizeOverride: 13.5),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDark, {double? fontSizeOverride}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: fontSizeOverride ?? 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xff0f172a),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: List.generate(6, (index) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Center(child: CircularProgressIndicator()),
        );
      }),
    );
  }

  Widget _buildToolsMenu(bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      int crossCount = constraints.maxWidth > 800 ? 3 : 2;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.15,
        children: [
          _buildToolGridItem(
            icon: Icons.camera_alt_rounded,
            title: 'Scan Skin Disease',
            subtitle: 'Gemini Vision AI lesion evaluations',
            color: AppTheme.primaryColor,
            onTap: () => context.push('/scan-skin-disease${_patient != null ? "?patientId=${_patient!.id}" : ""}'),
          ),
          _buildToolGridItem(
            icon: Icons.record_voice_over_rounded,
            title: 'Voice Assistant HUD',
            subtitle: 'ChatGPT conversational diagnostic consults',
            color: AppTheme.secondaryColor,
            onTap: _openVoiceAssistant,
          ),
          _buildToolGridItem(
            icon: Icons.search_rounded,
            title: 'Symptom Checker',
            subtitle: 'Search and match clinical complaints',
            color: Colors.teal,
            onTap: () => _openSymptomCheckerDialog(),
          ),
          _buildToolGridItem(
            icon: Icons.medication_rounded,
            title: 'Medicine Index',
            subtitle: 'Suggestions and precaution warnings',
            color: Colors.purple,
            onTap: () => _openMedsReferenceDialog(),
          ),
          _buildToolGridItem(
            icon: Icons.menu_book_rounded,
            title: 'Health Education',
            subtitle: 'Prevention policies and schemes guides',
            color: Colors.orange,
            onTap: () => _openEducationGuidesDialog(),
          ),
          _buildToolGridItem(
            icon: Icons.history_edu_rounded,
            title: 'Logs / History Archive',
            subtitle: 'Audit scan history exports',
            color: Colors.blueGrey,
            onTap: () => context.push('/scan-history'),
          ),
        ],
      );
    });
  }

  Widget _buildToolGridItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 10.5, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReportsList(bool isDark) {
    if (_recentReports.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('No diagnostic reports registered.')),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentReports.length,
        separatorBuilder: (ctx, idx) => const Divider(height: 1),
        itemBuilder: (ctx, idx) {
          final rep = _recentReports[idx];
          final date = (rep['date'] as Timestamp?)?.toDate();
          final dateStr = date != null ? DateFormat('dd MMM, hh:mm a').format(date) : 'N/A';
          final disease = rep['analysis']?['possibleDisease'] ?? 'Anomaly';
          final category = rep['analysis']?['diseaseCategory'] ?? 'General';
          final severity = rep['analysis']?['severity'] ?? 'Low';
          final patName = rep['patientName'] ?? 'Anonymous';

          final severityColor = severity == 'High' || severity == 'Critical'
              ? AppTheme.dangerColor
              : (severity == 'Moderate' ? Colors.orange : AppTheme.secondaryColor);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: severityColor.withOpacity(0.08),
              child: Icon(Icons.health_and_safety_rounded, color: severityColor),
            ),
            title: Text('$disease ($category)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
            subtitle: Text('Patient: $patName • Scanned: $dateStr', style: GoogleFonts.inter(fontSize: 11.5)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: severityColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(
                severity,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: severityColor),
              ),
            ),
          );
        },
      ),
    );
  }

  // Symptom Checker Dialog Mock Integration
  void _openSymptomCheckerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('AI Symptom Checker', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick check symptom profiles using Gemini Voice assistant.', style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Enter symptoms (e.g. fever, rash, stomach ache)',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openVoiceAssistant();
            },
            child: const Text('Scan with Voice Assistant'),
          ),
        ],
      ),
    );
  }

  // Meds Dialog Mock Integration
  void _openMedsReferenceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ASHA Medicine Reference Index', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('Paracetamol'), subtitle: const Text('Usage: Mild/Moderate Fever, Headache. Dosage: 500mg (as advised).')),
              ListTile(title: const Text('ORS (Oral Rehydration Salts)'), subtitle: const Text('Usage: Dehydration, Diarrhea. Dosage: Mix 1 packet in 1L water.')),
              ListTile(title: const Text('IFA (Iron Folic Acid)'), subtitle: const Text('Usage: Maternal Anemia. Dosage: 1 tablet daily (maternal cycle).')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  // Health Education Reference Dialog
  void _openEducationGuidesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('National Health Schemes & Education', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryColor),
                title: const Text('Maternal Vaccination Schedule'),
                subtitle: const Text('Tetanus Toxoid (TT-1, TT-2) and booster regulations for pregnant mothers.'),
              ),
              ListTile(
                leading: const Icon(Icons.shield_rounded, color: AppTheme.secondaryColor),
                title: const Text('Ayushman Bharat PM-JAY'),
                subtitle: const Text('Cashless tertiary health covers up to Rs 5 Lakhs per family annually.'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
