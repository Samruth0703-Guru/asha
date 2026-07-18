import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cancer_models.dart';
import '../../data/repositories/cancer_repository.dart';
import 'cancer_dashboard_screen.dart';

class CancerMedicineScreen extends ConsumerStatefulWidget {
  const CancerMedicineScreen({super.key});

  @override
  ConsumerState<CancerMedicineScreen> createState() => _CancerMedicineScreenState();
}

class _CancerMedicineScreenState extends ConsumerState<CancerMedicineScreen> {
  List<CancerPatient> _patients = [];
  CancerPatient? _selectedPatient;
  bool _isLoadingPatients = true;
  CancerTreatment? _activeTreatment;

  // Track missed doses counter locally for simulation
  final Map<String, int> _missedDosesMap = {};
  final Map<String, bool> _remindersMap = {};

  // Oncology Medicine Education Dictionary
  final Map<String, Map<String, String>> _medEducationDict = {
    'doxorubicin': {
      'class': 'Anthracycline Chemotherapy',
      'purpose': 'Stops growth of cancer cells by blocking replication.',
      'precautions': 'Can safely color urine red (harmless side-effect). Report breathlessness or rapid heart rate immediately.',
      'diet': 'Drink lots of fluids. Avoid raw fruits or unpasteurized dairy during low blood count cycles.'
    },
    'cisplatin': {
      'class': 'Platinum Alkylating Chemo agent',
      'purpose': 'Interferes with DNA repair mechanism in tumor tissues.',
      'precautions': 'Kidney function must be audited. Notify doctor of ringing in ears (tinnitus) or cold sensations.',
      'diet': 'Maintain strict hydration (2-3 Litres of fluids daily) to protect kidney tissues.'
    },
    'tamoxifen': {
      'class': 'Hormone Receptor Modulator',
      'purpose': 'Blocks estrogen receptors in ER-positive Breast Cancers.',
      'precautions': 'Hot flashes are common. Report sudden leg pain, swelling or vision blur to oncologist.',
      'diet': 'Avoid grapefruits and Seville oranges as they interfere with drug absorption.'
    },
    'paclitaxel': {
      'class': 'Mitotic Inhibitor (Taxane)',
      'purpose': 'Prevents cancer cell division by stabilizing microtubules.',
      'precautions': 'Can cause neuropathy. Report numbness, burning or tingling in fingers or toes immediately.',
      'diet': 'Eat cooked, high-protein foods. Limit sodium if swelling develops.'
    },
    'ondansetron': {
      'class': '5-HT3 Receptor Antagonist (Anti-Emetic)',
      'purpose': 'Prevents nausea and vomiting induced by chemotherapy.',
      'precautions': 'Take 30 minutes before food. Can cause mild headache or constipation.',
      'diet': 'Take with water or light meals. Avoid greasy, heavy, or highly spiced dishes.'
    },
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
          _loadPrescriptions();
        }
      });
    } catch (_) {
      setState(() {
        _isLoadingPatients = false;
      });
    }
  }

  Future<void> _loadPrescriptions() async {
    if (_selectedPatient == null) return;
    final currentRole = ref.read(cancerRoleProvider);
    final repo = ref.read(cancerRepositoryProvider);

    try {
      final treatment = await repo.getTreatment(_selectedPatient!.id, currentRole, 'LAKSHMI_001');
      setState(() {
        _activeTreatment = treatment;
        if (_activeTreatment != null) {
          // Initialize mock variables
          for (var med in _activeTreatment!.medicationList) {
            final name = (med['name'] as String).toLowerCase();
            _missedDosesMap.putIfAbsent(name, () => 0);
            _remindersMap.putIfAbsent(name, () => true);
          }
        }
      });
    } catch (_) {}
  }

  Map<String, String>? _getEducation(String medName) {
    final cleanName = medName.toLowerCase().trim();
    for (var key in _medEducationDict.keys) {
      if (cleanName.contains(key)) {
        return _medEducationDict[key];
      }
    }
    return {
      'class': 'Oncology Medication',
      'purpose': 'Treats cancer pathology as prescribed by the consulting oncologist.',
      'precautions': 'Follow oncologist dosing instructions precisely. Inform doctor of severe rashes, mouth sores, or high fevers.',
      'diet': 'Eat a clean, well-balanced diet. Ensure water is boiled and filtered.'
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Medicine Management', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingPatients
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Prescribe disclaimer message
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
                        const Icon(Icons.gavel_rounded, color: AppTheme.dangerColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'LEGAL DISCLAIMER: ASHA Workers are strictly forbidden from prescribing cancer therapies. This menu displays oncologist prescriptions for patient tracking and compliance checks.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.dangerColor,
                              height: 1.4,
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
                            labelText: 'Patient Profile',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: _patients.map((p) {
                            return DropdownMenuItem<CancerPatient>(value: p, child: Text('${p.name} (${p.id})'));
                          }).toList(),
                          onChanged: (p) {
                            setState(() {
                              _selectedPatient = p;
                              _loadPrescriptions();
                            });
                          },
                        ),
                    const SizedBox(height: 24),

                    // Prescribed Medications List
                    Text('Active Chemotherapy Prescriptions', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (_activeTreatment == null || _activeTreatment!.medicationList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCardColor : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No active oncological prescriptions logged for this patient.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activeTreatment!.medicationList.length,
                        itemBuilder: (context, index) {
                          final med = _activeTreatment!.medicationList[index];
                          final medName = med['name'] ?? 'Unknown Medicine';
                          final dosage = med['dosage'] ?? 'N/A';
                          final freq = med['frequency'] ?? 'N/A';
                          final cleanName = medName.toLowerCase().trim();

                          final missed = _missedDosesMap[cleanName] ?? 0;
                          final reminder = _remindersMap[cleanName] ?? true;
                          final edu = _getEducation(medName)!;

                          return FadeInUp(
                            duration: Duration(milliseconds: 200 + (index * 100)),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkCardColor : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0xff1f2937) : const Color(0xffe2e8f0),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              medName,
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Dosage: $dosage • Frequency: $freq',
                                              style: GoogleFonts.inter(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: reminder,
                                        activeColor: AppTheme.secondaryColor,
                                        onChanged: (val) {
                                          setState(() {
                                            _remindersMap[cleanName] = val;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(val 
                                                  ? 'Daily alert reminder enabled for $medName' 
                                                  : 'Reminders disabled for $medName'),
                                              backgroundColor: AppTheme.secondaryColor,
                                            ),
                                          );
                                        },
                                      )
                                    ],
                                  ),
                                  const Divider(height: 24),

                                  // Missed doses logic
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Missed Doses Counters: $missed',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: missed > 0 ? AppTheme.dangerColor : Colors.grey,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _missedDosesMap[cleanName] = missed + 1;
                                              });
                                            },
                                            icon: const Icon(Icons.add_circle_outline, size: 16, color: AppTheme.dangerColor),
                                            label: Text('Log Missed Dose', style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.dangerColor, fontWeight: FontWeight.bold)),
                                          ),
                                          if (missed > 0)
                                            IconButton(
                                              icon: const Icon(Icons.undo_rounded, size: 16, color: Colors.grey),
                                              onPressed: () {
                                                setState(() {
                                                  _missedDosesMap[cleanName] = missed - 1;
                                                });
                                              },
                                            )
                                        ],
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Drug Education Section
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Patient Counseling Guide (${edu['class']})',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white70 : const Color(0xff475569),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildEduRow('Action:', edu['purpose']!),
                                        const SizedBox(height: 6),
                                        _buildEduRow('Warning:', edu['precautions']!),
                                        const SizedBox(height: 6),
                                        _buildEduRow('Diet Advice:', edu['diet']!),
                                      ],
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

  Widget _buildEduRow(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title ',
          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
        Expanded(
          child: Text(
            desc,
            style: GoogleFonts.inter(fontSize: 11.5, height: 1.3),
          ),
        ),
      ],
    );
  }
}
