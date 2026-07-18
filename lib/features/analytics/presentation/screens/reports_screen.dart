import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedMonth = 'July 2026';
  String _selectedVillage = 'All Villages';

  final List<Map<String, dynamic>> _reportTemplates = [
    {
      'title': 'Monthly Sub-Centre Report (Form 6)',
      'desc': 'Consolidated maternal indicators, immunizations & vital registrations.',
      'size': '1.2 MB',
      'format': 'PDF',
    },
    {
      'title': 'Anemia Screener Log Sheet',
      'desc': 'Detailed patient Hb level trends, IFA counts & high-risk referrals.',
      'size': '840 KB',
      'format': 'EXCEL',
    },
    {
      'title': 'Weekly Immunization Microplan',
      'desc': 'List of infants, vaccines due, doses, & location maps.',
      'size': '450 KB',
      'format': 'PDF',
    },
    {
      'title': 'ASHA Compensation & Tour Log',
      'desc': 'Self-reported visits records & compensation claiming slips.',
      'size': '310 KB',
      'format': 'PDF',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Health Reports Hub', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Configurations Card
            Text('Report Generation Filters', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedMonth,
                          decoration: const InputDecoration(labelText: 'Reporting Month'),
                          items: ['June 2026', 'July 2026', 'August 2026'].map((m) {
                            return DropdownMenuItem(value: m, child: Text(m));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedMonth = val ?? 'July 2026'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedVillage,
                          decoration: const InputDecoration(labelText: 'Village Block'),
                          items: ['All Villages', 'Alanganallur', 'Kulamangalam', 'Paravai'].map((v) {
                            return DropdownMenuItem(value: v, child: Text(v));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedVillage = val ?? 'All Villages'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Templates list
            Text('Available Administrative Formats', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...List.generate(_reportTemplates.length, (index) {
              final rep = _reportTemplates[index];
              final isPdf = rep['format'] == 'PDF';
              return FadeInUp(
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
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isPdf ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isPdf ? Icons.picture_as_pdf_rounded : Icons.table_view_rounded,
                          color: isPdf ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rep['title'],
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rep['desc'],
                              style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Size: ${rep['size']} • Format: ${rep['format']}',
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Downloading ${rep['title']} for $_selectedMonth...'),
                              backgroundColor: AppTheme.secondaryColor,
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
