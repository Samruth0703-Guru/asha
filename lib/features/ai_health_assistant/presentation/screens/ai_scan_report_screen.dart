import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';

class AiScanReportScreen extends StatelessWidget {
  final Map<String, dynamic> report;
  final Uint8List imageBytes;
  final String patientName;

  const AiScanReportScreen({
    super.key,
    required this.report,
    required this.imageBytes,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final condition = report['condition'] ?? report['possibleDisease'] ?? 'Condition Detected';
    final severity = report['severity'] ?? 'Moderate';
    final confidence = report['confidence'] ?? '85%';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Screening Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Download PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading Premium PDF Report...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: MemoryImage(imageBytes),
                  ),
                  const SizedBox(height: 16),
                  Text(patientName, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // AI Result Card
            Card(
              color: severity == 'High' || severity == 'Critical' ? Colors.red.shade50 : const Color(0xffF4F1FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text('Detected Condition', style: GoogleFonts.inter(color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Text(
                      condition,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xff334155)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('Confidence', confidence, Icons.psychology_rounded),
                        _buildStat('Severity', severity, Icons.warning_rounded, color: severity == 'High' ? Colors.red : Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Actionable Steps
            _buildSectionTitle('Recommended Action'),
            _buildList(report['firstAid'] ?? report['immediateCare'] ?? ['Consult a doctor immediately']),
            const SizedBox(height: 16),
            
            _buildSectionTitle('Suggested Medicines'),
            _buildList(report['medicines'] ?? ['Ointments as prescribed by doctor']),
            const SizedBox(height: 24),
            
            // Warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emergency_rounded, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      report['emergencyWarningSigns'] ?? 'Visit hospital if condition worsens quickly.',
                      style: GoogleFonts.inter(color: Colors.red.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? const Color(0xff7C3AED)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildList(List<dynamic> items) {
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(item.toString(), style: GoogleFonts.inter(height: 1.5))),
          ],
        ),
      )).toList(),
    );
  }
}
