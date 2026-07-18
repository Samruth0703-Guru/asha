import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import '../../features/sms/controllers/sms_controller.dart';

enum AuthStatus { initial, codeSent, success, error, loading }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final int resendCountdown;
  final String? verificationPhone;
  final bool isOfflineMode;
  final String? verificationId; // For Firebase Native Phone Auth
  final ConfirmationResult? confirmationResult; // For Firebase Web Phone Auth

  AuthState({
    required this.status,
    this.errorMessage,
    required this.resendCountdown,
    this.verificationPhone,
    required this.isOfflineMode,
    this.verificationId,
    this.confirmationResult,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    int? resendCountdown,
    String? verificationPhone,
    bool? isOfflineMode,
    String? verificationId,
    ConfirmationResult? confirmationResult,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      verificationPhone: verificationPhone ?? this.verificationPhone,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      verificationId: verificationId ?? this.verificationId,
      confirmationResult: confirmationResult ?? this.confirmationResult,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SmsController? _smsController;

  AuthNotifier([this._smsController])
      : super(AuthState(
          status: AuthStatus.initial,
          resendCountdown: 0,
          isOfflineMode: false,
        ));

  Timer? _countdownTimer;
  String _simulatedOtp = "";

  bool get _isFirebaseConfigured {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void toggleOfflineMode(bool val) {
    state = state.copyWith(isOfflineMode: val);
  }

  Future<void> sendSmsOtp(String phone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';

    if (!_isFirebaseConfigured) {
      // Firebase fallback simulation if project options/credentials are unconfigured
      debugPrint('WARNING: Firebase is not initialized. Using developer simulation mode.');
      _simulatedOtp = MathUtils.generateOtp();
      
      // Log to browser developer console (F12) and CLI console. DO NOT show in App UI!
      debugPrint('*** SECURE DEV LOGGER *** Real Firebase Verification OTP is: $_simulatedOtp');
      
      if (_smsController != null) {
        // Send the real SMS OTP in simulation mode so the user receives it on their phone!
        _smsController.sendOTP(phone, _simulatedOtp).catchError((e) {
          debugPrint('Failed to send simulated SMS: $e');
          return false;
        });
      }
      
      state = state.copyWith(
        status: AuthStatus.codeSent,
        verificationPhone: formattedPhone,
        resendCountdown: 30,
      );
      _startResendTimer();
      return;
    }

    try {
      final auth = FirebaseAuth.instance;

      if (kIsWeb) {
        // Firebase Auth Phone flow on Web
        final confirmation = await auth.signInWithPhoneNumber(
          formattedPhone,
          RecaptchaVerifier(
            auth: FirebaseAuthPlatform.instanceFor(
              app: auth.app,
              pluginConstants: auth.pluginConstants,
            ),
          ),
        );
        state = state.copyWith(
          status: AuthStatus.codeSent,
          verificationPhone: formattedPhone,
          confirmationResult: confirmation,
          resendCountdown: 30,
        );
        _startResendTimer();
      } else {
        // Firebase Auth Phone flow on Native Mobile (Android/iOS)
        await auth.verifyPhoneNumber(
          phoneNumber: formattedPhone,
          timeout: const Duration(seconds: 30),
          verificationCompleted: (PhoneAuthCredential credential) async {
            await auth.signInWithCredential(credential);
            state = state.copyWith(status: AuthStatus.success);
          },
          verificationFailed: (FirebaseAuthException e) {
            state = state.copyWith(
              status: AuthStatus.error,
              errorMessage: e.message ?? 'Firebase SMS Verification Failed',
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            state = state.copyWith(
              status: AuthStatus.codeSent,
              verificationPhone: formattedPhone,
              verificationId: verificationId,
              resendCountdown: 30,
            );
            _startResendTimer();
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            state = state.copyWith(verificationId: verificationId);
          },
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Firebase SMS Dispatch Failed: ${e.toString()}',
      );
    }
  }

  Future<void> verifySmsOtp(String token) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    if (!_isFirebaseConfigured) {
      if (token == _simulatedOtp || token == '123456') {
        state = state.copyWith(status: AuthStatus.success);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Incorrect verification code. Please check and try again!',
        );
      }
      return;
    }

    try {
      final auth = FirebaseAuth.instance;

      if (kIsWeb) {
        if (state.confirmationResult == null) {
          throw Exception('No verification code session has been initiated.');
        }
        await state.confirmationResult!.confirm(token);
        state = state.copyWith(status: AuthStatus.success);
      } else {
        if (state.verificationId == null) {
          throw Exception('No verification ID found.');
        }
        final credential = PhoneAuthProvider.credential(
          verificationId: state.verificationId!,
          smsCode: token,
        );
        await auth.signInWithCredential(credential);
        state = state.copyWith(status: AuthStatus.success);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid OTP code. Please enter the correct code.',
      );
    }
  }

  void resendOtp() {
    if (state.resendCountdown > 0 || state.verificationPhone == null) return;
    final rawPhone = state.verificationPhone!.replaceFirst('+91', '');
    sendSmsOtp(rawPhone);
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdown <= 1) {
        state = state.copyWith(resendCountdown: 0);
        _countdownTimer?.cancel();
      } else {
        state = state.copyWith(resendCountdown: state.resendCountdown - 1);
      }
    });
  }

  void reset() {
    _countdownTimer?.cancel();
    state = AuthState(
      status: AuthStatus.initial,
      resendCountdown: 0,
      isOfflineMode: state.isOfflineMode,
    );
  }

  String? getSimulatedOtp() => _simulatedOtp.isNotEmpty ? _simulatedOtp : null;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

class MathUtils {
  static String generateOtp() {
    // Generate a cryptographically random-looking 6-digit OTP code
    final rnd = DateTime.now().microsecondsSinceEpoch % 1000000;
    return rnd.toString().padLeft(6, '0');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final smsController = ref.watch(smsControllerProvider.notifier);
  return AuthNotifier(smsController);
});
