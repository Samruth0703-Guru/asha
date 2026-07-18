import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/cancer_ai_service.dart';
import 'cancer_dashboard_screen.dart';

class CancerVisionScreeningScreen extends ConsumerStatefulWidget {
  const CancerVisionScreeningScreen({super.key});

  @override
  ConsumerState<CancerVisionScreeningScreen> createState() => _CancerVisionScreeningScreenState();
}

class _CancerVisionScreeningScreenState extends ConsumerState<CancerVisionScreeningScreen> {
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  
  String _imageCategory = 'Oral lesions';
  final List<String> _categories = [
    'Oral lesions',
    'Breast skin abnormalities',
    'Skin wounds',
    'Suspicious visible growths'
  ];

  bool _isScanning = false;
  Map<String, dynamic>? _scanResult;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageFile = picked;
          _imageBytes = bytes;
          _scanResult = null; // Clear previous result
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or capture an image first.'), backgroundColor: AppTheme.dangerColor),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    final aiService = ref.read(cancerAiServiceProvider);

    try {
      final result = await aiService.analyzeCancerImage(_imageBytes!, _imageCategory);
      setState(() {
        _scanResult = result;
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini Vision scan completed successfully!'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Vision Analysis failed: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  Color _getSeverityColor(String? severity) {
    if (severity == null) return Colors.grey;
    switch (severity.toLowerCase()) {
      case 'low':
        return AppTheme.secondaryColor;
      case 'moderate':
      case 'medium':
        return AppTheme.warningColor;
      case 'high':
        return Colors.orange.shade700;
      case 'critical':
        return AppTheme.dangerColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('AI Image Screening', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Category selector
            Text('Anomaly Category Selection', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _imageCategory,
              dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
              decoration: const InputDecoration(
                labelText: 'Select Observation Area',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem<String>(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _imageCategory = val!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Image Preview box
            Text('Visual Intake', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08), width: 1.5),
              ),
              child: _imageBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 14),
                        Text(
                          'No photo selected',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: kIsWeb
                          ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                          : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 20),

            // Camera / Upload Action Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Upload Image'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Analyze button
            ElevatedButton.icon(
              onPressed: _isScanning || _imageBytes == null ? null : _analyzeImage,
              icon: _isScanning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.center_focus_strong_rounded),
              label: Text(_isScanning ? 'Gemini Visual Screening...' : 'Screen Image using Gemini Vision'),
            ),
            const SizedBox(height: 32),

            // Vision Diagnosis Results Card
            if (_scanResult != null)
              FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: _buildVisionResultCard(isDark),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildVisionResultCard(bool isDark) {
    final cond = _scanResult!['condition'] ?? 'Unknown Lesion';
    final conf = _scanResult!['confidence'] ?? 'N/A';
    final sev = _scanResult!['severity'] ?? 'Moderate';
    final causes = List<String>.from(_scanResult!['possibleCauses'] ?? []);
    final steps = List<String>.from(_scanResult!['suggestedNextSteps'] ?? []);
    final refRec = _scanResult!['referral'] ?? 'Consult local specialist';
    final disclaimer = _scanResult!['disclaimer'] ?? 'AI-generated screening only. Consult doctor.';
    final color = _getSeverityColor(sev);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.4), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Condition name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI IMAGE OBSERVATION',
                      style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cond,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xff1e293b),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Severity: $sev',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Gemini AI Confidence Score: $conf',
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
            ),
            const Divider(height: 32),

            // Possible causes
            if (causes.isNotEmpty) ...[
              Text(
                'Possible Contributing Causes:',
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...causes.map((cause) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right_rounded, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cause,
                            style: GoogleFonts.inter(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
            ],

            // Clinical Steps
            if (steps.isNotEmpty) ...[
              Text(
                'Suggested Next Steps:',
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...steps.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: color, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step,
                            style: GoogleFonts.inter(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
            ],

            // Referral Slips
            Text(
              'Referral Recommendation:',
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              refRec,
              style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xff475569)),
            ),
            const Divider(height: 36),

            // Mandatory disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.dangerColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: AppTheme.dangerColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      disclaimer,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dangerColor,
                      ),
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
}
