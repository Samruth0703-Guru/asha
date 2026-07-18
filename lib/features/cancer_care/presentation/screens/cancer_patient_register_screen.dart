import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cancer_models.dart';
import '../../data/repositories/cancer_repository.dart';
import 'cancer_dashboard_screen.dart';

class CancerPatientRegisterScreen extends ConsumerStatefulWidget {
  const CancerPatientRegisterScreen({super.key});

  @override
  ConsumerState<CancerPatientRegisterScreen> createState() => _CancerPatientRegisterScreenState();
}

class _CancerPatientRegisterScreenState extends ConsumerState<CancerPatientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _diseasesController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _gender = 'Female';
  String _bloodGroup = 'O+';
  String _familyHistory = 'No';
  String _tobaccoUsage = 'No';
  String _alcoholConsumption = 'No';
  String _pregnancyStatus = 'No';
  double _bmi = 0.0;
  late String _generatedPatientId;

  @override
  void initState() {
    super.initState();
    _generatedPatientId = _generateId();
    _heightController.addListener(_calculateBmi);
    _weightController.addListener(_calculateBmi);
  }

  String _generateId() {
    final randomPart = math.Random().nextInt(9000) + 1000;
    return 'CAN-2026-$randomPart';
  }

  void _calculateBmi() {
    final hStr = _heightController.text.trim();
    final wStr = _weightController.text.trim();
    if (hStr.isEmpty || wStr.isEmpty) {
      setState(() {
        _bmi = 0.0;
      });
      return;
    }

    final h = double.tryParse(hStr);
    final w = double.tryParse(wStr);

    if (h != null && w != null && h > 0) {
      final hMeter = h / 100.0;
      setState(() {
        _bmi = w / (hMeter * hMeter);
      });
    } else {
      setState(() {
        _bmi = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _aadhaarController.dispose();
    _diseasesController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final currentRole = ref.read(cancerRoleProvider);
    if (currentRole == 'Doctor') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied. Doctors cannot edit registrations (View-Only mode).'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final patient = CancerPatient(
      id: _generatedPatientId,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      gender: _gender,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      village: _villageController.text.trim(),
      district: _districtController.text.trim(),
      aadhaar: _aadhaarController.text.trim(),
      bloodGroup: _bloodGroup,
      existingDiseases: _diseasesController.text.trim(),
      familyHistoryOfCancer: _familyHistory,
      tobaccoUsage: _tobaccoUsage,
      alcoholConsumption: _alcoholConsumption,
      height: double.tryParse(_heightController.text.trim()) ?? 0.0,
      weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
      bmi: double.tryParse(_bmi.toStringAsFixed(1)) ?? 0.0,
      pregnancyStatus: _gender == 'Female' ? _pregnancyStatus : 'N/A',
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(cancerRepositoryProvider).registerPatient(
        patient,
        currentRole,
        'LAKSHMI_001',
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Patient registered successfully! ID: $_generatedPatientId'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Failed: ${e.toString()}'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRole = ref.watch(cancerRoleProvider);
    final isDoctor = currentRole == 'Doctor';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Register Cancer Patient', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warn Doctor view-only status
              if (isDoctor)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dangerColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.dangerColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You are logged in as Doctor (View Only). You cannot submit registrations.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dangerColor,
                          ),
                        ),
                      )
                    ],
                  ),
                ),

              // ID Display card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCardColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AUTO-GENERATED PATIENT ID',
                          style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _generatedPatientId,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
                      tooltip: 'Regenerate ID',
                      onPressed: isDoctor ? null : () {
                        setState(() {
                          _generatedPatientId = _generateId();
                        });
                      },
                    )
                  ],
                ),
              ),

              Text('Personal Information', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                enabled: !isDoctor,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      enabled: !isDoctor,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.calendar_month_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_outlined)),
                      dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                      items: <String>['Male', 'Female', 'Other'].map((String val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val));
                      }).toList(),
                      onChanged: isDoctor ? null : (val) {
                        setState(() {
                          _gender = val!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                enabled: !isDoctor,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone_android_outlined), counterText: ''),
                validator: (val) => val == null || val.length < 10 ? 'Enter valid 10-digit number' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _aadhaarController,
                enabled: !isDoctor,
                keyboardType: TextInputType.number,
                maxLength: 12,
                decoration: const InputDecoration(labelText: 'Aadhaar Number (Optional)', prefixIcon: Icon(Icons.credit_card_outlined), counterText: ''),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _bloodGroup,
                decoration: const InputDecoration(labelText: 'Blood Group', prefixIcon: Icon(Icons.bloodtype_outlined)),
                dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                items: <String>['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((String val) {
                  return DropdownMenuItem<String>(value: val, child: Text(val));
                }).toList(),
                onChanged: isDoctor ? null : (val) {
                  setState(() {
                    _bloodGroup = val!;
                  });
                },
              ),
              const SizedBox(height: 28),

              Text('Address Details', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                enabled: !isDoctor,
                decoration: const InputDecoration(labelText: 'Residential Address', prefixIcon: Icon(Icons.home_outlined)),
                validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _villageController,
                      enabled: !isDoctor,
                      decoration: const InputDecoration(labelText: 'Village', prefixIcon: Icon(Icons.location_city_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      enabled: !isDoctor,
                      decoration: const InputDecoration(labelText: 'District', prefixIcon: Icon(Icons.map_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Text('Biometrics & Vital Stats', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      enabled: !isDoctor,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      enabled: !isDoctor,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined)),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // BMI Display box (Auto Computed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff1e293b) : const Color(0xffeff6ff),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Computed BMI Score:',
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _bmi > 0 ? _bmi.toStringAsFixed(1) : '--',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _bmi > 0 && (_bmi < 18.5 || _bmi >= 25.0)
                            ? AppTheme.warningColor
                            : AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text('Medical History & Habits', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _diseasesController,
                enabled: !isDoctor,
                decoration: const InputDecoration(
                  labelText: 'Existing Diseases (e.g. Diabetes, Hypertension)',
                  prefixIcon: Icon(Icons.coronavirus_outlined),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _familyHistory,
                decoration: const InputDecoration(labelText: 'Family History of Cancer', prefixIcon: Icon(Icons.family_restroom_outlined)),
                dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                items: <String>['No', 'Yes (First-degree relative)', 'Yes (Second-degree relative)'].map((String val) {
                  return DropdownMenuItem<String>(value: val, child: Text(val));
                }).toList(),
                onChanged: isDoctor ? null : (val) {
                  setState(() {
                    _familyHistory = val!;
                  });
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _tobaccoUsage,
                      decoration: const InputDecoration(labelText: 'Tobacco Usage', prefixIcon: Icon(Icons.smoking_rooms_outlined)),
                      dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                      items: <String>['No', 'Occasional', 'Frequent / Daily'].map((String val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val));
                      }).toList(),
                      onChanged: isDoctor ? null : (val) {
                        setState(() {
                          _tobaccoUsage = val!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _alcoholConsumption,
                      decoration: const InputDecoration(labelText: 'Alcohol Consumption', prefixIcon: Icon(Icons.local_bar_outlined)),
                      dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                      items: <String>['No', 'Occasional', 'Frequent / Daily'].map((String val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val));
                      }).toList(),
                      onChanged: isDoctor ? null : (val) {
                        setState(() {
                          _alcoholConsumption = val!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_gender == 'Female')
                FadeInDown(
                  duration: const Duration(milliseconds: 200),
                  child: DropdownButtonFormField<String>(
                    value: _pregnancyStatus,
                    decoration: const InputDecoration(labelText: 'Pregnancy Status', prefixIcon: Icon(Icons.pregnant_woman_outlined)),
                    dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                    items: <String>['No', 'Yes (1st Trimester)', 'Yes (2nd Trimester)', 'Yes (3rd Trimester)', 'Lactating'].map((String val) {
                      return DropdownMenuItem<String>(value: val, child: Text(val));
                    }).toList(),
                    onChanged: isDoctor ? null : (val) {
                      setState(() {
                        _pregnancyStatus = val!;
                      });
                    },
                  ),
                ),
              const SizedBox(height: 36),

              ElevatedButton.icon(
                onPressed: isDoctor ? null : _handleRegister,
                icon: const Icon(Icons.app_registration_rounded),
                label: const Text('Submit Registration'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
