import 'stt_service_stub.dart'
    if (dart.library.js) 'stt_service_web.dart' as impl;

class STTService {
  void init(Function(String) onResult, Function(String) onStateChange) {
    impl.sttInstance.onResult = onResult;
    impl.sttInstance.onStateChange = onStateChange;
    impl.sttInstance.init();
  }

  void start(String langCode) {
    impl.sttInstance.start(langCode);
  }

  void stop() {
    impl.sttInstance.stop();
  }
}

final sttServiceProvider = STTService();
