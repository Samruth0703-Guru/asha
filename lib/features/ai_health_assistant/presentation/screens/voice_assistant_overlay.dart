import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/tts_service.dart' as tts;
import '../../../../core/services/stt_service.dart';

class VoiceAssistantOverlay extends ConsumerStatefulWidget {
  final Map<String, dynamic>? patientContext;
  const VoiceAssistantOverlay({super.key, this.patientContext});

  @override
  ConsumerState<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends ConsumerState<VoiceAssistantOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  // Assistant states
  String _assistantState = 'idle'; // 'idle', 'listening', 'thinking', 'speaking', 'error'
  String _spokenText = "";
  String _aiSpeechReply = "";
  Map<String, dynamic>? _structuredData;

  // TTS parameters
  String _selectedLang = 'en';
  double _ttsRate = 1.0;
  double _ttsPitch = 1.0;
  bool _isSpeaking = false;
  bool _isPaused = false;

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
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Initialize Speech to Text Callback
    sttServiceProvider.init((transcript) {
      setState(() {
        _spokenText = transcript;
      });
      _processUserInput(transcript);
    }, (sttState) {
      if (sttState == 'listening') {
        setState(() {
          _assistantState = 'listening';
          _spokenText = "Listening...";
        });
      } else if (sttState == 'idle' && _assistantState == 'listening') {
        setState(() {
          _assistantState = 'thinking';
        });
      } else if (sttState == 'error') {
        setState(() {
          _assistantState = 'error';
        });
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _stopSpeaking();
    sttServiceProvider.stop();
    super.dispose();
  }

  void _startListening() {
    _stopSpeaking();
    sttServiceProvider.start(_selectedLang);
  }

  void _stopListening() {
    sttServiceProvider.stop();
  }

  Future<void> _processUserInput(String text) async {
    if (text.isEmpty || text == "Listening...") return;
    setState(() {
      _assistantState = 'thinking';
      _structuredData = null;
    });

    try {
      final gemini = ref.read(geminiServiceProvider);
      final response = await gemini.getVoiceAssistantReply(
        text,
        _selectedLang,
        patientContext: widget.patientContext,
      );

      setState(() {
        _aiSpeechReply = response['speechText'] ?? 'No response';
        _structuredData = response['structuredData'];
        _assistantState = 'speaking';
      });

      _speakReply(_aiSpeechReply);
    } catch (e) {
      setState(() {
        _assistantState = 'error';
        _aiSpeechReply = 'System processing error: $e';
      });
    }
  }

  void _speakReply(String text) {
    tts.speakText(text, _selectedLang, rate: _ttsRate, pitch: _ttsPitch);
    setState(() {
      _isSpeaking = true;
      _isPaused = false;
      _assistantState = 'speaking';
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
      _assistantState = 'idle';
    });
  }

  Future<void> _saveVoiceReportToPatient() async {
    if (widget.patientContext == null || _structuredData == null) return;

    try {
      final patientId = widget.patientContext!['id'];
      final patientName = widget.patientContext!['name'];

      final record = {
        'patientId': patientId,
        'patientName': patientName,
        'ashaWorkerId': 'LAKSHMI_001',
        'type': 'voice_consult',
        'query': _spokenText,
        'reply': _aiSpeechReply,
        'structuredData': _structuredData,
        'date': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('health_scans').add({
        'patientId': patientId,
        'patientName': patientName,
        'ashaWorkerId': 'LAKSHMI_001',
        'imageUrl': '', // Voice report has no skin image url
        'confidence': _structuredData!['confidence'] ?? 'N/A',
        'date': Timestamp.now(),
        'analysis': {
          'possibleDisease': _structuredData!['possibleDisease'] ?? 'General Consultation',
          'diseaseCategory': 'Voice Consultation',
          'severity': _structuredData!['emergencyAlert'] != null ? 'High' : 'Low',
          'symptoms': _structuredData!['homeCare'] ?? [],
          'medicines': _structuredData!['suggestedMedicines'] ?? [],
          'homeRemedies': _structuredData!['homeCare'] ?? [],
          'foodsToEat': _structuredData!['dietSuggestions'] ?? [],
          'whenToVisitHospital': _structuredData!['nearestPHC'] ?? '',
          'emergencyWarningSigns': _structuredData!['emergencyAlert'] ?? '',
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Consultation log synced to patient profile!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save context log: $e'), backgroundColor: AppTheme.dangerColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xff090d16),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Drag handle
          _buildOverlayHeader(),

          // Main anim block
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Sine Wave animation
                  _buildAnimatedWaveform(),
                  const SizedBox(height: 16),
                  
                  // Text fields
                  _buildSpokenAndReplyTexts(),
                  const SizedBox(height: 24),

                  // Smart diagnostic widgets
                  if (_structuredData != null) _buildDiagnosticDetailsCard(),
                ],
              ),
            ),
          ),

          // Bottom speech adjustments panel
          _buildPlaybackAdjustmentsBar(),
        ],
      ),
    );
  }

  Widget _buildOverlayHeader() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 48,
          height: 5,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Voice Copilot',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedWaveform() {
    return Column(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                painter: SineWavePainter(
                  phase: _waveController.value * 2 * math.pi,
                  state: _assistantState,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _assistantState == 'listening'
              ? 'Listening...'
              : (_assistantState == 'thinking'
                  ? 'Thinking...'
                  : (_assistantState == 'speaking' ? 'Speaking...' : 'Ready')),
          style: GoogleFonts.inter(
            color: _assistantState == 'listening'
                ? Colors.tealAccent
                : (_assistantState == 'thinking' ? Colors.orangeAccent : Colors.white),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSpokenAndReplyTexts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_spokenText.isNotEmpty) ...[
          Text('ASHA Worker Input:', style: GoogleFonts.inter(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
            child: Text(_spokenText, style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5)),
          ),
          const SizedBox(height: 16),
        ],
        if (_aiSpeechReply.isNotEmpty) ...[
          Text('AI Assistant Output:', style: GoogleFonts.inter(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Text(_aiSpeechReply, style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5, height: 1.4)),
          ),
        ],
      ],
    );
  }

  Widget _buildDiagnosticDetailsCard() {
    final sd = _structuredData!;
    final disease = sd['possibleDisease'] ?? 'General Consultation';
    final confidence = sd['confidence'] ?? 'N/A';
    final medicines = (sd['suggestedMedicines'] as List?) ?? [];
    final homeCare = (sd['homeCare'] as List?) ?? [];
    final diet = (sd['dietSuggestions'] as List?) ?? [];
    final phc = sd['nearestPHC']?.toString() ?? '';
    final emergency = sd['emergencyAlert']?.toString() ?? '';
    final scheme = sd['govScheme']?.toString() ?? '';
    final education = sd['healthEducation']?.toString() ?? '';

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Card(
        color: const Color(0xff121824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CLINICAL ASSISTANT SUMMARY', style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12.5)),
                  if (widget.patientContext != null)
                    TextButton.icon(
                      icon: const Icon(Icons.sync_rounded, size: 14),
                      label: const Text('Save to Profile', style: TextStyle(fontSize: 11)),
                      onPressed: _saveVoiceReportToPatient,
                    ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),

              // Emergency Flash Banner
              if (emergency.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.dangerColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.dangerColor.withOpacity(0.3))),
                  child: Row(
                    children: [
                      const Icon(Icons.crisis_alert_rounded, color: AppTheme.dangerColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(emergency, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11.5, fontWeight: FontWeight.bold, height: 1.35)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Disease name
              Text('Condition evaluated:', style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
              Text('$disease (Confidence: $confidence)', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _buildAssistantSectionList('Suggested Medicines', medicines, Icons.medical_services_rounded),
              const SizedBox(height: 12),
              _buildAssistantSectionList('Home Care Guidance', homeCare, Icons.healing_rounded),
              const SizedBox(height: 12),
              _buildAssistantSectionList('Dietary Guidelines', diet, Icons.restaurant_rounded),
              const SizedBox(height: 12),

              if (phc.isNotEmpty) ...[
                _buildAssistantHeader('PHC Actions', Icons.local_hospital_rounded),
                Text(phc, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.5, height: 1.35)),
                const SizedBox(height: 12),
              ],
              if (scheme.isNotEmpty) ...[
                _buildAssistantHeader('Eligible Gov Schemes', Icons.shield_rounded),
                Text(scheme, style: GoogleFonts.inter(color: Colors.tealAccent, fontSize: 12, height: 1.35)),
                const SizedBox(height: 12),
              ],
              if (education.isNotEmpty) ...[
                _buildAssistantHeader('Health Education Facts', Icons.menu_book_rounded),
                Text(education, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.35)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(title, style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAssistantSectionList(String title, List<dynamic> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAssistantHeader(title, icon),
        ...items.map((i) => Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
              child: Text('• ${i.toString()}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.5)),
            )),
      ],
    );
  }

  Widget _buildPlaybackAdjustmentsBar() {
    return Container(
      color: const Color(0xff0e1422),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              DropdownButton<String>(
                dropdownColor: const Color(0xff0e1422),
                value: _selectedLang,
                style: const TextStyle(color: Colors.white),
                items: _languages.map((l) {
                  return DropdownMenuItem<String>(
                    value: l['code'],
                    child: Text(l['name'] ?? '', style: const TextStyle(fontSize: 12.5)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedLang = val;
                    });
                  }
                },
              ),
              const Spacer(),
              // Rate / Speed
              Text('Speed: ', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
              SizedBox(
                width: 70,
                child: Slider(
                  activeColor: AppTheme.primaryColor,
                  value: _ttsRate,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (v) {
                    setState(() {
                      _ttsRate = v;
                    });
                    if (_isSpeaking && !_isPaused) _speakReply(_aiSpeechReply);
                  },
                ),
              ),
              // Pitch
              Text('Pitch: ', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
              SizedBox(
                width: 70,
                child: Slider(
                  activeColor: AppTheme.secondaryColor,
                  value: _ttsPitch,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (v) {
                    setState(() {
                      _ttsPitch = v;
                    });
                    if (_isSpeaking && !_isPaused) _speakReply(_aiSpeechReply);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play/Pause
              IconButton.filledTonal(
                icon: Icon(_isSpeaking && !_isPaused ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: AppTheme.secondaryColor, minimumSize: const Size(48, 48)),
                onPressed: () {
                  if (_isSpeaking) {
                    if (_isPaused) {
                      _resumeSpeaking();
                    } else {
                      _pauseSpeaking();
                    }
                  } else {
                    if (_aiSpeechReply.isNotEmpty) {
                      _speakReply(_aiSpeechReply);
                    }
                  }
                },
              ),
              const SizedBox(width: 24),
              // Mic / Start Recognition
              IconButton.filled(
                icon: Icon(_assistantState == 'listening' ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: AppTheme.primaryColor, minimumSize: const Size(64, 64)),
                onPressed: () {
                  if (_assistantState == 'listening') {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
              ),
              const SizedBox(width: 24),
              // Stop speech
              IconButton.filledTonal(
                icon: const Icon(Icons.stop_rounded, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: AppTheme.dangerColor, minimumSize: const Size(48, 48)),
                onPressed: _isSpeaking ? _stopSpeaking : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SineWavePainter extends CustomPainter {
  final double phase;
  final String state;

  SineWavePainter({required this.phase, required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final double amplitude = state == 'listening'
        ? 35.0
        : (state == 'speaking' ? 45.0 : (state == 'thinking' ? 12.0 : 4.0));
    final double frequency = state == 'thinking' ? 0.08 : 0.04;

    final paint = Paint()
      ..color = state == 'listening'
          ? Colors.tealAccent.withOpacity(0.8)
          : (state == 'speaking'
              ? AppTheme.primaryColor.withOpacity(0.8)
              : (state == 'thinking' ? Colors.orangeAccent.withOpacity(0.8) : Colors.white24))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double x = 0; x < size.width; x++) {
      final double y = size.height / 2 + amplitude * math.sin(frequency * x + phase);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = paint.color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path2 = Path();
    path2.moveTo(0, size.height / 2);
    for (double x = 0; x < size.width; x++) {
      final double y = size.height / 2 + (amplitude * 0.55) * math.sin((frequency * 0.8) * x + phase + math.pi / 4);
      path2.lineTo(x, y);
    }
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
