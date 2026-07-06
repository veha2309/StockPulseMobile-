import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ArcPortfolioDial extends StatefulWidget {
  final List<String> items;
  final int initialIndex;
  final double? externalPage;
  final Function(int) onSelectedItemChanged;
  final Function(bool)? onScrollStateChanged;

  const ArcPortfolioDial({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.externalPage,
    required this.onSelectedItemChanged,
    this.onScrollStateChanged,
  });

  @override
  State<ArcPortfolioDial> createState() => _ArcPortfolioDialState();
}

class _ArcPortfolioDialState extends State<ArcPortfolioDial>
    with SingleTickerProviderStateMixin {
  late PageController _controller;
  late AnimationController _arcController;
  double _currentPage = 0;
  int _lastSnapped = -1;
  bool _userScrolling = false;
  bool _syncing = false;

  // Wide enough to show ~5 items at once
  static const double _viewportFraction = 0.22;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex.toDouble();
    _lastSnapped = widget.initialIndex;

    _controller = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: _viewportFraction,
    )..addListener(_onScroll);

    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(ArcPortfolioDial old) {
    super.didUpdateWidget(old);
    if (!_userScrolling &&
        widget.externalPage != null &&
        (widget.externalPage! - _currentPage).abs() > 0.01) {
      _syncToPage(widget.externalPage!);
    }
  }

  void _syncToPage(double page) {
    if (!_controller.hasClients || _syncing) return;
    _syncing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) {
        _syncing = false;
        return;
      }
      final target = page.round().clamp(0, widget.items.length - 1);
      _controller
          .animateToPage(
            target,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          )
          .then((_) => _syncing = false);
    });
  }

  void _onScroll() {
    if (!mounted) return;
    final page = _controller.page ?? 0;
    setState(() => _currentPage = page);

    final snapped = page.round();
    // Wider threshold (0.2) makes haptics feel "stickier" during free scroll
    if (snapped != _lastSnapped && (snapped - page).abs() < 0.2) {
      HapticFeedback.selectionClick();
      _lastSnapped = snapped;
      if (_userScrolling) widget.onSelectedItemChanged(snapped);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    _arcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollStartNotification && !_syncing) {
          _userScrolling = true;
          _arcController.forward();
          widget.onScrollStateChanged?.call(true);
          HapticFeedback.mediumImpact();
        } else if (n is ScrollEndNotification && !_syncing) {
          _userScrolling = false;
          _arcController.reverse();
          widget.onScrollStateChanged?.call(false);
          HapticFeedback.lightImpact();

          // Manual smooth snap to the nearest item at the end of a free scroll
          final page = _controller.page ?? 0;
          final snapped = page.round();
          if ((page - snapped).abs() > 0.01) {
            _syncing = true;
            _controller.animateToPage(
              snapped,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            ).then((_) => _syncing = false);
            widget.onSelectedItemChanged(snapped);
          }
        }
        return false;
      },
      child: AnimatedBuilder(
        animation: _arcController,
        builder: (context, _) => SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            // Disable default aggressive snapping to allow free scrolling
            pageSnapping: false,
            // Elastic bouncing physics for the infinite-sphere feel
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemBuilder: (context, index) {
              final rel = index - _currentPage;
              // final abs = rel.abs().clamp(0.0, math.pi / 2);
              final isSelected = rel.abs() < 0.5;

              // True sphere arc: items follow a sin curve so they
              // rise smoothly from center to edges like a globe surface.
              final arcAngle = (rel.abs() / 2.2).clamp(0.0, math.pi / 2);
              final yOffset = math.sin(arcAngle) * 110.0 * _arcController.value;

              // Scale: center is largest, drops off with cos curve
              final scale = math.max(0.52, math.cos(arcAngle * 0.9) * 1.28);

              return GestureDetector(
                onTap: () {
                  if (!isSelected) {
                    _userScrolling = true;
                    _controller
                        .animateToPage(
                          index,
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.easeOutCubic,
                        )
                        .then((_) => _userScrolling = false);
                    widget.onSelectedItemChanged(index);
                  }
                },
                child: Transform.translate(
                  offset: Offset(0, yOffset),
                  child: Transform.scale(
                    scale: scale,
                    child: _DialItem(
                      symbol: widget.items[index],
                      isSelected: isSelected,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DialItem extends StatelessWidget {
  final String symbol;
  final bool isSelected;
  const _DialItem({required this.symbol, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final display = symbol.split(':').last;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 60, // Fixed width for each item
          height: isSelected ? 58 : 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [AppTheme.primary, const Color(0xFF05B68C)]
                  : [AppTheme.card, AppTheme.surfaceContainer],
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              display.substring(0, math.min(2, display.length)),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSelected ? 15 : 11,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
            fontSize: isSelected ? 9.0 : 7.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 0.2,
          ),
          child: Text(display, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
