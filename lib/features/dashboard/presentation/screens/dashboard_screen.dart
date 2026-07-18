import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/sync_service.dart';
import '../../../../core/database/local_database.dart';
import '../../../sms/services/sms_service.dart';

class DashboardStats {
  final int totalPatients;
  final int pregnantMothers;
  final int highRiskCases;
  final int vaccinationsDone;

  DashboardStats({
    required this.totalPatients,
    required this.pregnantMothers,
    required this.highRiskCases,
    required this.vaccinationsDone,
  });
}

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  try {
    final db = ref.watch(localDatabaseProvider);
    final result = await Future(() async {
      final patients = await db.getAllPatients();
      
      int pregnant = 0;
      int highRisk = 0;
      for (final p in patients) {
        if (p.isHighRisk || p.riskLevel == 'High' || p.riskLevel == 'Critical') {
          highRisk++;
        }
        if (p.previousPregnancies > 0 || p.symptoms != null) {
          pregnant++;
        }
      }

      final completedVacs = await (db.select(db.vaccinations)..where((t) => t.status.equals('Completed'))).get();

      return DashboardStats(
        totalPatients: patients.length,
        pregnantMothers: pregnant,
        highRiskCases: highRisk,
        vaccinationsDone: completedVacs.length,
      );
    }).timeout(const Duration(seconds: 3));
    return result;
  } catch (e) {
    return DashboardStats(
      totalPatients: 0,
      pregnantMothers: 0,
      highRiskCases: 0,
      vaccinationsDone: 0,
    );
  }
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isOnline = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Simulate connectivity check changes
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        setState(() {
          _isOnline = !_isOnline;
        });
      }
    });

    // Background SMS Automation Cron Scheduler
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (mounted) {
        final db = ref.read(localDatabaseProvider);
        await SmsService().checkAndSendAutomatedAlerts(db);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);
    final syncNotifier = ref.read(syncProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final stats = statsAsync.value ?? DashboardStats(totalPatients: 0, pregnantMothers: 0, highRiskCases: 0, vaccinationsDone: 0);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      drawer: _buildMenuDrawer(context),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppTheme.primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        automaticallyImplyLeading: false,
        toolbarHeight: 75,
        title: Row(
          children: [
            // Premium Profile avatar with gradient ring
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=150'),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Namaste, Lakshmi',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PHC MADURAI',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Madurai Central Block • Ward 4',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Weather and Online indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.wb_sunny_rounded,
                  size: 16,
                  color: Colors.orange.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  '32°C',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xff334155),
                  ),
                ),
              ],
            ),
          ),
          // Connection Status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Tooltip(
              message: _isOnline ? 'Online - Cloud Synced' : 'Offline Mode Active',
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOnline ? AppTheme.secondaryColor : AppTheme.warningColor,
                          boxShadow: [
                            BoxShadow(
                              color: (_isOnline ? AppTheme.secondaryColor : AppTheme.warningColor)
                                  .withOpacity(_pulseController.value * 0.6),
                              blurRadius: 6,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey : const Color(0xff334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.push('/emergency-hud'),
            icon: const Icon(Icons.emergency_rounded, color: AppTheme.dangerColor),
            tooltip: 'Emergency Actions',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Dynamic Cloud Synchronization Banner
            if (syncState.status == SyncStatus.syncing || syncState.pendingItems > 0)
              FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: syncState.status == SyncStatus.syncing
                        ? AppTheme.warningColor.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.08),
                    border: Border(
                      bottom: BorderSide(
                        color: syncState.status == SyncStatus.syncing
                            ? AppTheme.warningColor.withOpacity(0.3)
                            : AppTheme.primaryColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        syncState.status == SyncStatus.syncing ? Icons.sync : Icons.cloud_queue_rounded,
                        color: syncState.status == SyncStatus.syncing ? AppTheme.warningColor : AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          syncState.message,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xff334155),
                          ),
                        ),
                      ),
                      if (syncState.pendingItems > 0 && syncState.status != SyncStatus.syncing)
                        TextButton(
                          onPressed: () => syncNotifier.forceSync(),
                          child: Text(
                            'SYNC NOW (${syncState.pendingItems})',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large Welcome Banner Photo
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: NetworkImage('hospital_banner.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Welcome, Lakshmi!',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your community health and maternal care companion.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Overview Metric Cards Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15,
                    children: [
                      _buildFriendlyMetricCard(
                        title: 'Total Patients',
                        value: '${stats.totalPatients}',
                        subtitle: 'Registered in block',
                        icon: Icons.people_rounded,
                        iconColor: AppTheme.primaryColor,
                        onTap: () => context.push('/patient-list'),
                      ),
                      _buildFriendlyMetricCard(
                        title: 'Pregnant Mothers',
                        value: '${stats.pregnantMothers}',
                        subtitle: 'Maternal care cases',
                        icon: Icons.child_care_rounded,
                        iconColor: AppTheme.secondaryColor,
                        onTap: () => context.push('/patient-list'),
                      ),
                      _buildFriendlyMetricCard(
                        title: 'High Risk Cases',
                        value: '${stats.highRiskCases}',
                        subtitle: 'Requires clinical check',
                        icon: Icons.error_outline_rounded,
                        iconColor: AppTheme.dangerColor,
                        onTap: () => context.push('/patient-list'),
                      ),
                      _buildFriendlyMetricCard(
                        title: 'Vaccinations Done',
                        value: '${stats.vaccinationsDone}',
                        subtitle: 'Completed immunizations',
                        icon: Icons.vaccines_rounded,
                        iconColor: AppTheme.warningColor,
                        onTap: () => context.push('/vaccination-calendar'),
                      ),
                      _buildFriendlyMetricCard(
                        title: 'Pending Sync',
                        value: '${syncState.pendingItems}',
                        subtitle: 'Offline updates queued',
                        icon: Icons.cloud_sync_rounded,
                        iconColor: Colors.blue.shade600,
                        onTap: () => syncNotifier.forceSync(),
                      ),
                      _buildFriendlyMetricCard(
                        title: 'Medicine Stock',
                        value: '5 Items',
                        subtitle: '2 Items low in stock',
                        icon: Icons.medical_services_outlined,
                        iconColor: Colors.purple.shade600,
                        onTap: () => context.push('/medicine-inventory'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions Row
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildQuickActionBtn(
                          icon: Icons.pregnant_woman_rounded,
                          label: 'Pregnancy',
                          route: '/pregnancy-dashboard',
                          color: Colors.pink,
                        ),
                        _buildQuickActionBtn(
                          icon: Icons.vaccines_rounded,
                          label: 'Vaccination',
                          route: '/vaccination-dashboard',
                          color: Colors.blue,
                        ),
                        _buildQuickActionBtn(
                          icon: Icons.shield_moon_outlined,
                          label: 'Cancer Care',
                          route: '/cancer-care',
                          color: AppTheme.dangerColor,
                        ),
                        _buildQuickActionBtn(
                          icon: Icons.person_add_alt_1_rounded,
                          label: 'Register',
                          route: '/register-patient',
                          color: AppTheme.primaryColor,
                        ),
                        _buildQuickActionBtn(
                          icon: Icons.spatial_audio_off_rounded,
                          label: 'AI Voice',
                          route: '/chat-assistant',
                          color: AppTheme.secondaryColor,
                        ),
                        _buildQuickActionBtn(
                          icon: Icons.health_and_safety_outlined,
                          label: 'Risk Check',
                          route: '/patient-profile/PT001',
                          color: Colors.purple.shade600,
                        ),
                        _buildQuickActionBtn(
                          icon: Icons.inventory_2_outlined,
                          label: 'Inventory',
                          route: '/medicine-inventory',
                          color: Colors.teal.shade600,
                        ),
                        _buildQuickActionBtn(
                          icon: Icons.map_rounded,
                          label: 'Village Map',
                          route: '/village-map',
                          color: Colors.orange.shade700,
                        ),
                        _buildQuickActionBtn(
                          icon: Icons.calendar_month_rounded,
                          label: 'Schedule',
                          route: '/vaccination-calendar',
                          color: Colors.pink.shade600,
                        ),
                        _buildQuickActionBtn(
                          icon: Icons.assessment_outlined,
                          label: 'Reports',
                          route: '/district-analytics',
                          color: Colors.blue.shade800,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Daily Activity & Alerts (Simple Activity List)
                  Text(
                    'Daily Activity & Alerts',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFriendlyActivityList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0),
              width: 1.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: isDark ? AppTheme.darkCardColor : Colors.white,
          indicatorColor: AppTheme.primaryColor.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 65,
          onDestinationSelected: (idx) {
            setState(() {
              _currentIndex = idx;
            });
            if (idx == 1) {
              context.push('/patient-list');
            } else if (idx == 2) {
              context.push('/village-map');
            } else if (idx == 3) {
              context.push('/chat-assistant');
            } else if (idx == 4) {
              context.push('/reports');
            }
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_rounded, color: _currentIndex == 0 ? AppTheme.primaryColor : Colors.grey),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_alt_rounded, color: _currentIndex == 1 ? AppTheme.primaryColor : Colors.grey),
              label: 'Patients',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_rounded, color: _currentIndex == 2 ? AppTheme.primaryColor : Colors.grey),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.mic_rounded, color: _currentIndex == 3 ? AppTheme.primaryColor : Colors.grey),
              label: 'AI Assistant',
            ),
            NavigationDestination(
              icon: Icon(Icons.document_scanner_rounded, color: _currentIndex == 4 ? AppTheme.primaryColor : Colors.grey),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget drawerItem({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color? iconColor,
    }) {
      return ListTile(
        leading: Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: 20),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xff0f172a),
          ),
        ),
        onTap: onTap,
        dense: true,
      );
    }

    Widget drawerHeaderCategory(String category) {
      return Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 18.0, bottom: 6.0),
        child: Text(
          category.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 1.1,
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: isDark ? AppTheme.darkCardColor : Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.medical_services_outlined, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASHA CARE+',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor),
                      ),
                      Text(
                        'Maternal System Console',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  drawerHeaderCategory('Core Hub & Directory'),
                  drawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard Home',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  drawerItem(
                    icon: Icons.contacts_rounded,
                    title: 'Patients Directory (List)',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/patient-list');
                    },
                  ),
                  drawerItem(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'Register New Patient',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/register-patient');
                    },
                  ),
                  drawerItem(
                    icon: Icons.map_rounded,
                    title: 'Village Disease Heatmap',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/village-map');
                    },
                  ),
                  
                  const Divider(height: 12, indent: 16, endIndent: 16),
                  drawerHeaderCategory('Clinical Schedules'),
                  drawerItem(
                    icon: Icons.calendar_month_rounded,
                    title: 'Home Visit Planner',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/visit-planner');
                    },
                  ),
                  drawerItem(
                    icon: Icons.vaccines_rounded,
                    title: 'Vaccination Calendar',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/vaccination-calendar');
                    },
                  ),
                  drawerItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'Medicine Stocks Inventory',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/medicine-inventory');
                    },
                  ),

                  const Divider(height: 12, indent: 16, endIndent: 16),
                  drawerHeaderCategory('Gemini AI Diagnoses'),
                  drawerItem(
                    icon: Icons.forum_outlined,
                    title: 'Gemini Chat Copilot',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/ai-chat');
                    },
                  ),
                  drawerItem(
                    icon: Icons.keyboard_voice_rounded,
                    title: 'Live Voice Assistant (Orb)',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/chat-assistant');
                    },
                  ),
                  drawerItem(
                    icon: Icons.offline_bolt_rounded,
                    title: 'High-Risk Diagnosis Model',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/risk-assessment/PT001');
                    },
                  ),
                  drawerItem(
                    icon: Icons.center_focus_strong_rounded,
                    title: 'AI Health Image Scanner',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/health-scan');
                    },
                  ),
                  drawerItem(
                    icon: Icons.healing_rounded,
                    title: 'AI Health Assistant',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/ai-health-assistant');
                    },
                  ),
                  drawerItem(
                    icon: Icons.shield_moon_outlined,
                    title: 'Cancer Care & Screening',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/cancer-care');
                    },
                    iconColor: AppTheme.dangerColor,
                  ),

                  const Divider(height: 12, indent: 16, endIndent: 16),
                  drawerHeaderCategory('Administrative Center'),
                  drawerItem(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notifications Center',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/notifications');
                    },
                  ),
                  drawerItem(
                    icon: Icons.sms_rounded,
                    title: 'SMS Delivery History',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/sms-history');
                    },
                  ),
                  drawerItem(
                    icon: Icons.document_scanner_rounded,
                    title: 'Monthly Form Reports',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/reports');
                    },
                  ),
                  drawerItem(
                    icon: Icons.trending_up_rounded,
                    title: 'District Analytics Panel',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/district-analytics');
                    },
                  ),
                  drawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings Console',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  drawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Sign Out (Login Screen)',
                    iconColor: AppTheme.dangerColor,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendlyMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.grey : Colors.grey.shade400,
                  size: 12,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xff0f172a),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isDark ? const Color(0xff94a3b8) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required String route,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        margin: const EdgeInsets.only(right: 18),
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xffe2e8f0) : const Color(0xff334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendlyActivityList() {
    final activities = [
      {
        'title': 'High Risk Alert: Meena Karuppasamy',
        'subtitle': 'Critical pre-eclampsia risk. Follow up immediately.',
        'time': 'Today',
        'icon': Icons.error_rounded,
        'iconColor': AppTheme.dangerColor,
        'route': '/patient-profile/PT003',
      },
      {
        'title': 'Vaccination Due: Rajeshwari Devi',
        'subtitle': 'TT-2 (Tetanus Toxoid) dose is scheduled for today.',
        'time': 'Today',
        'icon': Icons.vaccines_rounded,
        'iconColor': AppTheme.warningColor,
        'route': '/vaccination-calendar',
      },
      {
        'title': 'Sync Complete',
        'subtitle': 'All offline records have been successfully saved.',
        'time': '2 hours ago',
        'icon': Icons.check_circle_rounded,
        'iconColor': AppTheme.secondaryColor,
        'route': '/dashboard',
      },
      {
        'title': 'Pregnancy Registered: Anjali Sharma',
        'subtitle': 'New patient profile added with routine care plan.',
        'time': 'Yesterday',
        'icon': Icons.pregnant_woman_rounded,
        'iconColor': AppTheme.primaryColor,
        'route': '/patient-profile/PT002',
      },
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: activities.map((act) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xff1f2937) : Colors.grey.shade100,
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: (act['iconColor'] as Color).withOpacity(0.1),
              child: Icon(act['icon'] as IconData, color: act['iconColor'] as Color),
            ),
            title: Text(
              act['title'] as String,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: isDark ? Colors.white : const Color(0xff0f172a),
              ),
            ),
            subtitle: Text(
              act['subtitle'] as String,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? const Color(0xff94a3b8) : Colors.grey.shade600,
              ),
            ),
            trailing: Text(
              act['time'] as String,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            onTap: () {
              final route = act['route'] as String;
              if (route != '/dashboard') {
                context.push(route);
              }
            },
          ),
        );
      }).toList(),
    );
  }
}

// Sparkline Painter for Overview Cards
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = maxVal == minVal ? 1.0 : (maxVal - minVal);

    final double widthSegment = size.width / (data.length - 1);
    
    double getX(int index) => index * widthSegment;
    double getY(double value) => size.height - ((value - minVal) / range * (size.height - 6) + 3);

    path.moveTo(getX(0), getY(data[0]));
    fillPath.moveTo(getX(0), size.height);
    fillPath.lineTo(getX(0), getY(data[0]));

    for (int i = 1; i < data.length; i++) {
      path.lineTo(getX(i), getY(data[i]));
      fillPath.lineTo(getX(i), getY(data[i]));
    }

    fillPath.lineTo(getX(data.length - 1), size.height);
    fillPath.close();

    // Draw gradient area below line
    fillPaint.shader = LinearGradient(
      colors: [color.withOpacity(0.24), color.withOpacity(0.0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => oldDelegate.data != data;
}

// Progress Ring Painter
class ProgressRingPainter extends CustomPainter {
  final double percentage;
  final Color color;

  ProgressRingPainter(this.percentage, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;

    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressRingPainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
