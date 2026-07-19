import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanHistoryComparer extends StatelessWidget {
  final Map<String, dynamic> currentScan;
  final Map<String, dynamic> previousScan;

  const ScanHistoryComparer({
    super.key,
    required this.currentScan,
    required this.previousScan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Healing Progress Comparison')),
      body: Row(
        children: [
          Expanded(
            child: _buildScanPanel(
              title: 'Previous Scan',
              date: '2 weeks ago',
              scanData: previousScan,
              isCurrent: false,
            ),
          ),
          Container(width: 2, color: Colors.grey.shade200),
          Expanded(
            child: _buildScanPanel(
              title: 'Current Scan',
              date: 'Today',
              scanData: currentScan,
              isCurrent: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanPanel({
    required String title,
    required String date,
    required Map<String, dynamic> scanData,
    required bool isCurrent,
  }) {
    final condition = scanData['analysis']?['condition'] ?? scanData['analysis']?['possibleDisease'] ?? 'Unknown';
    final severity = scanData['analysis']?['severity'] ?? 'Moderate';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: isCurrent ? const Color(0xff7C3AED) : Colors.grey.shade700)),
          Text(date, style: GoogleFonts.inter(color: Colors.grey)),
          const SizedBox(height: 24),
          
          if (scanData['imageUrl'] != null && scanData['imageUrl'].toString().startsWith('http'))
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                scanData['imageUrl'],
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 300,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                ),
              ),
            ),
            
          const SizedBox(height: 24),
          Text('Detected Condition', style: GoogleFonts.inter(color: Colors.grey)),
          Text(condition, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Severity Level', style: GoogleFonts.inter(color: Colors.grey)),
          Container(
            margin: const EdgeInsets.top: 4,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: severity == 'High' ? Colors.red.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              severity,
              style: TextStyle(
                color: severity == 'High' ? Colors.red.shade900 : Colors.orange.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
