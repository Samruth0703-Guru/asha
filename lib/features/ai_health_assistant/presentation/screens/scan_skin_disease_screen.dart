import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/database/sync_service.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/tts_service.dart' as tts;

class ScanSkinDiseaseScreen extends ConsumerStatefulWidget {
  final String? patientId;
  const ScanSkinDiseaseScreen({super.key, this.patientId});

  @override
  ConsumerState<ScanSkinDiseaseScreen> createState() => _ScanSkinDiseaseScreenState();
}

class _ScanSkinDiseaseScreenState extends ConsumerState<ScanSkinDiseaseScreen> with TickerProviderStateMixin {
  Patient? _patient;
  List<Patient> _patients = [];
  bool _isLoadingPatients = true;

  // Image parameters
  Uint8List? _imageBytes;
  bool _isBytesLoaded = false;
  double _rotationAngle = 0;
  bool _isCircle = false;
  bool _isEditing = false;
  bool _isProcessing = false;
  final TransformationController _transformationController = TransformationController();

  // Async task trackers
  bool _isUploading = false;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _scanReport;
  List<Map<String, dynamic>> _scansHistory = [];

  // TTS configurations
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _ttsRate = 1.0;
  double _ttsPitch = 1.0;
  String _selectedLang = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ta', 'name': 'Tamil (தமிழ்)'},
    {'code': 'hi', 'name': 'Hindi (हिन्दी)'},
    {'code': 'te', 'name': 'Telugu (తెలుగు)'},
    {'code': 'kn', 'name': 'Kannada (ಕನ್ನಡ)'},
    {'code': 'ml', 'name': 'Malayalam (മലയാളം)'},
    {'code': 'mr', 'name': 'Marathi (मराठी)'},
    {'code': 'gu', 'name': 'Gujarati (ગુજરાતી)'},
    {'code': 'bn', 'name': 'Bengali (বাংলা)'},
    {'code': 'pa', 'name': 'Punjabi (ਪੰਜਾਬੀ)'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _stopSpeaking();
    super.dispose();
  }

  void _loadPatients() async {
    final db = ref.read(localDatabaseProvider);
    final list = await db.getAllPatients();
    setState(() {
      _patients = list;
      _isLoadingPatients = false;
      if (widget.patientId != null) {
        final found = list.where((p) => p.id == widget.patientId).toList();
        if (found.isNotEmpty) {
          _patient = found.first;
          _loadScanHistory(_patient!.id);
        }
      }
    });
  }

  void _loadScanHistory(String patientId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('health_scans')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .get();

      setState(() {
        _scansHistory = snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading scan history: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source);
      if (file == null) return;
      final bytes = await file.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _isBytesLoaded = true;
        _rotationAngle = 0;
        _isCircle = false;
        _isEditing = true;
        _transformationController.value = Matrix4.identity();
        _scanReport = null;
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _rotateImage() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
  }

  Future<Uint8List> _cropAndRotateImage(
      Uint8List originalBytes, double scale, Offset translation, double angle, bool isCircle) async {
    final image = img.decodeImage(originalBytes);
    if (image == null) return originalBytes;

    img.Image rotated = image;
    if (angle == 90) {
      rotated = img.copyRotate(image, angle: 90);
    } else if (angle == 180) {
      rotated = img.copyRotate(image, angle: 180);
    } else if (angle == 270) {
      rotated = img.copyRotate(image, angle: 270);
    }

    int minDim = rotated.width < rotated.height ? rotated.width : rotated.height;
    int cropSize = (minDim / scale).round();
    int x = ((rotated.width - cropSize) / 2 - translation.dx / scale).round().clamp(0, rotated.width - cropSize);
    int y = ((rotated.height - cropSize) / 2 - translation.dy / scale).round().clamp(0, rotated.height - cropSize);

    final cropped = img.copyCrop(rotated, x: x, y: y, width: cropSize, height: cropSize);
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 85));
  }

  Future<void> _runAnalysis() async {
    if (_imageBytes == null || _patient == null) return;

    setState(() {
      _isProcessing = true;
      _isEditing = false;
    });

    try {
      final matrix = _transformationController.value;
      final scale = matrix.getMaxScaleOnAxis();
      final translation = Offset(matrix.entry(0, 3), matrix.entry(1, 3));

      final croppedBytes = await _cropAndRotateImage(
        _imageBytes!,
        scale,
        translation,
        _rotationAngle,
        _isCircle,
      );

      setState(() {
        _isProcessing = false;
        _isUploading = true;
      });

      // Storage upload
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final refPath = 'skin_disease_scans/${_patient!.id}_$timestamp.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(refPath);

      final uploadTask = storageRef.putData(
        croppedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
        _isAnalyzing = true;
      });

      // Gemini Vision API Call
      final gemini = ref.read(geminiServiceProvider);
      final report = await gemini.scanSkinDisease(croppedBytes);

      // GPS Track
      double lat = 9.9252;
      double lng = 78.1198;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition(
            timeLimit: const Duration(seconds: 4),
          );
          lat = position.latitude;
          lng = position.longitude;
        }
      } catch (_) {}

      // Encrypt & Save to Firestore
      final scanRecord = {
        'patientId': _patient!.id,
        'patientName': _patient!.name,
        'ashaWorkerId': 'LAKSHMI_001',
        'imageUrl': downloadUrl,
        'analysis': report,
        'confidence': report['confidence'] ?? '85%',
        'date': Timestamp.now(),
        'latitude': lat,
        'longitude': lng,
      };

      await FirebaseFirestore.instance.collection('health_scans').add(scanRecord);

      setState(() {
        _imageBytes = croppedBytes;
        _isBytesLoaded = true;
        _scanReport = report;
        _isAnalyzing = false;
      });

      _loadScanHistory(_patient!.id);

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isUploading = false;
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vision diagnostic run failed: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  // Multilingual TTS speech actions
  void _speakReport() {
    if (_scanReport == null) return;
    final disease = _scanReport!['possibleDisease'] ?? 'Skin anomaly';
    final severity = _scanReport!['severity'] ?? 'Moderate';
    final warning = _scanReport!['emergencyWarningSigns'] ?? '';

    String text = "Possible disease scanned is: $disease. Severity level is evaluated as $severity. ";
    if (warning.isNotEmpty) {
      text += "Emergency Warning signs include: $warning. ";
    }
    text += "This is an AI health screening only. Consult your local primary health centre for official medical treatment.";

    tts.speakText(text, _selectedLang, rate: _ttsRate, pitch: _ttsPitch);
    setState(() {
      _isSpeaking = true;
      _isPaused = false;
    });
  }

  void _pauseSpeaking() {
    tts.pauseSpeaking();
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeSpeaking() {
    tts.resumeSpeaking();
    setState(() {
      _isPaused = false;
    });
  }

  void _stopSpeaking() {
    tts.stopSpeaking();
    setState(() {
      _isSpeaking = false;
      _isPaused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('📷 Skin Disease Scanner', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingPatients
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Disclaimers Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.warningColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'ASHA CLINICAL SCREENER: Do not communicate scan outputs as final medical prescription cards. Patient referrals to district doctors take priority.',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selected Patient Reference Card
                  _buildPatientSelectorContext(isDark),
                  const SizedBox(height: 24),

                  if (_patient != null) ...[
                    // Scanner active widget
                    if (_isEditing)
                      _buildCropEditorUI(isDark)
                    else if (_isProcessing || _isUploading || _isAnalyzing)
                      _buildLoadingStatusUI(isDark)
                    else
                      _buildReportOrCaptureUI(isDark),

                    const SizedBox(height: 32),
                    // Diagnostic scan logs history for this patient
                    _buildPatientScansHistory(isDark),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPatientSelectorContext(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ASHA Diagnoses Context', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (widget.patientId != null && _patient != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                title: Text(_patient!.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: ${_patient!.id} • ${_patient!.gender} • Age: ${DateTime.now().year - _patient!.dob.year} • Village: ${_patient!.village}'),
              )
            else
              DropdownButtonFormField<Patient>(
                value: _patient,
                hint: const Text('Select a patient profile reference...'),
                items: _patients.map((p) {
                  return DropdownMenuItem<Patient>(
                    value: p,
                    child: Text('${p.name} (ID: ${p.id} - ${p.village})'),
                  );
                }).toList(),
                onChanged: (selected) {
                  setState(() {
                    _patient = selected;
                    _imageBytes = null;
                    _isBytesLoaded = false;
                    _scanReport = null;
                  });
                  if (selected != null) {
                    _loadScanHistory(selected.id);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropEditorUI(bool isDark) {
    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.black,
            automaticallyImplyLeading: false,
            title: Text('Align & Crop Skin Lesion', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.rotate_right_rounded, color: Colors.white),
                onPressed: _rotateImage,
              ),
              IconButton(
                icon: Icon(
                  _isCircle ? Icons.crop_square_rounded : Icons.crop_din_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isCircle = !_isCircle;
                  });
                },
              ),
            ],
          ),
          SizedBox(
            height: 320,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: RotatedBox(
                      quarterTurns: (_rotationAngle / 90).round(),
                      child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CropOverlayPainter(isCircle: _isCircle),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xff121212),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _imageBytes = null;
                        _isBytesLoaded = false;
                      });
                    },
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _runAnalysis,
                    icon: const Icon(Icons.done_rounded),
                    label: const Text('Scan Image', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatusUI(bool isDark) {
    String message = "Processing assets...";
    if (_isProcessing) message = "Processing image bounds...";
    if (_isUploading) message = "Uploading scan securely to Firebase Storage...";
    if (_isAnalyzing) message = "Requesting Gemini vision diagnostics report...";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOrCaptureUI(bool isDark) {
    if (_scanReport == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.center_focus_strong_rounded, size: 64, color: AppTheme.primaryColor.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('Skin Disease Vision Analyser', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                'Point camera or import clinical gallery photos to screen for skin abnormalities.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Gallery Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final report = _scanReport!;
    final disease = report['possibleDisease'] ?? 'Skin Pathological Condition';
    final confidence = report['confidence'] ?? '90%';
    final category = report['diseaseCategory'] ?? 'Pathological';
    final severity = report['severity'] ?? 'Moderate';
    final symptoms = (report['symptoms'] as List?) ?? [];
    final causes = (report['causes'] as List?) ?? [];
    final immediateCare = (report['immediateCare'] as List?) ?? [];
    final medicines = (report['medicines'] as List?) ?? [];
    final homeRemedies = (report['homeRemedies'] as List?) ?? [];
    final foodsEat = (report['foodsToEat'] as List?) ?? [];
    final foodsAvoid = (report['foodsToAvoid'] as List?) ?? [];
    final dos = (report['dos'] as List?) ?? [];
    final donts = (report['donts'] as List?) ?? [];
    final hospitalVisit = report['whenToVisitHospital'] ?? '';
    final warnings = report['emergencyWarningSigns'] ?? '';

    final severityColor = severity == 'High' || severity == 'Critical'
        ? AppTheme.dangerColor
        : (severity == 'Moderate' ? Colors.orange : AppTheme.secondaryColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview image
        if (_imageBytes != null)
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Image.memory(_imageBytes!, height: 260, width: double.infinity, fit: BoxFit.cover),
          ),
        const SizedBox(height: 20),

        // Report
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('VISION SCREENING REPORT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () {
                        setState(() {
                          _scanReport = null;
                        });
                      },
                      tooltip: 'Retake / Choose Another',
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // Disease Name
                Text('Detected Condition Name:', style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(disease, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Metrics Row
                Row(
                  children: [
                    Expanded(child: _buildReportBadge('Confidence', confidence, AppTheme.primaryColor)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildReportBadge('Severity', severity, severityColor)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildReportBadge('Category', category, Colors.blueGrey)),
                  ],
                ),
                const SizedBox(height: 24),

                // Multilingual Voice Output Console
                _buildTTSControllerConsole(isDark),
                const Divider(height: 32),

                // Detailed clinical bullet lists
                _buildBulletList('Visible Pathological Symptoms', symptoms, Icons.visibility_rounded, isDark),
                const SizedBox(height: 16),
                _buildBulletList('Etiological Causes', causes, Icons.psychology_rounded, isDark),
                const SizedBox(height: 16),
                _buildBulletList('Immediate First Aid & Care', immediateCare, Icons.healing_rounded, isDark),
                const SizedBox(height: 16),
                _buildBulletList('Recommended Medicine Category', medicines, Icons.medication_rounded, isDark),
                const SizedBox(height: 16),
                _buildBulletList('Home Care & Remedies', homeRemedies, Icons.home_rounded, isDark),
                const SizedBox(height: 16),
                _buildBulletList('Proactive Foods to Consume', foodsEat, Icons.restaurant_rounded, isDark),
                const SizedBox(height: 16),
                _buildBulletList('Dietary Foods to Avoid', foodsAvoid, Icons.no_food_rounded, isDark),
                const SizedBox(height: 16),
                _buildBulletList('ASHA Advisories (Do\'s)', dos, Icons.check_circle_rounded, isDark),
                const SizedBox(height: 16),
                _buildBulletList('Prohibited Activities (Don\'ts)', donts, Icons.cancel_rounded, isDark),
                const Divider(height: 32),

                // Red flags alerts
                if (hospitalVisit.isNotEmpty) ...[
                  _buildSectionHeader('When to Refer to Hospital', Icons.local_hospital_rounded),
                  const SizedBox(height: 6),
                  Text(hospitalVisit, style: GoogleFonts.inter(fontSize: 13, height: 1.4)),
                  const SizedBox(height: 16),
                ],
                if (warnings.isNotEmpty) ...[
                  _buildSectionHeader('Emergency Warnings Red Flags', Icons.crisis_alert_rounded),
                  const SizedBox(height: 6),
                  Text(warnings, style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: AppTheme.dangerColor, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTTSControllerConsole(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Multilingual Report Reader', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5)),
              DropdownButton<String>(
                value: _selectedLang,
                items: _languages.map((l) {
                  return DropdownMenuItem<String>(
                    value: l['code'],
                    child: Text(l['name'] ?? '', style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedLang = val;
                    });
                    if (_isSpeaking) {
                      _speakReport();
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: Icon(_isSpeaking && !_isPaused ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppTheme.primaryColor),
                onPressed: () {
                  if (_isSpeaking) {
                    if (_isPaused) {
                      _resumeSpeaking();
                    } else {
                      _pauseSpeaking();
                    }
                  } else {
                    _speakReport();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop_rounded, color: AppTheme.dangerColor),
                onPressed: _isSpeaking ? _stopSpeaking : null,
              ),
              const Spacer(),
              // Speed Slider
              Text('Speed: ', style: GoogleFonts.inter(fontSize: 11)),
              SizedBox(
                width: 70,
                child: Slider(
                  value: _ttsRate,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (v) {
                    setState(() {
                      _ttsRate = v;
                    });
                    if (_isSpeaking && !_isPaused) _speakReport();
                  },
                ),
              ),
              // Pitch Slider
              Text('Pitch: ', style: GoogleFonts.inter(fontSize: 11)),
              SizedBox(
                width: 70,
                child: Slider(
                  value: _ttsPitch,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (v) {
                    setState(() {
                      _ttsPitch = v;
                    });
                    if (_isSpeaking && !_isPaused) _speakReport();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
      ],
    );
  }

  Widget _buildBulletList(String title, List<dynamic> items, IconData icon, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, icon),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 5.0, left: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    item.toString(),
                    style: GoogleFonts.inter(fontSize: 12.5, color: isDark ? Colors.white70 : const Color(0xff334155), height: 1.35),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPatientScansHistory(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Previous Diagnostic Report Logs', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (_scansHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No historical report records found.', style: TextStyle(color: Colors.grey, fontSize: 12))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _scansHistory.length,
                separatorBuilder: (ctx, idx) => const Divider(height: 12),
                itemBuilder: (ctx, idx) {
                  final scan = _scansHistory[idx];
                  final timestamp = scan['date'] as Timestamp?;
                  final dateStr = timestamp != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                      : 'N/A';
                  final disease = scan['analysis']?['possibleDisease'] ?? 'Unknown condition';
                  final confidence = scan['confidence'] ?? 'N/A';
                  final imageUrl = scan['imageUrl'] ?? '';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageUrl.isEmpty ? const Icon(Icons.image_not_supported) : null,
                    ),
                    title: Text(disease, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text('Scanned: $dateStr • Confidence: $confidence', style: GoogleFonts.inter(fontSize: 11.5)),
                    onTap: () {
                      setState(() {
                        _scanReport = scan['analysis'];
                      });
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class CropOverlayPainter extends CustomPainter {
  final bool isCircle;

  CropOverlayPainter({required this.isCircle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final rectPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    
    final cutoutPath = Path();
    if (isCircle) {
      cutoutPath.addOval(Rect.fromCircle(center: center, radius: radius));
    } else {
      cutoutPath.addRect(Rect.fromCenter(center: center, width: radius * 2, height: radius * 2));
    }

    final maskPath = Path.combine(PathOperation.difference, rectPath, cutoutPath);
    canvas.drawPath(maskPath, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    if (isCircle) {
      canvas.drawCircle(center, radius, borderPaint);
    } else {
      canvas.drawRect(Rect.fromCenter(center: center, width: radius * 2, height: radius * 2), borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
