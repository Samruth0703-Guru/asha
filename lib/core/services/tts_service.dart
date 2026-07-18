import 'tts_service_stub.dart'
    if (dart.library.js) 'tts_service_web.dart' as impl;

void speakText(String text, String langCode, {double rate = 1.0, double pitch = 1.0}) {
  impl.speakText(text, langCode, rate: rate, pitch: pitch);
}

void stopSpeaking() {
  impl.stopSpeaking();
}

void pauseSpeaking() {
  impl.pauseSpeaking();
}

void resumeSpeaking() {
  impl.resumeSpeaking();
}
