import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ExportMenu extends ConsumerWidget {
  const ExportMenu({super.key});

  void _handleExport(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting analytics data as $type...'),
        backgroundColor: const Color(0xffA476FF),
        duration: const Duration(seconds: 2),
      ),
    );
    // In a real app, generate the PDF/CSV and trigger a download using url_launcher or dart:html
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleExport(context, value),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      offset: const Offset(0, 48),
      tooltip: 'Export Analytics',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.download_rounded, size: 18, color: Color(0xff64748B)),
            const SizedBox(width: 8),
            Text(
              'Export',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xff64748B),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildPopupItem('PDF', Icons.picture_as_pdf_rounded, Colors.red.shade400),
        _buildPopupItem('CSV', Icons.table_chart_rounded, Colors.green.shade400),
        _buildPopupItem('PNG', Icons.image_rounded, Colors.blue.shade400),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String title, IconData icon, Color iconColor) {
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xff334155),
            ),
          ),
        ],
      ),
    );
  }
}
