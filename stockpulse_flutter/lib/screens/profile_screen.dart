import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatter.dart';
import '../widgets/glass_card.dart';
import 'recharge_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _branchController = TextEditingController();
  final _enrollmentController = TextEditingController();
  bool _isEditing = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _branchController.text = user.branch;
      _enrollmentController.text = user.enrollment;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    _enrollmentController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // orbs (Dark mode only)
          if (AppTheme.isDark) ...[
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ],
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 24),
                    _buildProfileCard(user),
                    const SizedBox(height: 16),
                    _buildStatsRow(user),
                    const SizedBox(height: 16),
                    _buildSettingsCard(context),
                    const SizedBox(height: 16),
                    _buildRechargeButton(context),
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      _buildEditForm(auth),
                    ],
                    const SizedBox(height: 16),
                    _buildLogoutButton(context, auth),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        Text(
          'My Profile',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _isEditing = !_isEditing),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(dynamic user) {
    return GlassCard(
      glow: true,
      child: Column(
        children: [
          // Avatar with gradient ring
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
              ),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primary.withValues(alpha: AppTheme.isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    spreadRadius: -4),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.card,
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppTheme.primary, size: 44),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _badge(user.branch, AppTheme.primary),
              const SizedBox(width: 8),
              _badge(user.enrollment, AppTheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatsRow(dynamic user) {
    return Row(
      children: [
        Expanded(
          child: AnimatedStatCard(
            label: 'Cash Balance',
            value: formatINR(user.eTokens),
            icon: Icons.account_balance_wallet_rounded,
            delay: 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedStatCard(
            label: 'Holdings',
            value: '${user.portfolio.length}',
            icon: Icons.pie_chart_rounded,
            delay: 100,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedStatCard(
            label: 'Options',
            value: '${user.options.length}',
            icon: Icons.candlestick_chart_rounded,
            delay: 200,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Settings',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            activeThumbColor: AppTheme.primary,
            title: Text(
              'Dark Theme',
              style: TextStyle(color: AppTheme.onSurface, fontSize: 14),
            ),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppTheme.primary,
            ),
            value: themeProvider.isDarkMode,
            onChanged: (bool value) {
              themeProvider.toggleTheme();
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const RechargeScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.25), width: 1),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_card_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 10),
              Text(
                'REQUEST E-TOKEN RECHARGE',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm(AuthProvider auth) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Information',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(_nameController, 'Full Name', Icons.person_outline),
          const SizedBox(height: 14),
          _buildTextField(_branchController, 'Branch', Icons.school_outlined),
          const SizedBox(height: 14),
          _buildTextField(_enrollmentController, 'Enrollment Number',
              Icons.numbers_outlined),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      try {
                        await auth.updateProfile(
                          name: _nameController.text,
                          branch: _branchController.text,
                          enrollment: _enrollmentController.text,
                        );
                        setState(() => _isEditing = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Profile Updated!'),
                              backgroundColor: AppTheme.primary),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppTheme.secondary));
                      }
                    },
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('SAVE CHANGES',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppTheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        filled: true,
        fillColor: AppTheme.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.secondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => auth.logout(),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('LOG OUT',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}
