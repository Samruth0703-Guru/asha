import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cancer_models.dart';
import '../../data/repositories/cancer_repository.dart';
import 'cancer_dashboard_screen.dart';

class CancerFollowUpScreen extends ConsumerStatefulWidget {
  const CancerFollowUpScreen({super.key});

  @override
  ConsumerState<CancerFollowUpScreen> createState() => _CancerFollowUpScreenState();
}

class _CancerFollowUpScreenState extends ConsumerState<CancerFollowUpScreen> {
  final _formKey = GlobalKey<FormState>();

  List<CancerPatient> _patients = [];
  CancerPatient? _selectedPatient;
  bool _isLoadingPatients = true;

  // Form Fields
  DateTime _visitDate = DateTime.now();
  final _conditionController = TextEditingController();
  String _compliance = 'High';
  final _symptomsController = TextEditingController();
  final _weightChangeController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _commentsController = TextEditingController();
  final _voiceNotesController = TextEditingController();
  DateTime _nextFollowUpDate = DateTime.now().add(const Duration(days: 14)); // Auto-scheduled (14 days later)

  // Speech to Text STT
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadPatients();
    _initSpeechEngine();
  }

  Future<void> _loadPatients() async {
    final currentRole = ref.read(cancerRoleProvider);
    final repo = ref.read(cancerRepositoryProvider);
    try {
      final list = await repo.getPatients(currentRole, 'LAKSHMI_001');
      setState(() {
        _patients = list;
        _isLoadingPatients = false;
        if (_patients.isNotEmpty) {
          _selectedPatient = _patients.first;
        }
      });
    } catch (_) {
      setState(() {
        _isLoadingPatients = false;
      });
    }
  }

  void _initSpeechEngine() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            setState(() {
              _isListening = false;
            });
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
      debugPrint('Speech initialization failed in follow-up: $e');
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      return;
    }

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dictation not available. Please allow microphone permissions.'), backgroundColor: AppTheme.warningColor),
      );
      // Fallback simulated dictation text
      setState(() {
        _voiceNotesController.text += ' [Simulated Dictation: Patient reports mild fatigue but is taking supportive nutrition as advised.]';
      });
      return;
    }

    setState(() {
      _isListening = true;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _voiceNotesController.text = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 10),
      );
    } catch (_) {
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _saveFollowUp() async {
    final currentRole = ref.read(cancerRoleProvider);
    if (_selectedPatient == null) return;
    if (!_formKey.currentState!.validate()) return;

    final followUp = CancerFollowUp(
      id: 'FOL-${DateTime.now().millisecondsSinceEpoch}',
      patientId: _selectedPatient!.id,
      patientName: _selectedPatient!.name,
      visitDate: _visitDate,
      patientCondition: _conditionController.text.trim(),
      medicationCompliance: _compliance,
      symptoms: _symptomsController.text.trim(),
      weightChanges: double.tryParse(_weightChangeController.text.trim()) ?? 0.0,
      sideEffects: _sideEffectsController.text.trim(),
      photoUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&q=80&w=300', // Mock photo url
      doctorComments: _commentsController.text.trim(),
      voiceNotesText: _voiceNotesController.text.trim(),
      nextFollowUpDate: _nextFollowUpDate,
    );

    try {
      await ref.read(cancerRepositoryProvider).addFollowUp(followUp, currentRole, 'LAKSHMI_001');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Follow-up recorded! Next visit: ${DateFormat('dd-MMM').format(_nextFollowUpDate)}'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Log failed: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  @override
  void dispose() {
    _conditionController.dispose();
    _symptomsController.dispose();
    _weightChangeController.dispose();
    _sideEffectsController.dispose();
    _commentsController.dispose();
    _voiceNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Record Home Visit', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingPatients
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Patient Selection
                    Text('Select Visited Patient', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _patients.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.warningColor),
                            ),
                            child: Text(
                              'Please register a patient first.',
                              style: GoogleFonts.inter(color: AppTheme.warningColor, fontWeight: FontWeight.bold),
                            ),
                          )
                        : DropdownButtonFormField<CancerPatient>(
                            value: _selectedPatient,
                            dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                            decoration: const InputDecoration(
                              labelText: 'Select Patient',
                              prefixIcon: Icon(Icons.person),
                            ),
                            items: _patients.map((p) {
                              return DropdownMenuItem<CancerPatient>(value: p, child: Text('${p.name} (${p.id})'));
                            }).toList(),
                            onChanged: (p) {
                              setState(() {
                                _selectedPatient = p;
                              });
                            },
                          ),
                    const SizedBox(height: 24),

                    Text('Visit Summary', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _conditionController,
                      decoration: const InputDecoration(labelText: 'Patient General Condition (e.g. Weakness, Stable)', prefixIcon: Icon(Icons.monitor_heart_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _compliance,
                      dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                      decoration: const InputDecoration(labelText: 'Medication Compliance', prefixIcon: Icon(Icons.done_all_rounded)),
                      items: <String>['High', 'Medium', 'Low'].map((val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _compliance = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _symptomsController,
                      decoration: const InputDecoration(labelText: 'Active Warning Symptoms (if any)', prefixIcon: Icon(Icons.coronavirus_outlined)),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightChangeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Weight Change (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined)),
                            validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sideEffectsController,
                            decoration: const InputDecoration(labelText: 'Side Effects Observed', prefixIcon: Icon(Icons.warning_amber_outlined)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _commentsController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Oncologist Instructions / Comments', prefixIcon: Icon(Icons.comment_bank_outlined)),
                    ),
                    const SizedBox(height: 24),

                    // Voice Notes Dictation Box
                    Text('Voice Notes Dictation', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _voiceNotesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'ASHA Home Observation Dictation',
                              hintText: 'Tap mic to speak observations...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: _isListening ? AppTheme.dangerColor : AppTheme.primaryColor,
                          child: IconButton(
                            icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white),
                            onPressed: _toggleListening,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Auto-scheduler Next Visit Date picker
                    Text('Follow-Up visit Scheduler', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _nextFollowUpDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setState(() {
                            _nextFollowUpDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text('Next Scheduled Visit: ${DateFormat('dd-MMM-yyyy').format(_nextFollowUpDate)} (Auto Scheduled)'),
                    ),
                    const SizedBox(height: 36),

                    ElevatedButton.icon(
                      onPressed: _patients.isEmpty ? null : _saveFollowUp,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Log Home Visit'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
