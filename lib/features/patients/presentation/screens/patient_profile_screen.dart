import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/database/sync_service.dart';
import 'package:drift/drift.dart' as drift;

class PatientProfileScreen extends ConsumerStatefulWidget {
  final String id;
  const PatientProfileScreen({super.key, required this.id});

  @override
  ConsumerState<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Patient? _patient;
  bool _isLoading = true;
  bool _isVisitModeActive = false;

  // Visit checklist state
  final Map<String, bool> _visitChecklist = {
    'Vitals screening recorded (BP, Hb, Sugar)': false,
    'Distributed daily Iron & Calcium supplements': false,
    'Queried client on child fetal movement counts': false,
    'Screened for danger signs (blurred vision, swelling)': false,
    'Advised clinical referral protocols where needed': false,
  };
  String _visitVoiceNotes = "";
  bool _isRecordingVisitVoice = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadPatient();
  }

  void _loadPatient() async {
    final db = ref.read(localDatabaseProvider);
    final p = await db.getPatientById(widget.id);
    if (mounted) {
      setState(() {
        _patient = p;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _recordVisitVoiceNote() async {
    setState(() {
      _isRecordingVisitVoice = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isRecordingVisitVoice = false;
      _visitVoiceNotes = "Client complains of slight fatigue and calf muscle cramps in evenings. Fetal movement counts regular. IFA pills handed over.";
    });
  }

  void _completeVisit() async {
    if (_patient == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maternal Home Visit Completed for ${_patient!.name}! logs queued for sync.'),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
    setState(() {
      _isVisitModeActive = false;
      _visitChecklist.updateAll((key, value) => false);
      _visitVoiceNotes = "";
    });
  }

  Widget _buildProfilePhoto() {
    final photoPath = _patient?.photoPath;
    if (photoPath == null || photoPath.isEmpty) {
      // Fallback: show patient initials
      final initials = (_patient?.name ?? 'P').split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
      return Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
        ),
      );
    }
    // Base64 data URL (from web camera capture)
    if (photoPath.startsWith('data:')) {
      try {
        final base64Str = photoPath.split(',')[1];
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 85,
          height: 85,
          errorBuilder: (_, __, ___) => _buildInitialsFallback(),
        );
      } catch (_) {
        return _buildInitialsFallback();
      }
    }
    // Network URL (from Firebase or web)
    if (photoPath.startsWith('http') || photoPath.startsWith('blob:')) {
      return Image.network(
        photoPath,
        fit: BoxFit.cover,
        width: 85,
        height: 85,
        errorBuilder: (_, __, ___) => _buildInitialsFallback(),
      );
    }
    // Fallback for any other path
    return _buildInitialsFallback();
  }

  Widget _buildInitialsFallback() {
    final initials = (_patient?.name ?? 'P').split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_patient == null) {
      return const Scaffold(body: Center(child: Text('Patient not found.')));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color riskColor;
    switch (_patient!.riskLevel.toLowerCase()) {
      case 'critical':
        riskColor = AppTheme.dangerColor;
        break;
      case 'high':
        riskColor = Colors.orange.shade700;
        break;
      case 'medium':
        riskColor = AppTheme.warningColor;
        break;
      case 'low':
      default:
        riskColor = AppTheme.secondaryColor;
        break;
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Maternal Health Record', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => context.push('/emergency-hud'),
            icon: const Icon(Icons.emergency_rounded, color: AppTheme.dangerColor),
            tooltip: 'Red Alert Protocol',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Patient Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              color: isDark ? AppTheme.darkCardColor : Colors.white,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circular patient profile image
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            height: 85,
                            width: 85,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xff3b82f6), Color(0xff8b5cf6)],
                              ),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? AppTheme.darkCardColor : Colors.white,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buildProfilePhoto(),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xff3b82f6), Color(0xff2563eb)]),
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? AppTheme.darkCardColor : Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 12),
                          )
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _patient!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: riskColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: riskColor, width: 1),
                                  ),
                                  child: Text(
                                    _patient!.riskLevel.toUpperCase(),
                                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: riskColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // ABHA verification badge
                            Row(
                              children: [
                                const Icon(Icons.badge_outlined, size: 13, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'ABHA ID: ${_patient!.abhaId ?? "Unregistered"}',
                                  style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 6),
                                if (_patient!.abhaId != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text('VERIFIED', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_patient!.gender} • ${_patient!.village} • Phone: ${_patient!.phone}',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xff64748b), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/risk-assessment/${_patient!.id}'),
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text('AI Risk Predictor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/health-scan?patientId=${_patient!.id}'),
                          icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
                          label: const Text('AI Health Scan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isVisitModeActive = !_isVisitModeActive;
                        });
                      },
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: Text(_isVisitModeActive ? 'Close Visit HUD' : 'Home Visit Active'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isVisitModeActive) ...[
              // Integrated Home Visit Checklist HUD
              FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.18), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gps_fixed_rounded, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'GEOLOCATED HOME VISIT CONSOLE',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.primaryColor, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ..._visitChecklist.keys.map((key) {
                        return CheckboxListTile(
                          title: Text(key, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          value: _visitChecklist[key],
                          dense: true,
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() {
                              _visitChecklist[key] = val ?? false;
                            });
                          },
                        );
                      }).toList(),
                      const Divider(height: 24),
                      Text('Visit Voice Notes Transcription:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff0f172a) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _visitVoiceNotes.isEmpty ? 'No recording logs. Press microphone to dictate note...' : _visitVoiceNotes,
                          style: GoogleFonts.inter(fontSize: 13, fontStyle: _visitVoiceNotes.isEmpty ? FontStyle.italic : FontStyle.normal),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isRecordingVisitVoice ? null : _recordVisitVoiceNote,
                            icon: Icon(_isRecordingVisitVoice ? Icons.hourglass_top_rounded : Icons.mic_rounded),
                            label: Text(_isRecordingVisitVoice ? 'Dictating...' : 'Record Voice'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecordingVisitVoice ? AppTheme.dangerColor : AppTheme.secondaryColor,
                              minimumSize: const Size(120, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _completeVisit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                minimumSize: const Size(120, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Save & Submit Log'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Tabs System
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              isScrollable: true,
              tabs: const [
                Tab(text: 'Vitals & Charts'),
                Tab(text: 'Pregnancy'),
                Tab(text: 'Timeline'),
                Tab(text: 'Vaccines'),
                Tab(text: 'AI Guidelines'),
              ],
            ),

            SizedBox(
              height: 480,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVitalsAndChartsTab(),
                  _buildPregnancyTab(),
                  _buildTimelineTab(),
                  _buildVaccinesTab(),
                  _buildAIGuidelinesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsAndChartsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Charts Header
        Text(
          'Hemoglobin Progression Trend (g/dL)',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Line chart representing clinical trends
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
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
                          return const Text('May', style: TextStyle(fontSize: 9, color: Colors.grey));
                        case 2:
                          return const Text('Jun', style: TextStyle(fontSize: 9, color: Colors.grey));
                        case 4:
                          return const Text('Jul', style: TextStyle(fontSize: 9, color: Colors.grey));
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 7.2),
                    FlSpot(1, 7.8),
                    FlSpot(2, 8.2),
                    FlSpot(3, 8.0),
                    FlSpot(4, 8.5),
                  ],
                  isCurved: true,
                  color: AppTheme.dangerColor,
                  barWidth: 4,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.dangerColor.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 32),

        // Vitals Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _buildVitalItem('Blood Pressure', _patient!.bloodPressure ?? 'N/A', Icons.speed_rounded, Colors.blue),
            _buildVitalItem('Hemoglobin', _patient!.hemoglobin != null ? '${_patient!.hemoglobin} g/dL' : 'N/A', Icons.bloodtype_rounded, Colors.red),
            _buildVitalItem('Blood Sugar', _patient!.bloodSugar != null ? '${_patient!.bloodSugar} mg/dL' : 'N/A', Icons.biotech_rounded, Colors.orange),
            _buildVitalItem('Temperature', _patient!.temperature != null ? '${_patient!.temperature} °F' : 'N/A', Icons.thermostat_rounded, Colors.amber),
            _buildVitalItem('Weight', _patient!.weight != null ? '${_patient!.weight} kg' : 'N/A', Icons.scale_rounded, Colors.teal),
          ],
        ),
        const SizedBox(height: 16),
        if (_patient!.symptoms != null) ...[
          Text('Reported Symptoms Indicators', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff151e2e) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0)),
            ),
            child: Text(
              _patient!.symptoms!,
              style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVitalItem(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff151e2e) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    final events = [
      {'title': 'Maternal Checkup Done', 'desc': 'BP 145/95, Hb 8.5 g/dL. Clinical medication given.', 'date': 'Jul 8, 2026', 'icon': Icons.home_rounded, 'color': AppTheme.secondaryColor},
      {'title': 'Sub-Centre Doctor Visit', 'desc': 'High risk category assigned by PHC doctor.', 'date': 'Jun 20, 2026', 'icon': Icons.local_hospital_rounded, 'color': Colors.purple},
      {'title': 'TT-1 Vaccine Completed', 'desc': 'Administered at Ward 4 health post.', 'date': 'Jun 05, 2026', 'icon': Icons.vaccines_rounded, 'color': AppTheme.warningColor},
      {'title': 'Registered in ASHA CARE', 'desc': 'Profile initialised by Lakshmi worker.', 'date': 'May 10, 2026', 'icon': Icons.person_add_rounded, 'color': AppTheme.primaryColor},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: events.length,
      itemBuilder: (ctx, index) {
        final ev = events[index];
        final icon = ev['icon'] as IconData;
        final color = ev['color'] as Color;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color, size: 14),
                ),
                if (index < events.length - 1)
                  Container(
                    width: 2,
                    height: 55,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ev['title'] as String, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  Text(ev['desc'] as String, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(ev['date'] as String, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPregnancyTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xff151e2e) : Colors.white;
    final borderColor = isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pregnancy Details', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 12),
              _buildInfoRow('Status', _patient?.isPregnant == true ? 'Active Pregnancy' : 'Not Pregnant', Icons.pregnant_woman),
              _buildInfoRow('Expected Delivery Date', '12 Oct 2026', Icons.calendar_today),
              _buildInfoRow('Previous Pregnancies', '${_patient?.previousPregnancies ?? 0}', Icons.history),
              _buildInfoRow('Risk Level', _patient?.riskLevel ?? 'Low', Icons.warning_amber_rounded),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ANC Visits', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 12),
              _buildInfoRow('Total Visits', '4 / 8', Icons.check_circle_outline),
              _buildInfoRow('Next Visit', '22 Dec 2026', Icons.calendar_month),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showScheduleAncDialog(),
                icon: const Icon(Icons.add_alarm),
                label: const Text('Schedule ANC Visit'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildVaccinesTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildVaccineSection('Missed Vaccinations', [
          {'name': 'Measles 1st Dose', 'date': 'Oct 15, 2026', 'done': false},
        ], Colors.red, isDark),
        const SizedBox(height: 16),
        _buildVaccineSection('Upcoming Vaccinations', [
          {'name': 'Hepatitis B', 'date': 'Nov 12, 2026', 'done': false},
          {'name': 'OPV-1', 'date': 'Dec 05, 2026', 'done': false},
        ], AppTheme.primaryColor, isDark),
        const SizedBox(height: 16),
        _buildVaccineSection('Completed Vaccinations', [
          {'name': 'BCG', 'date': 'Jan 10, 2026', 'done': true},
          {'name': 'OPV-0', 'date': 'Jan 10, 2026', 'done': true},
          {'name': 'Hepatitis B (Birth)', 'date': 'Jan 10, 2026', 'done': true},
        ], AppTheme.secondaryColor, isDark),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _showScheduleVaccineDialog(),
          icon: const Icon(Icons.add_task),
          label: const Text('Schedule New Vaccination'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildVaccineSection(String title, List<Map<String, dynamic>> vaccines, Color headerColor, bool isDark) {
    if (vaccines.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: headerColor)),
        const SizedBox(height: 8),
        ...vaccines.map((vac) {
          final done = vac['done'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff151e2e) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0)),
            ),
            child: Row(
              children: [
                Icon(
                  done ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                  color: done ? AppTheme.secondaryColor : AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vac['name'] as String, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('Date: ${vac['date']}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                if (!done)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sms broadcast queued for ${_patient!.name}.'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    },
                    child: const Text('Remind', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showScheduleAncDialog() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final db = ref.read(localDatabaseProvider);
      await db.into(db.ancVisits).insert(
        AncVisitsCompanion.insert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          patientId: _patient!.id,
          visitDate: picked,
          nextVisitDate: drift.Value(picked),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ANC Visit scheduled successfully and SMS alerts queued.')));
      }
    }
  }

  void _showScheduleVaccineDialog() async {
    String selectedVaccine = 'Pentavalent';
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select Vaccine Type/Dose'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButtonFormField<String>(
                value: selectedVaccine,
                items: ['Pentavalent', 'OPV-1', 'OPV-2', 'Measles', 'Vitamin A', 'TT-1'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (val) => setState(() => selectedVaccine = val!),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final db = ref.read(localDatabaseProvider);
                await db.into(db.vaccinations).insert(
                  VaccinationsCompanion.insert(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    patientId: _patient!.id,
                    vaccineName: selectedVaccine,
                    dueDate: picked,
                  ),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vaccination scheduled successfully and SMS alerts queued.')));
                }
              },
              child: const Text('Save Schedule'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAIGuidelinesTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Safety Confidence: ${( (_patient!.confidenceScore) * 100).toInt()}%',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('Classification: ${_patient!.riskLevel}',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange.shade700)),
          ],
        ),
        const Divider(height: 24),
        Text('Primary Risk Diagnostics Reasons', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff151e2e) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0)),
          ),
          child: Text(
            _patient!.reasons ?? 'Vitals screening required to compute clinical guidelines.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xff475569), height: 1.4, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 16),
        Text('Clinical Guideline Interventions', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff151e2e) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0)),
          ),
          child: Text(
            _patient!.recommendations ?? 'N/A',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xff475569), height: 1.4, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
