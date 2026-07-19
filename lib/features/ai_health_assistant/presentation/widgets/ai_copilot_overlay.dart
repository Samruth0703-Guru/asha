import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/voice_copilot_provider.dart';
import '../../../../core/services/voice_copilot_service.dart';

class AiCopilotOverlay extends ConsumerStatefulWidget {
  const AiCopilotOverlay({super.key});

  @override
  ConsumerState<AiCopilotOverlay> createState() => _AiCopilotOverlayState();
}

class _AiCopilotOverlayState extends ConsumerState<AiCopilotOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _emergencyController;
  late Animation<double> _pulseAnimation;
  CopilotState? _lastState;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _emergencyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Initialize the voice copilot service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceCopilotServiceProvider).initialize();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  void _syncAnimations(CopilotState state) {
    if (state == _lastState) return;
    _lastState = state;

    switch (state) {
      case CopilotState.idle:
        _pulseController.stop();
        _pulseController.reset();
        _waveController.stop();
        _waveController.reset();
        _emergencyController.stop();
        _emergencyController.reset();
        break;
      case CopilotState.listening:
        _pulseController.repeat(reverse: true);
        _waveController.repeat(reverse: true);
        _emergencyController.stop();
        break;
      case CopilotState.thinking:
        _pulseController.repeat(reverse: true);
        _waveController.stop();
        _emergencyController.stop();
        break;
      case CopilotState.speaking:
        _pulseController.stop();
        _pulseController.reset();
        _waveController.repeat(reverse: true);
        _emergencyController.stop();
        break;
      case CopilotState.emergency:
        _emergencyController.repeat(reverse: true);
        _pulseController.stop();
        _waveController.stop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final copilotData = ref.watch(voiceCopilotProvider);
    final isExpanded = copilotData.state != CopilotState.idle;

    // Drive animations from state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAnimations(copilotData.state);
    });

    return Positioned(
      right: 20,
      bottom: isExpanded ? 80 : 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expanded panel
          if (isExpanded) ...[
            copilotData.state == CopilotState.emergency
                ? _buildEmergencyCard(copilotData)
                : _buildConversationCard(copilotData),
            const SizedBox(height: 12),
          ],

          // Floating mic button (always visible)
          _buildFab(copilotData),
        ],
      ),
    );
  }

  Widget _buildFab(VoiceCopilotData data) {
    Color bgColor;
    IconData icon;
    switch (data.state) {
      case CopilotState.idle:
        bgColor = const Color(0xff7C3AED);
        icon = Icons.mic_rounded;
        break;
      case CopilotState.listening:
        bgColor = const Color(0xff10B981);
        icon = Icons.hearing_rounded;
        break;
      case CopilotState.thinking:
        bgColor = const Color(0xff3B82F6);
        icon = Icons.psychology_rounded;
        break;
      case CopilotState.speaking:
        bgColor = const Color(0xff8B5CF6);
        icon = Icons.record_voice_over_rounded;
        break;
      case CopilotState.emergency:
        bgColor = const Color(0xffEF4444);
        icon = Icons.emergency_rounded;
        break;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = (data.state == CopilotState.listening || data.state == CopilotState.thinking)
            ? _pulseAnimation.value
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: () {
          if (data.state == CopilotState.speaking) {
            ref.read(voiceCopilotServiceProvider).interruptAndListen();
          } else if (data.state == CopilotState.idle) {
            ref.read(voiceCopilotServiceProvider).manualActivate();
          } else if (data.state == CopilotState.emergency) {
            ref.read(voiceCopilotProvider.notifier).setIdle();
          }
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: bgColor.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildConversationCard(VoiceCopilotData data) {
    String statusLabel;
    Color statusColor;
    Widget statusWidget;

    switch (data.state) {
      case CopilotState.listening:
        statusLabel = '👂 Listening...';
        statusColor = const Color(0xff10B981);
        statusWidget = _buildWaveform(statusColor);
        break;
      case CopilotState.thinking:
        statusLabel = '🧠 Generating medical advice...';
        statusColor = const Color(0xff3B82F6);
        statusWidget = SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: statusColor),
        );
        break;
      case CopilotState.speaking:
        statusLabel = '🔊 Speaking...';
        statusColor = const Color(0xff8B5CF6);
        statusWidget = _buildWaveform(statusColor);
        break;
      default:
        statusLabel = '';
        statusColor = Colors.grey;
        statusWidget = const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 320,
        constraints: const BoxConstraints(maxHeight: 240),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.97),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  statusWidget,
                  const SizedBox(width: 12),
                  Text(
                    statusLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ref.read(voiceCopilotProvider.notifier).setIdle(),
                    child: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 20),
                  ),
                ],
              ),
              if (data.currentText.isNotEmpty &&
                  data.currentText != '👂 Listening...') ...[
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      data.currentText,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        height: 1.5,
                        color: const Color(0xff334155),
                      ),
                    ),
                  ),
                ),
              ],
              if (data.state == CopilotState.speaking) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.touch_app_rounded, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      'Tap mic to interrupt',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(VoiceCopilotData data) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 340,
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffDC2626), Color(0xff991B1B)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    '🚨 EMERGENCY PROTOCOL',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    data.emergencyMessage,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Call Ambulance: 108',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform(Color color) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        final t = _waveController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final phase = (i * 0.25 + t) * 2 * pi;
            final height = 6.0 + (sin(phase).abs() * 14.0);
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Custom AnimatedWidget wrapper to avoid name collision with Flutter's AnimatedBuilder
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
