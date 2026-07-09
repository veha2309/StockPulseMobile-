import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final bool animate;
  final bool glow;
  final VoidCallback? onTap;
  final Color? accentColor; // NEW: optional colored border + glow

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.blur = 16.0,
    this.opacity = 1.0,
    this.borderRadius,
    this.animate = false,
    this.glow = false,
    this.onTap,
    this.accentColor,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(20);
    final accent = widget.accentColor;
    final effectiveBorderColor = accent != null
        ? accent.withValues(alpha: 0.35)
        : widget.glow
            ? AppTheme.primary.withValues(alpha: 0.4)
            : AppTheme.borderColor;

    Widget card = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: br,
        border: Border.all(
          color: effectiveBorderColor,
          width: accent != null ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (widget.glow || accent != null)
            BoxShadow(
              color: (accent ?? AppTheme.primary).withValues(
                alpha: AppTheme.isDark ? 0.12 : 0.04,
              ),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: card,
        ),
      );
    }

    return card;
  }
}

// ── Animated stat card with slide-up entrance ──
class AnimatedStatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final Color? iconColor; // NEW: distinct icon color per stat
  final int delay; // ms

  const AnimatedStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.iconColor,
    this.delay = 0,
  });

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconC = widget.iconColor ?? AppTheme.primary;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: GlassCard(
          accentColor: iconC,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconC.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: iconC, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                widget.value,
                style: TextStyle(
                  color: widget.valueColor ?? AppTheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
