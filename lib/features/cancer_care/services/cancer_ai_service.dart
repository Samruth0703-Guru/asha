import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/services/gemini_service.dart';

final cancerAiServiceProvider = Provider<CancerAiService>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return CancerAiService(geminiService);
});

class CancerAiService {
  final GeminiService _geminiService;

  CancerAiService(this._geminiService);

  GenerativeModel? _getModel() {
    final key = _geminiService.apiKey;
    if (key.isNotEmpty) {
      return GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
      );
    }
    return null;
  }

  // ==========================================
  // SYMPTOM RISK SCREENING EVALUATION
  // ==========================================
  Future<Map<String, dynamic>> evaluateSymptomRisk({
    required String cancerType,
    required List<String> symptoms,
    required List<String> riskFactors,
    required String lifestyle,
    required String familyHistory,
    required String clinicalNotes,
  }) async {
    final model = _getModel();
    if (model == null) {
      return {
        'riskLevel': 'Medium Risk',
        'confidenceScore': 65.0,
        'explanation': 'Simulation Fallback: Gemini API not configured. Based on provided parameters, symptoms indicate moderate concern.',
        'suggestedNextSteps': [
          'Verify symptoms with repeat clinical examination.',
          'Schedule an immediate Primary Health Centre (PHC) reference consult.'
        ]
      };
    }

    final prompt = '''
You are a clinical decision support AI assistant specialized in oncology and primary cancer screening guidelines. Your role is to perform early detection risk screening for $cancerType Cancer based on guidelines from WHO and ICMR.

Patient Parameters provided by the community health worker:
- Cancer Type Category: $cancerType
- Reported Symptoms: ${symptoms.isNotEmpty ? symptoms.join(', ') : 'None'}
- Selected Risk Factors: ${riskFactors.isNotEmpty ? riskFactors.join(', ') : 'None'}
- Lifestyle Details: $lifestyle
- Family History of Cancer: $familyHistory
- Clinical notes / Vitals: $clinicalNotes

Assess the early warning risk level of this patient.
You MUST output your assessment strictly in the following JSON format. Do not output any markdown wrappers (like ```json), just raw JSON:
{
  "riskLevel": "Low Risk" | "Medium Risk" | "High Risk" | "Critical Risk",
  "confidenceScore": 0.0 to 100.0,
  "explanation": "A detailed explanation of why they are at this risk level, detailing any warning flags and advising on target organ checks.",
  "suggestedNextSteps": [
    "Next step 1 (e.g. schedule home visit, refer to CHC, monitor monthly)",
    "Next step 2"
  ]
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final text = response.text?.trim() ?? '';
      
      String jsonString = text;
      if (jsonString.startsWith('```')) {
        final firstLineEnd = jsonString.indexOf('\n');
        final lastBackticks = jsonString.lastIndexOf('```');
        if (firstLineEnd != -1 && lastBackticks != -1) {
          jsonString = jsonString.substring(firstLineEnd + 1, lastBackticks).trim();
        }
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('AI Symptom Screening error: $e');
      // Graceful offline fallback scoring
      double simulatedScore = 15.0;
      String level = 'Low Risk';
      if (symptoms.isNotEmpty || riskFactors.isNotEmpty) {
        simulatedScore = 55.0;
        level = 'Medium Risk';
      }
      if (symptoms.any((s) => s.toLowerCase().contains('lump') || s.toLowerCase().contains('bleeding') || s.toLowerCase().contains('difficulty swallowing'))) {
        simulatedScore = 88.0;
        level = 'High Risk';
      }

      return {
        'riskLevel': level,
        'confidenceScore': simulatedScore,
        'explanation': 'Offline fallback assessment. Real-time Gemini evaluation could not be reached. Vitals indicate positive symptoms or risk factors that require clinical evaluation by a medical officer at the PHC.',
        'suggestedNextSteps': [
          'Verify symptoms with repeat clinical examination.',
          'Schedule an immediate Primary Health Centre (PHC) reference consult.',
          'Advise patient to avoid self-medicating.'
        ]
      };
    }
  }

  // ==========================================
  // IMAGE SCANNING (GEMINI VISION)
  // ==========================================
  Future<Map<String, dynamic>> analyzeCancerImage(Uint8List imageBytes, String imageCategory) async {
    final model = _getModel();
    if (model == null) {
      return {
        'condition': 'Simulation Fallback: Possible Lesion Detected',
        'confidence': '80%',
        'severity': 'Moderate',
        'possibleCauses': ['UV Exposure', 'Chronic Irritation'],
        'suggestedNextSteps': [
          'Consult local doctor if redness or pain spreads.',
          'Monitor changes weekly'
        ],
        'referral': 'Referral to District General Hospital Oncology Department recommended.',
        'disclaimer': 'Simulated offline screening only. Gemini API not configured.'
      };
    }

    final prompt = '''
You are an advanced medical vision screening assistant specialized in oncology and pathological dermatology.
Analyze this screening image of a patient (Category: $imageCategory). This might display oral lesions, breast skin abnormalities, skin wounds, or suspicious growths.

Examine the image for indicators of visible cancer risk, premalignant lesions, or external anomalies.

You MUST follow these rules:
1. Never claim a confirmed medical diagnosis. Always phrase results as potential risks.
2. Formulate a bold disclaimer in suggestions.
3. Respond STRICTLY in raw JSON format (no markdown blocks like ```json).

The output JSON structure:
{
  "condition": "Name of the possible condition/lesion detected (e.g. Oral Leukoplakia, Suspicious Breast Skin Dimpling, Suspected Melanoma)",
  "confidence": "Confidence score as percentage (e.g. 84%)",
  "severity": "Low" | "Moderate" | "High" | "Critical",
  "possibleCauses": [
    "Tobacco/Areca nut chewing (for oral)",
    "Ultraviolet exposure",
    "Cellular dysplasia"
  ],
  "suggestedNextSteps": [
    "Schedule biopsy or mammography at District Hospital",
    "Immediately stop tobacco and alcohol consumption",
    "Monitor size, shape, and color changes weekly"
  ],
  "referral": "Recommend referral to a qualified Oncologist at the Regional Cancer Centre.",
  "disclaimer": "AI-generated screening only. Please consult an oncologist or qualified doctor."
}
''';

    try {
      final textPart = TextPart(prompt);
      final imagePart = DataPart('image/jpeg', imageBytes);
      final response = await model.generateContent([
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

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('AI Vision Screening error: $e');
      // Offline fallback
      return {
        'condition': 'External Lesion (Offline Fallback)',
        'confidence': '60%',
        'severity': 'Moderate',
        'possibleCauses': ['Chronic tissue irritation', 'Infectious skin lesion'],
        'suggestedNextSteps': [
          'Wash wound and cover with sterile gauze.',
          'Schedule clinical examination under doctor consultation.',
          'Consult local doctor if redness or pain spreads.'
        ],
        'referral': 'Referral to District General Hospital Oncology Department recommended.',
        'disclaimer': 'AI-generated screening only. Please consult an oncologist or qualified doctor.'
      };
    }
  }

  // ==========================================
  // VOICE ASSISTANT CANCER SUPPORT
  // ==========================================
  Future<Map<String, dynamic>> getVoiceAssistantReply(String query, String langCode) async {
    final model = _getModel();
    if (model == null) {
      throw StateError('Gemini model not configured.');
    }

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

    final prompt = '''
You are a smart clinical voice assistant for ASHA healthcare workers in India.
The user is asking: "$query"
Language requested: $langName (Translate the main conversational speech response into this language).

Analyze if the query relates to cancer care, screening, follow-up, chemotherapy side-effects, pain management, or referrals.
Formulate a highly helpful, clinical response.

You MUST follow these rules:
1. Provide a natural, friendly, conversational speech response in the requested language ($langName). Do not prescribe any medicines (only advice supportive care like hydration, nutritional advice, or consulting a doctor).
2. Always emphasize that this is a clinical screen and a doctor/oncologist consultation is mandatory.
3. Do not include markdown formatting.
4. Respond STRICTLY in raw JSON format matching this schema:
{
  "speechText": "Natural voice conversational response in the requested language ($langName)",
  "structuredData": {
    "queryCategory": "Cancer Screening | Treatment Care | Side Effects Management | General info",
    "urgency": "Low" | "Medium" | "High" | "Critical",
    "recommendations": [
      "Consult oncologist immediately",
      "Supportive hydration and diet advice"
    ],
    "disclaimer": "AI-generated screening only. Please consult an oncologist or qualified doctor."
  }
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final text = response.text?.trim() ?? '';
      
      String jsonString = text;
      if (jsonString.startsWith('```')) {
        final firstLineEnd = jsonString.indexOf('\n');
        final lastBackticks = jsonString.lastIndexOf('```');
        if (firstLineEnd != -1 && lastBackticks != -1) {
          jsonString = jsonString.substring(firstLineEnd + 1, lastBackticks).trim();
        }
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Voice reply error: $e');
      // Offline fallback
      return {
        'speechText': 'Connection error. Please ensure internet access to compute clinical voice replies.',
        'structuredData': {
          'queryCategory': 'General info',
          'urgency': 'Medium',
          'recommendations': ['Refer to medical officer', 'Verify vitals'],
          'disclaimer': 'AI-generated screening only. Please consult an oncologist or qualified doctor.'
        }
      };
    }
  }
}
