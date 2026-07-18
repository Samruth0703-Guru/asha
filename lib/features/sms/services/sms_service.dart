import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/database/local_database.dart';

class SmsService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<String> _loadApiKey() async {
    const defineKey = String.fromEnvironment('FAST2SMS_API_KEY');
    if (defineKey.isNotEmpty) return defineKey;

    // Fallback: load from the root .env file
    // 1. Web fallback (fetches /.env from server)
    if (kIsWeb) {
      try {
        final response = await _dio.get('/.env');
        if (response.statusCode == 200) {
          final lines = response.data.toString().split('\n');
          for (final line in lines) {
            final parts = line.split('=');
            if (parts.length >= 2 && parts[0].trim() == 'FAST2SMS_API_KEY') {
              return parts[1].trim();
            }
          }
        }
      } catch (e) {
        debugPrint('Web SMS key load error: $e');
      }
    }

    // 2. Native fallback (reads from File)
    if (!kIsWeb) {
      try {
        final file = File('.env');
        if (await file.exists()) {
          final lines = await file.readAsLines();
          for (final line in lines) {
            final parts = line.split('=');
            if (parts.length >= 2 && parts[0].trim() == 'FAST2SMS_API_KEY') {
              return parts[1].trim();
            }
          }
        }
      } catch (e) {
        debugPrint('Native SMS key load error: $e');
      }
    }

    return '';
  }

  Future<bool> sendRawSms({required String number, required String message}) async {
    try {
      final apiKey = await _loadApiKey();
      if (apiKey.isEmpty) {
        debugPrint('FAST2SMS_API_KEY is not configured.');
        return false;
      }

      final response = await _dio.post(
        'https://www.fast2sms.com/dev/bulkV2',
        options: Options(
          headers: {
            'authorization': apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'route': 'q',
          'message': message,
          'language': 'english',
          'numbers': number,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['return'] == true) {
          debugPrint('SMS sent successfully to $number: ${data['message']}');
          return true;
        }
        debugPrint('Fast2SMS API returned error: ${data['message']}');
      }
      return false;
    } catch (e) {
      debugPrint('SMS send network failure: $e');
      return false;
    }
  }

  Future<bool> sendOTP(String phoneNumber, String otp) async {
    final message = 'ASHA CARE+ OTP Verification Code: $otp. Valid for 5 minutes. Please do not share this OTP.';
    return sendRawSms(number: phoneNumber, message: message);
  }

  Future<bool> sendVaccinationReminder(Patient patient) async {
    final message = 'ASHA CARE+ Reminder: Dear ${patient.name}, your child\'s next immunization dose is due tomorrow. Please visit the Sub-Centre in ${patient.village}.';
    return sendRawSms(number: patient.phone, message: message);
  }

  Future<bool> sendPregnancyReminder(Patient patient) async {
    final message = 'ASHA CARE+ ANC Alert: Dear ${patient.name}, your weekly antenatal checkup is scheduled tomorrow. Please contact ANM Lakshmi at PHC Madurai.';
    return sendRawSms(number: patient.phone, message: message);
  }

  Future<bool> sendMedicineReminder(Patient patient) async {
    final message = 'ASHA CARE+ Notice: Dear ${patient.name}, please remember to take your regular iron and folic acid (IFA) supplements daily as directed.';
    return sendRawSms(number: patient.phone, message: message);
  }

  Future<bool> sendHighRiskAlert(Patient patient) async {
    final message = '⚠️ ASHA CARE+ URGENT: High-risk pregnancy parameters identified for patient ${patient.name} (${patient.village}). ANC attention is required immediately.';
    return sendRawSms(number: patient.phone, message: message);
  }

  Future<bool> sendAppointmentReminder(Patient patient) async {
    final message = 'ASHA CARE+ Update: Dear ${patient.name}, your doctor consultation at the Primary Health Centre is confirmed for tomorrow morning.';
    return sendRawSms(number: patient.phone, message: message);
  }

  Future<bool> sendEmergencyReferral(Patient patient) async {
    final message = '🚨 EMERGENCY RED ALERT: Patient ${patient.name} from ${patient.village} has been referred to the District Hospital under emergency dispatch.';
    return sendRawSms(number: patient.phone, message: message);
  }

  static final Set<String> _sentAlertsCache = {};

  Future<void> checkAndSendAutomatedAlerts(LocalDatabase db) async {
    try {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}";
      
      // Check Vaccinations
      final allVacs = await db.select(db.vaccinations).get();
      for (final vac in allVacs) {
        if (vac.status != 'Completed') {
          final patient = await db.getPatientById(vac.patientId);
          if (patient != null) {
            final daysDifference = vac.dueDate.difference(now).inDays;
            final cacheKey = "${patient.id}-vac-${vac.id}-$daysDifference-$todayStr";
            
            if (!_sentAlertsCache.contains(cacheKey)) {
              if (daysDifference == 7 || daysDifference == 3 || daysDifference == 1 || daysDifference == 0) {
                final dayStr = daysDifference == 0 ? "today" : "in $daysDifference days";
                await sendRawSms(number: patient.phone, message: 'ASHA CARE+ Reminder: Dear ${patient.name}, your child\'s immunization (${vac.vaccineName}) is due $dayStr. Please visit the Sub-Centre.');
                _sentAlertsCache.add(cacheKey);
              } else if (daysDifference < 0) { // Missed
                await sendRawSms(number: patient.phone, message: 'ASHA CARE+ Alert: Dear ${patient.name}, your child\'s immunization (${vac.vaccineName}) was missed. Please visit immediately.');
                _sentAlertsCache.add(cacheKey);
              }
            }
          }
        }
      }

      // Check ANC Visits
      final allAnc = await db.select(db.ancVisits).get();
      for (final anc in allAnc) {
        if (anc.status != 'Completed') {
          final patient = await db.getPatientById(anc.patientId);
          if (patient != null) {
            final targetDate = anc.nextVisitDate ?? anc.visitDate;
            final daysDifference = targetDate.difference(now).inDays;
            final cacheKey = "${patient.id}-anc-${anc.id}-$daysDifference-$todayStr";

            if (!_sentAlertsCache.contains(cacheKey)) {
              if (daysDifference == 7 || daysDifference == 3 || daysDifference == 1 || daysDifference == 0) {
                final dayStr = daysDifference == 0 ? "today" : "in $daysDifference days";
                await sendRawSms(number: patient.phone, message: 'ASHA CARE+ ANC Alert: Dear ${patient.name}, your antenatal checkup is scheduled $dayStr. Please contact your ASHA worker.');
                _sentAlertsCache.add(cacheKey);
              } else if (daysDifference < 0) {
                await sendRawSms(number: patient.phone, message: 'ASHA CARE+ Alert: Dear ${patient.name}, you missed your ANC visit scheduled for ${targetDate.toString().split(' ')[0]}. Please contact your ASHA worker.');
                _sentAlertsCache.add(cacheKey);
              }
            }
          }
        }
      }
      
      debugPrint('Automated SMS checks completed.');
    } catch (e) {
      debugPrint('Error in automated SMS checks: $e');
    }
  }
}
