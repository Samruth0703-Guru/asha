import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiInsightsPanel extends StatelessWidget {
  final List<String> insights;

  const AiInsightsPanel({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffA476FF).withOpacity(0.3), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xffF4F1FF).withOpacity(0.4),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xffA476FF), size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Analytics Insights',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffA476FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (insights.isEmpty)
            Text(
              'Analyzing data...',
              style: GoogleFonts.inter(color: Colors.grey, fontStyle: FontStyle.italic),
            )
          else
            ...insights.map((insight) => _buildInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xffA476FF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xff334155),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
