import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../database/local_database.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

class GeminiService {
  String _apiKey = '';
  GenerativeModel? _model;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  GeminiService() {
    _init();
  }

  String get apiKey => _apiKey;
  bool get isConfigured => _model != null;

  Future<void> _init() async {
    _apiKey = await _loadApiKey();
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );
    }
  }

  // Allow setting API Key dynamically (e.g. from Settings Dialog)
  void setApiKey(String key) {
    _apiKey = key;
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );
    } else {
      _model = null;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_apiKey.isNotEmpty) return;
    await _init();
  }

  Future<String> _loadApiKey() async {
    const defineKey = String.fromEnvironment('GEMINI_API_KEY');
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
            if (parts.length >= 2 && parts[0].trim() == 'GEMINI_API_KEY') {
              return parts[1].trim();
            }
          }
        }
      } catch (e) {
        debugPrint('Web Gemini key load error: $e');
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
            if (parts.length >= 2 && parts[0].trim() == 'GEMINI_API_KEY') {
              return parts[1].trim();
            }
          }
        }
      } catch (e) {
        debugPrint('Native Gemini key load error: $e');
      }
    }

    return '';
  }

  Future<String> generateTextResponse(String prompt) async {
    await _ensureInitialized();
    if (_model == null) {
      throw StateError('Gemini model is not configured.');
    }
    final content = [Content.text(prompt)];
    final response = await _model!.generateContent(content);
    return response.text ?? 'No response generated.';
  }

  Future<Map<String, dynamic>> evaluateRisk(Patient patient) async {
    await _ensureInitialized();
    if (_model == null) {
      throw StateError('Gemini model is not configured.');
    }

    final prompt = '''
You are a clinical decision support AI assistant analyzing maternal health vitals for a pregnant mother based on the guidelines of the Indian Council of Medical Research (ICMR) and National Health Mission (NHM) of India.

Patient Vitals and Details:
- Name: ${patient.name}
- DOB/Age: ${patient.dob}
- Blood Pressure: ${patient.bloodPressure ?? 'N/A'}
- Hemoglobin: ${patient.hemoglobin != null ? '${patient.hemoglobin} g/dL' : 'N/A'}
- Blood Sugar: ${patient.bloodSugar != null ? '${patient.bloodSugar} mg/dL' : 'N/A'}
- Temperature: ${patient.temperature != null ? '${patient.temperature} F' : 'N/A'}
- Weight: ${patient.weight != null ? '${patient.weight} kg' : 'N/A'}
- Symptoms: ${patient.symptoms ?? 'None reported'}
- Previous Pregnancies: ${patient.previousPregnancies}

Based on these vitals, evaluate the patient's risk level.
Output your assessment strictly in the following JSON format. Do not output any markdown formatting (like ```json), just raw JSON:
{
  "riskLevel": "Low" | "Medium" | "High" | "Critical",
  "confidenceScore": 0.0 to 1.0,
  "reasons": "A concise explanation of the risk classification highlighting any abnormal vitals",
  "recommendations": "Specific NHM/ICMR guidelines clinical steps for the ASHA worker, e.g. IFA supplements dosage, diet, precautions",
  "referral": "PHC referral recommendation or Emergency referral description if needed"
}
''';

    final content = [Content.text(prompt)];
    final response = await _model!.generateContent(content);
    final text = response.text?.trim() ?? '';
    
    // Clean markdown wrappers if any
    String jsonString = text;
    if (jsonString.startsWith('```')) {
      final firstLineEnd = jsonString.indexOf('\n');
      final lastBackticks = jsonString.lastIndexOf('```');
      if (firstLineEnd != -1 && lastBackticks != -1) {
        jsonString = jsonString.substring(firstLineEnd + 1, lastBackticks).trim();
      }
    }

    final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
    return parsed;
  }

  Future<Map<String, dynamic>> analyzeHealthImage(Uint8List imageBytes) async {
    await _ensureInitialized();
    if (_model == null) {
      throw StateError('Gemini model is not configured.');
    }

    final prompt = '''
You are an advanced medical vision screening assistant. Analyze this image (e.g. skin, eyes, mouth, wound, swelling, etc.) to detect possible visible conditions.

Evaluate for possible visible conditions like:
Skin Allergy, Fungal Infection, Ringworm, Eczema, Psoriasis, Chickenpox (visible rash), Measles (visible rash), Burns, Cuts and Wounds, Swelling, Insect Bite, Eye Redness, Mouth Ulcers, Nail Infection.

You MUST follow these rules:
1. Never claim medical certainty. Use terms like "Possible condition detected".
2. Add a clear disclaimer: "AI screening only. Final diagnosis should be confirmed by a qualified medical professional."
3. Respond STRICTLY in raw JSON format (no markdown blocks like ```json).

The output JSON structure:
{
  "condition": "Name of the possible condition detected",
  "confidence": "Confidence score as percentage (e.g., 92%)",
  "severity": "Low" | "Moderate" | "High",
  "possibleCauses": [
    "Cause 1",
    "Cause 2"
  ],
  "symptoms": [
    "Symptom 1",
    "Symptom 2"
  ],
  "firstAid": [
    "Step 1",
    "Step 2"
  ],
  "medicines": [
    "Antihistamine (as advised by doctor)",
    "Calamine lotion"
  ],
  "homeCare": [
    "Advice 1",
    "Advice 2"
  ],
  "prevention": [
    "Tip 1",
    "Tip 2"
  ],
  "whenToVisitPHC": "Visit PHC immediately if breathing difficulty, fever develops, or swelling increases",
  "emergencyWarningSigns": "Breathing difficulty, severe pain, spreading infection, high fever",
  "referral": "Referral recommendation e.g. consult PHC medical officer"
}
''';

    try {
      final textPart = TextPart(prompt);
      final imagePart = DataPart('image/jpeg', imageBytes);
      final response = await _model!.generateContent([
        Content.multi([textPart, imagePart])
      ]);
      final text = response.text?.trim() ?? '';
      
      // Clean markdown wrappers if any
      String jsonString = text;
      if (jsonString.startsWith('```')) {
        final firstLineEnd = jsonString.indexOf('\n');
        final lastBackticks = jsonString.lastIndexOf('```');
        if (firstLineEnd != -1 && lastBackticks != -1) {
          jsonString = jsonString.substring(firstLineEnd + 1, lastBackticks).trim();
        }
      }

      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
      return parsed;
    } catch (e) {
      debugPrint('Gemini API Error caught. Returning simulation. Error: $e');
      return {
        'condition': 'Simulation Fallback: Mild Skin Irritation',
        'confidence': '85%',
        'severity': 'Low',
        'possibleCauses': ['Allergic reaction', 'Mild insect bite'],
        'symptoms': ['Redness', 'Slight swelling', 'Mild itchiness'],
        'firstAid': ['Wash gently with clean water', 'Apply a cold compress'],
        'medicines': ['Calamine lotion (apply locally)'],
        'homeCare': ['Avoid scratching the area', 'Keep the affected skin clean and dry'],
        'prevention': ['Use insect repellent', 'Avoid known allergens'],
        'whenToVisitPHC': 'Visit PHC if swelling increases, pus forms, or fever develops.',
        'emergencyWarningSigns': 'Breathing difficulty, severe pain, spreading redness',
        'referral': 'Routine checkup with PHC medical officer if symptoms persist.'
      };
    }
  }

  Future<Map<String, dynamic>> scanSkinDisease(Uint8List imageBytes) async {
    await _ensureInitialized();
    if (_model == null) {
      throw StateError('Gemini model is not configured.');
    }

    final prompt = '''
You are an advanced medical vision screening assistant specialized in skin pathology and external visible lesions. Analyze this image to detect potential visible diseases.

You MUST follow these rules:
1. Never claim medical certainty. Use terms like "Possible condition detected".
2. Add a clear disclaimer: "AI screening only. Final diagnosis should be confirmed by a qualified medical professional."
3. Respond STRICTLY in raw JSON format (no markdown blocks like ```json).

The output JSON structure:
{
  "possibleDisease": "Name of the possible disease/anomaly detected",
  "confidence": "Confidence score as percentage (e.g., 88%)",
  "diseaseCategory": "Infectious | Fungal | Allergy | Burn | Wound | Swelling | Other",
  "severity": "Low" | "Moderate" | "High" | "Critical",
  "symptoms": [
    "Symptom 1",
    "Symptom 2"
  ],
  "causes": [
    "Cause 1",
    "Cause 2"
  ],
  "immediateCare": [
    "Step 1",
    "Step 2"
  ],
  "medicines": [
    "Name of medicine or ointment (consult doctor)"
  ],
  "homeRemedies": [
    "Remedy 1",
    "Remedy 2"
  ],
  "foodsToEat": [
    "Food 1",
    "Food 2"
  ],
  "foodsToAvoid": [
    "Food 1",
    "Food 2"
  ],
  "dos": [
    "Do 1",
    "Do 2"
  ],
  "donts": [
    "Don't 1",
    "Don't 2"
  ],
  "whenToVisitHospital": "Clinical guidance when hospital visit is recommended",
  "emergencyWarningSigns": "Red flag symptoms e.g. breathing difficulty, high fever, rapid spread"
}
''';

    final textPart = TextPart(prompt);
    final imagePart = DataPart('image/jpeg', imageBytes);
    final response = await _model!.generateContent([
      Content.multi([textPart, imagePart])
    ]);
    final text = response.text?.trim() ?? '';
    
    // Clean markdown wrappers if any
    String jsonString = text;
    if (jsonString.startsWith('```')) {
      final firstLineEnd = jsonString.indexOf('\n');
      final lastBackticks = jsonString.lastIndexOf('```');
      if (firstLineEnd != -1 && lastBackticks != -1) {
        jsonString = jsonString.substring(firstLineEnd + 1, lastBackticks).trim();
      }
    }

    final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
    return parsed;
  }

  Future<Map<String, dynamic>> getVoiceAssistantReply(
      String query, String langCode, {Map<String, dynamic>? patientContext}) async {
    await _ensureInitialized();
    if (_model == null) {
      throw StateError('Gemini model is not configured.');
    }

    // Map language codes to clear names for prompt
    final langNames = {
      'en': 'English',
      'ta': 'Tamil',
      'hi': 'Hindi',
      'te': 'Telugu',
      'kn': 'Kannada',
      'ml': 'Malayalam',
      'mr': 'Marathi',
      'gu': 'Gujarati',
      'bn': 'Bengali',
      'pa': 'Punjabi',
    };
    final langName = langNames[langCode] ?? 'English';

    final contextStr = patientContext != null 
        ? "Patient context: ${jsonEncode(patientContext)}" 
        : "No patient pre-selected.";

    final prompt = '''
You are a smart clinical voice assistant for ASHA healthcare workers in India.
The user is asking: "$query"
Language requested: $langName (Translate the main conversational speech response to this language).

$contextStr

You MUST follow these rules:
1. Provide a natural, friendly, conversational speech response in the requested language ($langName).
2. Maintain clinical screening boundaries (recommend professional consults for severe queries).
3. Do not include markdown formatting.
4. Respond STRICTLY in raw JSON format matching this schema:

{
  "speechText": "Natural voice conversational response in the requested language ($langName)",
  "structuredData": {
    "possibleDisease": "Name of the possible disease/condition (e.g. Common Cold, Skin Allergy, Gastroenteritis) or 'None' if conversational/greeting",
    "confidence": "Confidence level percentage e.g. 85% or 'N/A'",
    "suggestedMedicines": ["Paracetamol (as advised by medical officer)", "Oral Rehydration Salts (ORS)"],
    "homeCare": ["Rest and stay hydrated", "Cool compresses for skin itching"],
    "dietSuggestions": ["Warm soups, soft rice", "Avoid spicy, fried foods"],
    "nearestPHC": "Visit local Primary Health Centre (PHC) if symptoms persist more than 2 days",
    "emergencyAlert": "Seek immediate emergency care if high fever (above 103F), severe vomiting, or chest congestion occurs",
    "healthEducation": "ASHA workers should promote hand hygiene, proper sanitation, and routine immunization updates.",
    "govScheme": "Ayushman Bharat PM-JAY covers tertiary care. General NHM health benefits apply for free PHC checkups."
  }
}
''';

    final content = [Content.text(prompt)];
    final response = await _model!.generateContent(content);
    final text = response.text?.trim() ?? '';
    
    // Clean markdown wrappers if any
    String jsonString = text;
    if (jsonString.startsWith('```')) {
      final firstLineEnd = jsonString.indexOf('\n');
      final lastBackticks = jsonString.lastIndexOf('```');
      if (firstLineEnd != -1 && lastBackticks != -1) {
        jsonString = jsonString.substring(firstLineEnd + 1, lastBackticks).trim();
      }
    }

    final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
    return parsed;
  }

  Future<Map<String, dynamic>> extractOCRData(Uint8List imageBytes) async {
    await _ensureInitialized();
    if (_model == null) {
      throw StateError('Gemini model is not configured.');
    }

    final prompt = '''
You are ASHA AI. Extract the patient details from the provided medical card or physical register book image.
Return ONLY valid JSON with no markdown and no notes.
Schema:
{
  "patientName": "",
  "phoneNumber": "",
  "abhaId": "",
  "dob": "YYYY-MM-DD",
  "village": "",
  "bloodPressure": "",
  "hemoglobin": "",
  "bloodSugar": "",
  "temperature": "",
  "weight": "",
  "symptoms": [],
  "gender": "Female" | "Male",
  "pregnancyStatus": "Yes" | "No"
}
If a field is not found, leave it empty.
''';

    final textPart = TextPart(prompt);
    final imagePart = DataPart('image/jpeg', imageBytes);
    final response = await _model!.generateContent([
      Content.multi([textPart, imagePart])
    ]);
    final text = response.text?.trim() ?? '';
    
    String jsonString = text;
    if (jsonString.startsWith('```')) {
      final firstLineEnd = jsonString.indexOf('\n');
      final lastBackticks = jsonString.lastIndexOf('```');
      if (firstLineEnd != -1 && lastBackticks != -1) {
        jsonString = jsonString.substring(firstLineEnd + 1, lastBackticks).trim();
      }
    }

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('AI OCR Parse Error: \$e');
      return {};
    }
  }

  Future<Map<String, dynamic>> parseVoiceTranscript(String transcript) async {
    await _ensureInitialized();
    if (_model == null) {
      throw StateError('Gemini model is not configured.');
    }

    final prompt = '''
You are ASHA AI, an intelligent AI Voice Assistant developed to assist ASHA Workers in India during patient visits.

Your primary responsibility is to listen to the ASHA worker's spoken conversation, understand the patient's medical information, and automatically populate the Electronic Health Record (EHR).

## Your Responsibilities
1. Listen to the complete voice transcript.
2. Understand natural human conversation even if:
   - sentences are incomplete
   - words are repeated
   - grammar is incorrect
   - English, Tamil, Hindi or mixed language is used.
3. Extract every possible patient detail.
4. Automatically map every extracted value to its corresponding form field.
5. If a field is not mentioned, return an empty string.
6. Never guess patient information.
7. Correct obvious speech recognition mistakes whenever possible.
8. Ignore greetings, filler words and unnecessary conversation.
9. Return ONLY valid JSON.

-----------------------------------------------------
Automatically Fill These Fields
Patient Name, Age, Gender, Phone Number, Village, Address, Pregnancy Status, Child Age, Weight, Height, Temperature, Blood Pressure, Blood Sugar, Pulse Rate, Oxygen Saturation (SpO₂), Symptoms, Duration, Existing Diseases, Current Medications, Allergies, Vaccination Status, Follow-up Date, Emergency Level, Doctor Recommendation, Patient Summary
-----------------------------------------------------

Emergency Detection Rules
If transcript contains
• chest pain
• difficulty breathing
• unconscious
• heavy bleeding
• seizure
• very high fever
• pregnancy bleeding
• severe dehydration
then "emergency": true
otherwise "emergency": false

-----------------------------------------------------
Auto Fill Rules
Extract information and automatically assign it to the matching field.
Examples
"My patient Lakshmi is 45 years old."
↓
patientName = Lakshmi
age = 45

"She has fever and cough since three days."
↓
symptoms = ["Fever","Cough"]
duration = "3 days"

"Blood pressure is 150 over 90"
↓
bloodPressure = "150/90"

"He is diabetic"
↓
existingDiseases = ["Diabetes"]

"Taking Paracetamol"
↓
currentMedications = ["Paracetamol"]

-----------------------------------------------------
Return ONLY this JSON format
{
  "patientName": "",
  "age": "",
  "gender": "",
  "phoneNumber": "",
  "village": "",
  "address": "",
  "pregnancyStatus": "",
  "childAge": "",
  "weight": "",
  "height": "",
  "temperature": "",
  "bloodPressure": "",
  "bloodSugar": "",
  "pulseRate": "",
  "spo2": "",
  "symptoms": [],
  "duration": "",
  "existingDiseases": [],
  "currentMedications": [],
  "allergies": [],
  "vaccinationStatus": "",
  "followUpDate": "",
  "emergency": false,
  "doctorRecommendation": "",
  "patientSummary": ""
}

Do not return explanations.
Do not return markdown.
Do not return notes.
Return only JSON that can directly auto-fill the patient form.

TRANSCRIPT:
"\$transcript"
''';

    final content = [Content.text(prompt)];
    final response = await _model!.generateContent(content);
    final text = response.text?.trim() ?? '';
    
    // Clean markdown wrappers if any
    String jsonString = text;
    if (jsonString.startsWith('```')) {
      final firstLineEnd = jsonString.indexOf('\n');
      final lastBackticks = jsonString.lastIndexOf('```');
      if (firstLineEnd != -1 && lastBackticks != -1) {
        jsonString = jsonString.substring(firstLineEnd + 1, lastBackticks).trim();
      }
    }

    try {
      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
      return parsed;
    } catch (e) {
      debugPrint('AI Transcript Parse Error: \$e');
      return {};
    }
  }
}
