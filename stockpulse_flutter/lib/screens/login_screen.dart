import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'dashboard_screen.dart'; // Import your main dashboard screen
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
  bool _isRegister = false; // Changed to non-final to allow toggling

  void _submit() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Field validations
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
        // After login, if the widget is still mounted, replace the entire navigation stack with Dashboard
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 64, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                _isRegister ? "Join StockPulse" : "Welcome Back",
                style: textTheme.displayLarge?.copyWith(color: AppTheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                _isRegister ? "Create your trading account" : "Sign in to continue trading",
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 48),
              GlassCard(
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
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: context.watch<AuthProvider>().isLoading ? null : _submit,
                        child: context.watch<AuthProvider>().isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(
                                _isRegister ? "REGISTER" : "LOGIN",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        filled: true,
        fillColor: AppTheme.isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1),
        ),
      ),
    );
  }
}
