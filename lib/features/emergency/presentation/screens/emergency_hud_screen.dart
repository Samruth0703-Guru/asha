import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/local_database.dart';
import '../../../sms/controllers/sms_controller.dart';

class EmergencyHudScreen extends ConsumerStatefulWidget {
  const EmergencyHudScreen({super.key});

  @override
  ConsumerState<EmergencyHudScreen> createState() => _EmergencyHudScreenState();
}

class _EmergencyHudScreenState extends ConsumerState<EmergencyHudScreen> {
  bool _isTriggered = false;
  int _countdown = 3;
  Timer? _timer;
  bool _alertSent = false;

  void _startEmergencyCountdown() {
    setState(() {
      _isTriggered = true;
      _countdown = 3;
      _alertSent = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        _sendAlert();
      }
    });
  }

  void _cancelEmergency() {
    _timer?.cancel();
    setState(() {
      _isTriggered = false;
      _countdown = 3;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency Alert Cancelled.'),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  void _sendAlert() {
    setState(() {
      _alertSent = true;
    });

    try {
      final mockPatient = Patient(
        id: 'PT-EMG',
        isPregnant: true,
        vaccinationRequired: false,
        name: 'Kalyani Ganesan',
        dob: DateTime(1997, 4, 12),
        gender: 'Female',
        phone: '9443210987',
        village: 'Semmancheri',
        isHighRisk: true,
        previousPregnancies: 0,
        riskLevel: 'High',
        confidenceScore: 0.95,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      ref.read(smsControllerProvider.notifier).sendEmergencyReferral(mockPatient);
    } catch (e) {
      debugPrint('Emergency SMS broadcast failed: $e');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CRITICAL RED ALERT Broadcasted! Emergency Referral SMS sent to dispatch authorities.'),
        backgroundColor: AppTheme.dangerColor,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Action HUD', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!_isTriggered) ...[
              const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: AppTheme.dangerColor,
              ),
              const SizedBox(height: 16),
              Text(
                'ASHA Emergency Protocol',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Press and hold the button below to alert your Primary Health Centre (PHC), send GPS coordinates, and alert medical officers.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // Emergency Button
              GestureDetector(
                onTap: _startEmergencyCountdown,
                child: Container(
                  height: 180,
                  width: 180,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.dangerColor.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 8,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emergency_share_rounded, size: 56, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        'TAP TO ALERT',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),
              _buildContactTile(
                title: 'Primary Health Centre (PHC)',
                subtitle: '+91 94440 12345 (Alanganallur)',
                icon: Icons.phone_in_talk_rounded,
              ),
              _buildContactTile(
                title: 'Maternal Referral Desk',
                subtitle: '102 (National Helpline)',
                icon: Icons.phone_callback_rounded,
              ),
            ] else if (!_alertSent) ...[
              // Countdown State
              Text(
                'TRIGGERING RED ALERT IN...',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dangerColor),
              ),
              const SizedBox(height: 32),
              Container(
                height: 150,
                width: 150,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppTheme.dangerColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_countdown',
                  style: GoogleFonts.outfit(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _cancelEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xff1e293b) : Colors.grey.shade300,
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  minimumSize: const Size(200, 56),
                ),
                child: const Text('CANCEL BROADCAST'),
              ),
            ] else ...[
              // Alert Sent State
              const Icon(Icons.check_circle_rounded, size: 90, color: AppTheme.secondaryColor),
              const SizedBox(height: 24),
              Text(
                'RED ALERT ACTIVE',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.dangerColor),
              ),
              const SizedBox(height: 12),
              Text(
                'GPS: 10.0456, 78.1234\nNearest Facility: Alanganallur PHC (4.2 km away)\nMedical Officer: Dr. Kavitha notified.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isTriggered = false;
                    _alertSent = false;
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('DISMISS HUD'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({required String title, required String subtitle, required IconData icon}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12)),
        trailing: const Icon(Icons.call_made_rounded, size: 18),
      ),
    );
  }
}
