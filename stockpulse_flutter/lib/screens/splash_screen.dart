import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/stock_pulse_logo.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Master controller — 4 seconds total
  late final AnimationController _ctrl;

  // Logo: scale + fade in
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // Pulse rings
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _pulse2Scale;
  late final Animation<double> _pulse2Opacity;

  // App name
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  // Tagline
  late final Animation<double> _taglineFade;

  // Loading bar
  late final Animation<double> _barProgress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.35, curve: Curves.elasticOut)),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.25, curve: Curves.easeIn)),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );

    _pulse2Scale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 0.85, curve: Curves.easeOut)),
    );
    _pulse2Opacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 0.85, curve: Curves.easeOut)),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.35, 0.6, curve: Curves.easeOut)),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.35, 0.6, curve: Curves.easeOut)),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 0.75, curve: Curves.easeIn)),
    );

    _barProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.65, 1.0, curve: Curves.easeInOut)),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });

    _ctrl.forward();
  }

  void _navigateToNext() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    
    // Determine target screen based on auth state
    final Widget nextScreen = auth.isAuthenticated 
        ? const DashboardScreen() 
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch ThemeProvider to ensure colors update correctly
    context.watch<ThemeProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, __) => Scaffold(
          backgroundColor: AppTheme.background,
          body: Stack(
            children: [
              // Ambient orbs for dark mode consistency
              if (AppTheme.isDark) ...[
                Positioned(
                  top: -100,
                  left: -60,
                  child: _Orb(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    size: 320,
                  ),
                ),
                Positioned(
                  bottom: -80,
                  right: -60,
                  child: _Orb(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    size: 240,
                  ),
                ),
              ],
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo Section ──────────────────────
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(alignment: Alignment.center, children: [
                        Opacity(
                          opacity: _pulse2Opacity.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _pulse2Scale.value,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                  width: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: _pulseOpacity.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _pulseScale.value,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.isDark 
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : AppTheme.primary.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: AppTheme.isDark ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.15),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  )
                                ] : [],
                              ),
                              child: const StockPulseLogo(size: 44),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 28),

                    // ── App Name & Subtitle ───────────────────────
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: 'Stock',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.onSurface,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Pulse',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.primary,
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 8),
                            FadeTransition(
                              opacity: _taglineFade,
                              child: Text(
                                'a paper trading platform',
                                style: GoogleFonts.inter(
                                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  fontSize: 16,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 64),

                    // ── Loading bar ───────────────────────────────
                    FadeTransition(
                      opacity: _taglineFade,
                      child: SizedBox(
                        width: 180,
                        child: Column(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _barProgress.value,
                              minHeight: 2.5,
                              backgroundColor: AppTheme.isDark 
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppTheme.primary.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _barProgress.value < 0.4 
                                ? 'Initializing Terminal...' 
                                : _barProgress.value < 0.8 
                                    ? 'Fetching Real-time Markets...' 
                                    : 'Almost ready...',
                            style: GoogleFonts.inter(
                              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ]),
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
