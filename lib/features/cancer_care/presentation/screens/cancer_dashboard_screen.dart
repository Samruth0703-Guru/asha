import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/cancer_repository.dart';
import '../../data/models/cancer_models.dart';

// State Provider to track current user role for live testing
final cancerRoleProvider = StateProvider<String>((ref) => 'ASHA Worker');

class CancerDashboardScreen extends ConsumerStatefulWidget {
  const CancerDashboardScreen({super.key});

  @override
  ConsumerState<CancerDashboardScreen> createState() => _CancerDashboardScreenState();
}

class _ChatStats {
  final int totalScreened;
  final int highRisk;
  final int underTreatment;
  final int completedTreatment;
  final int missedFollowUps;
  final int pendingReferrals;

  _ChatStats({
    required this.totalScreened,
    required this.highRisk,
    required this.underTreatment,
    required this.completedTreatment,
    required this.missedFollowUps,
    required this.pendingReferrals,
  });
}

class _CancerDashboardScreenState extends ConsumerState<CancerDashboardScreen> {
  int _touchedPieIndex = -1;
  int _selectedMapVillageIndex = -1;

  final List<Map<String, dynamic>> _villages = [
    {'name': 'Alanganallur', 'cases': 14, 'highRisk': 5, 'lat': 9.9723, 'lng': 78.1121},
    {'name': 'Kulamangalam', 'cases': 8, 'highRisk': 2, 'lat': 9.9760, 'lng': 78.1150},
    {'name': 'Paravai', 'cases': 19, 'highRisk': 8, 'lat': 9.9680, 'lng': 78.1090},
    {'name': 'Othakadai', 'cases': 12, 'highRisk': 4, 'lat': 9.9520, 'lng': 78.1630},
    {'name': 'Melur', 'cases': 23, 'highRisk': 11, 'lat': 10.0240, 'lng': 78.3370},
  ];

  Future<_ChatStats> _loadStats(String role) async {
    final repo = ref.read(cancerRepositoryProvider);
    final userId = 'LAKSHMI_001';

    final patients = await repo.getPatients(role, userId);
    final screenings = await repo.getAllScreenings(role, userId);
    final treatments = await repo.getAllTreatments(role, userId);
    final referrals = await repo.getAllReferrals(role, userId);
    final followups = await repo.getAllFollowUps(role, userId);

    int highRisk = screenings.where((s) => s.riskLevel == 'High Risk' || s.riskLevel == 'Critical Risk').length;
    int underTreatment = treatments.where((t) => t.treatmentStatus == 'Under Treatment').length;
    int completed = treatments.where((t) => t.treatmentStatus == 'Completed').length;
    int pendingReferrals = referrals.where((r) => r.referralStatus == 'Pending').length;

    // Simulate some starting seed data if empty
    return _ChatStats(
      totalScreened: screenings.isEmpty ? 58 : screenings.length,
      highRisk: screenings.isEmpty ? 12 : highRisk,
      underTreatment: treatments.isEmpty ? 9 : underTreatment,
      completedTreatment: treatments.isEmpty ? 4 : completed,
      missedFollowUps: followups.isEmpty ? 3 : followups.where((f) => f.medicationCompliance == 'Low').length,
      pendingReferrals: referrals.isEmpty ? 2 : pendingReferrals,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRole = ref.watch(cancerRoleProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield_moon_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Text(
              'Cancer Care & Screening',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Secure Role switcher widget
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentRole,
                dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                onChanged: (String? newRole) {
                  if (newRole != null) {
                    ref.read(cancerRoleProvider.notifier).state = newRole;
                    ref.read(cancerRepositoryProvider).logAudit(
                      newRole,
                      'LAKSHMI_001',
                      'ROLE_SWITCH',
                      'Swapped tester role profile to: $newRole',
                    );
                  }
                },
                items: <String>['ASHA Worker', 'Nurse', 'Doctor', 'Administrator']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          value == 'ASHA Worker'
                              ? Icons.badge_outlined
                              : value == 'Nurse'
                                  ? Icons.healing_rounded
                                  : value == 'Doctor'
                                      ? Icons.medical_services_rounded
                                      : Icons.admin_panel_settings_rounded,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<_ChatStats>(
        future: _loadStats(currentRole),
        builder: (context, snapshot) {
          final stats = snapshot.data ??
              _ChatStats(
                totalScreened: 58,
                highRisk: 12,
                underTreatment: 9,
                completedTreatment: 4,
                missedFollowUps: 3,
                pendingReferrals: 2,
              );

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Welcome banner with role descriptor
                FadeInDown(
                  duration: const Duration(milliseconds: 300),
                  child: _buildBannerCard(isDark, currentRole),
                ),
                const SizedBox(height: 24),

                // Metrics Grid Cards
                FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: _buildMetricsGrid(stats),
                ),
                const SizedBox(height: 28),

                // Quick Actions Dashboard Panel (Role restricted)
                Text(
                  'Operations & Forms Dashboard',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildQuickActionGrid(context, currentRole),
                const SizedBox(height: 32),

                // Analytics Graphs Section
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPieChartCard(isDark, stats)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildLineChartCard(isDark)),
                    ],
                  )
                else ...[
                  _buildPieChartCard(isDark, stats),
                  const SizedBox(height: 20),
                  _buildLineChartCard(isDark),
                ],
                const SizedBox(height: 20),

                // Interactive Village Cluster Map
                _buildInteractiveVillageMap(isDark),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerCard(bool isDark, String currentRole) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        gradient: const LinearGradient(
          colors: [Color(0xff1e3a8a), Color(0xff3b82f6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ACTIVE USER PROFILE: ${currentRole.toUpperCase()}',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'National Cancer Screening Campaign',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enabling early detection, screening audits, oncologist reference systems, and supportive post-chemo follow-ups under PHC Madurai Central Block.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(_ChatStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 750 ? 3 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.28,
      children: [
        _buildMetricCard('Total Screened', '${stats.totalScreened}', 'Cumulative records', Icons.screen_search_desktop_rounded, AppTheme.primaryColor),
        _buildMetricCard('High/Crit Risk', '${stats.highRisk}', 'Requires specialist referral', Icons.report_problem_outlined, AppTheme.dangerColor),
        _buildMetricCard('Under Treatment', '${stats.underTreatment}', 'Active chemo/surgery', Icons.healing_rounded, Colors.purple.shade600),
        _buildMetricCard('Completed Care', '${stats.completedTreatment}', 'In remission surveillance', Icons.verified_rounded, AppTheme.secondaryColor),
        _buildMetricCard('Missed Follow-Ups', '${stats.missedFollowUps}', 'Unscheduled home visits', Icons.event_busy_rounded, AppTheme.warningColor),
        _buildMetricCard('Pending Referrals', '${stats.pendingReferrals}', 'Awaiting hospital intake', Icons.reply_all_rounded, Colors.teal.shade600),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey : const Color(0xff64748b)),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xff0f172a)),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid(BuildContext context, String currentRole) {
    // Defines operations grid with role checks
    final isAdmin = currentRole == 'Administrator';
    final isDoctor = currentRole == 'Doctor';
    final isNurse = currentRole == 'Nurse';
    final isAsha = currentRole == 'ASHA Worker';

    Widget actionCard(String label, IconData icon, String route, Color color, bool isAllowed) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Opacity(
        opacity: isAllowed ? 1.0 : 0.45,
        child: InkWell(
          onTap: () {
            if (!isAllowed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Access Denied. $label is restricted to appropriate medical profiles.'),
                  backgroundColor: AppTheme.dangerColor,
                ),
              );
              return;
            }
            context.push(route);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xff1e293b),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 750 ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        actionCard('Register Patient', Icons.person_add_alt_1_rounded, '/cancer-care/register', AppTheme.primaryColor, isAsha || isNurse || isAdmin),
        actionCard('Symptom Screen', Icons.checklist_rtl_rounded, '/cancer-care/screening', AppTheme.secondaryColor, isAsha || isNurse || isAdmin),
        actionCard('AI Vision Scan', Icons.add_a_photo_rounded, '/cancer-care/vision', Colors.orange.shade700, isAsha || isNurse || isAdmin),
        actionCard('Treatment Plan', Icons.edit_calendar_rounded, '/cancer-care/treatment', Colors.purple.shade600, isDoctor || isNurse || isAdmin),
        actionCard('Follow-Up Log', Icons.house_rounded, '/cancer-care/follow-up', Colors.teal.shade600, isAsha || isNurse || isAdmin),
        actionCard('Medicine Tracker', Icons.medical_services_outlined, '/cancer-care/medicine', Colors.pink.shade600, true),
        actionCard('Referral Slips', Icons.launch_rounded, '/cancer-care/referral', Colors.blue.shade800, true),
        actionCard('Admin Audit Logs', Icons.security_rounded, '/cancer-care/audit-logs', AppTheme.dangerColor, isAdmin),
      ],
    );
  }

  Widget _buildPieChartCard(bool isDark, _ChatStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Level demographics (%)',
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
                        _buildPieSection(0, AppTheme.secondaryColor, 55, 'Low'),
                        _buildPieSection(1, AppTheme.warningColor, 25, 'Med'),
                        _buildPieSection(2, Colors.orange.shade700, 15, 'High'),
                        _buildPieSection(3, AppTheme.dangerColor, 5, 'Crit'),
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
                    _buildLegend('Low Risk', AppTheme.secondaryColor),
                    const SizedBox(height: 6),
                    _buildLegend('Medium Risk', AppTheme.warningColor),
                    const SizedBox(height: 6),
                    _buildLegend('High Risk', Colors.orange.shade700),
                    const SizedBox(height: 6),
                    _buildLegend('Critical Risk', AppTheme.dangerColor),
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Screening Trends (2026)',
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
                      FlSpot(0, 15),
                      FlSpot(1, 28),
                      FlSpot(2, 20),
                      FlSpot(3, 34),
                      FlSpot(4, 48),
                      FlSpot(5, 58),
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

  Widget _buildInteractiveVillageMap(bool isDark) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Village Disease Density Map',
                    style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Tap target village nodes to inspect caseload details',
                    style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey),
                  ),
                ],
              ),
              const Icon(Icons.map_rounded, color: AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff111827) : const Color(0xffeff6ff),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
            ),
            child: Stack(
              children: [
                // Render stylized grid lines representing the block map
                Positioned.fill(
                  child: GridPaper(
                    color: isDark ? Colors.blue.withOpacity(0.02) : Colors.blue.withOpacity(0.05),
                    divisions: 2,
                    subdivisions: 1,
                  ),
                ),
                
                // Map Pins representing Villages
                Positioned(
                  left: 60,
                  top: 50,
                  child: _buildMapPin(0),
                ),
                Positioned(
                  left: 220,
                  top: 30,
                  child: _buildMapPin(1),
                ),
                Positioned(
                  left: 140,
                  top: 130,
                  child: _buildMapPin(2),
                ),
                Positioned(
                  right: 90,
                  top: 90,
                  child: _buildMapPin(3),
                ),
                Positioned(
                  right: 150,
                  bottom: 40,
                  child: _buildMapPin(4),
                ),

                // Map Information Overlay
                if (_selectedMapVillageIndex != -1)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _villages[_selectedMapVillageIndex]['name'],
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Total Cancer Cases: ${_villages[_selectedMapVillageIndex]['cases']} • Critical/High Risk: ${_villages[_selectedMapVillageIndex]['highRisk']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedMapVillageIndex = -1;
                                });
                              },
                              icon: const Icon(Icons.close, color: Colors.white, size: 16),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(int index) {
    final isSelected = _selectedMapVillageIndex == index;
    final isCritical = _villages[index]['highRisk'] > 5;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMapVillageIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.blue.shade800 
                  : (isCritical ? AppTheme.dangerColor : AppTheme.secondaryColor),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isCritical ? AppTheme.dangerColor : AppTheme.secondaryColor).withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            ),
            child: Icon(
              Icons.location_on_rounded, 
              color: Colors.white, 
              size: isSelected ? 22 : 16,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _villages[index]['name'],
              style: GoogleFonts.inter(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
