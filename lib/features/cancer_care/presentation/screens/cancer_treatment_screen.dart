import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cancer_models.dart';
import '../../data/repositories/cancer_repository.dart';
import 'cancer_dashboard_screen.dart';

class CancerTreatmentScreen extends ConsumerStatefulWidget {
  const CancerTreatmentScreen({super.key});

  @override
  ConsumerState<CancerTreatmentScreen> createState() => _CancerTreatmentScreenState();
}

class _CancerTreatmentScreenState extends ConsumerState<CancerTreatmentScreen> {
  final _formKey = GlobalKey<FormState>();

  List<CancerPatient> _patients = [];
  CancerPatient? _selectedPatient;
  bool _isLoadingPatients = true;

  // Form Fields
  DateTime _diagnosisDate = DateTime.now();
  String _cancerType = 'Breast';
  String _cancerStage = 'Stage II';
  final _hospitalController = TextEditingController();
  final _doctorController = TextEditingController();
  final _planController = TextEditingController();
  final _surgeryController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _nutritionController = TextEditingController();
  
  int _painScore = 5;
  String _treatmentStatus = 'Under Treatment';

  final List<DateTime> _chemoSchedule = [];
  final List<DateTime> _radioSchedule = [];
  final List<Map<String, dynamic>> _medicationList = []; // { name, dosage, frequency, startDate, endDate }

  // Medications sub-form fields
  final _medNameController = TextEditingController();
  final _medDosageController = TextEditingController();
  final _medFreqController = TextEditingController();
  DateTime _medStartDate = DateTime.now();
  DateTime _medEndDate = DateTime.now().add(const Duration(days: 30));

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
          _loadExistingTreatment();
        }
      });
    } catch (_) {
      setState(() {
        _isLoadingPatients = false;
      });
    }
  }

  Future<void> _loadExistingTreatment() async {
    if (_selectedPatient == null) return;

    final currentRole = ref.read(cancerRoleProvider);
    final repo = ref.read(cancerRepositoryProvider);

    try {
      final treatment = await repo.getTreatment(_selectedPatient!.id, currentRole, 'LAKSHMI_001');
      if (treatment != null) {
        setState(() {
          _diagnosisDate = treatment.diagnosisDate;
          _cancerType = treatment.cancerType;
          _cancerStage = treatment.cancerStage;
          _hospitalController.text = treatment.hospitalName;
          _doctorController.text = treatment.doctorName;
          _planController.text = treatment.treatmentPlan;
          _surgeryController.text = treatment.surgeryDetails;
          _sideEffectsController.text = treatment.sideEffects;
          _nutritionController.text = treatment.nutritionNotes;
          _painScore = treatment.painScore;
          _treatmentStatus = treatment.treatmentStatus;
          
          _chemoSchedule.clear();
          _chemoSchedule.addAll(treatment.chemotherapySchedule);
          _radioSchedule.clear();
          _radioSchedule.addAll(treatment.radiotherapySchedule);
          _medicationList.clear();
          _medicationList.addAll(treatment.medicationList);
        });
      } else {
        // Clear forms for new entry
        setState(() {
          _hospitalController.clear();
          _doctorController.clear();
          _planController.clear();
          _surgeryController.clear();
          _sideEffectsController.clear();
          _nutritionController.clear();
          _chemoSchedule.clear();
          _radioSchedule.clear();
          _medicationList.clear();
          _painScore = 5;
          _treatmentStatus = 'Under Treatment';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _hospitalController.dispose();
    _doctorController.dispose();
    _planController.dispose();
    _surgeryController.dispose();
    _sideEffectsController.dispose();
    _nutritionController.dispose();
    _medNameController.dispose();
    _medDosageController.dispose();
    _medFreqController.dispose();
    super.dispose();
  }

  Future<void> _addChemoDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
    );
    if (picked != null) {
      setState(() {
        _chemoSchedule.add(picked);
        _chemoSchedule.sort();
      });
    }
  }

  Future<void> _addRadioDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
    );
    if (picked != null) {
      setState(() {
        _radioSchedule.add(picked);
        _radioSchedule.sort();
      });
    }
  }

  void _addMedication() {
    final name = _medNameController.text.trim();
    final dosage = _medDosageController.text.trim();
    final freq = _medFreqController.text.trim();

    if (name.isEmpty || dosage.isEmpty || freq.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all medication fields'), backgroundColor: AppTheme.dangerColor),
      );
      return;
    }

    setState(() {
      _medicationList.add({
        'name': name,
        'dosage': dosage,
        'frequency': freq,
        'startDate': DateFormat('yyyy-MM-dd').format(_medStartDate),
        'endDate': DateFormat('yyyy-MM-dd').format(_medEndDate),
      });

      _medNameController.clear();
      _medDosageController.clear();
      _medFreqController.clear();
    });
  }

  Future<void> _saveTreatmentPlan() async {
    final currentRole = ref.read(cancerRoleProvider);
    if (currentRole == 'ASHA Worker') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied. ASHA Workers cannot modify treatment files.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    if (_selectedPatient == null) return;
    if (!_formKey.currentState!.validate()) return;

    final treatment = CancerTreatment(
      patientId: _selectedPatient!.id,
      diagnosisDate: _diagnosisDate,
      cancerType: _cancerType,
      cancerStage: _cancerStage,
      hospitalName: _hospitalController.text.trim(),
      doctorName: _doctorController.text.trim(),
      treatmentPlan: _planController.text.trim(),
      chemotherapySchedule: _chemoSchedule,
      radiotherapySchedule: _radioSchedule,
      surgeryDetails: _surgeryController.text.trim(),
      medicationList: _medicationList,
      followUpDates: [],
      treatmentStatus: _treatmentStatus,
      sideEffects: _sideEffectsController.text.trim(),
      nutritionNotes: _nutritionController.text.trim(),
      painScore: _painScore,
    );

    try {
      await ref.read(cancerRepositoryProvider).updateTreatment(treatment, currentRole, 'LAKSHMI_001');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treatment plan saved successfully!'), backgroundColor: AppTheme.secondaryColor),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save treatment: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRole = ref.watch(cancerRoleProvider);
    final isAsha = currentRole == 'ASHA Worker'; // View Only

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isAsha ? 'View Patient Clinical Chart' : 'Manage Treatment Plans', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
                    // ASHA Worker view only banner
                    if (isAsha)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.secondaryColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppTheme.secondaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You are logged in as ASHA Worker (Read-Only). You can view schedules to help home visit follow-ups, but cannot alter medication prescriptions.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),

                    // Patient Selector
                    Text('Select Patient Chart', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
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
                              labelText: 'Active Patient',
                              prefixIcon: Icon(Icons.person),
                            ),
                            items: _patients.map((p) {
                              return DropdownMenuItem<CancerPatient>(value: p, child: Text('${p.name} (${p.id})'));
                            }).toList(),
                            onChanged: (p) {
                              setState(() {
                                _selectedPatient = p;
                                _loadExistingTreatment();
                              });
                            },
                          ),
                    const SizedBox(height: 24),

                    // Clinical details
                    Text('Diagnosis Details', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _cancerType,
                            dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                            decoration: const InputDecoration(labelText: 'Cancer Type'),
                            items: <String>['Breast', 'Cervical', 'Oral', 'Lung', 'Colorectal'].map((type) {
                              return DropdownMenuItem<String>(value: type, child: Text(type));
                            }).toList(),
                            onChanged: isAsha ? null : (val) {
                              setState(() {
                                _cancerType = val!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _cancerStage,
                            dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                            decoration: const InputDecoration(labelText: 'Cancer Stage'),
                            items: <String>['Stage I', 'Stage II', 'Stage III', 'Stage IV'].map((stage) {
                              return DropdownMenuItem<String>(value: stage, child: Text(stage));
                            }).toList(),
                            onChanged: isAsha ? null : (val) {
                              setState(() {
                                _cancerStage = val!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _hospitalController,
                      enabled: !isAsha,
                      decoration: const InputDecoration(labelText: 'Treating Oncology Hospital', prefixIcon: Icon(Icons.apartment_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _doctorController,
                      enabled: !isAsha,
                      decoration: const InputDecoration(labelText: 'Consulting Oncologist Name', prefixIcon: Icon(Icons.badge_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 16),

                    // Diagnosis Date Picker
                    OutlinedButton.icon(
                      onPressed: isAsha
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _diagnosisDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _diagnosisDate = picked;
                                });
                              }
                            },
                      icon: const Icon(Icons.date_range),
                      label: Text('Diagnosis Date: ${DateFormat('dd-MMM-yyyy').format(_diagnosisDate)}'),
                    ),
                    const SizedBox(height: 24),

                    Text('Therapy & Surgery Schedules', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Chemo dates list
                    Text('Chemotherapy Cycle Dates:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ..._chemoSchedule.map((date) => Chip(
                              label: Text(DateFormat('dd-MM-yyyy').format(date)),
                              onDeleted: isAsha
                                  ? null
                                  : () {
                                      setState(() {
                                        _chemoSchedule.remove(date);
                                      });
                                    },
                            )),
                        if (!isAsha)
                          ActionChip(
                            label: const Icon(Icons.add, size: 18),
                            onPressed: _addChemoDate,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Radio dates list
                    Text('Radiotherapy Session Dates:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ..._radioSchedule.map((date) => Chip(
                              label: Text(DateFormat('dd-MM-yyyy').format(date)),
                              onDeleted: isAsha
                                  ? null
                                  : () {
                                      setState(() {
                                        _radioSchedule.remove(date);
                                      });
                                    },
                            )),
                        if (!isAsha)
                          ActionChip(
                            label: const Icon(Icons.add, size: 18),
                            onPressed: _addRadioDate,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _surgeryController,
                      enabled: !isAsha,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Surgery Details (if applicable)', prefixIcon: Icon(Icons.content_cut_outlined)),
                    ),
                    const SizedBox(height: 28),

                    // Pain score slider
                    Text('Pain Assessment Score', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Slider(
                      value: _painScore.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: 'Pain Level: $_painScore',
                      activeColor: _painScore > 7
                          ? AppTheme.dangerColor
                          : (_painScore > 4 ? AppTheme.warningColor : AppTheme.secondaryColor),
                      onChanged: isAsha
                          ? null
                          : (val) {
                              setState(() {
                                _painScore = val.toInt();
                              });
                            },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('1 - No Pain', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('5 - Moderate', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('10 - Worst Pain', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 28),

                    Text('Medications Prescription', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Medications list table
                    if (_medicationList.isNotEmpty)
                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FixedColumnWidth(40),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade100),
                            children: [
                              Padding(padding: const EdgeInsets.all(8.0), child: Text('Med Name', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                              Padding(padding: const EdgeInsets.all(8.0), child: Text('Dosage', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                              Padding(padding: const EdgeInsets.all(8.0), child: Text('Freq', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                              const Padding(padding: EdgeInsets.all(8.0), child: Text('')),
                            ],
                          ),
                          ..._medicationList.map((med) => TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(8.0), child: Text(med['name'] ?? '', style: GoogleFonts.inter(fontSize: 12))),
                                  Padding(padding: const EdgeInsets.all(8.0), child: Text(med['dosage'] ?? '', style: GoogleFonts.inter(fontSize: 12))),
                                  Padding(padding: const EdgeInsets.all(8.0), child: Text(med['frequency'] ?? '', style: GoogleFonts.inter(fontSize: 12))),
                                  Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor),
                                      onPressed: isAsha
                                          ? null
                                          : () {
                                              setState(() {
                                                _medicationList.remove(med);
                                              });
                                            },
                                    ),
                                  ),
                                ],
                              )),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Add med row (only if not ASHA)
                    if (!isAsha)
                      Card(
                        color: isDark ? AppTheme.darkCardColor : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Add Prescription Medicine', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _medNameController,
                                decoration: const InputDecoration(labelText: 'Medicine Name', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _medDosageController,
                                      decoration: const InputDecoration(labelText: 'Dosage (e.g. 50mg)', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _medFreqController,
                                      decoration: const InputDecoration(labelText: 'Freq (e.g. 1-0-1)', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                                onPressed: _addMedication,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Medicine to List'),
                              )
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),

                    Text('Supportive Care & Lifestyle', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _sideEffectsController,
                      enabled: !isAsha,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Side Effects Observed (Nausea, Hair loss, etc.)', prefixIcon: Icon(Icons.warning_amber_rounded)),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nutritionController,
                      enabled: !isAsha,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Dietary & Nutrition Plan Notes', prefixIcon: Icon(Icons.rice_bowl_outlined)),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _treatmentStatus,
                      dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                      decoration: const InputDecoration(labelText: 'Active Status'),
                      items: <String>['Under Treatment', 'Completed', 'Remission Surveillance', 'Suspended'].map((status) {
                        return DropdownMenuItem<String>(value: status, child: Text(status));
                      }).toList(),
                      onChanged: isAsha ? null : (val) {
                        setState(() {
                          _treatmentStatus = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 36),

                    ElevatedButton.icon(
                      onPressed: isAsha || _patients.isEmpty ? null : _saveTreatmentPlan,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Treatment Chart'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
