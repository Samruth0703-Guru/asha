import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/services/google_maps_service.dart';
import '../../../../core/services/web_camera_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/database/sync_service.dart';
import '../../../../core/database/local_storage_helper.dart';
import '../../../sms/controllers/sms_controller.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/stt_service.dart' as stt;

import 'package:drift/drift.dart' as drift;

class PatientRegisterScreen extends ConsumerStatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  ConsumerState<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends ConsumerState<PatientRegisterScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  // Basic Info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _abhaController = TextEditingController();
  String _gender = 'Female';
  DateTime? _dob;
  
  // Health Data
  bool _isPregnant = false;
  int _previousPregnancies = 0;

  // Additional Workflows
  bool _isVaccinationRequired = false;

  final List<String> _districts = [];

  bool _isAutoSaving = false;
  String _autoSaveMessage = "Draft Saved Locally";

  GoogleMapsPlaceDetails? _selectedPlaceDetails;
  bool _isValidAddress = false;
  bool _addressTouched = false;
  bool _isSearching = false;
  bool _noResults = false;
  bool _isOffline = false;
  List<String> _autocompleteSuggestions = [];
  Timer? _debounceTimer;
  String? _uploadedPhotoUrl;
  late final String _patientId;

  // Additional Workflows
  bool _isPregnantWoman = false;

  // Voice Assistant Auto-fill state
  bool _isListeningVoice = false;
  bool _isProcessingVoice = false;


  Future<bool> _hasInternet() async {
    if (kIsWeb) {
      return true;
    } else {
      try {
        final result = await io.InternetAddress.lookup('google.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  void _onAddressChanged(String val) {
    if (_isValidAddress) {
      setState(() {
        _isValidAddress = false;
        _selectedPlaceDetails = null;
      });
    }
    setState(() {
      _addressTouched = true;
      _noResults = false;
      _isOffline = false;
      _autocompleteSuggestions = [];
    });

    if (val.trim().isEmpty) {
      setState(() { _isSearching = false; });
      return;
    }

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    setState(() { _isSearching = true; });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final hasInternet = await _hasInternet();
      if (!hasInternet) {
        if (mounted) {
          setState(() {
            _isOffline = true;
            _autocompleteSuggestions = [];
            _isSearching = false;
          });
        }
        return;
      }

      int retryCount = 3;
      bool success = false;
      List<String> suggestions = [];

      while (retryCount > 0 && !success) {
        try {
          suggestions = await GoogleMapsService.getAutocompleteSuggestions(val.trim())
              .timeout(const Duration(seconds: 2));
          success = true;
        } catch (e) {
          retryCount--;
          if (retryCount > 0) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _autocompleteSuggestions = suggestions;
        _isSearching = false;
        _noResults = suggestions.isEmpty && val.trim().isNotEmpty;
      });
    });
  }

  void _onSuggestionSelected(String suggestion) async {
    setState(() {
      _villageController.text = suggestion;
      _autocompleteSuggestions = [];
      _isSearching = true;
      _noResults = false;
    });

    final details = await GoogleMapsService.getPlaceDetails(suggestion);
    if (!mounted) return;
    if (details != null) {
      setState(() {
        _selectedPlaceDetails = details;
        _isValidAddress = true;
        _addressTouched = true;
        _isSearching = false;
      });
    } else {
      setState(() {
        _isValidAddress = false;
        _isSearching = false;
      });
    }
  }

  void _clearAddress() {
    setState(() {
      _villageController.clear();
      _selectedPlaceDetails = null;
      _isValidAddress = false;
      _addressTouched = false;
      _isSearching = false;
      _noResults = false;
      _autocompleteSuggestions = [];
    });
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (kIsWeb) return true;
    if (!kIsWeb && io.Platform.isWindows) return true;

    if (permission == Permission.storage && !kIsWeb && io.Platform.isAndroid) {
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted) return true;
      
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;

      final Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
      ].request();

      return statuses[Permission.photos]?.isGranted == true ||
          statuses[Permission.storage]?.isGranted == true;
    }

    final status = await permission.status;
    if (status.isGranted) return true;
    final result = await permission.request();
    return result.isGranted;
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor),
              title: const Text('📷 Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor),
              title: const Text('🖼 Upload from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openCropScreen(XFile file) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PhotoEditScreen(
          imageFile: file,
          patientId: _patientId,
          onCompleted: (String finalPath, String downloadUrl) {
            setState(() {
              _capturedPhotoPath = finalPath;
              _uploadedPhotoUrl = downloadUrl;
            });
            Navigator.pop(ctx);
            _showSnackbar('Patient photo saved successfully.', AppTheme.secondaryColor);
          },
          onRetake: () {
            Navigator.pop(ctx);
            _pickImage(ImageSource.camera);
          },
          onChooseAnother: () {
            Navigator.pop(ctx);
            _pickImage(ImageSource.gallery);
          },
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (kIsWeb && source == ImageSource.camera) {
        final capturedUrl = await captureWebImage(context);
        if (capturedUrl != null) {
          final base64Str = capturedUrl.split(',')[1];
          final bytes = base64Decode(base64Str);
          final xFile = XFile.fromData(bytes, mimeType: 'image/jpeg');
          _openCropScreen(xFile);
        } else {
          _showSnackbar('Camera not available. Use Gallery instead.', AppTheme.dangerColor);
        }
        return;
      }

      if (!kIsWeb && io.Platform.isWindows && source == ImageSource.camera) {
        _showSnackbar('Camera not available. Use Gallery instead.', AppTheme.dangerColor);
        return;
      }

      if (!kIsWeb && !io.Platform.isWindows) {
        final permission = source == ImageSource.camera
            ? Permission.camera
            : Permission.storage;
        final granted = await _requestPermission(permission);
        if (!granted) {
          _showSnackbar('Permission denied. Please enable access in settings.', AppTheme.dangerColor);
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (image == null) return;

      _openCropScreen(image);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (e.toString().contains('Unimplemented') || e.toString().contains('camera')) {
        _showSnackbar('Camera not available. Use Gallery instead.', AppTheme.dangerColor);
      } else {
        _showSnackbar('Failed to access camera/gallery: $e', AppTheme.dangerColor);
      }
    }
  }

  void _showSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _reverseGeocodeCoordinates(double lat, double lng) async {
    setState(() {
      _isSearching = true;
    });
    try {
      final details = await GoogleMapsService.getPlaceDetailsByCoordinates(lat, lng);
      if (!mounted) return;
      if (details != null) {
        setState(() {
          _selectedPlaceDetails = details;
          _isValidAddress = true;
          _addressTouched = true;
          _villageController.text = details.formattedAddress;
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
        });
        _showSnackbar('Reverse geocoding failed. Try dragging again.', AppTheme.dangerColor);
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        _showSnackbar('Geocoding failed: $e', AppTheme.dangerColor);
      }
    }
  }

  Widget _buildPhotoWidget() {
    if (_capturedPhotoPath == null) {
      return const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor, size: 30);
    }
    if (kIsWeb) {
      if (_capturedPhotoPath!.startsWith('data:')) {
        // Decode base64 data URL to bytes for reliable rendering
        try {
          final base64Str = _capturedPhotoPath!.split(',')[1];
          final bytes = base64Decode(base64Str);
          return ClipOval(
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: 95,
              height: 95,
              errorBuilder: (_, __, ___) => const Icon(Icons.check_circle_rounded, color: AppTheme.secondaryColor, size: 40),
            ),
          );
        } catch (_) {
          return ClipOval(
            child: Container(
              width: 95, height: 95,
              color: AppTheme.secondaryColor.withOpacity(0.1),
              alignment: Alignment.center,
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.secondaryColor, size: 40),
            ),
          );
        }
      }
      if (_capturedPhotoPath!.startsWith('blob:') ||
          _capturedPhotoPath!.startsWith('http')) {
        return ClipOval(
          child: Image.network(
            _capturedPhotoPath!,
            fit: BoxFit.cover,
            width: 95,
            height: 95,
            errorBuilder: (_, __, ___) => const Icon(Icons.check_circle_rounded, color: AppTheme.secondaryColor, size: 40),
          ),
        );
      }
    } else {
      if (!_capturedPhotoPath!.startsWith('http') && !_capturedPhotoPath!.startsWith('blob:')) {
        return ClipOval(
          child: Image.file(
            io.File(_capturedPhotoPath!),
            fit: BoxFit.cover,
            width: 95,
            height: 95,
            errorBuilder: (_, __, ___) => const Icon(Icons.check_circle_rounded, color: AppTheme.secondaryColor, size: 40),
          ),
        );
      }
    }
    return ClipOval(
      child: Container(
        width: 95, height: 95,
        color: AppTheme.secondaryColor.withOpacity(0.1),
        alignment: Alignment.center,
        child: const Icon(Icons.check_circle_rounded, color: AppTheme.secondaryColor, size: 40),
      ),
    );
  }

  void _useCurrentLocation() async {
    setState(() { _isSearching = true; });
    try {
      if (!kIsWeb) {
        final granted = await _requestPermission(Permission.location);
        if (!granted) {
          _showSnackbar('Location permission denied.', AppTheme.dangerColor);
          setState(() { _isSearching = false; });
          return;
        }
      } else {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
          _showSnackbar('Location permission denied.', AppTheme.dangerColor);
          setState(() { _isSearching = false; });
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      
      await _reverseGeocodeCoordinates(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('GPS error: $e');
      if (mounted) {
        setState(() { _isSearching = false; });
        _showSnackbar('GPS error: $e', AppTheme.dangerColor);
      }
    }
  }


  // Form Field controllers
  final _dobController = TextEditingController();
  final _villageController = TextEditingController();
  
  final _bpController = TextEditingController();
  final _hbController = TextEditingController();
  final _sugarController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _symptomsController = TextEditingController();

  String _selectedGender = 'Female';
  
  bool _isScanningOCR = false;
  String? _capturedPhotoPath;

  bool _manualHighRisk = false;
  final _bpFocusNode = FocusNode();
  final _hbFocusNode = FocusNode();
  final _sugarFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _patientId = 'PT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    // Simulate auto-save when values change
    _nameController.addListener(_triggerAutoSave);
    _abhaController.addListener(_triggerAutoSave);
    _phoneController.addListener(_triggerAutoSave);

    _bpFocusNode.addListener(_checkBP);
    _hbFocusNode.addListener(_checkHb);
    _sugarFocusNode.addListener(_checkSugar);
  }

  @override
  void dispose() {
    _nameController.removeListener(_triggerAutoSave);
    _abhaController.removeListener(_triggerAutoSave);
    _phoneController.removeListener(_triggerAutoSave);

    _bpFocusNode.removeListener(_checkBP);
    _hbFocusNode.removeListener(_checkHb);
    _sugarFocusNode.removeListener(_checkSugar);

    _bpFocusNode.dispose();
    _hbFocusNode.dispose();
    _sugarFocusNode.dispose();

    _nameController.dispose();
    _abhaController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _villageController.dispose();
    _bpController.dispose();
    _hbController.dispose();
    _sugarController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _symptomsController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoSave() {
    if (_nameController.text.isEmpty && _abhaController.text.isEmpty && _phoneController.text.isEmpty) return;
    if (_isAutoSaving) return;
    
    setState(() {
      _isAutoSaving = true;
      _autoSaveMessage = "Saving registration draft...";
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isAutoSaving = false;
          _autoSaveMessage = "Draft Auto-Saved (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})";
        });
      }
    });
  }

  void _startOCRScan() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? docImage = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (docImage == null) return;

      setState(() {
        _isScanningOCR = true;
      });

      final bytes = await docImage.readAsBytes();
      final gemini = ref.read(geminiServiceProvider);
      final data = await gemini.extractOCRData(bytes);

      if (!mounted) return;

      setState(() {
        _isScanningOCR = false;
        
        if (data['patientName']?.toString().isNotEmpty == true) _nameController.text = data['patientName'];
        if (data['abhaId']?.toString().isNotEmpty == true) _abhaController.text = data['abhaId'];
        if (data['phoneNumber']?.toString().isNotEmpty == true) _phoneController.text = data['phoneNumber'];
        if (data['dob']?.toString().isNotEmpty == true) _dobController.text = data['dob'];
        if (data['village']?.toString().isNotEmpty == true) _villageController.text = data['village'];
        if (data['bloodPressure']?.toString().isNotEmpty == true) _bpController.text = data['bloodPressure'];
        if (data['hemoglobin']?.toString().isNotEmpty == true) _hbController.text = data['hemoglobin'];
        if (data['bloodSugar']?.toString().isNotEmpty == true) _sugarController.text = data['bloodSugar'];
        if (data['temperature']?.toString().isNotEmpty == true) _tempController.text = data['temperature'];
        if (data['weight']?.toString().isNotEmpty == true) _weightController.text = data['weight'];
        
        if (data['symptoms'] != null && data['symptoms'] is List) {
          _symptomsController.text = (data['symptoms'] as List).join(', ');
        }
        
        if (data['gender']?.toString().toLowerCase() == 'male') _selectedGender = 'Male';
        if (data['gender']?.toString().toLowerCase() == 'female') _selectedGender = 'Female';
        
        if (data['pregnancyStatus']?.toString().toLowerCase() == 'yes') _isPregnant = true;
        if (data['pregnancyStatus']?.toString().toLowerCase() == 'no') _isPregnant = false;

        _capturedPhotoPath = docImage.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI OCR Scan Complete! Extracted patient details.'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    } catch (e) {
      debugPrint('OCR camera capture error: \$e');
      if (mounted) {
        setState(() {
          _isScanningOCR = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to extract OCR data: \$e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }



  Future<void> _startVoiceDictation() async {
    if (_isListeningVoice) {
      stt.sttServiceProvider.stop();
      setState(() { _isListeningVoice = false; });
      return;
    }

    setState(() {
      _isListeningVoice = true;
    });

    String lastWords = "";
    
    stt.sttServiceProvider.init(
      (text) {
        lastWords = text;
      },
      (status) {
        // Handle STT status if needed
      }
    );
    stt.sttServiceProvider.start('en');

    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(32),
              height: 350,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic, size: 64, color: AppTheme.secondaryColor),
                  const SizedBox(height: 24),
                  const Text('Listening to Patient Details...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Speak naturally in any language.', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      stt.sttServiceProvider.stop();
                      Navigator.pop(ctx);
                      _processVoiceTranscript(lastWords);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: const Text('Finish & Auto-Fill'),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }


  Future<void> _processVoiceTranscript(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isListeningVoice = false;
      _isProcessingVoice = true;
    });

    try {
      final gemini = ref.read(geminiServiceProvider);
      final data = await gemini.parseVoiceTranscript(text);

      setState(() {
        if (data['patientName']?.toString().isNotEmpty == true) _nameController.text = data['patientName'];
        if (data['phoneNumber']?.toString().isNotEmpty == true) _phoneController.text = data['phoneNumber'];
        if (data['village']?.toString().isNotEmpty == true) _villageController.text = data['village'];
        if (data['bloodPressure']?.toString().isNotEmpty == true) _bpController.text = data['bloodPressure'];
        if (data['bloodSugar']?.toString().isNotEmpty == true) _sugarController.text = data['bloodSugar'];
        if (data['temperature']?.toString().isNotEmpty == true) _tempController.text = data['temperature'];
        if (data['weight']?.toString().isNotEmpty == true) _weightController.text = data['weight'];
        if (data['symptoms'] != null && data['symptoms'] is List) {
          _symptomsController.text = (data['symptoms'] as List).join(', ');
        }
        
        if (data['gender']?.toString().toLowerCase() == 'male') _selectedGender = 'Male';
        if (data['gender']?.toString().toLowerCase() == 'female') _selectedGender = 'Female';
        
        if (data['pregnancyStatus']?.toString().toLowerCase() == 'yes') _isPregnant = true;
        if (data['pregnancyStatus']?.toString().toLowerCase() == 'no') _isPregnant = false;

        _isProcessingVoice = false;
      });

      _showSnackbar('Form auto-filled from voice transcript!', AppTheme.secondaryColor);

    } catch (e) {
      setState(() { _isProcessingVoice = false; });
      _showSnackbar('Voice processing failed: \$e', AppTheme.dangerColor);
    }
  }

  void _checkBP() {
    if (!_bpFocusNode.hasFocus) {
      final text = _bpController.text.trim();
      if (text.isEmpty) return;

      final parts = text.split('/');
      int? systolic;
      int? diastolic;
      if (parts.isNotEmpty) {
        systolic = int.tryParse(parts[0]);
      }
      if (parts.length > 1) {
        diastolic = int.tryParse(parts[1]);
      }

      if ((systolic != null && systolic >= 140) || (diastolic != null && diastolic >= 90)) {
        _showRiskAlert(
          title: 'Hypertension Detected (High Blood Pressure)',
          parameter: 'BP: $text mmHg',
          guideline: 'Systolic ≥ 140 or Diastolic ≥ 90 indicates Stage 1 or 2 Hypertension. An hypertensive crisis could lead to Pre-eclampsia.',
        );
      }
    }
  }

  void _checkHb() {
    if (!_hbFocusNode.hasFocus) {
      final text = _hbController.text.trim();
      if (text.isEmpty) return;
      final val = double.tryParse(text);
      if (val != null && val < 10.0) {
        _showRiskAlert(
          title: 'Moderate to Severe Anemia Detected',
          parameter: 'Hb: $text g/dL',
          guideline: 'Hemoglobin levels below 10.0 g/dL indicate moderate/severe gestational anemia. Normal is 11.5 - 16.0 g/dL.',
        );
      }
    }
  }

  void _checkSugar() {
    if (!_sugarFocusNode.hasFocus) {
      final text = _sugarController.text.trim();
      if (text.isEmpty) return;
      final val = double.tryParse(text);
      if (val != null && (val >= 140.0 || val < 60.0)) {
        final condition = val >= 140.0 ? 'Hyperglycemia (High Sugar)' : 'Hypoglycemia (Low Sugar)';
        _showRiskAlert(
          title: '$condition Detected',
          parameter: 'Blood Sugar: $text mg/dL',
          guideline: 'Postprandial sugar ≥ 140 mg/dL suggests Gestational Diabetes, while sugar < 60 mg/dL poses acute hypoglycemic shock risks.',
        );
      }
    }
  }

  void _showRiskAlert({
    required String title,
    required String parameter,
    required String guideline,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.dangerColor, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('Critical Parameter Warning', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.dangerColor)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                parameter,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.dangerColor, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            Text(guideline, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 16),
            Text(
              'Do you want to flag this patient as "High Risk" and add them to the high-risk directory?',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Routine Care', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                _manualHighRisk = true;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Patient flagged as High Risk'),
                  backgroundColor: AppTheme.dangerColor,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Add to Risk List', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _savePatient() async {
    final db = ref.read(localDatabaseProvider);
    final syncNotifier = ref.read(syncProvider.notifier);

    final patientId = _patientId;
    final isHigh = _manualHighRisk ||
                  (double.tryParse(_hbController.text) ?? 12.0) < 10.0 || 
                  _bpController.text.startsWith('14') || 
                  _bpController.text.startsWith('15') || 
                  _bpController.text.startsWith('16');

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );

    String? photoUrl = _uploadedPhotoUrl;

    // 2. Save document to Cloud Firestore
    try {
      await FirebaseFirestore.instance.collection('patients').doc(patientId).set({
        'patientName': _nameController.text,
        'phone': _phoneController.text,
        'abhaId': _abhaController.text.isNotEmpty ? _abhaController.text : null,
        'photoUrl': photoUrl,
        'address': _villageController.text,
        'latitude': _selectedPlaceDetails?.latitude,
        'longitude': _selectedPlaceDetails?.longitude,
        'placeId': _selectedPlaceDetails?.placeId,
        'district': _selectedPlaceDetails?.district,
        'state': _selectedPlaceDetails?.state,
        'country': _selectedPlaceDetails?.country,
        'postalCode': _selectedPlaceDetails?.postalCode,
        'isPregnant': _isPregnant,
        'vaccinationRequired': _isVaccinationRequired,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Patient saved to Cloud Firestore successfully.');
      _showSnackbar('Patient registered and synced to Cloud successfully! ✅', AppTheme.secondaryColor);
    } catch (e) {
      debugPrint('Cloud Firestore save failed: $e');
      _showSnackbar('Cloud sync failed: $e. Patient saved locally.', AppTheme.dangerColor);
    }

    // Dismiss loading overlay
    if (mounted) {
      Navigator.pop(context);
    }

    final newPatient = Patient(
      id: patientId,
      abhaId: _abhaController.text.isNotEmpty ? _abhaController.text : null,
      name: _nameController.text,
      photoPath: _capturedPhotoPath,
      dob: DateTime.tryParse(_dobController.text) ?? DateTime(1995, 1, 1),
      gender: _selectedGender,
      phone: _phoneController.text,
      village: _villageController.text,
      isHighRisk: isHigh,
      bloodPressure: _bpController.text.isNotEmpty ? _bpController.text : null,
      hemoglobin: double.tryParse(_hbController.text),
      bloodSugar: double.tryParse(_sugarController.text),
      temperature: double.tryParse(_tempController.text),
      weight: double.tryParse(_weightController.text),
      symptoms: _symptomsController.text.isNotEmpty ? _symptomsController.text : null,
      previousPregnancies: _previousPregnancies,
      riskLevel: isHigh ? 'High' : 'Low',
      confidenceScore: 0.90,
      latitude: _selectedPlaceDetails?.latitude,
      longitude: _selectedPlaceDetails?.longitude,
      placeId: _selectedPlaceDetails?.placeId,
      district: _selectedPlaceDetails?.district,
      state: _selectedPlaceDetails?.state,
      country: _selectedPlaceDetails?.country,
      postalCode: _selectedPlaceDetails?.postalCode,
      isPregnant: _isPregnant,
      vaccinationRequired: _isVaccinationRequired,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save Patient (try persistent DB, fallback to memory list if WASM/SQLite is missing on web browser)
    try {
      await db.insertPatient(newPatient);
      
      // Auto-create workflow records based on checkboxes
      if (_isPregnant) {
        await db.into(db.ancVisits).insert(
          AncVisitsCompanion.insert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            patientId: newPatient.id,
            visitDate: DateTime.now(),
            nextVisitDate: drift.Value(DateTime.now().add(const Duration(days: 30))),
            expectedDeliveryDate: drift.Value(DateTime.now().add(const Duration(days: 280)).toIso8601String()),
            status: const drift.Value('Completed'),
          ),
        );
      }
      
      if (_isVaccinationRequired) {
        await db.into(db.vaccinations).insert(
          VaccinationsCompanion.insert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            patientId: newPatient.id,
            vaccineName: 'OPV-1',
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
        );
      }
      
      debugPrint('Patient saved to persistent local database successfully.');
    } catch (e) {
      debugPrint('Drift local DB save failed (\$e) — falling back to static memory listing.');
      LocalDatabaseFallback.registeredPatients.add(newPatient);
      savePatientsToWeb(LocalDatabaseFallback.registeredPatients);
    }

    // Sync queue insert (wrapped in try/catch to avoid blocking registration on web if IndexedDB fails)
    try {
      final payload = {
        'id': newPatient.id,
        'abhaId': newPatient.abhaId,
        'name': newPatient.name,
        'dob': newPatient.dob.toIso8601String(),
        'gender': newPatient.gender,
        'phone': newPatient.phone,
        'village': newPatient.village,
        'isHighRisk': newPatient.isHighRisk,
        'bloodPressure': newPatient.bloodPressure,
        'isPregnant': newPatient.isPregnant,
        'vaccinationRequired': newPatient.vaccinationRequired,
        'hemoglobin': newPatient.hemoglobin,
        'riskLevel': newPatient.riskLevel,
        'latitude': newPatient.latitude,
        'longitude': newPatient.longitude,
        'placeId': newPatient.placeId,
        'district': newPatient.district,
        'state': newPatient.state,
        'country': newPatient.country,
        'postalCode': newPatient.postalCode,
      };
      await syncNotifier.addRecordToSyncQueue('patients', newPatient.id, 'INSERT', payload);
    } catch (e) {
      debugPrint('Sync queue insert failed ($e). Offline operation allowed.');
    }

    // Trigger Fast2SMS alerts automatically
    try {
      final smsController = ref.read(smsControllerProvider.notifier);
      // Send confirm confirmation/appointment SMS
      await smsController.sendAppointmentReminder(newPatient);
      // If pregnancy screening shows high risk, send urgent high risk SMS alert
      if (newPatient.isHighRisk) {
        await smsController.sendHighRiskAlert(newPatient);
      }
    } catch (e) {
      debugPrint('SMS notification automatic trigger failure: $e');
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppTheme.secondaryColor, size: 28),
              SizedBox(width: 10),
              Text('Registration Complete'),
            ],
          ),
          content: Text('${newPatient.name} has been added locally. Vitals queued for background database synchronization.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/dashboard');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      floatingActionButton: _isProcessingVoice 
          ? const FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'voice_fab',
                  onPressed: _startVoiceDictation,
                  backgroundColor: AppTheme.secondaryColor,
                  icon: const Icon(Icons.mic, color: Colors.white),
                  label: const Text('Voice Auto-Fill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  heroTag: 'register_fab',
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _savePatient();
                    } else {
                      _showSnackbar('Please fill all required fields (*) before registering.', AppTheme.dangerColor);
                    }
                  },
                  backgroundColor: AppTheme.primaryColor,
                  icon: const Icon(Icons.how_to_reg_rounded, color: Colors.white),
                  label: const Text('Register Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
      appBar: AppBar(
        title: Text('New Patient Registration', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _isScanningOCR ? null : _startOCRScan,
            icon: const Icon(Icons.document_scanner_rounded, color: AppTheme.primaryColor),
            tooltip: 'OCR Register Import',
          ),
        ],
      ),
      body: _isScanningOCR
          ? _buildScanningLoader()
          : Column(
              children: [
                // Auto-save Status bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  color: isDark ? const Color(0xff151e2e) : Colors.white,
                  child: Row(
                    children: [
                      Icon(
                        _isAutoSaving ? Icons.sync : Icons.cloud_done_outlined,
                        size: 14,
                        color: _isAutoSaving ? AppTheme.warningColor : AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _autoSaveMessage,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isAutoSaving ? AppTheme.warningColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Stepper progress header
                _buildStepperHeader(),

                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(24.0),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (_currentStep == 0) _buildStepOne(isDark),
                        if (_currentStep == 1) _buildStepTwo(isDark),
                        if (_currentStep == 2) _buildStepThree(isDark),
                      ],
                    ),
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildScanningLoader() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            Text(
              'Scanning Physical NHM Register book...',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'AI OCR is digitizing vitals and patient demographics.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    final steps = ['Profile', 'Vitals Screener', 'Review & Scan'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;
          return Row(
            children: [
              Container(
                height: 24,
                width: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppTheme.secondaryColor
                      : (isActive ? AppTheme.primaryColor : Colors.grey.shade300),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                steps[index],
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppTheme.primaryColor : (isCompleted ? AppTheme.secondaryColor : Colors.grey),
                ),
              ),
              if (index < steps.length - 1)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 24,
                  height: 1.5,
                  color: Colors.grey.shade300,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepOne(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Camera upload placeholder
        Center(
          child: GestureDetector(
            onTap: _showImagePickerOptions,
            child: Stack(
              children: [
                Container(
                  height: 105,
                  width: 105,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _capturedPhotoPath != null
                        ? const LinearGradient(colors: [Color(0xff10b981), Color(0xff059669)])
                        : const LinearGradient(colors: [Color(0xff3b82f6), Color(0xff8b5cf6)]),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff151e2e) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: _buildPhotoWidget(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xff3b82f6), Color(0xff2563eb)]),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xff151e2e) : Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff3b82f6).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _capturedPhotoPath != null ? Icons.edit_rounded : Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _capturedPhotoPath != null ? '✓ Photo Attached' : 'Tap to Capture Photo',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _capturedPhotoPath != null ? AppTheme.secondaryColor : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (val) => val == null || val.isEmpty ? 'Full Name is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _abhaController,
          decoration: const InputDecoration(
            labelText: 'ABHA Health Card ID',
            prefixIcon: Icon(Icons.badge_outlined),
            hintText: 'e.g., 14-digit NDHM ID number',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (val) => val == null || val.length != 10 ? 'Enter valid 10-digit number' : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                ),
                items: const [
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => _selectedGender = val ?? 'Female'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'DOB (YYYY-MM-DD) *',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _villageController,
                    onChanged: _onAddressChanged,
                    decoration: InputDecoration(
                      labelText: 'Village Name / Address *',
                      hintText: 'Start typing to search Google Maps...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _isValidAddress
                              ? IconButton(
                                  icon: const Icon(Icons.check_circle, color: AppTheme.secondaryColor),
                                  onPressed: _clearAddress,
                                  tooltip: 'Clear address',
                                )
                              : _addressTouched && _villageController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, color: Colors.grey),
                                      onPressed: _clearAddress,
                                    )
                                  : null,
                    ),
                    validator: (val) {
                      if (!_isValidAddress) return 'Please select a valid address from Google Maps';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── STATE: Searching ──
        if (_isSearching && _autocompleteSuggestions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('Searching Google Maps...', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),

        // ── STATE: No Internet ──
        if (_isOffline && !_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, size: 16, color: AppTheme.dangerColor),
                const SizedBox(width: 6),
                Text('No Internet Connection',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.dangerColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),

        // ── STATE: No Results ──
        if (_noResults && !_isSearching && !_isOffline)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.location_off, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Text('No locations found',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
              ],
            ),
          ),

        // ── STATE: Suggestions Dropdown ──
        if (_autocompleteSuggestions.isNotEmpty && !_isValidAddress)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff1a2235) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _autocompleteSuggestions.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
              itemBuilder: (context, idx) {
                final suggestion = _autocompleteSuggestions[idx];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _onSuggestionSelected(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_outlined, color: AppTheme.primaryColor, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(Icons.north_west, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // ── STATE: Invalid Address ──
        if (_addressTouched && !_isValidAddress && !_isSearching && _autocompleteSuggestions.isEmpty && _villageController.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.dangerColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.dangerColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('❌ Invalid Address',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.dangerColor)),
                      Text('No matching Google Maps location found.',
                          style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.dangerColor.withOpacity(0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // ── STATE: Location Verified ✅ ──
        if (_isValidAddress && _selectedPlaceDetails != null) ...[
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppTheme.secondaryColor, size: 18),
                    const SizedBox(width: 6),
                    Text('Location Verified ✅',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _clearAddress,
                      icon: const Icon(Icons.edit_location_alt, size: 14),
                      label: const Text('Change', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_selectedPlaceDetails!.formattedAddress,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (_selectedPlaceDetails!.village.isNotEmpty)
                      _infoChip(Icons.home_work_outlined, 'Village: ${_selectedPlaceDetails!.village}'),
                    if (_selectedPlaceDetails!.taluk.isNotEmpty)
                      _infoChip(Icons.map_outlined, 'Taluk: ${_selectedPlaceDetails!.taluk}'),
                    if (_selectedPlaceDetails!.district.isNotEmpty)
                      _infoChip(Icons.location_city_outlined, 'District: ${_selectedPlaceDetails!.district}'),
                    if (_selectedPlaceDetails!.state.isNotEmpty)
                      _infoChip(Icons.flag_outlined, _selectedPlaceDetails!.state),
                    if (_selectedPlaceDetails!.postalCode.isNotEmpty)
                      _infoChip(Icons.markunread_mailbox_outlined, _selectedPlaceDetails!.postalCode),
                    _infoChip(Icons.my_location,
                      '${_selectedPlaceDetails!.latitude.toStringAsFixed(4)}, ${_selectedPlaceDetails!.longitude.toStringAsFixed(4)}'),
                  ],
                ),
                const SizedBox(height: 12),
                // Real interactive Google Map preview with draggable marker
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _selectedPlaceDetails!.latitude,
                          _selectedPlaceDetails!.longitude,
                        ),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('patient_location'),
                          position: LatLng(
                            _selectedPlaceDetails!.latitude,
                            _selectedPlaceDetails!.longitude,
                          ),
                          draggable: true,
                          onDragEnd: (LatLng newPosition) async {
                            await _reverseGeocodeCoordinates(newPosition.latitude, newPosition.longitude);
                          },
                        ),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSearching ? null : _useCurrentLocation,
          icon: _isSearching
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location, size: 16),
          label: Text(_isSearching ? 'Detecting Location...' : 'Use Current GPS Location'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryColor),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStepTwo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _isPregnant,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) => setState(() => _isPregnant = val ?? false),
            ),
            const Text('Client pregnancy screening active', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        if (_isPregnant) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Previous Pregnancies Count: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: _previousPregnancies,
                items: List.generate(10, (index) => DropdownMenuItem(value: index, child: Text(index.toString()))),
                onChanged: (val) => setState(() => _previousPregnancies = val ?? 0),
              ),
            ],
          ),
        ],
        Row(
          children: [
            Checkbox(
              value: _isVaccinationRequired,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) => setState(() => _isVaccinationRequired = val ?? false),
            ),
            const Text('Vaccination Required', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const Divider(height: 28),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _bpController,
                focusNode: _bpFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Blood Pressure',
                  hintText: 'e.g., 120/80',
                  prefixIcon: Icon(Icons.speed_outlined),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: _hbController,
                focusNode: _hbFocusNode,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hemoglobin (g/dL)',
                  hintText: 'e.g., 11.5',
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _sugarController,
                focusNode: _sugarFocusNode,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Blood Sugar (mg/dL)',
                  prefixIcon: Icon(Icons.biotech_outlined),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _symptomsController,
          decoration: const InputDecoration(
            labelText: 'Active Symptoms (comma separated)',
            prefixIcon: Icon(Icons.sick_outlined),
            hintText: 'e.g., headache, swelling feet',
          ),
        ),
      ],
    );
  }

  Widget _buildStepThree(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Demographics & Parameters',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff151e2e) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewRow('Client Name', _nameController.text),
              _buildReviewRow('ABHA Health ID', _abhaController.text.isNotEmpty ? _abhaController.text : 'Unregistered'),
              _buildReviewRow('Phone Connection', _phoneController.text),
              _buildReviewRow('Village Area', _villageController.text),
              _buildReviewRow('Vitals Summary', 'BP: ${_bpController.text}, Hb: ${_hbController.text} g/dL, Sugar: ${_sugarController.text} mg/dL'),
              _buildReviewRow('Captured Photo Status', _capturedPhotoPath != null ? 'Verification Attached' : 'No photo uploaded'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isValidAddress ? _savePatient : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isValidAddress ? AppTheme.primaryColor : Colors.grey.shade400,
          ),
          child: const Text('Confirm & Save Registration'),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 90),
      color: isDark ? AppTheme.darkCardColor : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, 50),
              ),
              child: const Text('Back'),
            )
          else
            const SizedBox(),
          if (_currentStep < 2)
            ElevatedButton(
              onPressed: (_currentStep == 0 && !_isValidAddress) ? null : () {
                if (_formKey.currentState!.validate() || _currentStep > 0) {
                  setState(() {
                    _currentStep++;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 50),
              ),
              child: const Text('Next Step'),
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }
}

class PhotoEditScreen extends StatefulWidget {
  final XFile imageFile;
  final String patientId;
  final Function(String finalPath, String downloadUrl) onCompleted;
  final VoidCallback onRetake;
  final VoidCallback onChooseAnother;

  const PhotoEditScreen({
    super.key,
    required this.imageFile,
    required this.patientId,
    required this.onCompleted,
    required this.onRetake,
    required this.onChooseAnother,
  });

  @override
  State<PhotoEditScreen> createState() => _PhotoEditScreenState();
}

class _PhotoEditScreenState extends State<PhotoEditScreen> {
  final TransformationController _transformationController = TransformationController();
  double _rotationAngle = 0;
  bool _isCircle = true;
  bool _isProcessing = false;
  late Uint8List _imageBytes;
  bool _bytesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _bytesLoaded = true;
    });
  }

  void _rotateImage() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
  }

  Future<void> _usePhoto() async {
    if (!_bytesLoaded) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      final matrix = _transformationController.value;
      final scale = matrix.getMaxScaleOnAxis();
      final translation = Offset(matrix.entry(0, 3), matrix.entry(1, 3));

      final processedBytes = await _cropAndRotateImage(
        _imageBytes,
        scale,
        translation,
        _rotationAngle,
        _isCircle,
      );

      // Step 1: Save photo locally FIRST (this always works)
      String resultPath;
      if (kIsWeb) {
        final base64Str = base64Encode(processedBytes);
        resultPath = 'data:image/jpeg;base64,$base64Str';
      } else {
        final tempDir = await io.Directory.systemTemp.createTemp();
        final tempFile = io.File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(processedBytes);
        resultPath = tempFile.path;
      }

      // Step 2: Immediately assign the photo to the profile (no waiting for upload)
      String downloadUrl = '';
      widget.onCompleted(resultPath, downloadUrl);

      // Step 3: Try Firebase upload in background (non-blocking)
      _attemptFirebaseUpload(processedBytes);
    } catch (e) {
      debugPrint('Error processing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo processing failed: $e'),
            backgroundColor: AppTheme.dangerColor,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _usePhoto,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _attemptFirebaseUpload(Uint8List processedBytes) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('patient_photos')
          .child('${widget.patientId}.jpg');

      final uploadTask = storageRef.putData(
        processedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Firebase photo upload succeeded: $downloadUrl');
    } catch (e) {
      debugPrint('Firebase background photo upload failed (photo still saved locally): $e');
    }
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
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 80));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xff0a0a0a),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff3b82f6), Color(0xff8b5cf6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.crop_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Edit Photo', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.rotate_right_rounded, color: Colors.white70, size: 22),
              onPressed: _rotateImage,
              tooltip: 'Rotate 90°',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(
                _isCircle ? Icons.crop_square_rounded : Icons.circle_outlined,
                color: Colors.white70,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _isCircle = !_isCircle;
                });
              },
              tooltip: _isCircle ? 'Switch to Square' : 'Switch to Circle',
            ),
          ),
        ],
      ),
      body: _isProcessing || !_bytesLoaded
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xff3b82f6)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isProcessing ? 'Processing your photo...' : 'Loading image...',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Crop area with subtle border glow
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
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
                                _imageBytes,
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
                        // Hint text at the top
                        Positioned(
                          top: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Pinch to zoom • Drag to reposition',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Professional bottom action bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff111111),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Primary action button with gradient
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff3b82f6), Color(0xff2563eb)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xff3b82f6).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _usePhoto,
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                            label: Text(
                              'Use This Photo',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Secondary actions
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white54,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: Text('Cancel', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white54,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                                ),
                              ),
                              onPressed: widget.onRetake,
                              icon: const Icon(Icons.camera_alt_outlined, size: 16),
                              label: Text('Retake', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white54,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                                ),
                              ),
                              onPressed: widget.onChooseAnother,
                              icon: const Icon(Icons.photo_library_outlined, size: 16),
                              label: Text('Gallery', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
