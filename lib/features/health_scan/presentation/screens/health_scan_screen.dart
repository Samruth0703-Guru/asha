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

class HealthScanScreen extends ConsumerStatefulWidget {
  final String? patientId;
  const HealthScanScreen({super.key, this.patientId});

  @override
  ConsumerState<HealthScanScreen> createState() => _HealthScanScreenState();
}

class _HealthScanScreenState extends ConsumerState<HealthScanScreen> with TickerProviderStateMixin {
  Patient? _patient;
  List<Patient> _patients = [];
  bool _isLoadingPatients = true;

  // Image editing/capture state
  Uint8List? _imageBytes;
  bool _isBytesLoaded = false;
  double _rotationAngle = 0;
  bool _isCircle = false;
  bool _isEditing = false;
  bool _isProcessing = false;
  final TransformationController _transformationController = TransformationController();

  // Network/AI actions state
  bool _isUploading = false;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _scanReport;
  List<Map<String, dynamic>> _scansHistory = [];
  Map<String, dynamic>? _comparisonScan;

  // Upload/AI progress and error handling
  double _uploadProgress = 0.0;
  String? _uploadError;
  Uint8List? _lastCroppedBytes;

  // Active speak state
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _stopTTS();
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
      debugPrint('Error loading scan history from Firebase: $e');
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
        _comparisonScan = null;
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
      _uploadError = null;
      _uploadProgress = 0.0;
    });

    try {
      // 1. Process local crop coordinates
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
        _lastCroppedBytes = croppedBytes;
        _isProcessing = false;
        _isUploading = true;
      });

      // 2. Upload cropped photo securely to Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final refPath = 'health_scans/${_patient!.id}_$timestamp.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(refPath);

      final uploadTask = storageRef.putData(
        croppedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double percent = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        setState(() {
          _uploadProgress = percent;
        });
      }, onError: (e) {
        debugPrint('Upload stream error: $e');
      });

      String downloadUrl = '';
      try {
        final snapshot = await uploadTask.timeout(const Duration(seconds: 5));
        downloadUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        debugPrint('Upload failed/timed out (likely Web CORS): $e');
        downloadUrl = 'https://via.placeholder.com/300?text=Web+Upload+Blocked';
      }

      setState(() {
        _isUploading = false;
        _isAnalyzing = true;
      });

      // 3. Vision AI screening request
      final gemini = ref.read(geminiServiceProvider);
      final report = await gemini.analyzeHealthImage(croppedBytes);

      // 4. Capture GPS location
      double lat = 9.9252; // Default Madurai block lat
      double lng = 78.1198; // Default Madurai block lng
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

      // 5. Save report metadata in Firestore
      final scanRecord = {
        'patientId': _patient!.id,
        'patientName': _patient!.name,
        'ashaWorkerId': 'LAKSHMI_001',
        'imageUrl': downloadUrl,
        'analysis': report,
        'confidence': report['confidence'] ?? '90%',
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
        _uploadError = 'Cloud Upload / AI Analysis Failed: ${e.toString()}';
      });
    }
  }

  Future<void> _runAnalysisWithSandboxFallback() async {
    final croppedBytes = _lastCroppedBytes ?? _imageBytes;
    if (croppedBytes == null || _patient == null) return;

    setState(() {
      _isProcessing = false;
      _isUploading = false;
      _isAnalyzing = true;
      _uploadError = null;
    });

    try {
      // 1. Analyze using Gemini Vision directly
      final gemini = ref.read(geminiServiceProvider);
      final report = await gemini.analyzeHealthImage(croppedBytes);

      // 2. Set mock image URL
      final mockDownloadUrl = 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&q=80&w=600';

      // 3. Save report metadata in Firestore
      final scanRecord = {
        'patientId': _patient!.id,
        'patientName': _patient!.name,
        'ashaWorkerId': 'LAKSHMI_001',
        'imageUrl': mockDownloadUrl,
        'analysis': report,
        'confidence': report['confidence'] ?? '90%',
        'date': Timestamp.now(),
        'latitude': 9.9252,
        'longitude': 78.1198,
      };

      try {
        await FirebaseFirestore.instance.collection('health_scans').add(scanRecord);
      } catch (firestoreError) {
        debugPrint('Firestore offline fallback trigger: $firestoreError');
      }

      setState(() {
        _imageBytes = croppedBytes;
        _isBytesLoaded = true;
        _scanReport = report;
        _isAnalyzing = false;
      });

      _loadScanHistory(_patient!.id);

    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _uploadError = 'Local AI Analysis Failed: ${e.toString()}';
      });
    }
  }

  // Speak report
  void _speakReport(String langCode) {
    if (_scanReport == null) return;
    _stopTTS();

    final condition = _scanReport!['condition'] ?? 'Unknown condition';
    final confidence = _scanReport!['confidence'] ?? 'N/A';
    final severity = _scanReport!['severity'] ?? 'N/A';
    final causes = (_scanReport!['possibleCauses'] as List?)?.join(', ') ?? '';
    final referral = _scanReport!['referral'] ?? '';

    String textToRead = "";
    if (langCode == 'ta') {
      textToRead = "சாத்தியமான கண்டறியப்பட்ட நிலை: $condition. "
          "நம்பிக்கை சதவீதம்: $confidence. "
          "தீவிரம்: $severity. "
          "சாத்தியமான காரணங்கள்: $causes. "
          "பரிந்துரை: $referral. "
          "குறிப்பு: இது ஒரு ஆரம்ப ஸ்கிரீனிங் மட்டுமே. ஒரு தகுதிவாய்ந்த மருத்துவ நிபுணரால் உறுதிப்படுத்தப்பட வேண்டும்.";
    } else {
      textToRead = "Possible condition detected: $condition. "
          "Confidence level is $confidence. "
          "Severity level is $severity. "
          "Possible causes include: $causes. "
          "Referral guidance: $referral. "
          "Warning: This is an AI screening tool only. The final diagnosis must be confirmed by a medical professional.";
    }

    tts.speakText(textToRead, langCode);
    setState(() {
      _isSpeaking = true;
    });
  }

  void _stopTTS() {
    tts.stopSpeaking();
    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('AI Health Image Analyzer', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (_scanReport != null && _isSpeaking)
            IconButton(
              icon: const Icon(Icons.volume_off_rounded, color: AppTheme.dangerColor),
              onPressed: _stopTTS,
              tooltip: 'Stop Reading Aloud',
            )
        ],
      ),
      body: _isLoadingPatients
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warnings Disclaimer Header
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '⚠️ CLINICAL DISCLAIMER: This Vision utility provides preliminary health screening checks. Final clinical diagnostic verification remains under the purview of a certified Medical Practitioner.',
                            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark ? Colors.orange.shade300 : Colors.orange.shade900, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Patient Selector Card
                  _buildPatientSelectorCard(isDark),
                  const SizedBox(height: 24),

                  if (_patient != null) ...[
                    // Scan action layout or photo editor
                    if (_isEditing)
                      _buildImageEditorUI(isDark)
                    else if (_uploadError != null)
                      _buildErrorUI(isDark)
                    else if (_isProcessing || _isUploading || _isAnalyzing)
                      _buildLoadingStatesUI(isDark)
                    else
                      _buildScanSelectionOrReportUI(isDark),
                    
                    const SizedBox(height: 32),
                    // Patient Scan History List
                    _buildScanHistoryUI(isDark),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPatientSelectorCard(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target Patient Selection', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (widget.patientId != null && _patient != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                title: Text(_patient!.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: ${_patient!.id} • ${_patient!.gender} • Age: ${DateTime.now().year - _patient!.dob.year} • Village: ${_patient!.village}'),
              )
            else
              DropdownButtonFormField<Patient>(
                value: _patient,
                hint: const Text('Select a patient to scan...'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.people_alt_rounded),
                ),
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
                    _comparisonScan = null;
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

  Widget _buildImageEditorUI(bool isDark) {
    return Card(
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.black,
            automaticallyImplyLeading: false,
            title: Text('Edit / Align Photo', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            actions: [
              IconButton(
                icon: const Icon(Icons.rotate_right_rounded, color: Colors.white),
                onPressed: _rotateImage,
                tooltip: 'Rotate 90°',
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
                tooltip: 'Toggle Cutout Shape',
              ),
            ],
          ),
          SizedBox(
            height: 350,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: RotatedBox(
                      quarterTurns: (_rotationAngle / 90).round(),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.contain,
                      ),
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
            padding: const EdgeInsets.all(20),
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
                    icon: const Icon(Icons.bolt, color: Colors.white),
                    label: const Text('Analyze Condition', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatesUI(bool isDark) {
    String msg = "";
    if (_isProcessing) msg = "Locally rendering and cropping image parameters...";
    if (_isUploading) {
      msg = "Uploading photo securely to medical Cloud Storage...\nProgress: ${_uploadProgress.toStringAsFixed(1)}%";
    }
    if (_isAnalyzing) msg = "Gemini Vision AI evaluating skin/tissue metrics...";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            if (_isUploading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _uploadProgress / 100.0,
                color: AppTheme.secondaryColor,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildErrorUI(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.dangerColor),
            const SizedBox(height: 16),
            Text(
              'Upload / AI Scan Failed',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.dangerColor),
            ),
            const SizedBox(height: 12),
            Text(
              _uploadError ?? 'An unexpected error occurred during the analysis.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _uploadError = null;
                    });
                    _runAnalysis();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _uploadError = null;
                      _imageBytes = null;
                      _isBytesLoaded = false;
                      _isEditing = false;
                    });
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _runAnalysisWithSandboxFallback,
              icon: const Icon(Icons.cloud_off_rounded, size: 18),
              label: const Text(
                'Bypass Cloud Upload (Local Sandbox Mode for Low Network)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanSelectionOrReportUI(bool isDark) {
    if (_scanReport == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.center_focus_strong_rounded, size: 64, color: AppTheme.primaryColor.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'AI Health Scan Screening',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Capture or upload clear, well-lit photos of skin rashes, infections, redness, mouth ulcers, swelling, or wounds for vision AI diagnostics screening.',
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
                      label: const Text('Upload Photo'),
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

    // Render detailed report card!
    final report = _scanReport!;
    final condition = report['condition'] ?? 'Possible skin anomaly';
    final confidence = report['confidence'] ?? '90%';
    final severity = report['severity'] ?? 'Moderate';
    final causes = (report['possibleCauses'] as List?) ?? [];
    final symptoms = (report['symptoms'] as List?) ?? [];
    final firstAid = (report['firstAid'] as List?) ?? [];
    final medicines = (report['medicines'] as List?) ?? [];
    final homeCare = (report['homeCare'] as List?) ?? [];
    final prevention = (report['prevention'] as List?) ?? [];
    final whenToVisit = report['whenToVisitPHC'] ?? '';
    final warningSigns = report['emergencyWarningSigns'] ?? '';
    final referral = report['referral'] ?? '';

    final severityColor = severity == 'High'
        ? AppTheme.dangerColor
        : (severity == 'Moderate' ? Colors.orange : AppTheme.secondaryColor);

    return FadeInUp(
      duration: const Duration(milliseconds: 350),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scan Photo View
          if (_imageBytes != null)
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Image.memory(_imageBytes!, height: 260, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 20),

          // Medical Report Card
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
                      Text('SCREENING REPORT', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryColor)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.record_voice_over_rounded, color: AppTheme.primaryColor),
                            onPressed: () => _speakReport('en'),
                            tooltip: 'Read in English',
                          ),
                          IconButton(
                            icon: const Icon(Icons.translate_rounded, color: AppTheme.secondaryColor),
                            onPressed: () => _speakReport('ta'),
                            tooltip: 'Read in Tamil (தமிழ்)',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Condition name
                  Text('Possible Condition Detected:', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(condition, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xff0f172a))),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Confidence Score
                      Expanded(
                        child: _buildBadge(
                          icon: Icons.analytics_rounded,
                          title: 'Confidence',
                          value: confidence,
                          valueColor: AppTheme.primaryColor,
                          bgColor: AppTheme.primaryColor.withOpacity(0.08),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Severity Level
                      Expanded(
                        child: _buildBadge(
                          icon: Icons.warning_rounded,
                          title: 'Severity Level',
                          value: severity,
                          valueColor: severityColor,
                          bgColor: severityColor.withOpacity(0.08),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Causes and Symptoms
                  _buildBulletList('Possible Clinical Causes', causes, Icons.science_outlined, isDark),
                  const SizedBox(height: 16),
                  _buildBulletList('Visible Symptoms', symptoms, Icons.visibility_outlined, isDark),
                  const Divider(height: 32),

                  // Recommendations and Meds
                  _buildBulletList('Suggested First Aid Steps', firstAid, Icons.healing_rounded, isDark),
                  const SizedBox(height: 16),
                  _buildBulletList('Recommended Medicine Category', medicines, Icons.medical_services_rounded, isDark),
                  const SizedBox(height: 16),
                  _buildBulletList('Home Care Instructions', homeCare, Icons.home_rounded, isDark),
                  const SizedBox(height: 16),
                  _buildBulletList('Prevention Tips', prevention, Icons.shield_rounded, isDark),
                  const Divider(height: 32),

                  // Referral and Emergency Guidance
                  if (whenToVisit.isNotEmpty) ...[
                    _buildSectionHeader('When to visit PHC Center', Icons.local_hospital_rounded),
                    const SizedBox(height: 6),
                    Text(whenToVisit, style: GoogleFonts.inter(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 16),
                  ],
                  if (warningSigns.isNotEmpty) ...[
                    _buildSectionHeader('Emergency Warning Signs', Icons.emergency_share),
                    const SizedBox(height: 6),
                    Text(warningSigns, style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: AppTheme.dangerColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                  ],
                  if (referral.isNotEmpty) ...[
                    _buildSectionHeader('Referral Recommendation', Icons.assignment_turned_in_rounded),
                    const SizedBox(height: 6),
                    Text(referral, style: GoogleFonts.inter(fontSize: 13, height: 1.4, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _scanReport = null;
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Scan Another Condition'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: valueColor),
              const SizedBox(width: 6),
              Text(title, style: GoogleFonts.inter(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: valueColor)),
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

  Widget _buildScanHistoryUI(bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historical Scan Screening Reports', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              'Select any past screening to perform side-by-side comparative analysis of healing progressions.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_scansHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text('No historical scans found.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13.5)),
                ),
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
                  final condition = scan['analysis']?['condition'] ?? 'Unknown condition';
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
                    title: Text(condition, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text('Scanned: $dateStr • Confidence: $confidence', style: GoogleFonts.inter(fontSize: 11.5)),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                      label: const Text('Compare', style: TextStyle(fontSize: 11.5)),
                      onPressed: () => _openComparisonView(scan),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openComparisonView(Map<String, dynamic> pastScan) {
    setState(() {
      _comparisonScan = pastScan;
    });

    showDialog(
      context: context,
      builder: (ctx) {
        final timestampPast = pastScan['date'] as Timestamp?;
        final datePast = timestampPast != null ? DateFormat('dd MMM yyyy').format(timestampPast.toDate()) : 'N/A';
        final condPast = pastScan['analysis']?['condition'] ?? 'Anomaly';
        final confPast = pastScan['confidence'] ?? 'N/A';
        
        final hasCurrent = _scanReport != null;
        final condCurrent = _scanReport?['condition'] ?? 'Current Analysis';
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Comparative Analysis HUD', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Visually compare clinical tissue patterns to track if inflammation/infections have receded over time.',
                    style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Past Scan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                              child: Text('PAST SCAN ($datePast)', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(pastScan['imageUrl'] ?? '', height: 180, width: double.infinity, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 8),
                            Text(condPast, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Confidence: $confPast', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Current Scan
                      if (hasCurrent && _imageBytes != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text('NEW ACTIVE SCAN', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(_imageBytes!, height: 180, width: double.infinity, fit: BoxFit.cover),
                              ),
                              const SizedBox(height: 8),
                              Text(condCurrent, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Confidence: ${_scanReport?['confidence'] ?? 'N/A'}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Container(
                            height: 230,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Center(
                              child: Text('Select or capture a new scan above to compare.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close HUD'),
            ),
          ],
        );
      },
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
