import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../sms/controllers/sms_controller.dart';
import '../../../../core/database/local_database.dart';

class VaccinationCalendarScreen extends ConsumerStatefulWidget {
  const VaccinationCalendarScreen({super.key});

  @override
  ConsumerState<VaccinationCalendarScreen> createState() => _VaccinationCalendarScreenState();
}

class _VaccinationCalendarScreenState extends ConsumerState<VaccinationCalendarScreen> {
  final List<_MockVaccination> _vaccinations = [];

  void _triggerSMSReminder(_MockVaccination vac) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending SMS Reminder to ${vac.patientName}...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );

    final patient = Patient(
      id: 'PT-${vac.id}',
      isPregnant: false,
      vaccinationRequired: false,
      name: vac.patientName,
      dob: DateTime(2000, 1, 1),
      gender: 'Female',
      phone: vac.phone,
      village: vac.village,
      isHighRisk: false,
      previousPregnancies: 0,
      riskLevel: 'Low',
      confidenceScore: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref.read(smsControllerProvider.notifier).sendVaccinationReminder(patient);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'SMS Reminder successfully sent to ${vac.patientName}!'
            : 'Failed to send SMS reminder to ${vac.patientName}.'
          ),
          backgroundColor: success ? AppTheme.secondaryColor : AppTheme.dangerColor,
        ),
      );
    }
  }

  void _markAsAdministered(String id) {
    setState(() {
      final index = _vaccinations.indexWhere((element) => element.id == id);
      if (index != -1) {
        _vaccinations[index] = _vaccinations[index].copyWith(status: 'Completed');
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vaccine status updated to administered.'),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _vaccinations.where((v) => v.status == 'Pending').toList();
    final missed = _vaccinations.where((v) => v.status == 'Missed').toList();
    final completed = _vaccinations.where((v) => v.status == 'Completed').toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Vaccination Tracker', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'Due (Upcoming)'),
              Tab(text: 'Missed Alerts'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Due Tab
            _buildVaccineList(pending, isDark),
            // Missed Tab
            _buildVaccineList(missed, isDark),
            // Completed Tab
            _buildVaccineList(completed, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccineList(List<_MockVaccination> list, bool isDark) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vaccines_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No vaccine schedules found', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final vac = list[index];
        final isCompleted = vac.status == 'Completed';
        final isMissed = vac.status == 'Missed';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vac.patientName,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.secondaryColor.withOpacity(0.1)
                            : isMissed
                                ? AppTheme.dangerColor.withOpacity(0.1)
                                : AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vac.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? AppTheme.secondaryColor
                              : isMissed
                                  ? AppTheme.dangerColor
                                  : AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Vaccine: ${vac.vaccineName}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('Due Date: ${vac.dueDate.year}-${vac.dueDate.month.toString().padLeft(2, '0')}-${vac.dueDate.day.toString().padLeft(2, '0')}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                Text('Village: ${vac.village}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isCompleted) ...[
                      OutlinedButton.icon(
                        onPressed: () => _triggerSMSReminder(vac),
                        icon: const Icon(Icons.sms_outlined, size: 16),
                        label: const Text('Send SMS'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(100, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _markAsAdministered(vac.id),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          minimumSize: const Size(100, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Administered successfully',
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MockVaccination {
  final String id;
  final String patientName;
  final String vaccineName;
  final DateTime dueDate;
  final String status;
  final String village;
  final String phone;

  _MockVaccination({
    required this.id,
    required this.patientName,
    required this.vaccineName,
    required this.dueDate,
    required this.status,
    required this.village,
    required this.phone,
  });

  _MockVaccination copyWith({String? status}) {
    return _MockVaccination(
      id: id,
      patientName: patientName,
      vaccineName: vaccineName,
      dueDate: dueDate,
      status: status ?? this.status,
      village: village,
      phone: phone,
    );
  }
}
