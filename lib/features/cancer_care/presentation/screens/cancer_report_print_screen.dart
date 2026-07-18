import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cancer_models.dart';
import '../../data/repositories/cancer_repository.dart';
import 'cancer_dashboard_screen.dart';

import '../../../../core/services/print_service.dart' as print_svc;

class CancerReportPrintScreen extends ConsumerStatefulWidget {
  final String patientId;
  const CancerReportPrintScreen({super.key, required this.patientId});

  @override
  ConsumerState<CancerReportPrintScreen> createState() => _CancerReportPrintScreenState();
}

class _CancerReportPrintScreenState extends ConsumerState<CancerReportPrintScreen> {
  CancerPatient? _patient;
  List<CancerScreening> _screenings = [];
  CancerTreatment? _treatment;
  List<CancerFollowUp> _followUps = [];
  List<CancerReferral> _referrals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDossier();
  }

  Future<void> _loadDossier() async {
    final currentRole = ref.read(cancerRoleProvider);
    final repo = ref.read(cancerRepositoryProvider);
    final userId = 'LAKSHMI_001';

    try {
      final patients = await repo.getPatients(currentRole, userId);
      final pMatch = patients.where((p) => p.id == widget.patientId).toList();
      
      if (pMatch.isNotEmpty) {
        _patient = pMatch.first;
        _screenings = await repo.getScreenings(widget.patientId, currentRole, userId);
        _treatment = await repo.getTreatment(widget.patientId, currentRole, userId);
        _followUps = await repo.getFollowUps(widget.patientId, currentRole, userId);
        _referrals = await repo.getReferrals(widget.patientId, currentRole, userId);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _triggerNativePrint() {
    if (_patient == null) return;
    
    // HTML string compilation for printing
    String html = '''
      <html>
      <head>
        <title>ASHA CARE+ Cancer Patient Dossier</title>
        <style>
          body { font-family: Arial, sans-serif; padding: 40px; color: #0f172a; line-height: 1.5; }
          h1 { color: #1e3a8a; font-size: 26px; border-bottom: 3px solid #2563eb; padding-bottom: 8px; margin-bottom: 2px; }
          h2 { color: #0f172a; font-size: 16px; margin-top: 30px; border-bottom: 1.5px solid #cbd5e1; padding-bottom: 4px; }
          p.meta { color: #64748b; font-size: 12px; margin-bottom: 30px; }
          .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-top: 15px; }
          .grid-item { font-size: 13px; }
          .label { font-weight: bold; color: #475569; }
          table { width: 100%; border-collapse: collapse; margin-top: 15px; }
          th, td { border: 1px solid #e2e8f0; padding: 10px 12px; text-align: left; font-size: 12.5px; }
          th { background-color: #f8fafc; color: #475569; font-weight: 600; }
          .card { background-color: #f8fafc; border: 1px solid #e2e8f0; padding: 15px; border-radius: 8px; margin-top: 15px; }
          .disclaimer { border-left: 4px solid #ef4444; padding-left: 12px; font-style: italic; color: #991b1b; background-color: #fef2f2; padding: 10px; margin-top: 25px; font-size: 12px; }
          .signature-box { margin-top: 60px; display: flex; justify-content: space-between; font-size: 13px; }
          .sig-line { border-top: 1.5px solid #94a3b8; width: 220px; text-align: center; padding-top: 6px; }
        </style>
      </head>
      <body>
        <h1>NATIONAL HEALTH MISSION - CANCER REGISTRY</h1>
        <p class="meta">Patient Dossier ID: ${_patient!.id} • Generated: ${DateFormat('dd-MMM-yyyy HH:mm').format(DateTime.now())} • Operator: Lakshmi ASHA_001</p>
        
        <h2>1. Patient Demographics</h2>
        <div class="grid">
          <div class="grid-item"><span class="label">Full Name:</span> ${_patient!.name}</div>
          <div class="grid-item"><span class="label">Age / Gender:</span> ${_patient!.age} yrs / ${_patient!.gender}</div>
          <div class="grid-item"><span class="label">Contact Number:</span> ${_patient!.phone}</div>
          <div class="grid-item"><span class="label">Blood Group:</span> ${_patient!.bloodGroup}</div>
          <div class="grid-item"><span class="label">Residential Village:</span> ${_patient!.village}</div>
          <div class="grid-item"><span class="label">District / Block:</span> ${_patient!.district}</div>
          <div class="grid-item"><span class="label">Height / Weight / BMI:</span> ${_patient!.height} cm / ${_patient!.weight} kg / ${_patient!.bmi}</div>
          <div class="grid-item"><span class="label">Pregnancy Status:</span> ${_patient!.pregnancyStatus}</div>
        </div>

        <h2>2. Cancer Screening & AI Risk Assessment</h2>
        ${_screenings.isEmpty ? '<p>No screenings logged.</p>' : '''
          <table>
            <thead>
              <tr>
                <th>Date</th>
                <th>Cancer Type</th>
                <th>Risk Classification</th>
                <th>Confidence</th>
                <th>Clinical Key Finding</th>
              </tr>
            </thead>
            <tbody>
              ${_screenings.map((s) => '''
                <tr>
                  <td>${DateFormat('dd-MMM-yyyy').format(s.date)}</td>
                  <td>${s.cancerType}</td>
                  <td><strong>${s.riskLevel}</strong></td>
                  <td>${s.confidenceScore.toInt()}%</td>
                  <td>${s.clinicalNotes.isNotEmpty ? s.clinicalNotes : 'N/A'}</td>
                </tr>
              ''').join('')}
            </tbody>
          </table>
        '''}

        <h2>3. Active Treatment Roster</h2>
        ${_treatment == null ? '<p>No treatment records found.</p>' : '''
          <div class="card">
            <div class="grid">
              <div class="grid-item"><span class="label">Diagnosis Date:</span> ${DateFormat('dd-MMM-yyyy').format(_treatment!.diagnosisDate)}</div>
              <div class="grid-item"><span class="label">Oncology Stage:</span> ${_treatment!.cancerStage}</div>
              <div class="grid-item"><span class="label">Treating Centre:</span> ${_treatment!.hospitalName}</div>
              <div class="grid-item"><span class="label">Attending Oncologist:</span> ${_treatment!.doctorName}</div>
            </div>
            <div style="margin-top: 15px; font-size: 13px;">
              <span class="label">Treatment Plan:</span> ${_treatment!.treatmentPlan}
            </div>
            ${_treatment!.chemotherapySchedule.isEmpty ? '' : '''
              <div style="margin-top: 10px; font-size: 13px;">
                <span class="label">Chemotherapy Calendar Cycles:</span> 
                ${_treatment!.chemotherapySchedule.map((d) => DateFormat('dd-MM-yyyy').format(d)).join(', ')}
              </div>
            '''}
            ${_treatment!.surgeryDetails.isEmpty ? '' : '''
              <div style="margin-top: 10px; font-size: 13px;">
                <span class="label">Surgery Notes:</span> ${_treatment!.surgeryDetails}
              </div>
            '''}
          </div>
        '''}

        <h2>4. Supportive Care & Home Visits logs</h2>
        ${_followUps.isEmpty ? '<p>No follow-ups recorded.</p>' : '''
          <table>
            <thead>
              <tr>
                <th>Date</th>
                <th>General Vitals</th>
                <th>Missed Medication</th>
                <th>Symptoms Observed</th>
                <th>Next Scheduled Visit</th>
              </tr>
            </thead>
            <tbody>
              ${_followUps.map((f) => '''
                <tr>
                  <td>${DateFormat('dd-MMM-yyyy').format(f.visitDate)}</td>
                  <td>${f.patientCondition} (Weight: ${f.weightChanges} kg)</td>
                  <td>${f.medicationCompliance} compliance</td>
                  <td>${f.symptoms.isNotEmpty ? f.symptoms : 'None'}</td>
                  <td>${DateFormat('dd-MMM-yyyy').format(f.nextFollowUpDate)}</td>
                </tr>
              ''').join('')}
            </tbody>
          </table>
        '''}

        <h2>5. Specialist Referrals</h2>
        ${_referrals.isEmpty ? '<p>No hospital referrals created.</p>' : '''
          <table>
            <thead>
              <tr>
                <th>Referral Date</th>
                <th>Referred To Hospital</th>
                <th>Doctor</th>
                <th>Referral Reason</th>
                <th>Slip Status</th>
              </tr>
            </thead>
            <tbody>
              ${_referrals.map((r) => '''
                <tr>
                  <td>${DateFormat('dd-MMM-yyyy').format(r.referralDate)}</td>
                  <td>${r.hospitalName}</td>
                  <td>${r.doctorName}</td>
                  <td>${r.reasonForReferral}</td>
                  <td><strong>${r.referralStatus}</strong></td>
                </tr>
              ''').join('')}
            </tbody>
          </table>
        '''}

        <div class="disclaimer">
          <strong>Medical Notice:</strong> AI-generated screening and vital logs are strictly for preliminary community health screening. Confirmed diagnoses and prescriptions require signing authority from the treating Oncologist.
        </div>

        <div class="signature-box">
          <div class="sig-line">
            Lakshmi (ASHA Worker ID 206)<br/>
            Primary Health Centre Madurai
          </div>
          <div class="sig-line">
            Authorized Medical Officer Signature<br/>
            Madurai Oncology Clinic
          </div>
        </div>
      </body>
      </html>
    ''';

    try {
      // Print via the conditional compilation wrapper
      print_svc.printHtml(html);
    } catch (_) {
      // Native Share/PDF conversion simulation fallback using share_plus
      final shareText = '''
NATIONAL HEALTH MISSION - CANCER REGISTRY
Patient ID: ${_patient!.id}
Name: ${_patient!.name}
Age/Gender: ${_patient!.age} / ${_patient!.gender}
Oncology Stage: ${_treatment?.cancerStage ?? 'N/A'}
Chemo Dates: ${_treatment?.chemotherapySchedule.map((d) => DateFormat('dd-MM-yyyy').format(d)).join(', ') ?? 'N/A'}
Referral Center: ${_referrals.isNotEmpty ? _referrals.first.hospitalName : 'N/A'}

Dispatched from ASHA CARE+ Community app.
''';
      Share.share(shareText, subject: 'Cancer Patient Clinical Summary Report');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.grey.shade300,
      appBar: AppBar(
        title: Text('Dossier Print Preview', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Trigger PDF print',
            onPressed: _patient == null ? null : _triggerNativePrint,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patient == null
              ? const Center(child: Text('Patient records not found.'))
              : Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      width: 800,
                      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 16, spreadRadius: 4),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ASHA CARE+',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  Text(
                                    'National Cancer Registry • Govt. of India',
                                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'OFFICIAL RECORD',
                                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                                ),
                              )
                            ],
                          ),
                          const Divider(height: 24, thickness: 1.5),

                          Center(
                            child: Text(
                              'CANCER CLINICAL DOSSIER',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Demographics table
                          _buildSectionTitle('1. Patient Demographics'),
                          const SizedBox(height: 8),
                          _buildDemoGrid(),
                          const SizedBox(height: 24),

                          // Screening list
                          _buildSectionTitle('2. Screenings & AI Evaluations'),
                          const SizedBox(height: 8),
                          _buildScreeningsTable(),
                          const SizedBox(height: 24),

                          // Treatment plan
                          _buildSectionTitle('3. Prescribed Treatment & Chemo Schedules'),
                          const SizedBox(height: 8),
                          _buildTreatmentSection(),
                          const SizedBox(height: 24),

                          // Follow-ups
                          _buildSectionTitle('4. Home Visit Surveillance Logs'),
                          const SizedBox(height: 8),
                          _buildFollowupsTable(),
                          const SizedBox(height: 24),

                          // Referrals
                          _buildSectionTitle('5. Hospital referrals Slips'),
                          const SizedBox(height: 8),
                          _buildReferralsTable(),
                          const SizedBox(height: 32),

                          // Warning Disclaimer
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.red.shade900, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'AI-generated screening only. Please consult an oncologist or qualified doctor.',
                                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Signature fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Container(width: 180, height: 1, color: Colors.grey.shade400),
                                  const SizedBox(height: 4),
                                  Text('ASHA Worker Signature', style: GoogleFonts.inter(fontSize: 11, color: Colors.black87)),
                                  Text('PHC MADURAI', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
                                ],
                              ),
                              Column(
                                children: [
                                  Container(width: 180, height: 1, color: Colors.grey.shade400),
                                  const SizedBox(height: 4),
                                  Text('Medical Officer Signature', style: GoogleFonts.inter(fontSize: 11, color: Colors.black87)),
                                  Text('Madurai General Hospital', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildDemoGrid() {
    Widget gridCell(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Text('$label: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12, color: Colors.black87))),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: gridCell('Name', _patient!.name)),
            Expanded(child: gridCell('Patient ID', _patient!.id)),
          ],
        ),
        Row(
          children: [
            Expanded(child: gridCell('Age / Gender', '${_patient!.age} yrs / ${_patient!.gender}')),
            Expanded(child: gridCell('Blood Group', _patient!.bloodGroup)),
          ],
        ),
        Row(
          children: [
            Expanded(child: gridCell('Village', _patient!.village)),
            Expanded(child: gridCell('District', _patient!.district)),
          ],
        ),
        Row(
          children: [
            Expanded(child: gridCell('BMI Score', '${_patient!.bmi} (Height: ${_patient!.height}cm, Weight: ${_patient!.weight}kg)')),
            Expanded(child: gridCell('Pregnancy', _patient!.pregnancyStatus)),
          ],
        ),
      ],
    );
  }

  Widget _buildScreeningsTable() {
    if (_screenings.isEmpty) return const Text('No screenings registered.', style: TextStyle(fontSize: 11, color: Colors.grey));
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade50),
          children: const [
            Padding(padding: EdgeInsets.all(6.0), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(6.0), child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(6.0), child: Text('AI Risk Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(6.0), child: Text('Confidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          ],
        ),
        ..._screenings.map((s) => TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(6.0), child: Text(DateFormat('dd-MM-yy').format(s.date), style: const TextStyle(fontSize: 11))),
                Padding(padding: const EdgeInsets.all(6.0), child: Text(s.cancerType, style: const TextStyle(fontSize: 11))),
                Padding(padding: const EdgeInsets.all(6.0), child: Text(s.riskLevel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                Padding(padding: const EdgeInsets.all(6.0), child: Text('${s.confidenceScore.toInt()}%', style: const TextStyle(fontSize: 11))),
              ],
            )),
      ],
    );
  }

  Widget _buildTreatmentSection() {
    if (_treatment == null) return const Text('No active treatments prescribed.', style: TextStyle(fontSize: 11, color: Colors.grey));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Stage: ${_treatment!.cancerStage}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))),
              Expanded(child: Text('Hospital: ${_treatment!.hospitalName}', style: GoogleFonts.inter(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 6),
          Text('Plan: ${_treatment!.treatmentPlan}', style: GoogleFonts.inter(fontSize: 12)),
          if (_treatment!.chemotherapySchedule.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Chemo Dates: ${_treatment!.chemotherapySchedule.map((d) => DateFormat('dd-MM-yyyy').format(d)).join(', ')}',
              style: GoogleFonts.inter(fontSize: 11.5, color: Colors.purple.shade900, fontWeight: FontWeight.w600),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildFollowupsTable() {
    if (_followUps.isEmpty) return const Text('No home visit follow-ups recorded.', style: TextStyle(fontSize: 11, color: Colors.grey));
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade50),
          children: const [
            Padding(padding: EdgeInsets.all(6.0), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(6.0), child: Text('Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(6.0), child: Text('Compliance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(6.0), child: Text('Symptoms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          ],
        ),
        ..._followUps.map((f) => TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(6.0), child: Text(DateFormat('dd-MM-yy').format(f.visitDate), style: const TextStyle(fontSize: 11))),
                Padding(padding: const EdgeInsets.all(6.0), child: Text(f.patientCondition, style: const TextStyle(fontSize: 11))),
                Padding(padding: const EdgeInsets.all(6.0), child: Text(f.medicationCompliance, style: const TextStyle(fontSize: 11))),
                Padding(padding: const EdgeInsets.all(6.0), child: Text(f.symptoms.isNotEmpty ? f.symptoms : 'None', style: const TextStyle(fontSize: 11))),
              ],
            )),
      ],
    );
  }

  Widget _buildReferralsTable() {
    if (_referrals.isEmpty) return const Text('No specialist referrals requested.', style: TextStyle(fontSize: 11, color: Colors.grey));
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade50),
          children: const [
            Padding(padding: EdgeInsets.all(6.0), child: Text('Referred To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(6.0), child: Text('Specialist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(6.0), child: Text('Reason', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            Padding(padding: EdgeInsets.all(6.0), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          ],
        ),
        ..._referrals.map((r) => TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(6.0), child: Text(r.hospitalName, style: const TextStyle(fontSize: 11))),
                Padding(padding: const EdgeInsets.all(6.0), child: Text(r.doctorName, style: const TextStyle(fontSize: 11))),
                Padding(padding: const EdgeInsets.all(6.0), child: Text(r.reasonForReferral, style: const TextStyle(fontSize: 11))),
                Padding(padding: const EdgeInsets.all(6.0), child: Text(r.referralStatus, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            )),
      ],
    );
  }
}
