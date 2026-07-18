import 'dart:js' as js;

void speakText(String text, String langCode, {double rate = 1.0, double pitch = 1.0}) {
  try {
    final synth = js.context['speechSynthesis'];
    if (synth != null) {
      synth.callMethod('cancel');
      final utterance = js.JsObject(js.context['SpeechSynthesisUtterance'], [text]);
      
      final Map<String, String> langMap = {
        'en': 'en-US',
        'ta': 'ta-IN',
        'hi': 'hi-IN',
        'te': 'te-IN',
        'kn': 'kn-IN',
        'ml': 'ml-IN',
        'mr': 'mr-IN',
        'gu': 'gu-IN',
        'bn': 'bn-IN',
        'pa': 'pa-IN',
      };
      
      utterance['lang'] = langMap[langCode] ?? 'en-US';
      utterance['rate'] = rate;
      utterance['pitch'] = pitch;

      synth.callMethod('speak', [utterance]);
    }
  } catch (_) {}
}

void stopSpeaking() {
  try {
    final synth = js.context['speechSynthesis'];
    if (synth != null) {
      synth.callMethod('cancel');
    }
  } catch (_) {}
}

void pauseSpeaking() {
  try {
    final synth = js.context['speechSynthesis'];
    if (synth != null) {
      synth.callMethod('pause');
    }
  } catch (_) {}
}

void resumeSpeaking() {
  try {
    final synth = js.context['speechSynthesis'];
    if (synth != null) {
      synth.callMethod('resume');
    }
  } catch (_) {}
}
