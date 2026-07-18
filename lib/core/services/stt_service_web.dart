import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class STTServiceWeb {
  js.JsObject? _recognition;
  Function(String)? onResult;
  Function(String)? onStateChange;

  void init() {
    try {
      final speechClass = js.context['webkitSpeechRecognition'] ?? js.context['SpeechRecognition'];
      if (speechClass != null) {
        _recognition = js.JsObject(speechClass);
        _recognition!['continuous'] = false;
        _recognition!['interimResults'] = false;

        _recognition!['onstart'] = js.allowInterop((_) {
          onStateChange?.call('listening');
        });

        _recognition!['onerror'] = js.allowInterop((error) {
          debugPrint('STT Error: $error');
          onStateChange?.call('error');
        });

        _recognition!['onend'] = js.allowInterop((_) {
          onStateChange?.call('idle');
        });

        _recognition!['onresult'] = js.allowInterop((event) {
          try {
            final results = event['results'];
            final resultIndex = event['resultIndex'];
            final transcript = results[resultIndex][0]['transcript'].toString();
            onResult?.call(transcript);
          } catch (e) {
            debugPrint('STT result parse error: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('STT Web Initialization error: $e');
    }
  }

  void start(String langCode) {
    if (_recognition == null) init();
    if (_recognition != null) {
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
      _recognition!['lang'] = langMap[langCode] ?? 'en-US';
      _recognition!.callMethod('start');
    }
  }

  void stop() {
    if (_recognition != null) {
      _recognition!.callMethod('stop');
    }
  }
}

final sttInstance = STTServiceWeb();
