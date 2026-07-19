import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CopilotState { idle, listening, thinking, speaking, emergency }

class VoiceCopilotData {
  final CopilotState state;
  final String currentText;
  final String emergencyMessage;
  
  VoiceCopilotData({
    required this.state,
    required this.currentText,
    this.emergencyMessage = '',
  });

  VoiceCopilotData copyWith({
    CopilotState? state,
    String? currentText,
    String? emergencyMessage,
  }) {
    return VoiceCopilotData(
      state: state ?? this.state,
      currentText: currentText ?? this.currentText,
      emergencyMessage: emergencyMessage ?? this.emergencyMessage,
    );
  }
}

class VoiceCopilotNotifier extends StateNotifier<VoiceCopilotData> {
  VoiceCopilotNotifier()
      : super(VoiceCopilotData(state: CopilotState.idle, currentText: ''));

  void setIdle() {
    state = state.copyWith(state: CopilotState.idle, currentText: '');
  }

  void setListening(String text) {
    state = state.copyWith(state: CopilotState.listening, currentText: text);
  }

  void setThinking() {
    state = state.copyWith(state: CopilotState.thinking, currentText: 'Generating medical advice...');
  }

  void setSpeaking(String text) {
    state = state.copyWith(state: CopilotState.speaking, currentText: text);
  }

  void setEmergency(String message) {
    state = state.copyWith(state: CopilotState.emergency, currentText: 'EMERGENCY PROTOCOL', emergencyMessage: message);
  }
}

final voiceCopilotProvider = StateNotifierProvider<VoiceCopilotNotifier, VoiceCopilotData>((ref) {
  return VoiceCopilotNotifier();
});
