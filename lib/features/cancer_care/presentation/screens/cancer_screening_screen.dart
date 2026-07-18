import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cancer_models.dart';
import '../../data/repositories/cancer_repository.dart';
import '../../services/cancer_ai_service.dart';
import 'cancer_dashboard_screen.dart';

class CancerScreeningScreen extends ConsumerStatefulWidget {
  const CancerScreeningScreen({super.key});

  @override
  ConsumerState<CancerScreeningScreen> createState() => _CancerScreeningScreenState();
}

class _CancerScreeningScreenState extends ConsumerState<CancerScreeningScreen> {
  final _formKey = GlobalKey<FormState>();
  
  List<CancerPatient> _patients = [];
  CancerPatient? _selectedPatient;
  bool _isLoadingPatients = true;

  String _cancerType = 'Breast';
  final List<String> _selectedSymptoms = [];
  final List<String> _selectedRiskFactors = [];
  final _lifestyleController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  // Medically relevant symptoms checklists
  final Map<String, List<String>> _symptomTemplates = {
    'Breast': [
      'Painless lump or thickening in breast or underarm',
      'Change in size, shape or appearance of the breast',
      'Dimpling, redness or pitting of the breast skin (like orange peel)',
      'Nipple turning inward (retraction) or scaling',
      'Abnormal nipple discharge (blood-stained or clear)'
    ],
    'Cervical': [
      'Irregular vaginal bleeding between periods or after menopause',
      'Abnormal vaginal bleeding after sexual intercourse',
      'Foul-smelling or watery vaginal discharge',
      'Persistent pelvic or lower back pain',
      'Pain during sexual intercourse'
    ],
    'Oral': [
      'Sore or ulcer in the mouth that does not heal within 14 days',
      'White (leukoplakia) or red (erythroplakia) patches on gums, tongue or tonsils',
      'Unexplained loose teeth or bleeding in the mouth',
      'Lump or thickening in the neck or cheek',
      'Difficulty chewing, swallowing, or moving tongue'
    ],
    'Lung': [
      'Persistent cough that gets worse or does not go away',
      'Coughing up blood or rust-colored sputum',
      'Chest pain that worsens with deep breathing or coughing',
      'Shortness of breath or new onset wheezing',
      'Unexplained weight loss and loss of appetite'
    ],
    'Colorectal': [
      'Persistent change in bowel habits (diarrhea, constipation or narrowing)',
      'Bright red blood in stool or dark/tarry stools',
      'Persistent abdominal discomfort (cramping, gas, bloating or pain)',
      'Feeling that the bowel does not empty completely',
      'Weakness, fatigue or unexplained iron deficiency anemia'
    ],
  };

  // Common risk factors
  final Map<String, List<String>> _riskFactorTemplates = {
    'Breast': [
      'Age above 40 years',
      'Family history of breast or ovarian cancer',
      'Early onset of menstruation (before age 12) or late menopause',
      'First pregnancy after age 30 or never been pregnant',
      'Lack of breastfeeding history'
    ],
    'Cervical': [
      'Multiple sexual partners or early marriage',
      'History of Human Papillomavirus (HPV) infection',
      'Weakened immune system (HIV or immunosuppressive therapy)',
      'Poor personal hygiene during menstruation',
      'More than 3 full-term pregnancies'
    ],
    'Oral': [
      'Habit of chewing tobacco, gutkha, or areca nut (supari)',
      'Heavy smoking or bidi usage',
      'Frequent alcohol consumption',
      'Poor oral hygiene or sharp jagged teeth causing chronic irritation',
      'Human Papillomavirus (HPV) oral infection'
    ],
    'Lung': [
      'Active smoking or bidi usage',
      'Exposure to secondhand passive smoke',
      'Occupational exposure to asbestos, arsenic, or chromium dust',
      'History of chronic lung disease (COPD, pulmonary fibrosis)',
      'Exposure to high radon gas levels in household'
    ],
    'Colorectal': [
      'Age above 50 years',
      'Family history of colon cancer or adenomatous polyps',
      'High-fat, low-fiber diet with excessive red/processed meat',
      'Sedentary lifestyle and obesity',
      'Inflammatory bowel disease (Ulcerative Colitis or Crohn\'s)'
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadPatients();
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
          _prefillPatientContext();
        }
      });
    } catch (_) {
      setState(() {
        _isLoadingPatients = false;
      });
    }
  }

  void _prefillPatientContext() {
    if (_selectedPatient == null) return;
    _lifestyleController.text = 'Tobacco Usage: ${_selectedPatient!.tobaccoUsage}. Alcohol: ${_selectedPatient!.alcoholConsumption}.';
    _familyHistoryController.text = 'Family Cancer History: ${_selectedPatient!.familyHistoryOfCancer}';
  }

  @override
  void dispose() {
    _lifestyleController.dispose();
    _familyHistoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _runRiskAnalysis() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or register a patient first.'), backgroundColor: AppTheme.dangerColor),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    final currentRole = ref.read(cancerRoleProvider);
    final aiService = ref.read(cancerAiServiceProvider);
    final repo = ref.read(cancerRepositoryProvider);

    try {
      final result = await aiService.evaluateSymptomRisk(
        cancerType: _cancerType,
        symptoms: _selectedSymptoms,
        riskFactors: _selectedRiskFactors,
        lifestyle: _lifestyleController.text.trim(),
        familyHistory: _familyHistoryController.text.trim(),
        clinicalNotes: _notesController.text.trim(),
      );

      final screening = CancerScreening(
        id: 'SCR-${DateTime.now().millisecondsSinceEpoch}',
        patientId: _selectedPatient!.id,
        patientName: _selectedPatient!.name,
        cancerType: _cancerType,
        symptoms: _selectedSymptoms,
        riskFactors: _selectedRiskFactors,
        lifestyleQuestions: _lifestyleController.text.trim(),
        familyHistory: _familyHistoryController.text.trim(),
        clinicalNotes: _notesController.text.trim(),
        riskLevel: result['riskLevel'] ?? 'Low Risk',
        confidenceScore: (result['confidenceScore'] as num?)?.toDouble() ?? 0.0,
        explanation: result['explanation'] ?? '',
        date: DateTime.now(),
      );

      // Save record in Firestore
      await repo.addScreening(screening, currentRole, 'LAKSHMI_001');

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screening completed. Risk Assessment: ${screening.riskLevel}'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Analysis failed: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low risk':
      case 'low':
        return AppTheme.secondaryColor;
      case 'medium risk':
      case 'medium':
      case 'moderate':
        return AppTheme.warningColor;
      case 'high risk':
      case 'high':
        return Colors.orange.shade700;
      case 'critical risk':
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
        title: Text('Cancer Warning Screening', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
                    // Patient Selection Dropdown
                    Text('Target Patient Selection', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _patients.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.warningColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No registered cancer patients found. Please register a patient first.',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.warningColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<CancerPatient>(
                            value: _selectedPatient,
                            dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                            decoration: const InputDecoration(
                              labelText: 'Select Registered Patient',
                              prefixIcon: Icon(Icons.person_pin_rounded),
                            ),
                            items: _patients.map((p) {
                              return DropdownMenuItem<CancerPatient>(
                                value: p,
                                child: Text('${p.name} (${p.id})'),
                              );
                            }).toList(),
                            onChanged: (p) {
                              setState(() {
                                _selectedPatient = p;
                                _prefillPatientContext();
                              });
                            },
                          ),
                    const SizedBox(height: 24),

                    // Cancer Type Segmented Picker
                    Text('Cancer Classification Target', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: ['Breast', 'Cervical', 'Oral', 'Lung', 'Colorectal'].map((type) {
                          final isSelected = _cancerType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text('$type Cancer'),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _cancerType = type;
                                    _selectedSymptoms.clear();
                                    _selectedRiskFactors.clear();
                                  });
                                }
                              },
                              selectedColor: AppTheme.primaryColor.withOpacity(0.18),
                              labelStyle: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Symptoms checklist
                    Text('Warning Symptoms Checklist', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Column(
                          children: _symptomTemplates[_cancerType]!.map((sym) {
                            final isChecked = _selectedSymptoms.contains(sym);
                            return CheckboxListTile(
                              title: Text(sym, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                              value: isChecked,
                              activeColor: AppTheme.primaryColor,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedSymptoms.add(sym);
                                  } else {
                                    _selectedSymptoms.remove(sym);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Risk Factors Checklist
                    Text('Lifestyle & Biological Risk Factors', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        child: Column(
                          children: _riskFactorTemplates[_cancerType]!.map((risk) {
                            final isChecked = _selectedRiskFactors.contains(risk);
                            return CheckboxListTile(
                              title: Text(risk, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                              value: isChecked,
                              activeColor: AppTheme.primaryColor,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedRiskFactors.add(risk);
                                  } else {
                                    _selectedRiskFactors.remove(risk);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lifestyle and Habits note
                    TextFormField(
                      controller: _lifestyleController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Detailed Lifestyle Habits (Smoking, Diet, etc.)',
                        prefixIcon: Icon(Icons.smoking_rooms_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Family History note
                    TextFormField(
                      controller: _familyHistoryController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Family Cancer History Description',
                        prefixIcon: Icon(Icons.history_edu_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Clinical notes / comments
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'ASHA Clinical Vitals Notes',
                        prefixIcon: Icon(Icons.comment_bank_outlined),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing || _patients.isEmpty ? null : _runRiskAnalysis,
                      icon: _isAnalyzing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.analytics_outlined),
                      label: Text(_isAnalyzing ? 'Computing Gemini Diagnostics...' : 'Evaluate Symptoms using Gemini AI'),
                    ),
                    const SizedBox(height: 32),

                    // Analysis Results Card
                    if (_analysisResult != null)
                      FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        child: _buildResultCard(isDark),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildResultCard(bool isDark) {
    final riskLevel = _analysisResult!['riskLevel'] ?? 'Low Risk';
    final score = _analysisResult!['confidenceScore'] ?? 0.0;
    final explanation = _analysisResult!['explanation'] ?? '';
    final steps = List<String>.from(_analysisResult!['suggestedNextSteps'] ?? []);
    final color = _getRiskColor(riskLevel);

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
            // Header showing risk level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI SCREENING RESULT',
                      style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      riskLevel,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Confidence: ${score.toInt()}%',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            Text(
              'Clinical Explanation:',
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              explanation,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xff334155),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            if (steps.isNotEmpty) ...[
              Text(
                'Suggested Clinical Protocol:',
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
              const SizedBox(height: 24),
            ],

            // Government disclaimer
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
                      'AI-generated screening only. Please consult an oncologist or qualified doctor.',
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
