import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/sync_service.dart';
import '../services/sms_service.dart';

// Providers
final smsServiceProvider = Provider<SmsService>((ref) => SmsService());

final smsControllerProvider = StateNotifierProvider<SmsController, List<SmsHistoryData>>((ref) {
  final db = ref.watch(localDatabaseProvider);
  final service = ref.watch(smsServiceProvider);
  return SmsController(db, service);
});

class SmsController extends StateNotifier<List<SmsHistoryData>> {
  final LocalDatabase _db;
  final SmsService _service;
  Timer? _retryTimer;

  SmsController(this._db, this._service) : super([]) {
    _loadHistory();
    // Set up background retry scanner (every 30 seconds)
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) => _autoRetryFailedSms());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final list = await _db.getSmsHistory();
      state = list;
    } catch (e) {
      debugPrint('Error loading SMS history: $e');
    }
  }

  Future<bool> _logAndSend({
    required String recipient,
    required String messageType,
    required String content,
    required Future<bool> Function() sendCall,
  }) async {
    int logId = 0;
    try {
      // 1. Insert failed/pending log into Local Database
      logId = await _db.insertSmsRecord(SmsHistoryCompanion(
        recipient: Value(recipient),
        messageType: Value(messageType),
        messageContent: Value(content),
        status: const Value('Pending'),
        sentAt: Value(DateTime.now()),
      ));
      await _loadHistory();
    } catch (e) {
      debugPrint('Drift SMS logging error ($e) — continuing memory-only dispatch.');
    }

    // 2. Perform REST API dispatch
    final success = await sendCall();

    try {
      if (logId > 0) {
        // 3. Update status in Database
        await _db.updateSmsRecord(SmsHistoryData(
          id: logId,
          recipient: recipient,
          messageType: messageType,
          messageContent: content,
          sentAt: DateTime.now(),
          status: success ? 'Sent' : 'Failed',
          retryCount: 0,
        ));
      }
      await _loadHistory();
    } catch (e) {
      debugPrint('Drift SMS status update error: $e');
    }

    return success;
  }

  // API Wrapper methods
  Future<bool> sendOTP(String phoneNumber, String otp) async {
    return _logAndSend(
      recipient: phoneNumber,
      messageType: 'OTP Verification',
      content: 'ASHA CARE+ OTP Code: $otp',
      sendCall: () => _service.sendOTP(phoneNumber, otp),
    );
  }

  Future<bool> sendVaccinationReminder(Patient patient) async {
    return _logAndSend(
      recipient: patient.phone,
      messageType: 'Vaccination Reminder',
      content: 'Immunization due tomorrow for child of ${patient.name}',
      sendCall: () => _service.sendVaccinationReminder(patient),
    );
  }

  Future<bool> sendPregnancyReminder(Patient patient) async {
    return _logAndSend(
      recipient: patient.phone,
      messageType: 'Pregnancy ANC Reminder',
      content: 'Antenatal care weekly review scheduled tomorrow for ${patient.name}',
      sendCall: () => _service.sendPregnancyReminder(patient),
    );
  }

  Future<bool> sendMedicineReminder(Patient patient) async {
    return _logAndSend(
      recipient: patient.phone,
      messageType: 'Medicine Reminder',
      content: 'Remember daily IFA supplement dosage for ${patient.name}',
      sendCall: () => _service.sendMedicineReminder(patient),
    );
  }

  Future<bool> sendHighRiskAlert(Patient patient) async {
    return _logAndSend(
      recipient: patient.phone,
      messageType: 'High-Risk Pregnancy Warning',
      content: 'URGENT: ANC consultation needed for high-risk flags: ${patient.name}',
      sendCall: () => _service.sendHighRiskAlert(patient),
    );
  }

  Future<bool> sendAppointmentReminder(Patient patient) async {
    return _logAndSend(
      recipient: patient.phone,
      messageType: 'Appointment Reminder',
      content: 'PHC consult verified tomorrow morning for ${patient.name}',
      sendCall: () => _service.sendAppointmentReminder(patient),
    );
  }

  Future<bool> sendEmergencyReferral(Patient patient) async {
    return _logAndSend(
      recipient: patient.phone,
      messageType: 'Emergency Referral HUD',
      content: '🚨 Patient ${patient.name} referred to District Hospital under alert.',
      sendCall: () => _service.sendEmergencyReferral(patient),
    );
  }

  // Direct manual retry action from UI History Screen
  Future<bool> retrySms(int id) async {
    final recordIndex = state.indexWhere((element) => element.id == id);
    if (recordIndex == -1) return false;
    final record = state[recordIndex];

    // Mark as Retrying
    try {
      await _db.updateSmsRecord(record.copyWith(status: 'Retrying', retryCount: record.retryCount + 1));
      await _loadHistory();
    } catch (e) {
      debugPrint('Error updating retry state: $e');
    }

    final success = await _service.sendRawSms(number: record.recipient, message: record.messageContent);

    try {
      await _db.updateSmsRecord(record.copyWith(
        status: success ? 'Sent' : 'Failed',
        retryCount: record.retryCount + 1,
      ));
      await _loadHistory();
    } catch (e) {
      debugPrint('Error writing completed retry: $e');
    }

    return success;
  }

  // Background retry handler
  Future<void> _autoRetryFailedSms() async {
    final failedItems = state.where((item) => item.status == 'Failed').toList();
    if (failedItems.isEmpty) return;

    debugPrint('Background SMS retry agent activated. Retrying ${failedItems.length} failed SMS messages...');
    for (final item in failedItems) {
      if (item.retryCount >= 3) {
        // Stop retrying after 3 unsuccessful attempts
        continue;
      }
      await retrySms(item.id);
    }
  }
}
