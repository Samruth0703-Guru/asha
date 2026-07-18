import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/auth/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    if (!_formKey.currentState!.validate()) return;
    
    final phone = _phoneController.text.trim();
    ref.read(authProvider.notifier).sendSmsOtp(phone);
  }

  void _handleVerifyOtp() {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP code'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }
    ref.read(authProvider.notifier).verifySmsOtp(code);
  }

  void _handleBiometricAuth() async {
    // Simulated fast biometric authentication
    ref.read(authProvider.notifier).sendSmsOtp('9876543210');
    // Wait for OTP generation and bypass
    await Future.delayed(const Duration(milliseconds: 600));
    final otp = ref.read(authProvider.notifier).getSimulatedOtp();
    ref.read(authProvider.notifier).verifySmsOtp((otp != null && otp.isNotEmpty) ? otp : '123456');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Listen to Auth State updates
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    // Watch for success status to route automatically
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication Successful! Welcome, ASHA Worker.'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
        context.go('/dashboard');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      } else if (next.status == AuthStatus.codeSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification Code Sent via SMS! Check your inbox.'),
            backgroundColor: AppTheme.secondaryColor,
            duration: Duration(seconds: 5),
          ),
        );
      }
    });

    final otpSent = authState.status == AuthStatus.codeSent || 
                    (authState.status == AuthStatus.error && authState.verificationPhone != null);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: size.height),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xff0f172a), const Color(0xff1e1b4b)]
                  : [const Color(0xfff8fafc), const Color(0xffeff6ff)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'emblem',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ASHA CARE+',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white : const Color(0xff1e3a8a),
                  ),
                ),
                Text(
                  'National Health Mission • Govt. of India',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 48),
                Card(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          otpSent ? 'Verify OTP' : 'Worker Login',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          otpSent
                              ? 'Enter the 6-digit code sent to your registered phone number'
                              : 'Enter your registered mobile number to proceed',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        if (!otpSent)
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.phone_android, color: AppTheme.primaryColor),
                              labelText: 'Mobile Number',
                              hintText: 'Enter 10-digit number',
                              counterText: '',
                            ),
                            validator: (val) {
                              if (val == null || val.length < 10) {
                                return 'Please enter a valid 10-digit phone number';
                              }
                              return null;
                            },
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                obscureText: false,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                                  labelText: 'SMS OTP Code',
                                  hintText: 'Enter 6-digit OTP',
                                  counterText: '',
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Resend countdown handler
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    authState.resendCountdown > 0
                                        ? 'Resend OTP in ${authState.resendCountdown}s'
                                        : 'Didn\'t receive OTP?',
                                    style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey),
                                  ),
                                  TextButton(
                                    onPressed: authState.resendCountdown > 0 ? null : authNotifier.resendOtp,
                                    child: Text(
                                      'Resend OTP',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: authState.resendCountdown > 0 ? Colors.grey : AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                        const SizedBox(height: 12),
                        // Offline Switch
                        Row(
                          children: [
                            Switch(
                              value: authState.isOfflineMode,
                              activeColor: AppTheme.secondaryColor,
                              onChanged: authNotifier.toggleOfflineMode,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Offline Mode Login',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Bypass cloud check (requires local cache)',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isLoading 
                              ? null 
                              : (otpSent ? _handleVerifyOtp : _handleSendOtp),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(otpSent ? 'Verify & Login' : 'Send OTP'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (!otpSent)
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        Text(
                          'OR LOGIN SECURELY WITH',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _handleBiometricAuth,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xff1e293b) : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              size: 40,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
