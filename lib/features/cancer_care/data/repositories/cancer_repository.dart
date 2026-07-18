import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cancer_models.dart';

final cancerRepositoryProvider = Provider<CancerRepository>((ref) => CancerRepository());

class CancerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get _isFirebaseConfigured {
    try {
      return FirebaseFirestore.instance.app.options.projectId.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Local caching fallbacks for Offline Mode/Fallback Support
  static final List<CancerPatient> _offlinePatients = [];
  static final List<CancerScreening> _offlineScreenings = [];
  static final List<CancerTreatment> _offlineTreatments = [];
  static final List<CancerFollowUp> _offlineFollowUps = [];
  static final List<CancerReferral> _offlineReferrals = [];
  static final List<CancerAuditLog> _offlineAuditLogs = [];

  // ==========================================
  // AUDIT LOGGING HELPER
  // ==========================================
  Future<void> logAudit(String role, String userId, String action, String details) async {
    final log = CancerAuditLog(
      id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      role: role,
      userId: userId,
      action: action,
      details: details,
    );

    if (!_isFirebaseConfigured) {
      _offlineAuditLogs.add(log);
      debugPrint('OFFLINE AUDIT LOGGED: ${log.action} - ${log.details}');
      return;
    }

    try {
      await _firestore.collection('cancer_audit_logs').doc(log.id).set(log.toFirestore());
    } catch (e) {
      _offlineAuditLogs.add(log);
      debugPrint('Error logging audit: $e');
    }
  }

  // ==========================================
  // PATIENT CRUD
  // ==========================================
  Future<List<CancerPatient>> getPatients(String role, String userId) async {
    await logAudit(role, userId, 'GET_PATIENTS', 'Requested complete cancer patient registry');

    if (!_isFirebaseConfigured) {
      return _offlinePatients;
    }

    try {
      final snap = await _firestore.collection('cancer_patients').orderBy('createdAt', descending: true).get();
      return snap.docs.map((doc) => CancerPatient.fromFirestore(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching firestore cancer patients, using offline database: $e');
      return _offlinePatients;
    }
  }

  Future<void> registerPatient(CancerPatient patient, String role, String userId) async {
    await logAudit(role, userId, 'REGISTER_PATIENT', 'Registered cancer patient ID: ${patient.id}, Name: ${patient.name}');

    if (!_isFirebaseConfigured) {
      _offlinePatients.insert(0, patient);
      return;
    }

    try {
      await _firestore.collection('cancer_patients').doc(patient.id).set(patient.toFirestore());
      // Also cache locally
      _offlinePatients.insert(0, patient);
    } catch (e) {
      debugPrint('Error registering cancer patient in firestore, saved in offline cache: $e');
      _offlinePatients.insert(0, patient);
      rethrow;
    }
  }

  // ==========================================
  // CANCER SCREENING CRUD
  // ==========================================
  Future<List<CancerScreening>> getScreenings(String patientId, String role, String userId) async {
    await logAudit(role, userId, 'GET_SCREENINGS', 'Fetched cancer screenings for patient ID: $patientId');

    if (!_isFirebaseConfigured) {
      return _offlineScreenings.where((s) => s.patientId == patientId).toList();
    }

    try {
      final snap = await _firestore
          .collection('cancer_screenings')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .get();
      return snap.docs.map((doc) => CancerScreening.fromFirestore(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching screening logs, using offline cache: $e');
      return _offlineScreenings.where((s) => s.patientId == patientId).toList();
    }
  }

  Future<List<CancerScreening>> getAllScreenings(String role, String userId) async {
    await logAudit(role, userId, 'GET_ALL_SCREENINGS', 'Requested entire screening collection details');

    if (!_isFirebaseConfigured) {
      return _offlineScreenings;
    }

    try {
      final snap = await _firestore.collection('cancer_screenings').orderBy('date', descending: true).get();
      return snap.docs.map((doc) => CancerScreening.fromFirestore(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching all screening logs: $e');
      return _offlineScreenings;
    }
  }

  Future<void> addScreening(CancerScreening screening, String role, String userId) async {
    await logAudit(role, userId, 'ADD_SCREENING', 'Performed AI screening for patient ID: ${screening.patientId}, Risk: ${screening.riskLevel}');

    if (!_isFirebaseConfigured) {
      _offlineScreenings.insert(0, screening);
      return;
    }

    try {
      await _firestore.collection('cancer_screenings').doc(screening.id).set(screening.toFirestore());
      _offlineScreenings.insert(0, screening);
    } catch (e) {
      debugPrint('Error adding cancer screening logs: $e');
      _offlineScreenings.insert(0, screening);
      rethrow;
    }
  }

  // ==========================================
  // CANCER TREATMENT CRUD
  // ==========================================
  Future<CancerTreatment?> getTreatment(String patientId, String role, String userId) async {
    await logAudit(role, userId, 'GET_TREATMENT', 'Fetched cancer treatment history for patient ID: $patientId');

    if (!_isFirebaseConfigured) {
      final list = _offlineTreatments.where((t) => t.patientId == patientId).toList();
      return list.isNotEmpty ? list.first : null;
    }

    try {
      final doc = await _firestore.collection('cancer_treatments').doc(patientId).get();
      if (doc.exists && doc.data() != null) {
        return CancerTreatment.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting cancer treatments: $e');
      final list = _offlineTreatments.where((t) => t.patientId == patientId).toList();
      return list.isNotEmpty ? list.first : null;
    }
  }

  Future<List<CancerTreatment>> getAllTreatments(String role, String userId) async {
    await logAudit(role, userId, 'GET_ALL_TREATMENTS', 'Requested general treatment tracking roster');

    if (!_isFirebaseConfigured) {
      return _offlineTreatments;
    }

    try {
      final snap = await _firestore.collection('cancer_treatments').get();
      return snap.docs.map((doc) => CancerTreatment.fromFirestore(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching all treatments: $e');
      return _offlineTreatments;
    }
  }

  Future<void> updateTreatment(CancerTreatment treatment, String role, String userId) async {
    await logAudit(role, userId, 'UPDATE_TREATMENT', 'Modified/Set treatment plan for patient ID: ${treatment.patientId}, Stage: ${treatment.cancerStage}');

    _offlineTreatments.removeWhere((t) => t.patientId == treatment.patientId);
    _offlineTreatments.insert(0, treatment);

    if (!_isFirebaseConfigured) return;

    try {
      await _firestore.collection('cancer_treatments').doc(treatment.patientId).set(treatment.toFirestore());
    } catch (e) {
      debugPrint('Error updating cancer treatments: $e');
      rethrow;
    }
  }

  // ==========================================
  // CANCER FOLLOW-UP CRUD
  // ==========================================
  Future<List<CancerFollowUp>> getFollowUps(String patientId, String role, String userId) async {
    await logAudit(role, userId, 'GET_FOLLOW_UPS', 'Requested home follow-ups list for patient ID: $patientId');

    if (!_isFirebaseConfigured) {
      return _offlineFollowUps.where((f) => f.patientId == patientId).toList();
    }

    try {
      final snap = await _firestore
          .collection('cancer_follow_ups')
          .where('patientId', isEqualTo: patientId)
          .orderBy('visitDate', descending: true)
          .get();
      return snap.docs.map((doc) => CancerFollowUp.fromFirestore(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching follow-ups: $e');
      return _offlineFollowUps.where((f) => f.patientId == patientId).toList();
    }
  }

  Future<List<CancerFollowUp>> getAllFollowUps(String role, String userId) async {
    await logAudit(role, userId, 'GET_ALL_FOLLOW_UPS', 'Requested entire district follow-up schedule list');

    if (!_isFirebaseConfigured) {
      return _offlineFollowUps;
    }

    try {
      final snap = await _firestore.collection('cancer_follow_ups').orderBy('visitDate', descending: true).get();
      return snap.docs.map((doc) => CancerFollowUp.fromFirestore(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching all follow-ups: $e');
      return _offlineFollowUps;
    }
  }

  Future<void> addFollowUp(CancerFollowUp followUp, String role, String userId) async {
    await logAudit(role, userId, 'ADD_FOLLOW_UP', 'Logged home follow-up for patient ID: ${followUp.patientId}, next visit: ${followUp.nextFollowUpDate}');

    if (!_isFirebaseConfigured) {
      _offlineFollowUps.insert(0, followUp);
      return;
    }

    try {
      await _firestore.collection('cancer_follow_ups').doc(followUp.id).set(followUp.toFirestore());
      _offlineFollowUps.insert(0, followUp);
    } catch (e) {
      debugPrint('Error logging follow-up: $e');
      _offlineFollowUps.insert(0, followUp);
      rethrow;
    }
  }

  // ==========================================
  // CANCER REFERRAL CRUD
  // ==========================================
  Future<List<CancerReferral>> getReferrals(String patientId, String role, String userId) async {
    await logAudit(role, userId, 'GET_REFERRALS', 'Requested referrals for patient ID: $patientId');

    if (!_isFirebaseConfigured) {
      return _offlineReferrals.where((r) => r.patientId == patientId).toList();
    }

    try {
      final snap = await _firestore
          .collection('cancer_referrals')
          .where('patientId', isEqualTo: patientId)
          .get();
      return snap.docs.map((doc) => CancerReferral.fromFirestore(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting referrals: $e');
      return _offlineReferrals.where((r) => r.patientId == patientId).toList();
    }
  }

  Future<List<CancerReferral>> getAllReferrals(String role, String userId) async {
    await logAudit(role, userId, 'GET_ALL_REFERRALS', 'Fetched referrals lists for dashboard');

    if (!_isFirebaseConfigured) {
      return _offlineReferrals;
    }

    try {
      final snap = await _firestore.collection('cancer_referrals').orderBy('referralDate', descending: true).get();
      return snap.docs.map((doc) => CancerReferral.fromFirestore(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting all referrals: $e');
      return _offlineReferrals;
    }
  }

  Future<void> createReferral(CancerReferral referral, String role, String userId) async {
    await logAudit(role, userId, 'CREATE_REFERRAL', 'Drafted referral to ${referral.hospitalName} for patient ID: ${referral.patientId}');

    if (!_isFirebaseConfigured) {
      _offlineReferrals.insert(0, referral);
      return;
    }

    try {
      await _firestore.collection('cancer_referrals').doc(referral.id).set(referral.toFirestore());
      _offlineReferrals.insert(0, referral);
    } catch (e) {
      debugPrint('Error creating referral: $e');
      _offlineReferrals.insert(0, referral);
      rethrow;
    }
  }

  // ==========================================
  // AUDIT LOGS RETRIEVAL (Admins Only)
  // ==========================================
  Future<List<CancerAuditLog>> getAuditLogs(String role, String userId) async {
    await logAudit(role, userId, 'ACCESS_AUDIT_LOGS', 'Requested full security audit ledger details');

    if (!_isFirebaseConfigured) {
      return _offlineAuditLogs;
    }

    try {
      final snap = await _firestore.collection('cancer_audit_logs').orderBy('timestamp', descending: true).get();
      return snap.docs.map((doc) => CancerAuditLog.fromFirestore(doc.data())).toList();
    } catch (e) {
      debugPrint('Error reading audit logs: $e');
      return _offlineAuditLogs;
    }
  }
}
