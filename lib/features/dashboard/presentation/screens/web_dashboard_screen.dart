import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WebDashboardScreen extends ConsumerStatefulWidget {
  const WebDashboardScreen({super.key});

  @override
  ConsumerState<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends ConsumerState<WebDashboardScreen> {
  String _activeRoute = 'Dashboard';
  MapType _mapType = MapType.normal;
  double _currentZoom = 12.0;
  GoogleMapController? _mapController;
  final String _googleMapsKey = 'AIzaSyBA9GgVEE6pcdWdKo2svvcP6zFc9Ds2bI8';

  bool get _isApiKeyMissing => _googleMapsKey.isEmpty || _googleMapsKey == 'YOUR_KEY_HERE';

  final Set<Marker> _villageMarkers = {
    const Marker(
      markerId: MarkerId('risk_cluster_1'),
      position: LatLng(9.9723, 78.1121),
      infoWindow: InfoWindow(title: 'High Risk Cluster: Alanganallur', snippet: '3 Mothers pending follow-up'),
    ),
    const Marker(
      markerId: MarkerId('risk_cluster_2'),
      position: LatLng(9.9760, 78.1150),
      infoWindow: InfoWindow(title: 'Anemia Cluster: North St', snippet: '2 Mothers pending Hb check'),
    ),
    const Marker(
      markerId: MarkerId('risk_cluster_3'),
      position: LatLng(9.9680, 78.1090),
      infoWindow: InfoWindow(title: 'Routine Care: West St', snippet: '5 Routine cases'),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 950;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final stats = statsAsync.value ?? DashboardStats(totalPatients: 0, pregnantMothers: 0, highRiskCases: 0, vaccinationsDone: 0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          // Sidebar Menu (Only visible on wide layouts)
          if (isDesktop) _buildSidebar(context),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(32),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 300),
                        child: _buildWelcomeHeader(),
                      ),
                      const SizedBox(height: 28),
                      
                      // Metric Cards Row
                      FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        child: _buildMetricGrid(stats),
                      ),
                      const SizedBox(height: 28),

                      // Graphs & Village Map Overviews
                      _buildMainChartsAndMapRow(isDesktop),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_rounded},
      {'title': 'Patients', 'icon': Icons.people_alt_rounded},
      {'title': 'Visits', 'icon': Icons.calendar_month_rounded},
      {'title': 'Pregnancies', 'icon': Icons.pregnant_woman_rounded},
      {'title': 'Vaccinations', 'icon': Icons.vaccines_rounded},
      {'title': 'Inventory', 'icon': Icons.inventory_2_outlined},
      {'title': 'AI Health Scan', 'icon': Icons.center_focus_strong_rounded},
      {'title': 'AI Health Assistant', 'icon': Icons.healing_rounded},
      {'title': 'Cancer Care', 'icon': Icons.shield_moon_outlined},
      {'title': 'Alerts', 'icon': Icons.notifications_active_rounded},
      {'title': 'SMS History', 'icon': Icons.sms_rounded},
      {'title': 'Reports', 'icon': Icons.document_scanner_rounded},
      {'title': 'Analytics', 'icon': Icons.bar_chart_rounded},
      {'title': 'Users', 'icon': Icons.admin_panel_settings_rounded},
      {'title': 'Settings', 'icon': Icons.settings_rounded},
    ];

    return Container(
      width: 260,
      color: const Color(0xFF1E293B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ASHA CARE+',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Block Console',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF334155)),

          // Sidebar Navigation List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final title = item['title'] as String;
                final isActive = _activeRoute == title;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isActive ? const Color(0xFFE6F4EA) : Colors.transparent,
                    leading: Icon(
                      item['icon'] as IconData,
                      color: isActive ? const Color(0xFF137333) : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    title: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? const Color(0xFF137333) : const Color(0xFF94A3B8),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _activeRoute = title;
                      });
                      if (title == 'Dashboard') context.go('/dashboard');
                      if (title == 'Patients') context.push('/patient-list');
                      if (title == 'Visits') context.push('/visit-planner');
                      if (title == 'Pregnancies') context.push('/patient-list?filter=Pregnant');
                      if (title == 'Vaccinations') context.push('/vaccination-calendar');
                      if (title == 'Inventory') context.push('/medicine-inventory');
                      if (title == 'AI Health Scan') context.push('/health-scan');
                      if (title == 'AI Health Assistant') context.push('/ai-health-assistant');
                      if (title == 'Cancer Care') context.push('/cancer-care');
                      if (title == 'Alerts') context.push('/notifications');
                      if (title == 'SMS History') context.push('/sms-history');
                      if (title == 'Reports') context.push('/reports');
                      if (title == 'Analytics') context.push('/district-analytics');
                      if (title == 'Users') context.push('/settings');
                      if (title == 'Settings') context.push('/settings');
                    },
                    dense: true,
                  ),
                );
              },
            ),
          ),

          // Campaign Banner Card at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF065F46).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CAMPAIGN INFO',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF34D399), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Make Every Mother Count, Every Life Matters.',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDqebMuKHIgqbWUAjgcnnREurIc6bWG6C3ja9tL197KVXSIETRj8_PL6Xg4LjI3Ys54eQBvSpUmTt76DGIvxD4Eb2GGmNFqCH_qi6mV2sn75KONjNOMzfV_4Zm3jRYTmaSh_9ZYokch8rhW5R2GkTym_mtpjOdKRFcTsA4ZX2kOnXiDegWtPQsGL9xE_dgScLwzrMo7mgzHf5_JWpUbkRNzvk-46esrVBXyzynL3s1B48PcCTwuT3ZYBQ',
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF334155)),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8)),
            title: Text(
              'Logout',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8)),
            ),
            onTap: () => context.go('/login'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_rounded, color: Color(0xFF94A3B8)),
              const SizedBox(width: 16),
              Container(
                width: 350,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search patients, villages, health records...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Stack(
                children: [
                  const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              const Icon(Icons.wb_sunny_outlined, color: Color(0xFF64748B)),
              const SizedBox(width: 20),
              Container(
                height: 24,
                width: 1,
                color: const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Dr. Rajesh', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      Text('MO - PHC', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDQQKDnoIW6yrZEUBwkiF_j7aWfb05QJiFhZg_kBkZosEJSEEVut6o3ELTRpUWUlJFufA7LVupVrKEtUtHaVHwMsCVnMdEN2r-YyzRJ0jWo6j2Cg6bOu2gHUi858MMmoTOBSFpc8RPMVlEwhH4_94IemhNSeUA4sW0X9S9bF7vh-rW9gkIg0HqrXnB2pnLRqdjCBAApY8QFyQr21tXqxMQu5gyFt_F9AvWje-nVoYhUCxFNPobRJFJLkg'),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Stack(
        children: [
          // Background consulting image
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 450,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBKagPQrRN5-FeXXpGNEfQT-I4XUN2v3HVzM_mR4mWnZOMZBnPDaGAdHWpBSsEf4QzANUt_HBIbcxisANbok6YRvVL0OvXYsa4dzNixGILml6ELAXGT6Bnk4cf9kmRzQUaS8jMFUnn2qmBEV3CwZVcoGZwYKhnwPiHpF53oN87h-pzdn3mBexeNiBOupBVcl7tn0PJO_UQxVBXBHOvDq0c0XUdq09M0H7Dxpr-YHG_9-2h523_tWA6MkA',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient fade
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white.withOpacity(0.9), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.55, 0.65, 1.0],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text('Welcome back, Doctor! ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF047857))),
                    const Text('👋', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome to ASHA Care Block Console',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'District PHC administrative center. Track community health, vaccine metrics, and clinic stock.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.push('/register-patient'),
                  icon: const Icon(Icons.person_add_rounded, size: 15),
                  label: const Text('Register New Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003D29),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(180, 46),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          // Date Overlay Badge
          Positioned(
            top: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              ),
              child: Column(
                children: [
                  Text('Today\'s Date', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 4),
                  Text('18 Jul 2025', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF003D29))),
                  const SizedBox(height: 2),
                  Text('Friday', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildStatCard('Total Patients', '${stats.totalPatients}', '1,204', '12% from last month', Icons.people_rounded, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
            _buildStatCard('Pregnant Mothers', '${stats.pregnantMothers}', '342', '8% from last month', Icons.pregnant_woman_rounded, const Color(0xFF059669), const Color(0xFFECFDF5)),
            _buildStatCard('Requires Clinic Check', '${stats.highRiskCases}', '28', '5% from last month', Icons.warning_rounded, const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
            _buildStatCard('Completed Immunizations', '${stats.vaccinationsDone}', '956', '15% from last month', Icons.vaccines_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String count, String value, String trend, IconData icon, Color color, Color bgIconColor) {
    return Container(
      width: 250,
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgIconColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 2),
                  Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF8FAFC), width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: color, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                CustomPaint(
                  size: const Size(60, 16),
                  painter: SparklinePainter(const [10.0, 15.0, 8.0, 20.0, 15.0, 25.0], color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChartsAndMapRow(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildMapOverviewCard(),
                const SizedBox(height: 28),
                _buildMonthlyVisitsCard(),
              ],
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildVaccinationDonutCard(),
                const SizedBox(height: 28),
                _buildAlertsCard(),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildMapOverviewCard(),
          const SizedBox(height: 28),
          _buildVaccinationDonutCard(),
          const SizedBox(height: 28),
          _buildMonthlyVisitsCard(),
          const SizedBox(height: 28),
          _buildAlertsCard(),
        ],
      );
    }
  }

  Widget _buildMapOverviewCard() {
    if (_isApiKeyMissing) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Village Health Overview', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dangerColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  '❌ Google Maps API Key is missing. Please configure it.',
                  style: GoogleFonts.inter(color: AppTheme.dangerColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
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
                  Text('Village Health Overview', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Risk clusters and follow-up map index representation.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
                ],
              ),
              Row(
                children: [
                  _mapModeButton('Normal', MapType.normal),
                  const SizedBox(width: 6),
                  _mapModeButton('Satellite', MapType.satellite),
                  const SizedBox(width: 6),
                  _mapModeButton('Terrain', MapType.terrain),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    mapType: _mapType,
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(9.9723, 78.1121),
                      zoom: 12.0,
                    ),
                    markers: _villageMarkers,
                    zoomControlsEnabled: true,
                    myLocationButtonEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onCameraMove: (position) {
                      setState(() {
                        _currentZoom = position.zoom;
                      });
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Zoom: ${_currentZoom.toStringAsFixed(1)}',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapModeButton(String title, MapType type) {
    final isSelected = _mapType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _mapType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildVaccinationDonutCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vaccination Coverage', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(color: AppTheme.secondaryColor, value: 78, title: '78%', radius: 24, showTitle: false),
                  PieChartSectionData(color: AppTheme.warningColor, value: 15, title: '15%', radius: 24, showTitle: false),
                  PieChartSectionData(color: AppTheme.dangerColor, value: 7, title: '7%', radius: 24, showTitle: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLegendRow('🟢 Completed (78%)', AppTheme.secondaryColor),
          _buildLegendRow('🟡 Pending (15%)', AppTheme.warningColor),
          _buildLegendRow('🔴 Missed (7%)', AppTheme.dangerColor),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMonthlyVisitsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Visits Progress', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 10),
                      FlSpot(1, 25),
                      FlSpot(2, 18),
                      FlSpot(3, 35),
                      FlSpot(4, 45),
                      FlSpot(5, 58),
                    ],
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 4,
                    belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withOpacity(0.05)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Alerts & Activities',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          _buildAlertItem(
            'High Risk Hb Alert',
            'Meena (PT003) Hb measured at 9.2 g/dL.',
            Icons.error_outline_rounded,
            AppTheme.dangerColor,
          ),
          _buildAlertItem(
            'Medicine Re-stock Needed',
            'Albendazole inventory threshold warning.',
            Icons.warehouse_rounded,
            AppTheme.warningColor,
          ),
          _buildAlertItem(
            'Cloud Synchronization Complete',
            'All offline records successfully uploaded.',
            Icons.cloud_done_rounded,
            AppTheme.secondaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String desc, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0f172a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
