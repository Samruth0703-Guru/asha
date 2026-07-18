import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/tts_service.dart' as tts;

class ChatAssistantScreen extends ConsumerStatefulWidget {
  const ChatAssistantScreen({super.key});

  @override
  ConsumerState<ChatAssistantScreen> createState() => _ChatAssistantScreenState();
}

class _ChatAssistantScreenState extends ConsumerState<ChatAssistantScreen> with TickerProviderStateMixin {
  final List<AshaMessage> _messages = [];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  
  bool _isVoiceMode = true; // Opens directly in voice hud
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;
  
  // Speech STT
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  String _spokenText = "";
  String _liveSubtitleText = "";

  // Multilingual Configuration
  String _selectedLangCode = 'en';
  final List<Map<String, String>> _supportedLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi / हिन्दी'},
    {'code': 'ta', 'name': 'Tamil / தமிழ்'},
    {'code': 'te', 'name': 'Telugu / తెలుగు'},
    {'code': 'kn', 'name': 'Kannada / ಕನ್ನಡ'},
    {'code': 'ml', 'name': 'Malayalam / മലയാളம்'},
    {'code': 'mr', 'name': 'Marathi / मराठी'},
    {'code': 'gu', 'name': 'Gujarati / ગુજરાતી'},
    {'code': 'bn', 'name': 'Bengali / বাংলা'},
    {'code': 'pa', 'name': 'Punjabi / ਪੰਜਾਬੀ'},
  ];

  // Gemini API integration details
  String _geminiApiKey = "";
  GenerativeModel? _geminiModel;

  // Wave and orb animators
  late AnimationController _waveController;
  late AnimationController _orbPulseController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _orbPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _initSpeechEngine();
    _initDefaultGemini();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final geminiService = ref.read(geminiServiceProvider);
      if (geminiService.apiKey.isNotEmpty) {
        setState(() {
          _geminiApiKey = geminiService.apiKey;
          _initDefaultGemini();
        });
      }
    });
    
    _addMessage(
      'Namaste! I am ASHA AI, your premium health intelligence assistant. How can I help you today?\n\nவணக்கம்! நான் ஆஷா ஐ. இன்று நான் உங்களுக்கு எவ்வாறு உதவ முடியும்?', 
      false
    );
  }

  void _initSpeechEngine() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' && _isListening) {
            _onSpeechListeningStopped();
          }
        },
        onError: (error) {
          setState(() {
            _isListening = false;
          });
        },
      );
      setState(() {
        _speechAvailable = available;
      });
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
    }
  }

  void _initDefaultGemini() {
    // Attempt default initialization if key is present
    if (_geminiApiKey.isNotEmpty) {
      _geminiModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
      );
    }
  }

  @override
  void dispose() {
    tts.stopSpeaking();
    _waveController.dispose();
    _orbPulseController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _startListening() async {
    tts.stopSpeaking();
    if (_isSpeaking) {
      setState(() {
        _isSpeaking = false;
      });
    }
    
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission denied or unavailable. Please type your message instead.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    _spokenText = "";
    setState(() {
      _isListening = true;
      _isThinking = false;
      _liveSubtitleText = "Listening for audio input...";
    });

    try {
      final Map<String, String> localeMap = {
        'en': 'en_IN',
        'hi': 'hi_IN',
        'ta': 'ta_IN',
        'te': 'te_IN',
        'kn': 'kn_IN',
        'ml': 'ml_IN',
        'mr': 'mr_IN',
        'gu': 'gu_IN',
        'bn': 'bn_IN',
        'pa': 'pa_IN',
      };
      await _speech.listen(
        localeId: localeMap[_selectedLangCode] ?? 'en_IN',
        onResult: (result) {
          setState(() {
            _spokenText = result.recognizedWords;
            _liveSubtitleText = _spokenText;
          });
        },
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechListeningStopped() {
    setState(() {
      _isListening = false;
    });
    if (_spokenText.trim().isNotEmpty) {
      _processUserMessage(_spokenText);
    }
  }

  void _processUserMessage(String text) async {
    if (text.trim().isEmpty) return;

    tts.stopSpeaking();
    _addMessage(text, true);
    setState(() {
      _isThinking = true;
      _isListening = false;
      _liveSubtitleText = "AI is computing diagnostics guidance...";
    });

    String responseText = "";

    final geminiService = ref.read(geminiServiceProvider);
    if (geminiService.isConfigured) {
      try {
        final replyData = await geminiService.getVoiceAssistantReply(text, _selectedLangCode);
        responseText = replyData['speechText'] ?? replyData['structuredData']?['speechText'] ?? '';
      } catch (e) {
        responseText = "Gemini API Connection failed: ${e.toString()}\n\nFalling back to local database diagnostics.";
      }
    } else if (_geminiModel != null) {
      try {
        final prompt = '''
You are a smart clinical voice assistant for ASHA healthcare workers in India.
The user is asking: "$text"
Language requested code: $_selectedLangCode. Respond strictly in the translation of this language.
Do not include markdown tags.
''';
        final content = [Content.text(prompt)];
        final response = await _geminiModel!.generateContent(content);
        responseText = response.text ?? "No response generated by model.";
      } catch (e) {
        responseText = "Gemini API Connection failed: ${e.toString()}\n\nFalling back to local database diagnostics.";
      }
    }

    if (responseText.isEmpty || responseText.startsWith("Gemini API Connection failed")) {
      // Offline local database clinical check fallback
      await Future.delayed(const Duration(seconds: 1));
      final cleanQuery = text.toLowerCase();

      // Cancer care queries
      if (cleanQuery.contains("mouth ulcer") || cleanQuery.contains("ulcer") || cleanQuery.contains("புண்") || cleanQuery.contains("छाले")) {
        if (_selectedLangCode == 'ta') {
          responseText = "வாய் புண் மற்றும் வெள்ளை திட்டுக்கள் வாய் புற்றுநோயின் ஆரம்ப அறிகுறிகளாக இருக்கலாம். தயவுசெய்து அருகில் உள்ள ஆரம்ப சுகாதார நிலையத்திற்கு சென்று பரிசோதிக்கவும். புகையிலை பழக்கத்தை உடனடியாக நிறுத்தவும்.";
        } else if (_selectedLangCode == 'hi') {
          responseText = "मुंह के छाले और सफेद धब्बे मुंह के कैंसर के शुरुआती लक्षण हो सकते हैं। कृपया तुरंत जांच के लिए नजदीकी प्राथमिक स्वास्थ्य केंद्र (PHC) जाएं और तंबाकू का सेवन तुरंत बंद करें।";
        } else {
          responseText = "Mouth ulcers or white patches lasting more than 2 weeks can be early warning signs of oral cancer. Please consult the PHC immediately and completely stop tobacco usage.";
        }
      } else if (cleanQuery.contains("breast lump") || cleanQuery.contains("lump") || cleanQuery.contains("கட்டி") || cleanQuery.contains("गांठ")) {
        if (_selectedLangCode == 'ta') {
          responseText = "மார்பகத்தில் வலி இல்லாத கட்டி, மார்பக காம்புகளில் மாற்றம் அல்லது மார்பக தோல் சுருங்குதல் ஆகியவை புற்றுநோயின் எச்சரிக்கை அறிகுறிகள் ஆகும். உடனடியாக ஆரம்ப சுகாதார நிலையத்திற்கு சென்று மேமோகிராபி பரிசோதனை செய்ய பரிந்துரைக்கப்படுகிறது.";
        } else if (_selectedLangCode == 'hi') {
          responseText = "स्तन में दर्द रहित गांठ, त्वचा में खिंचाव या निप्पल से स्राव स्तन कैंसर के लक्षण हो सकते हैं। तुरंत मैमोग्राफी और डॉक्टर से जांच कराने की सलाह दी जाती है।";
        } else {
          responseText = "A painless lump in the breast, nipple discharge, or breast dimpling are warnings for breast cancer. Clinical breast exam and mammography are strongly recommended at the PHC.";
        }
      } else if (cleanQuery.contains("severe pain") || cleanQuery.contains("chemo") || cleanQuery.contains("வலி") || cleanQuery.contains("कीमो")) {
        if (_selectedLangCode == 'ta') {
          responseText = "கீமோதெரபிக்கு பின் கடுமையான வலி அல்லது குமட்டல் இருந்தால், நோயாளிக்கு போதுமான தண்ணீர் கொடுக்கவும். வலி அளவை கண்காணித்து உடனடியாக புற்றுநோய் மருத்துவரை தொடர்பு கொள்ளவும்.";
        } else if (_selectedLangCode == 'hi') {
          responseText = "कीमोथेरेपी के बाद गंभीर दर्द या उल्टी होने पर मरीज को हाइड्रेटेड रखें। दर्द के स्कोर की जांच करें और तुरंत अपने ऑन्कोलॉजिस्ट (कैंसर डॉक्टर) से संपर्क करें।";
        } else {
          responseText = "Severe pain or nausea after chemotherapy requires adequate hydration. Monitor their pain score (1-10) and contact their treating oncologist or refer to the District Hospital.";
        }
      } else if (cleanQuery.contains("next chemotherapy") || cleanQuery.contains("appointment") || cleanQuery.contains("அடுத்த") || cleanQuery.contains("अगला")) {
        if (_selectedLangCode == 'ta') {
          responseText = "அடுத்த கீமோதெரபி சிகிச்சை அட்டவணையை மார்பக/புற்றுநோய் சிகிச்சை கோப்பில் சரிபார்க்கவும். வழக்கமாக 21 நாட்களுக்கு ஒருமுறை இது திட்டமிடப்படும்.";
        } else if (_selectedLangCode == 'hi') {
          responseText = "अगली कीमोथेरेपी की तारीख मरीज की फाइल में दी गई है। कृपया नियमित अपॉइंटमेंट सुनिश्चित करें और फॉलो-अप विजिट शेड्यूल करें।";
        } else {
          responseText = "Please check the patient's oncology file for their next chemotherapy schedule. Ensure travel is pre-arranged and follow-up is logged.";
        }
      } else if (cleanQuery.contains("follow-up") || cleanQuery.contains("visit") || cleanQuery.contains("இன்றைய") || cleanQuery.contains("फॉलो अप")) {
        if (_selectedLangCode == 'ta') {
          responseText = "இன்றைய புற்றுநோய் फॉलो-அட்டு அட்டவணையை புற்றுநோய் டேஷ்போர்டில் பார்க்கலாம். நோயாளியின் மருந்து உட்கொள்ளல் மற்றும் எடையை சரிபார்க்கவும்.";
        } else if (_selectedLangCode == 'hi') {
          responseText = "आज के कैंसर फॉलो-अप और गृह दौरों की सूची देखने के लिए कैंसर केयर डैशबोर्ड पर जाएं।";
        } else {
          responseText = "Today's cancer follow-ups are listed on your Cancer Care Dashboard. Check medication compliance, side effects, and schedule next visit.";
        }
      } else if (cleanQuery.contains("janani") || cleanQuery.contains("scheme") || cleanQuery.contains("திட்டம்")) {
        responseText = "The Janani Suraksha Yojana (JSY) is a safe motherhood intervention under the National Health Mission. It provides cash assistance for institutional delivery, encouraging poor pregnant women to deliver in health facilities:\n\n"
            "- **Cash Support**: ₹1,400 to rural mothers and ₹600 for ASHA workers.\n"
            "- **Next Steps**: Register the mother using their ABHA ID card on ASHA CARE+ dashboard to process auto-claims directly with Madurai PHC block.\n"
            "- **Guidance**: Arrange delivery transportation at least 2 weeks prior to EDD.";
      } else if (cleanQuery.contains("hypertension") || cleanQuery.contains("bp") || cleanQuery.contains("இரத்த அழுத்தம்")) {
        responseText = "Gestational Hypertension warning parameters & clinical protocols:\n\n"
            "- **BP Limit**: Any blood pressure measuring > 140/90 mmHg is classified as high-risk.\n"
            "- **Critical BP**: BP > 160/110 mmHg is classified as Critical Pre-Eclampsia.\n"
            "- **Emergency Intervention**: Administer 4g Magnesium Sulfate IV under PHC supervision. Dispatch emergency vehicle to Madurai Medical College Hospital.\n"
            "- **Next Steps**: Place patient in left lateral position, restrict heavy sodium diets.";
      } else if (cleanQuery.contains("iron") || cleanQuery.contains("ifa") || cleanQuery.contains("மாத்திரை")) {
        responseText = "Iron and Folic Acid (IFA) supplement distribution protocol guidelines:\n\n"
            "- **Dosage**: Take 1 tablet daily (containing 100mg elemental Iron and 500mcg Folic Acid) starting from 14-16th week of pregnancy for 180 days.\n"
            "- **Tamil Instruction**: இரும்புச்சத்து மாத்திரையை உணவுக்குப் பின் எலுமிச்சை சாறு அல்லது தண்ணீருடன் உட்கொள்ள வேண்டும். பால் அல்லது தேநீருடன் உட்கொள்ளக் கூடாது.\n"
            "- **Next Steps**: Monitor patient Hemoglobin levels. If Hb < 9 g/dL, double the daily dosage and refer to PHC officer.";
      } else {
        responseText = "ASHA CARE+ Intelligence guidelines:\n\n"
            "- **Summary**: Healthcare inquiry detected regarding: '$text'.\n"
            "- **Recommendation**: Advise client regular checkups. Take vital screenings for BP, Hb, and sugar parameters during home visits.\n"
            "- **Next Steps**: Register client details to sync local patient records to NHM cloud server.\n"
            "- **Emergency**: Dial 102 helpline desk if severe abdominal pains or blurred vision occurs.";
      }
    }

    if (!mounted) return;
    setState(() {
      _isThinking = false;
      _isSpeaking = true;
      _liveSubtitleText = responseText;
    });

    _addMessage(responseText, false);
    
    // Call Text-to-Speech
    tts.speakText(responseText, _selectedLangCode);
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(AshaMessage(
        text: text,
        isUser: isUser,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openSettingsDialog() {
    final controller = TextEditingController(text: _geminiApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Gemini API Setup', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your Google AI Studio API Key to enable real-time intelligent medical replies.',
              style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                prefixIcon: Icon(Icons.vpn_key_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _geminiApiKey = controller.text.trim();
                _initDefaultGemini();
              });
              ref.read(geminiServiceProvider).setApiKey(_geminiApiKey);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gemini AI Engine Initialized Successfully!'),
                  backgroundColor: AppTheme.secondaryColor,
                ),
              );
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  String _getOrbState() {
    if (_isThinking) return 'thinking';
    if (_isSpeaking) return 'speaking';
    if (_isListening) return 'listening';
    return 'idle';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('ASHA CARE+ AI', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.g_translate_rounded, color: AppTheme.primaryColor),
            tooltip: 'Select Speech Language',
            onSelected: (lang) {
              setState(() {
                _selectedLangCode = lang;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Language changed to: ${_supportedLanguages.firstWhere((element) => element["code"] == lang)["name"]}'),
                  backgroundColor: AppTheme.secondaryColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            itemBuilder: (BuildContext context) {
              return _supportedLanguages.map((lang) {
                return PopupMenuItem<String>(
                  value: lang['code'],
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: _selectedLangCode == lang['code'] ? AppTheme.primaryColor : Colors.transparent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(lang['name']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            onPressed: _openSettingsDialog,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Gemini Engine API Setup',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isVoiceMode = !_isVoiceMode;
                _isListening = false;
                _isSpeaking = false;
                _isThinking = false;
              });
            },
            icon: Icon(
              _isVoiceMode ? Icons.chat_bubble_outline_rounded : Icons.spatial_audio_off_rounded,
              color: AppTheme.primaryColor,
            ),
            tooltip: _isVoiceMode ? 'Chat View Console' : 'Live Voice HUD',
          ),
        ],
      ),
      body: _isVoiceMode ? _buildVoiceModeUI(isDark) : _buildChatModeUI(isDark),
    );
  }

  Widget _buildVoiceModeUI(bool isDark) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xff090d16), const Color(0xff121829)]
              : [const Color(0xfff8fafc), const Color(0xffeff6ff)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dynamic pulsing waves
          Positioned(
            bottom: size.height * 0.22,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (ctx, child) {
                return CustomPaint(
                  size: Size(size.width, 150),
                  painter: LiveWaveformPainter(
                    animationValue: _waveController.value,
                    state: _getOrbState(),
                    primaryColor: AppTheme.primaryColor,
                    secondaryColor: AppTheme.secondaryColor,
                  ),
                );
              },
            ),
          ),

          // Central glowing glassmorphic orb
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
                child: AnimatedBuilder(
                  animation: _orbPulseController,
                  builder: (context, child) {
                    double pulse = _orbPulseController.value;
                    double scale = 1.0 + (pulse * 0.1);
                    return Container(
                      height: 140 * scale,
                      width: 140 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _isListening
                                ? AppTheme.dangerColor.withOpacity(0.9)
                                : (_isThinking
                                    ? Colors.purple.withOpacity(0.9)
                                    : AppTheme.primaryColor.withOpacity(0.9)),
                            _isListening
                                ? AppTheme.dangerColor.withOpacity(0.3)
                                : (_isThinking
                                    ? Colors.purple.withOpacity(0.3)
                                    : AppTheme.secondaryColor.withOpacity(0.3)),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.65, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening
                                    ? AppTheme.dangerColor
                                    : (_isThinking ? Colors.purple : AppTheme.primaryColor))
                                .withOpacity(0.4),
                            blurRadius: 35,
                            spreadRadius: 8,
                          )
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              // Status descriptor text
              Text(
                _isListening
                    ? 'ASHA AI listening...'
                    : (_isThinking ? 'Analyzing clinical parameters...' : 'Tap orb to start continuous voice dialogue'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xff1e293b),
                ),
              ),
            ],
          ),

          // Speech subtitles container
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SUBTITLES TRANSLATION',
                          style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _liveSubtitleText.isEmpty ? 'Waiting for voice audio...' : _liveSubtitleText,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xff334155),
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

  Widget _buildChatModeUI(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length,
            itemBuilder: (ctx, idx) {
              final msg = _messages[idx];
              return _buildChatBubbleWidget(msg, isDark);
            },
          ),
        ),
        if (_isThinking)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('ASHA AI is thinking...', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? AppTheme.darkCardColor : Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    hintText: 'Ask question in English / தமிழ்...',
                  ),
                  onFieldSubmitted: (text) {
                    _processUserMessage(text);
                    _inputController.clear();
                  },
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primaryColor,
                child: IconButton(
                  onPressed: () {
                    _processUserMessage(_inputController.text);
                    _inputController.clear();
                  },
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubbleWidget(AshaMessage msg, bool isDark) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppTheme.primaryColor
              : (isDark ? const Color(0xff1e293b) : Colors.grey.shade100),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.4,
                color: msg.isUser
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xff1e293b)),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 9,
                    color: msg.isUser ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Live custom sinusoidal waveforms painter
class LiveWaveformPainter extends CustomPainter {
  final double animationValue;
  final String state;
  final Color primaryColor;
  final Color secondaryColor;

  LiveWaveformPainter({
    required this.animationValue,
    required this.state,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final centerY = size.height / 2;
    final width = size.width;

    if (state == 'idle') {
      paint.color = primaryColor.withOpacity(0.15);
      canvas.drawLine(Offset(0, centerY), Offset(width, centerY), paint);
      return;
    }

    if (state == 'thinking') {
      paint.style = PaintingStyle.fill;
      paint.color = secondaryColor.withOpacity(0.08);
      final radius = 35.0 + 8.0 * math.sin(animationValue * 2 * math.pi);
      canvas.drawCircle(Offset(width / 2, centerY), radius, paint);

      paint.style = PaintingStyle.stroke;
      paint.color = primaryColor.withOpacity(0.8);
      final outerRadius = 45.0 + 4.0 * math.cos(animationValue * 2 * math.pi);
      canvas.drawCircle(Offset(width / 2, centerY), outerRadius, paint);
      return;
    }

    // Sinusoidal waves for speaking/listening modes
    final double amplitude = state == 'speaking' ? 36.0 : 18.0;
    final double frequency = state == 'speaking' ? 0.02 : 0.012;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      path.moveTo(0, centerY);

      final double offset = i * (math.pi / 3);
      final double speed = (i + 1) * 1.5;
      final double waveOpacity = 1.0 - (i * 0.25);

      paint.color = (i % 2 == 0 ? primaryColor : secondaryColor).withOpacity(waveOpacity * 0.6);
      paint.strokeWidth = 3.0 - (i * 0.5);

      for (double x = 0; x <= width; x += 2) {
        final double y = centerY +
            amplitude *
                math.sin(x * frequency + (animationValue * speed * 2 * math.pi) + offset) *
                math.sin(x * math.pi / width); // Edge tapering
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LiveWaveformPainter oldDelegate) => true;
}

class AshaMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  AshaMessage({required this.text, required this.isUser, required this.time});
}
