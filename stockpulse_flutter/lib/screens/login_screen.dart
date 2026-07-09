import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'dashboard_screen.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegister = false;

  void _submit() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Enter a valid email address"), backgroundColor: AppTheme.secondary),
      );
      return;
    }

    if (_isRegister) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Name cannot be empty"), backgroundColor: AppTheme.secondary),
        );
        return;
      }
      if (password.length < 6) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Password must be at least 6 characters long"), backgroundColor: AppTheme.secondary),
        );
        return;
      }
    } else {
      if (password.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Password cannot be empty"), backgroundColor: AppTheme.secondary),
        );
        return;
      }
    }

    try {
      if (_isRegister) {
        final name = _nameController.text.trim();
        final success = await auth.sendOtp(email);
        if (success && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                name: name,
                email: email,
                password: password,
              ),
            ),
          );
        }
      } else {
        await auth.login(email, password);
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DashboardScreen()), (route) => false);
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.secondary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Multi-color ambient orbs
          if (AppTheme.isDark) ...[
            Positioned(
              top: -80,
              left: -60,
              child: _Orb(color: AppTheme.violet.withValues(alpha: 0.10), size: 300),
            ),
            Positioned(
              bottom: -60,
              right: -60,
              child: _Orb(color: AppTheme.blue.withValues(alpha: 0.08), size: 260),
            ),
            Positioned(
              top: 300,
              right: -40,
              child: _Orb(color: AppTheme.primary.withValues(alpha: 0.06), size: 200),
            ),
          ],
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with gradient ShaderMask
                  ShaderMask(
                    shaderCallback: (bounds) => AppTheme.violetGradient.createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: const Icon(Icons.account_balance_wallet_rounded, size: 64),
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      _isRegister ? "Join StockPulse" : "Welcome Back",
                      style: textTheme.displayLarge,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isRegister ? "Create your trading account" : "Sign in to continue trading",
                    style: textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 48),
                  GlassCard(
                    accentColor: AppTheme.violet,
                    child: Column(
                      children: [
                        if (_isRegister) ...[
                          _buildField(_nameController, "Full Name", Icons.person),
                          const SizedBox(height: 16),
                        ],
                        _buildField(_emailController, "Email Address", Icons.email),
                        const SizedBox(height: 16),
                        _buildField(_passwordController, "Password", Icons.lock, obscure: true),
                        const SizedBox(height: 32),
                        // Gradient submit button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: GestureDetector(
                            onTap: context.watch<AuthProvider>().isLoading ? null : _submit,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _isRegister ? AppTheme.violetGradient : AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRegister ? AppTheme.violet : AppTheme.primary)
                                        .withValues(alpha: AppTheme.isDark ? 0.35 : 0.18),
                                    blurRadius: 16,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: context.watch<AuthProvider>().isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        _isRegister ? "REGISTER" : "LOGIN",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegister = !_isRegister;
                      });
                    },
                    child: Text(
                      _isRegister ? "Already have an account? Login" : "Don't have an account? Register",
                      style: const TextStyle(
                          color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: AppTheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: AppTheme.violet, size: 20),
        filled: true,
        fillColor: AppTheme.isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.violet.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.violet.withValues(alpha: 0.55), width: 1.5),
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.3, 1.0],
        ),
      ),
    );
  }
}
