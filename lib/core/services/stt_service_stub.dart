class STTServiceStub {
  Function(String)? onResult;
  Function(String)? onStateChange;

  void init() {}
  void start(String langCode) {}
  void stop() {}
}

final sttInstance = STTServiceStub();
