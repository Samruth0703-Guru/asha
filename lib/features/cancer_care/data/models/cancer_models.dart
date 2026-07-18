import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/encryption_helper.dart';

class CancerPatient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String phone; // Encrypted in Firestore
  final String address;
  final String village;
  final String district;
  final String aadhaar; // Optional, encrypted in Firestore
  final String bloodGroup;
  final String existingDiseases;
  final String familyHistoryOfCancer;
  final String tobaccoUsage;
  final String alcoholConsumption;
  final double height;
  final double weight;
  final double bmi;
  final String pregnancyStatus;
  final DateTime createdAt;

  CancerPatient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.address,
    required this.village,
    required this.district,
    required this.aadhaar,
    required this.bloodGroup,
    required this.existingDiseases,
    required this.familyHistoryOfCancer,
    required this.tobaccoUsage,
    required this.alcoholConsumption,
    required this.height,
    required this.weight,
    required this.bmi,
    required this.pregnancyStatus,
    required this.createdAt,
  });

  // Client-side encryption before sending to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': EncryptionHelper.encrypt(phone),
      'address': address,
      'village': village,
      'district': district,
      'aadhaar': aadhaar.isNotEmpty ? EncryptionHelper.encrypt(aadhaar) : '',
      'bloodGroup': bloodGroup,
      'existingDiseases': existingDiseases,
      'familyHistoryOfCancer': familyHistoryOfCancer,
      'tobaccoUsage': tobaccoUsage,
      'alcoholConsumption': alcoholConsumption,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'pregnancyStatus': pregnancyStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Client-side decryption after reading from Firestore
  factory CancerPatient.fromFirestore(Map<String, dynamic> data) {
    return CancerPatient(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      phone: EncryptionHelper.decrypt(data['phone'] ?? ''),
      address: data['address'] ?? '',
      village: data['village'] ?? '',
      district: data['district'] ?? '',
      aadhaar: data['aadhaar'] != null && data['aadhaar'].isNotEmpty 
          ? EncryptionHelper.decrypt(data['aadhaar']) 
          : '',
      bloodGroup: data['bloodGroup'] ?? '',
      existingDiseases: data['existingDiseases'] ?? '',
      familyHistoryOfCancer: data['familyHistoryOfCancer'] ?? '',
      tobaccoUsage: data['tobaccoUsage'] ?? '',
      alcoholConsumption: data['alcoholConsumption'] ?? '',
      height: (data['height'] as num?)?.toDouble() ?? 0.0,
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      bmi: (data['bmi'] as num?)?.toDouble() ?? 0.0,
      pregnancyStatus: data['pregnancyStatus'] ?? 'N/A',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class CancerScreening {
  final String id;
  final String patientId;
  final String patientName;
  final String cancerType; // Breast, Cervical, Oral, Lung, Colorectal
  final List<String> symptoms;
  final List<String> riskFactors;
  final String lifestyleQuestions;
  final String familyHistory;
  final String clinicalNotes;
  final String riskLevel; // Low Risk, Medium Risk, High Risk, Critical Risk
  final double confidenceScore; // 0.0 - 1.0 or Percentage (e.g. 85.0)
  final String explanation;
  final DateTime date;

  CancerScreening({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.cancerType,
    required this.symptoms,
    required this.riskFactors,
    required this.lifestyleQuestions,
    required this.familyHistory,
    required this.clinicalNotes,
    required this.riskLevel,
    required this.confidenceScore,
    required this.explanation,
    required this.date,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'cancerType': cancerType,
      'symptoms': symptoms,
      'riskFactors': riskFactors,
      'lifestyleQuestions': lifestyleQuestions,
      'familyHistory': familyHistory,
      'clinicalNotes': clinicalNotes,
      'riskLevel': riskLevel,
      'confidenceScore': confidenceScore,
      'explanation': explanation,
      'date': Timestamp.fromDate(date),
    };
  }

  factory CancerScreening.fromFirestore(Map<String, dynamic> data) {
    return CancerScreening(
      id: data['id'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      cancerType: data['cancerType'] ?? '',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      riskFactors: List<String>.from(data['riskFactors'] ?? []),
      lifestyleQuestions: data['lifestyleQuestions'] ?? '',
      familyHistory: data['familyHistory'] ?? '',
      clinicalNotes: data['clinicalNotes'] ?? '',
      riskLevel: data['riskLevel'] ?? 'Low Risk',
      confidenceScore: (data['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      explanation: data['explanation'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class CancerTreatment {
  final String patientId;
  final DateTime diagnosisDate;
  final String cancerType;
  final String cancerStage;
  final String hospitalName;
  final String doctorName;
  final String treatmentPlan;
  final List<DateTime> chemotherapySchedule;
  final List<DateTime> radiotherapySchedule;
  final String surgeryDetails;
  final List<Map<String, dynamic>> medicationList; // { name, dosage, frequency, startDate, endDate, remindersEnabled }
  final List<DateTime> followUpDates;
  final String treatmentStatus; // Under Treatment, Completed, Suspended
  final String sideEffects;
  final String nutritionNotes;
  final int painScore; // 1 to 10

  CancerTreatment({
    required this.patientId,
    required this.diagnosisDate,
    required this.cancerType,
    required this.cancerStage,
    required this.hospitalName,
    required this.doctorName,
    required this.treatmentPlan,
    required this.chemotherapySchedule,
    required this.radiotherapySchedule,
    required this.surgeryDetails,
    required this.medicationList,
    required this.followUpDates,
    required this.treatmentStatus,
    required this.sideEffects,
    required this.nutritionNotes,
    required this.painScore,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'diagnosisDate': Timestamp.fromDate(diagnosisDate),
      'cancerType': cancerType,
      'cancerStage': cancerStage,
      'hospitalName': hospitalName,
      'doctorName': doctorName,
      'treatmentPlan': treatmentPlan,
      'chemotherapySchedule': chemotherapySchedule.map((d) => Timestamp.fromDate(d)).toList(),
      'radiotherapySchedule': radiotherapySchedule.map((d) => Timestamp.fromDate(d)).toList(),
      'surgeryDetails': surgeryDetails,
      'medicationList': medicationList,
      'followUpDates': followUpDates.map((d) => Timestamp.fromDate(d)).toList(),
      'treatmentStatus': treatmentStatus,
      'sideEffects': sideEffects,
      'nutritionNotes': nutritionNotes,
      'painScore': painScore,
    };
  }

  factory CancerTreatment.fromFirestore(Map<String, dynamic> data) {
    return CancerTreatment(
      patientId: data['patientId'] ?? '',
      diagnosisDate: (data['diagnosisDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cancerType: data['cancerType'] ?? '',
      cancerStage: data['cancerStage'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      doctorName: data['doctorName'] ?? '',
      treatmentPlan: data['treatmentPlan'] ?? '',
      chemotherapySchedule: (data['chemotherapySchedule'] as List?)
              ?.map((t) => (t as Timestamp).toDate())
              .toList() ?? [],
      radiotherapySchedule: (data['radiotherapySchedule'] as List?)
              ?.map((t) => (t as Timestamp).toDate())
              .toList() ?? [],
      surgeryDetails: data['surgeryDetails'] ?? '',
      medicationList: List<Map<String, dynamic>>.from(data['medicationList'] ?? []),
      followUpDates: (data['followUpDates'] as List?)
              ?.map((t) => (t as Timestamp).toDate())
              .toList() ?? [],
      treatmentStatus: data['treatmentStatus'] ?? 'Under Treatment',
      sideEffects: data['sideEffects'] ?? '',
      nutritionNotes: data['nutritionNotes'] ?? '',
      painScore: data['painScore'] ?? 1,
    );
  }
}

class CancerFollowUp {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime visitDate;
  final String patientCondition;
  final String medicationCompliance; // High, Medium, Low
  final String symptoms;
  final double weightChanges;
  final String sideEffects;
  final String photoUrl;
  final String doctorComments;
  final String voiceNotesText;
  final DateTime nextFollowUpDate;

  CancerFollowUp({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.visitDate,
    required this.patientCondition,
    required this.medicationCompliance,
    required this.symptoms,
    required this.weightChanges,
    required this.sideEffects,
    required this.photoUrl,
    required this.doctorComments,
    required this.voiceNotesText,
    required this.nextFollowUpDate,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'visitDate': Timestamp.fromDate(visitDate),
      'patientCondition': patientCondition,
      'medicationCompliance': medicationCompliance,
      'symptoms': symptoms,
      'weightChanges': weightChanges,
      'sideEffects': sideEffects,
      'photoUrl': photoUrl,
      'doctorComments': doctorComments,
      'voiceNotesText': voiceNotesText,
      'nextFollowUpDate': Timestamp.fromDate(nextFollowUpDate),
    };
  }

  factory CancerFollowUp.fromFirestore(Map<String, dynamic> data) {
    return CancerFollowUp(
      id: data['id'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      visitDate: (data['visitDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      patientCondition: data['patientCondition'] ?? '',
      medicationCompliance: data['medicationCompliance'] ?? 'High',
      symptoms: data['symptoms'] ?? '',
      weightChanges: (data['weightChanges'] as num?)?.toDouble() ?? 0.0,
      sideEffects: data['sideEffects'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      doctorComments: data['doctorComments'] ?? '',
      voiceNotesText: data['voiceNotesText'] ?? '',
      nextFollowUpDate: (data['nextFollowUpDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class CancerReferral {
  final String id;
  final String patientId;
  final String patientName;
  final int age;
  final String gender;
  final String screeningResult; // e.g. "Oral Cancer - High Risk"
  final String reasonForReferral;
  final String hospitalName;
  final String doctorName;
  final DateTime referralDate;
  final String referralStatus; // Pending, Visited, Completed

  CancerReferral({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.screeningResult,
    required this.reasonForReferral,
    required this.hospitalName,
    required this.doctorName,
    required this.referralDate,
    required this.referralStatus,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'age': age,
      'gender': gender,
      'screeningResult': screeningResult,
      'reasonForReferral': reasonForReferral,
      'hospitalName': hospitalName,
      'doctorName': doctorName,
      'referralDate': Timestamp.fromDate(referralDate),
      'referralStatus': referralStatus,
    };
  }

  factory CancerReferral.fromFirestore(Map<String, dynamic> data) {
    return CancerReferral(
      id: data['id'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      screeningResult: data['screeningResult'] ?? '',
      reasonForReferral: data['reasonForReferral'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      doctorName: data['doctorName'] ?? '',
      referralDate: (data['referralDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      referralStatus: data['referralStatus'] ?? 'Pending',
    );
  }
}

class CancerAuditLog {
  final String id;
  final DateTime timestamp;
  final String role;
  final String userId;
  final String action;
  final String details;

  CancerAuditLog({
    required this.id,
    required this.timestamp,
    required this.role,
    required this.userId,
    required this.action,
    required this.details,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'timestamp': Timestamp.fromDate(timestamp),
      'role': role,
      'userId': userId,
      'action': action,
      'details': details,
    };
  }

  factory CancerAuditLog.fromFirestore(Map<String, dynamic> data) {
    return CancerAuditLog(
      id: data['id'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: data['role'] ?? 'ASHA Worker',
      userId: data['userId'] ?? 'Unknown User',
      action: data['action'] ?? '',
      details: data['details'] ?? '',
    );
  }
}
