import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockpulse_flutter/screens/login_screen.dart';
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
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
                    AppTheme.violet.withValues(alpha: 0.09),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              top: 180,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.amber.withValues(alpha: 0.07),
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
                    AppTheme.blue.withValues(alpha: 0.06),
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
      ],
    );
  }

  Widget _buildProfileCard(dynamic user) {
    return GlassCard(
      glow: true,
      accentColor: AppTheme.violet,
      child: Column(
        children: [
          // Avatar with violet→primary gradient ring
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.violet, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.violet.withValues(alpha: AppTheme.isDark ? 0.35 : 0.12),
                    blurRadius: 24,
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
                child: const Icon(Icons.person_rounded, color: AppTheme.violet, size: 44),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _isEditing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 48), // Balance spacing for check button
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter Name',
                          hintStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _saveInlineName(),
                      ),
                    ),
                    GestureDetector(
                      onTap: _saveInlineName,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: AppTheme.primary, size: 20),
                      ),
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      _nameController.text = user.name;
                      _isEditing = true;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.edit_rounded, color: AppTheme.primary, size: 16),
                    ],
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
        ],
      ),
    );
  }


  Widget _buildStatsRow(dynamic user) {
    return Column(
      children: [
        AnimatedStatCard(
          label: 'Available Cash Balance',
          value: formatINR(user.eTokens),
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppTheme.amber,
          delay: 0,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnimatedStatCard(
                label: 'Holdings',
                value: '${user.portfolio.length} Stocks',
                icon: Icons.pie_chart_rounded,
                iconColor: AppTheme.blue,
                delay: 100,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedStatCard(
                label: 'Options Trades',
                value: '${user.options.length} Active',
                icon: Icons.candlestick_chart_rounded,
                iconColor: AppTheme.violet,
                delay: 200,
              ),
            ),
          ],
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
            gradient: AppTheme.amberGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.amber.withValues(alpha: AppTheme.isDark ? 0.30 : 0.15),
                blurRadius: 16,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_card_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'REQUEST E-TOKEN RECHARGE',
                style: TextStyle(
                  color: Colors.white,
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

  Future<void> _saveInlineName() async {
    final auth = context.read<AuthProvider>();
    if (_nameController.text.trim().isEmpty) return;
    try {
      await auth.updateProfile(name: _nameController.text.trim());
      setState(() => _isEditing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile Updated!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }
  
  void logOut(AuthProvider auth) {
    auth.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
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
        onPressed: () => logOut(auth),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('LOG OUT',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}
