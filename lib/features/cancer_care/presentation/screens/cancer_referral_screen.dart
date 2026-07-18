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

class CancerReferralScreen extends ConsumerStatefulWidget {
  const CancerReferralScreen({super.key});

  @override
  ConsumerState<CancerReferralScreen> createState() => _CancerReferralScreenState();
}

class _CancerReferralScreenState extends ConsumerState<CancerReferralScreen> {
  final _formKey = GlobalKey<FormState>();

  List<CancerPatient> _patients = [];
  CancerPatient? _selectedPatient;
  bool _isLoadingPatients = true;
  List<CancerReferral> _referrals = [];
  bool _isLoadingReferrals = true;

  // Form Fields
  String _screeningResult = 'Breast Cancer - Suspicious Lump';
  final _reasonController = TextEditingController();
  String _hospitalName = 'Regional Cancer Centre, Madurai';
  final _doctorController = TextEditingController();
  DateTime _referralDate = DateTime.now();

  final List<String> _hospitals = [
    'Regional Cancer Centre, Madurai',
    'Madurai Government Medical College Hospital',
    'Primary Health Centre (PHC) Madurai Central',
    'District General Hospital, Madurai',
    'Arignar Anna Memorial Cancer Hospital'
  ];

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _loadAllReferrals();
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

  Future<void> _loadAllReferrals() async {
    final currentRole = ref.read(cancerRoleProvider);
    final repo = ref.read(cancerRepositoryProvider);
    try {
      final list = await repo.getAllReferrals(currentRole, 'LAKSHMI_001');
      setState(() {
        _referrals = list;
        _isLoadingReferrals = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingReferrals = false;
      });
    }
  }

  Future<void> _submitReferral() async {
    final currentRole = ref.read(cancerRoleProvider);
    if (_selectedPatient == null) return;
    if (!_formKey.currentState!.validate()) return;

    final referral = CancerReferral(
      id: 'REF-${DateTime.now().millisecondsSinceEpoch}',
      patientId: _selectedPatient!.id,
      patientName: _selectedPatient!.name,
      age: _selectedPatient!.age,
      gender: _selectedPatient!.gender,
      screeningResult: _screeningResult,
      reasonForReferral: _reasonController.text.trim(),
      hospitalName: _hospitalName,
      doctorName: _doctorController.text.trim(),
      referralDate: _referralDate,
      referralStatus: 'Pending',
    );

    try {
      await ref.read(cancerRepositoryProvider).createReferral(referral, currentRole, 'LAKSHMI_001');
      _reasonController.clear();
      _doctorController.clear();
      _loadAllReferrals(); // Reload list
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral Slip dispatched successfully!'), backgroundColor: AppTheme.secondaryColor),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dispatched failed: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Referral Management', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingPatients
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Draft Referral form
                  Text('Draft New Referral Slip', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _patients.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: AppTheme.warningColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                    child: Text('Register a patient first to make a referral.', style: GoogleFonts.inter(color: AppTheme.warningColor, fontWeight: FontWeight.bold)),
                                  )
                                : DropdownButtonFormField<CancerPatient>(
                                    value: _selectedPatient,
                                    dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                                    decoration: const InputDecoration(labelText: 'Select Patient'),
                                    items: _patients.map((p) {
                                      return DropdownMenuItem<CancerPatient>(value: p, child: Text('${p.name} (${p.id})'));
                                    }).toList(),
                                    onChanged: (p) {
                                      setState(() {
                                        _selectedPatient = p;
                                      });
                                    },
                                  ),
                            const SizedBox(height: 16),

                            TextFormField(
                              initialValue: _screeningResult,
                              decoration: const InputDecoration(labelText: 'Screening Finding Summary'),
                              onChanged: (val) {
                                _screeningResult = val;
                              },
                              validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _reasonController,
                              maxLines: 2,
                              decoration: const InputDecoration(labelText: 'Clinical Reason for Referral'),
                              validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              value: _hospitalName,
                              dropdownColor: isDark ? AppTheme.darkCardColor : Colors.white,
                              decoration: const InputDecoration(labelText: 'Target Cancer Center'),
                              items: _hospitals.map((h) {
                                return DropdownMenuItem<String>(value: h, child: Text(h, style: const TextStyle(fontSize: 12.5)));
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _hospitalName = val!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _doctorController,
                              decoration: const InputDecoration(labelText: 'Target Specialist (Doctor Name)'),
                              validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                            ),
                            const SizedBox(height: 24),

                            ElevatedButton.icon(
                              onPressed: _patients.isEmpty ? null : _submitReferral,
                              icon: const Icon(Icons.send_rounded),
                              label: const Text('Dispatch Referral Slip'),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Referral logs list
                  Text('Dispatched Referrals Ledger', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  if (_isLoadingReferrals)
                    const Center(child: CircularProgressIndicator())
                  else if (_referrals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCardColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('No oncology referrals logged for this district.', style: GoogleFonts.inter(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _referrals.length,
                      itemBuilder: (context, index) {
                        final refSlip = _referrals[index];
                        final dateStr = DateFormat('dd-MMM-yyyy').format(refSlip.referralDate);

                        return FadeInUp(
                          duration: Duration(milliseconds: 200 + (index * 100)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCardColor : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0), width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${refSlip.patientName} (${refSlip.patientId})',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: refSlip.referralStatus == 'Pending'
                                            ? AppTheme.warningColor.withOpacity(0.12)
                                            : AppTheme.secondaryColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        refSlip.referralStatus,
                                        style: TextStyle(
                                          color: refSlip.referralStatus == 'Pending' ? AppTheme.warningColor : AppTheme.secondaryColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const Divider(height: 16),
                                _buildRowDetail('Finding:', refSlip.screeningResult),
                                const SizedBox(height: 6),
                                _buildRowDetail('Reason:', refSlip.reasonForReferral),
                                const SizedBox(height: 6),
                                _buildRowDetail('Center:', refSlip.hospitalName),
                                const SizedBox(height: 6),
                                _buildRowDetail('Doctor:', refSlip.doctorName),
                                const SizedBox(height: 6),
                                _buildRowDetail('Date:', dateStr),
                                const SizedBox(height: 12),
                                
                                // Dynamic Referral PDF printer shortcut
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      // Redirect to print slip
                                      context.push('/cancer-care/reports/${refSlip.patientId}');
                                    },
                                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                                    label: const Text('Print Referral Slip', style: TextStyle(fontSize: 12)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildRowDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.grey)),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 11.5))),
      ],
    );
  }
}
