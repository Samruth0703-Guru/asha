import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _syncWifiOnly = true;
  bool _pushNotifications = true;
  bool _anemiaAlerts = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Settings Console', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          // ASHA Worker Profile Info
          FadeInDown(
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text('LS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lakshmi Sundaram', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('ASHA Worker ID: IN-AN8819', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                        Text('Sub-Centre: Alanganallur Block', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Synchronization preferences
          Text('System Preferences', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          FadeInUp(
            duration: const Duration(milliseconds: 250),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Synchronize via Wi-Fi only'),
                    subtitle: const Text('Prevents background cellular data consumption.'),
                    value: _syncWifiOnly,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) => setState(() => _syncWifiOnly = val),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Language Settings'),
                    subtitle: Text('Current language: $_selectedLanguage'),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      underline: Container(),
                      items: ['English', 'Tamil (தமிழ்)', 'Hindi (हिंदी)'].map((l) {
                        return DropdownMenuItem(value: l, child: Text(l));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedLanguage = val ?? 'English'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Notifications Preferences
          Text('Alert Configurations', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          FadeInUp(
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Push Notifications Alerts'),
                    value: _pushNotifications,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('Severe Anemia Notifications'),
                    value: _anemiaAlerts,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) => setState(() => _anemiaAlerts = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Storage Actions
          Text('Database Operations', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          FadeInUp(
            duration: const Duration(milliseconds: 350),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_sweep_rounded, color: AppTheme.dangerColor),
                title: const Text('Clear Sync Cache logs', style: TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.bold)),
                subtitle: const Text('Clears local SQLite synchronized events archive.'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cleared sync logs cache safely.'),
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
