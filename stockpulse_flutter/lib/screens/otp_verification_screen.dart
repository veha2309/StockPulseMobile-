import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'dashboard_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const OtpVerificationScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  int _cooldownSeconds = 30;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _resendOtp() async {
    if (!_canResend) return;

    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final success = await auth.sendOtp(widget.email);
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("OTP has been resent to your email."),
            backgroundColor: AppTheme.primary,
          ),
        );
        _startCooldown();
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }

  void _submit() async {
    final code = _otpController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (code.length != 6) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 6-digit OTP code"),
          backgroundColor: AppTheme.secondary,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    try {
      final success = await auth.verifyOtpAndRegister(
        name: widget.name,
        email: widget.email,
        password: widget.password,
        otp: code,
      );

      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_read_rounded,
                size: 64,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                "Verify Your Email",
                style: textTheme.displayLarge?.copyWith(color: AppTheme.onSurface),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "We sent a 6-digit verification code to:\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              GlassCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _otpController,
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: "000000",
                        hintStyle: TextStyle(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                          fontSize: 24,
                          letterSpacing: 8,
                        ),
                        counterText: "",
                        filled: true,
                        fillColor: AppTheme.isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text(
                                "VERIFY & REGISTER",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _canResend ? "Didn't receive code? " : "Resend code in ",
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        if (_canResend)
                          GestureDetector(
                            onTap: _resendOtp,
                            child: const Text(
                              "Resend Code",
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        else
                          Text(
                            "$_cooldownSeconds s",
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                      ],
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
}
