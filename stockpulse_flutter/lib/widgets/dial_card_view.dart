import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/market_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatter.dart';

/// A card carousel synchronized with the Arc Dial.
///
/// Behaviour spec:
///  • Browsing mode  – dial is being dragged:
///    - Cards scale to ~88%, revealing neighbours on left/right
///    - Cards slide laterally in perfect sync with the dial index
///    - The outgoing card fades+scales out; the incoming card scales up from 90%
///  • Focus mode – user lifts thumb or taps the card:
///    - Active card expands to 100%, neighbours slide fully off-screen
///  • Elastic snap – SpringSimulation bounces the card into centre on settle
///  • High-speed flick: cards fade slightly during fast swipe (motion-blur feel)
class DialCardView extends StatefulWidget {
  final List<String> symbols;
  final int selectedIndex;
  final bool isDialActive;
  final VoidCallback? onCardTapped;

  const DialCardView({
    super.key,
    required this.symbols,
    required this.selectedIndex,
    required this.isDialActive,
    this.onCardTapped,
  });

  @override
  State<DialCardView> createState() => _DialCardViewState();
}

class _DialCardViewState extends State<DialCardView>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _snapController;
  late final AnimationController _browseController; // 0=focus, 1=browse
  double _currentPage = 0;
  double _velocity = 0;
  double _lastPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.selectedIndex.toDouble();
    _lastPage = _currentPage;
    _pageController = PageController(
      initialPage: widget.selectedIndex,
      viewportFraction: 1.0,
    )..addListener(_onPageScroll);

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _browseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  void _onPageScroll() {
    final page = _pageController.page ?? 0;
    _velocity = (page - _lastPage).abs();
    _lastPage = page;
    setState(() => _currentPage = page);
  }

  @override
  void didUpdateWidget(DialCardView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync page when dial changes index
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _pageController.animateToPage(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }

    // Toggle browse/focus mode
    if (oldWidget.isDialActive != widget.isDialActive) {
      if (widget.isDialActive) {
        _browseController.animateTo(1.0,
            curve: Curves.easeOutCubic,
            duration: const Duration(milliseconds: 250));
      } else {
        _browseController.animateTo(0.0,
            curve: Curves.elasticOut,
            duration: const Duration(milliseconds: 600));
        // Elastic snap bounce
        _snapController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _snapController.dispose();
    _browseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.symbols.isEmpty) return const SizedBox.shrink();
    final screenW = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: Listenable.merge([_browseController, _snapController]),
      builder: (context, _) {
        final browseT = _browseController.value; // 0=focus 1=browse

        // Card scale: 100% in focus, 88% while browsing
        final cardScale = 1.0 - (browseT * 0.12);

        // Elastic snap horizontal nudge (settles to 0)
        final snapNudge = _snapController.isAnimating
            ? math.sin(_snapController.value * math.pi * 3) *
                6 *
                (1 - _snapController.value)
            : 0.0;

        return SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Build up to 3 visible cards: prev, active, next
              for (int offset = -1; offset <= 1; offset++)
                _buildCard(
                  context,
                  screenW,
                  browseT,
                  cardScale,
                  snapNudge,
                  offset,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    double screenW,
    double browseT,
    double cardScale,
    double snapNudge,
    int offset,
  ) {
    final market = context.watch<MarketProvider>();
    final idx = widget.selectedIndex + offset;
    if (idx < 0 || idx >= (widget.symbols.isEmpty ? 0 : widget.symbols.length)) {
      return const SizedBox.shrink();
    }

    final symbol = widget.symbols[idx];
    final isActive = offset == 0;

    // How far is this card from the current scroll position
    final scrollOffset = _currentPage - (widget.selectedIndex + offset);

    // Lateral translation: each card is ~screenW * cardScale apart
    final cardWidth = screenW * cardScale;
    final baseX = offset * (cardWidth + 16); // 16px gap
    // During focus mode, side cards slide fully off screen
    final focusHide = (1.0 - browseT) * offset.sign * screenW * 0.5;
    final scrollX = scrollOffset * screenW;
    final totalX = baseX - scrollX - focusHide + (isActive ? snapNudge : 0);

    // Z-depth: active is in front
    final zOrder = isActive ? 10 : 1;

    // Opacity: neighbours fade at 60% while browsing, fully hidden in focus
    final opacity = isActive
        ? 1.0
        : (browseT * 0.55).clamp(0.0, 1.0);

    // Incoming/outgoing scale for Z-axis stacking effect
    final neighbourScale = isActive ? 1.0 : (0.92 + browseT * 0.04);

    // Velocity-based dimming on high-speed flick
    final bool fastFlick = _velocity > 0.04;
    final double cardOpacity = (isActive && fastFlick)
        ? (1.0 - (_velocity * 6).clamp(0.0, 0.35))
        : (isActive ? 1.0 : opacity);

    final bool isCurrentMarket = market.currentSymbol == symbol;
    final double price = isCurrentMarket ? market.underlyingPrice : 0;

    return Positioned(
      left: screenW / 2 - (cardWidth / 2) + totalX,
      child: Opacity(
        opacity: cardOpacity.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, isActive ? 0.0 : 12.0),
          child: Transform.scale(
            scale: isActive ? cardScale : cardScale * neighbourScale,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: isActive ? widget.onCardTapped : null,
              child: Material(
                color: Colors.transparent,
                elevation: isActive ? 8 : 0,
                shadowColor: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: cardWidth - 32,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primary.withValues(alpha: 0.4)
                          : AppTheme.borderColor,
                      width: isActive ? 1.5 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(
                                  alpha: AppTheme.isDark ? 0.12 : 0.06),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: AppTheme.isDark ? 0.18 : 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _StockCardContent(
                      symbol: symbol,
                      price: price,
                      isActive: isActive,
                      isLoading: market.isLoading && isCurrentMarket,
                      zOrder: zOrder,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _StockCardContent extends StatelessWidget {
  final String symbol;
  final double price;
  final bool isActive;
  final bool isLoading;
  final int zOrder;

  const _StockCardContent({
    required this.symbol,
    required this.price,
    required this.isActive,
    required this.isLoading,
    required this.zOrder,
  });

  @override
  Widget build(BuildContext context) {
    final display = symbol.split(':').last;
    final exchange = symbol.contains(':') ? symbol.split(':').first : 'NSE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Header row
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  display.substring(0, math.min(2, display.length)),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    display,
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    exchange,
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
          ],
        ),

        // Price area
        if (isLoading && isActive)
          _shimmerRow()
        else if (price > 0 && isActive)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatINR(price),
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.show_chart_rounded,
                      color: AppTheme.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to trade & analyse',
                    style: TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActive ? 'Spin dial to select' : display,
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: isActive ? 13 : 18,
                  fontWeight:
                      isActive ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              if (!isActive)
                Text(
                  exchange,
                  style: TextStyle(
                      color: AppTheme.onSurfaceVariant, fontSize: 11),
                ),
            ],
          ),
      ],
    );
  }

  Widget _shimmerRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedOpacity(
          opacity: 0.5,
          duration: const Duration(milliseconds: 600),
          child: Container(
            width: 140,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.borderColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}
