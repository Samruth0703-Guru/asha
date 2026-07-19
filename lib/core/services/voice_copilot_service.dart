import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/gemini_service.dart';
import '../../features/ai_health_assistant/presentation/providers/voice_copilot_provider.dart';
import '../../features/ai_health_assistant/presentation/widgets/voice_assistant_helper.dart';

/// Global navigator key used by the Voice Copilot to navigate without context.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final voiceCopilotServiceProvider = Provider<VoiceCopilotService>((ref) {
  return VoiceCopilotService(ref);
});

class VoiceCopilotService {
  final Ref _ref;
  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  bool _isActiveConversation = false;
  Timer? _restartTimer;

  // Wake word patterns
  static final RegExp _wakeWordRegex = RegExp(
    r'\b(hey\s*asha|hello\s*asha|hi\s*asha|asha\s*care|asha\s*assistant|asha)\b',
    caseSensitive: false,
  );

  // Emergency keywords
  static final RegExp _emergencyRegex = RegExp(
    r'\b(heart\s*attack|stroke|heavy\s*bleeding|seizure|snake\s*bite|poison|high\s*fever\s*in\s*child|pregnancy\s*emergency|unconscious|not\s*breathing)\b',
    caseSensitive: false,
  );

  // Navigation command map — keyword → route path
  static final Map<String, String> _navigationCommands = {
    'dashboard': '/dashboard',
    'register patient': '/register-patient',
    'new patient': '/register-patient',
    'patient list': '/patient-list',
    'patients': '/patient-list',
    'pregnancy': '/pregnancy-dashboard',
    'vaccination': '/vaccination-dashboard',
    'vaccine calendar': '/vaccination-calendar',
    'health scan': '/health-scan',
    'ai health': '/ai-health-assistant',
    'skin disease': '/scan-skin-disease',
    'ai assistant': '/ai-chat',
    'chat': '/ai-chat',
    'inventory': '/medicine-inventory',
    'medicine': '/medicine-inventory',
    'map': '/village-map',
    'village map': '/village-map',
    'report': '/reports',
    'analytics': '/district-analytics',
    'emergency': '/emergency-hud',
    'visit planner': '/visit-planner',
    'today visit': '/visit-planner',
    'notification': '/notifications',
    'setting': '/settings',
    'sms': '/sms-history',
    'cancer': '/cancer-care',
    'scan history': '/scan-history',
    'high risk': '/patient-list?filter=highRisk',
    'logout': '/login',
  };

  // Emergency first-aid responses (offline fallback)
  static final Map<String, String> _emergencyResponses = {
    'heart attack': 'Make the person sit down and rest. Give aspirin if available. Loosen tight clothing. Call ambulance 108 immediately. Begin CPR if person becomes unresponsive.',
    'stroke': 'Note the time symptoms started. Keep person lying down with head slightly elevated. Do NOT give food or water. Call ambulance 108 immediately.',
    'heavy bleeding': 'Apply firm direct pressure with a clean cloth. Elevate the injured area above heart level if possible. Do NOT remove the cloth. Call ambulance 108.',
    'seizure': 'Clear the area around the person. Place them on their side. Do NOT put anything in their mouth. Time the seizure. Call ambulance if it lasts more than 5 minutes.',
    'snake bite': 'Keep the person calm and still. Remove jewelry near the bite. Do NOT apply a tourniquet or try to suck the venom. Rush to nearest PHC immediately.',
    'poison': 'Do NOT induce vomiting. Try to identify the poison. Call Poison Control. Rush to nearest hospital immediately.',
    'high fever in child': 'Give paracetamol syrup as per age and weight. Sponge with lukewarm water. Remove excess clothing. Give plenty of fluids. Visit PHC if fever exceeds 103°F.',
    'pregnancy emergency': 'Keep the mother lying on her left side. Do NOT give food or water. Keep her warm. Call ambulance 108 immediately. Note time of bleeding or contractions.',
  };

  VoiceCopilotService(this._ref);

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[VoiceCopilot] STT status: $status');
          if (status == 'done' || status == 'notListening') {
            if (!_isActiveConversation) {
              _scheduleRestart();
            }
          }
        },
        onError: (error) {
          debugPrint('[VoiceCopilot] STT error: ${error.errorMsg}');
          _scheduleRestart();
        },
      );
      if (_isInitialized) {
        debugPrint('[VoiceCopilot] Initialized. Starting passive listening...');
        _startPassiveListening();
      }
    } catch (e) {
      debugPrint('[VoiceCopilot] Init failed: $e');
    }
  }

  void dispose() {
    _restartTimer?.cancel();
    _speech.cancel();
  }

  // ========================================
  // PHASE 1: Passive (Wake Word) Listening
  // ========================================

  void _startPassiveListening() {
    if (!_isInitialized || _speech.isListening || _isActiveConversation) return;

    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase().trim();
        if (text.isEmpty) return;

        if (_wakeWordRegex.hasMatch(text)) {
          _speech.cancel();
          _onWakeWordDetected();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      cancelOnError: false,
      listenMode: ListenMode.dictation,
    );
  }

  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!_isActiveConversation) {
        _startPassiveListening();
      }
    });
  }

  // ========================================
  // PHASE 2: Wake Word Detected → Active
  // ========================================

  Future<void> _onWakeWordDetected() async {
    _isActiveConversation = true;
    _restartTimer?.cancel();

    _ref.read(voiceCopilotProvider.notifier).setListening('👂 Listening...');

    // Greet user
    await VoiceAssistantHelper.speak("Hello! I'm listening.");

    // Brief pause to let TTS finish before listening
    await Future.delayed(const Duration(milliseconds: 1600));

    _startActiveListening();
  }

  // ========================================
  // PHASE 3: Active Command Listening
  // ========================================

  void _startActiveListening() {
    if (!_isInitialized) {
      _endSession();
      return;
    }

    _ref.read(voiceCopilotProvider.notifier).setListening('👂 Listening...');

    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        _ref.read(voiceCopilotProvider.notifier).setListening(text);

        if (result.finalResult && text.trim().isNotEmpty) {
          _speech.cancel();
          _processCommand(text.trim());
        }
      },
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: false,
      listenMode: ListenMode.dictation,
    );
  }

  // ========================================
  // PHASE 4: Command Processing & Routing
  // ========================================

  Future<void> _processCommand(String command) async {
    final lowerCommand = command.toLowerCase();

    // 1. Emergency check (highest priority)
    final emergencyMatch = _emergencyRegex.firstMatch(lowerCommand);
    if (emergencyMatch != null) {
      await _handleEmergency(emergencyMatch.group(0)!);
      return;
    }

    // 2. Navigation command check
    for (final entry in _navigationCommands.entries) {
      if (lowerCommand.contains(entry.key)) {
        await _navigateTo(entry.value, entry.key);
        return;
      }
    }

    // 3. Search patient by name (e.g., "open patient Samruth")
    final patientSearchMatch = RegExp(r'(?:open|search|find|show)\s*patient\s+(\w+)', caseSensitive: false).firstMatch(lowerCommand);
    if (patientSearchMatch != null) {
      final patientName = patientSearchMatch.group(1)!;
      await _navigateTo('/patient-list?filter=$patientName', 'Searching for patient $patientName');
      return;
    }

    // 4. Conversational AI fallback (medical questions, general queries)
    await _handleMedicalQuery(command);
  }

  // ========================================
  // Handlers
  // ========================================

  Future<void> _handleEmergency(String keyword) async {
    final key = _emergencyResponses.keys.firstWhere(
      (k) => keyword.contains(k),
      orElse: () => '',
    );

    final instructions = _emergencyResponses[key] ??
        'This is an emergency. Call ambulance 108 immediately. Rush to the nearest Primary Health Center.';

    _ref.read(voiceCopilotProvider.notifier).setEmergency(instructions);

    await VoiceAssistantHelper.stop();
    await VoiceAssistantHelper.speak(
      'Emergency detected! $instructions',
    );

    // Navigate to emergency HUD
    _navigateWithRouter('/emergency-hud');

    // Return to passive listening after a delay
    Future.delayed(const Duration(seconds: 15), () {
      _endSession();
    });
  }

  Future<void> _navigateTo(String path, String description) async {
    final humanLabel = description[0].toUpperCase() + description.substring(1);
    _ref.read(voiceCopilotProvider.notifier).setSpeaking('Opening $humanLabel');

    await VoiceAssistantHelper.speak('Opening $humanLabel.');

    _navigateWithRouter(path);

    Future.delayed(const Duration(seconds: 2), () {
      _endSession();
    });
  }

  Future<void> _handleMedicalQuery(String question) async {
    _ref.read(voiceCopilotProvider.notifier).setThinking();

    try {
      final gemini = _ref.read(geminiServiceProvider);
      final response = await gemini.askMedicalQuestion(question);

      _ref.read(voiceCopilotProvider.notifier).setSpeaking(response);
      await VoiceAssistantHelper.speak(response);
    } catch (e) {
      debugPrint('[VoiceCopilot] Gemini error: $e');
      _ref.read(voiceCopilotProvider.notifier).setSpeaking(
        'I could not connect to the AI service. Please check your internet.',
      );
      await VoiceAssistantHelper.speak(
        'I could not connect to the AI service. Please check your internet.',
      );
    }

    // After TTS finishes, listen again for follow-up
    Future.delayed(const Duration(seconds: 3), () {
      if (_isActiveConversation) {
        _startActiveListening();
      }
    });
  }

  void _navigateWithRouter(String path) {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).go(path);
    } else {
      debugPrint('[VoiceCopilot] No navigator context available for routing.');
    }
  }

  // ========================================
  // Voice Interrupt (like ChatGPT Voice)
  // ========================================

  Future<void> interruptAndListen() async {
    await VoiceAssistantHelper.stop();
    _speech.cancel();
    _isActiveConversation = true;
    _startActiveListening();
  }

  void _endSession() {
    _isActiveConversation = false;
    _ref.read(voiceCopilotProvider.notifier).setIdle();
    _scheduleRestart();
  }

  /// Called from outside to manually activate (e.g., tapping the mic icon)
  Future<void> manualActivate() async {
    _speech.cancel();
    await _onWakeWordDetected();
  }
}
