import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedTab = 'All';

  final List<Map<String, dynamic>> _allNotifications = [
    {
      'id': '1',
      'type': 'alert',
      'title': 'Critical Hemoglobin Level',
      'body': 'Meena Karuppasamy (PT003) recorded 9.2 g/dL Hb. Verify IFA counts immediately.',
      'time': '10 mins ago',
      'isRead': false,
    },
    {
      'id': '2',
      'type': 'calendar',
      'title': 'Vaccination Session Due',
      'body': 'Weekly immunization camp at Kulamangalam Sub-Centre starts tomorrow at 9:00 AM.',
      'time': '2 hours ago',
      'isRead': false,
    },
    {
      'id': '3',
      'type': 'sync',
      'title': 'Sync Queue Completed',
      'body': 'All 5 local patient registration records successfully pushed to district cloud.',
      'time': '5 hours ago',
      'isRead': true,
    },
    {
      'id': '4',
      'type': 'alert',
      'title': 'High BP Warning',
      'body': 'Rajeshwari Devi (PT001) systolic BP is 138. Scheduling referral checklist follow-up.',
      'time': '1 day ago',
      'isRead': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedTab == 'All') return _allNotifications;
    if (_selectedTab == 'Alerts') return _allNotifications.where((n) => n['type'] == 'alert').toList();
    if (_selectedTab == 'Updates') return _allNotifications.where((n) => n['type'] != 'alert').toList();
    return _allNotifications;
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'calendar':
        return Icons.calendar_today_rounded;
      default:
        return Icons.sync_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'alert':
        return AppTheme.dangerColor;
      case 'calendar':
        return AppTheme.primaryColor;
      default:
        return AppTheme.secondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Notifications Center', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: ['All', 'Alerts', 'Updates'].map((tab) {
                final selected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tab,
                        style: GoogleFonts.inter(
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          color: selected ? AppTheme.primaryColor : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: _filteredNotifications.length,
              itemBuilder: (context, index) {
                final notif = _filteredNotifications[index];
                final iconColor = _getColor(notif['type']);

                return FadeInRight(
                  duration: Duration(milliseconds: 250 + (index * 80)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: iconColor.withOpacity(0.1),
                          child: Icon(_getIcon(notif['type']), color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    notif['title'],
                                    style: GoogleFonts.inter(
                                      fontWeight: notif['isRead'] ? FontWeight.w600 : FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    notif['time'],
                                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif['body'],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
