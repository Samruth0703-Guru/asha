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
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo Section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.medical_services_rounded, color: AppTheme.primaryColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  'ASHA CARE+',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Sidebar Navigation List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final title = item['title'] as String;
                final isActive = _activeRoute == title;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isActive ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent,
                    leading: Icon(
                      item['icon'] as IconData,
                      color: isActive ? AppTheme.primaryColor : Colors.grey,
                      size: 20,
                    ),
                    title: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? AppTheme.primaryColor : const Color(0xff0f172a),
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

          // Logout Action
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: const Icon(Icons.logout_rounded, color: AppTheme.dangerColor),
            title: Text(
              'Logout',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dangerColor),
            ),
            onTap: () => context.go('/login'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search box
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search patients, villages...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Profile area
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.grey),
                onPressed: () => context.push('/notifications'),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=150'),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Dr. Rajesh', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('MO - PHC', style: GoogleFonts.inter(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
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
      height: 240,
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
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Welcome to ASHA Care Block Console',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'District PHC administrative center. Track community health, vaccine metrics, and clinic stock.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => context.push('/register-patient'),
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Register Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
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
            _buildStatCard('Total Patients', '${stats.totalPatients}', 'Registered patients', Icons.people_rounded, AppTheme.primaryColor, 'card_patients.png'),
            _buildStatCard('Pregnant Mothers', '${stats.pregnantMothers}', 'Maternal care cases', Icons.child_care_rounded, AppTheme.secondaryColor, 'card_maternal.png'),
            _buildStatCard('High Risk Cases', '${stats.highRiskCases}', 'Requires clinic check', Icons.error_outline_rounded, AppTheme.dangerColor, 'card_highrisk.png'),
            _buildStatCard('Vaccinations Done', '${stats.vaccinationsDone}', 'Completed immunizations', Icons.vaccines_rounded, AppTheme.warningColor, 'card_vaccination.png'),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, String trend, IconData icon, Color color, String bgImage) {
    return Container(
      width: 250,
      height: 160,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Stack(
        children: [
          // Background photo with reduced opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.network(
                bgImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.white),
              ),
            ),
          ),
          // White overlay to soften the image further
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.65),
                    Colors.white.withOpacity(0.35),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Text(
                      trend,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0f172a),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff475569),
                  ),
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
