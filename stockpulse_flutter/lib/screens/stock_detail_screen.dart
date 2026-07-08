import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_data.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/candle_chart.dart';
import '../widgets/trade_modal.dart';
import '../widgets/arc_portfolio_dial.dart';
import 'options_chain_screen.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with TickerProviderStateMixin {
  late PageController _mainPageController;
  double _currentPage = 0;
  bool _isDialActive = false;
  bool _showDial = false;
  bool _isMainPageUserScrolling = false;
  late List<String> _dialItems;

  late AnimationController _activeModeController;
  late Animation<double> _cardScale;

  final Map<String, TextEditingController> _slControllers = {};
  final Map<String, TextEditingController> _tpControllers = {};
  final Map<String, bool> _showHoldingsTargets = {};
  bool _isMonthly = true;

  List<ChartIndicator> _activeIndicators = [];

  static const _trendingStocks = [
    "NSE:RELIANCE",
    "NSE:TCS",
    "NSE:HDFCBANK",
    "NSE:INFY",
    "NSE:ICICIBANK",
    "NSE:HINDUNILVR",
    "NSE:SBIN",
    "NSE:BHARTIARTL",
    "NSE:ITC",
    "NSE:KOTAKBANK",
  ];

  List<String> _buildDialItems(MarketProvider market) {
    return <String>{
      ...market.watchlist,
      ..._trendingStocks,
      market.currentSymbol,
    }.toList();
  }

  @override
  void initState() {
    super.initState();
    final market = context.read<MarketProvider>();

    _dialItems = _buildDialItems(market);
    final initialIndex = _dialItems.indexOf(market.currentSymbol);
    final startPage = initialIndex >= 0 ? initialIndex : 0;

    _mainPageController = PageController(initialPage: startPage);
    _currentPage = startPage.toDouble();
    _mainPageController.addListener(_onPageScroll);

    _activeModeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardScale = Tween<double>(begin: 1.0, end: 0.58).animate(
      CurvedAnimation(
        parent: _activeModeController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _activeIndicators = [
      const ChartIndicator(
        type: IndicatorType.sma,
        period: 20,
        color: Colors.cyanAccent,
      ),
    ];
  }

  void _setShowDial(bool value) {
    if (_showDial == value) return;
    setState(() {
      _showDial = value;
      if (_showDial || _isDialActive) {
        _activeModeController.forward();
      } else {
        _activeModeController.reverse();
      }
    });
    HapticFeedback.lightImpact();
  }

  void _onPageScroll() {
    if (!mounted) return;
    setState(() => _currentPage = _mainPageController.page ?? 0);
  }

  void _toggleIndicator(IndicatorType type) {
    setState(() {
      final exists = _activeIndicators.any((i) => i.type == type);
      if (exists) {
        _activeIndicators.removeWhere((i) => i.type == type);
      } else {
        if (type == IndicatorType.sma) {
          _activeIndicators.add(
            const ChartIndicator(
              type: IndicatorType.sma,
              period: 20,
              color: Colors.cyanAccent,
            ),
          );
        } else if (type == IndicatorType.ema) {
          _activeIndicators.add(
            const ChartIndicator(
              type: IndicatorType.ema,
              period: 20,
              color: Colors.amberAccent,
            ),
          );
        } else if (type == IndicatorType.bollingerBands) {
          _activeIndicators.add(
            const ChartIndicator(
              type: IndicatorType.bollingerBands,
              period: 20,
              color: Colors.purpleAccent,
              multiplier: 2.0,
            ),
          );
        }
      }
    });
  }

  void _showTradeModal(
    BuildContext context,
    String symbol,
    double price,
    bool isBuy,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TradeModal(symbol: symbol, price: price, isBuy: isBuy),
    );
  }

  // --- NEW: Educational Modal Bottom Sheet ---
  void _showEducationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            physics: const BouncingScrollPhysics(),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                "Trading Academy",
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Paper trading lets you practice buying and selling in real market conditions without risking actual money. Master these indicators to improve your strategies.",
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              _buildEduCard(
                "SMA (Simple Moving Average)",
                "Calculates the average closing price over a specific period (e.g., 20 days). It smooths out daily price fluctuations so you can easily spot the overall trend.",
                Icons.stacked_line_chart_rounded,
                Colors.cyanAccent,
              ),
              _buildEduCard(
                "EMA (Exponential Moving Avg)",
                "Similar to SMA, but places more weight on recent prices. It reacts much faster to sudden price changes, making it ideal for short-term trading signals.",
                Icons.auto_graph_rounded,
                Colors.amberAccent,
              ),
              _buildEduCard(
                "Bollinger Bands",
                "Displays a middle SMA line surrounded by an upper and lower volatility band. When prices hit the upper band, the stock might be 'overbought'. When hitting the lower band, it may be 'oversold'.",
                Icons.blur_linear_rounded,
                Colors.purpleAccent,
              ),
              _buildEduCard(
                "Stop Loss & Take Profit",
                "A Stop Loss (SL) automatically sells your shares if the price drops to limit your losses. Take Profit (TP) automatically sells when you hit your target profit goal.",
                Icons.track_changes_rounded,
                AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEduCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // -------------------------------------------

  @override
  void dispose() {
    _mainPageController.removeListener(_onPageScroll);
    _mainPageController.dispose();
    _activeModeController.dispose();
    for (var c in _slControllers.values) {
      c.dispose();
    }
    for (var c in _tpControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();



    final currentIndex = _currentPage.round().clamp(0, _dialItems.length - 1);
    final currentSymbol = _dialItems[currentIndex];
    final isFavorite = market.watchlist.contains(currentSymbol);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppTheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            currentSymbol.split(':').last,
            key: ValueKey(currentSymbol),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                key: ValueKey(isFavorite),
                color: isFavorite ? Colors.amber : AppTheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            onPressed: () => market.toggleFavorite(currentSymbol),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OptionsChainScreen()),
            ),
            icon: const Icon(
              Icons.grid_view_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
            label: const Text(
              "OPTIONS",
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is UserScrollNotification) {
                setState(() {
                  _isMainPageUserScrolling = notification.direction != ScrollDirection.idle;
                });
              }
              return false;
            },
            child: PageView.builder(
              controller: _mainPageController,
              itemCount: _dialItems.length,
              onPageChanged: (index) => market.fetchMarketData(_dialItems[index]),
              itemBuilder: (context, index) => _buildStockCard(_dialItems[index]),
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_showDial,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showDial ? 1.0 : 0.0,
                child: GestureDetector(
                  onTap: () => _setShowDial(false),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            bottom: _showDial ? 0 : -220,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 4, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background.withValues(alpha: 0.0),
                    AppTheme.background.withValues(alpha: 0.95),
                    AppTheme.background,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _setShowDial(false),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      child: Container(
                        width: 44,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  ArcPortfolioDial(
                    items: _dialItems,
                    initialIndex: _mainPageController.initialPage,
                    externalPage: _isMainPageUserScrolling ? currentIndex.toDouble() : null,
                    onScrollStateChanged: (active) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _isDialActive = active);
                          if (_showDial || active) {
                            _activeModeController.forward();
                          } else {
                            _activeModeController.reverse();
                          }
                        }
                      });
                    },
                    onSelectedItemChanged: (index) {
                      if (index != _mainPageController.page?.round()) {
                        _mainPageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutBack,
                        );
                      }
                    },
                    onPageScroll: (page) {
                      if (_mainPageController.hasClients) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        _mainPageController.jumpTo(page * screenWidth);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedSlide(
                offset: _showDial ? const Offset(0, 2) : Offset.zero,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: _showDial ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: FloatingActionButton.extended(
                    onPressed: _showDial ? null : () => _setShowDial(true),
                    icon: const Icon(Icons.blur_circular_rounded, color: Colors.black),
                    label: const Text(
                      "QUICK DIAL",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    backgroundColor: AppTheme.primary,
                    elevation: 6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(String symbol, {bool isActiveOverride = false}) {
    final market = context.watch<MarketProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final auth = context.watch<AuthProvider>();

    final isActive = isActiveOverride || market.currentSymbol == symbol;

    final List<PortfolioItem> holdings = (auth.user?.portfolio ?? [])
        .where((p) => p.symbol == symbol)
        .toList();

    return AnimatedBuilder(
      animation: _activeModeController,
      builder: (context, child) {
        // Apply both scale and a 3D tilt transform
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(_activeModeController.value * -0.15), // tilt
          alignment: FractionalOffset.center,
          child: Transform.scale(scale: _cardScale.value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Show shimmer effect while loading
            if (market.isLoading && isActive)
              Expanded(child: _buildShimmerContent())
            else
              Expanded(
                child: SingleChildScrollView(
                  physics: (_isDialActive || _showDial)
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildPriceHeader(isActive ? market.underlyingPrice : 0),
                      const SizedBox(height: 24),
                      _buildChartSection(isActive ? market : null),
                      const SizedBox(height: 24),
                      _buildQuickActions(
                          context, symbol, market.underlyingPrice),
                      if (holdings.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Text(
                          "Active Positions",
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...holdings.map(
                          (h) => _buildHoldingTargetCard(context, portfolio, h),
                        ),
                      ],
                      const SizedBox(height: 160),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerContent() {
    final shimmerColor = AppTheme.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04);
    return Shimmer.fromColors(
      baseColor: shimmerColor,
      highlightColor: shimmerColor.withOpacity(0.5),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Price Header shimmer
            Container(width: 220, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 24),
            // Chart shimmer
            Container(width: double.infinity, height: 350, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 24),
            // Quick Actions shimmer
            Row(
              children: [
                Expanded(child: Container(height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
                const SizedBox(width: 16),
                Expanded(child: Container(height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceHeader(double price) {
    final market = context.read<MarketProvider>();
    final dailyChange = market.dailyChangePercent;
    final isPos = dailyChange >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          price > 0 ? "₹${price.toStringAsFixed(2)}" : "---",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
            letterSpacing: -1,
          ),
        ),
        Row(
          children: [
            Icon(
              isPos ? Icons.trending_up : Icons.trending_down,
              color: isPos ? AppTheme.primary : AppTheme.secondary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              "${isPos ? '+' : ''}${dailyChange.toStringAsFixed(2)}% Today",
              style: TextStyle(
                color: isPos ? AppTheme.primary : AppTheme.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openFullScreenChart(BuildContext context, MarketProvider market) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'chart',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      pageBuilder: (ctx, _, _a) => _FullScreenChart(
        market: market,
        isMonthly: _isMonthly,
        activeIndicators: _activeIndicators,
        onTimeframeChanged: (val) => setState(() => _isMonthly = val),
        onIndicatorToggled: _toggleIndicator,
      ),
    );
  }

  Widget _buildChartSection(MarketProvider? market) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- NEW: Learn Badge next to Performance header ---
            Row(
              children: [
                Text(
                  "Performance",
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _showEducationModal(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.school_rounded,
                          color: AppTheme.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "LEARN",
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildTimeframeToggle(),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildIndicatorChip(
                "SMA 20",
                IndicatorType.sma,
                Colors.cyanAccent,
              ),
              const SizedBox(width: 8),
              _buildIndicatorChip(
                "EMA 20",
                IndicatorType.ema,
                Colors.amberAccent,
              ),
              const SizedBox(width: 8),
              _buildIndicatorChip(
                "Bollinger",
                IndicatorType.bollingerBands,
                Colors.purpleAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: market != null
              ? () => _openFullScreenChart(context, market)
              : null,
          child: Stack(
            children: [
              GlassCard(
                child: market != null
                    ? CandleChart(
                        data: _isMonthly
                            ? market.chartData
                            : market.intradayChartData,
                        height: 280,
                        isIntraday: !_isMonthly,
                        activeIndicators: _activeIndicators,
                      )
                    : SizedBox(
                        height: 280,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
              ),
              if (market != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorChip(String label, IndicatorType type, Color color) {
    final isActive = _activeIndicators.any((i) => i.type == type);
    return GestureDetector(
      onTap: () => _toggleIndicator(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color: isActive
                ? color
                : AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? AppTheme.onSurface
                    : AppTheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem(
            "1M",
            _isMonthly,
            () => setState(() => _isMonthly = true),
          ),
          _buildToggleItem(
            "1D",
            !_isMonthly,
            () => setState(() => _isMonthly = false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : AppTheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, String symbol, double price) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () => _showTradeModal(context, symbol, price, true),
            child: const Text(
              "BUY STOCK",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () => _showTradeModal(context, symbol, price, false),
            child: const Text(
              "SELL STOCK",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoldingTargetCard(
    BuildContext context,
    PortfolioProvider portfolio,
    PortfolioItem holding,
  ) {
    if (!_slControllers.containsKey(holding.id)) {
      _slControllers[holding.id] = TextEditingController(
        text: holding.sl?.toString() ?? "",
      );
      _tpControllers[holding.id] = TextEditingController(
        text: holding.tp?.toString() ?? "",
      );
      _showHoldingsTargets[holding.id] =
          holding.sl != null || holding.tp != null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${holding.amount.toInt()} Units @ ₹${holding.avgBuyPrice.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Bought ${DateTime.parse(holding.timestamp).day}/${DateTime.parse(holding.timestamp).month}",
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _showHoldingsTargets[holding.id] ?? false,
                  onChanged: (val) =>
                      setState(() => _showHoldingsTargets[holding.id] = val),
                  activeThumbColor: AppTheme.primary,
                ),
              ],
            ),
            if (_showHoldingsTargets[holding.id] == true) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _tpControllers[holding.id]!,
                      "Take Profit",
                      Icons.trending_up,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      _slControllers[holding.id]!,
                      "Stop Loss",
                      Icons.trending_down,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: portfolio.isLoading
                      ? null
                      : () async {
                          final sl = double.tryParse(
                            _slControllers[holding.id]!.text,
                          );
                          final tp = double.tryParse(
                            _tpControllers[holding.id]!.text,
                          );
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await portfolio.updateTargets(holding.id, sl, tp);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text("Targets Updated for Holding!"),
                                backgroundColor: AppTheme.primary,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppTheme.secondary,
                              ),
                            );
                          }
                        },
                  child: portfolio.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "SET TARGETS",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    double fontSize = 14,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: AppTheme.onSurface, fontSize: fontSize),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: fontSize * 0.8,
        ),
        prefixIcon: Icon(icon, color: AppTheme.primary, size: fontSize + 4),
        filled: true,
        fillColor: AppTheme.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _FullScreenChart extends StatefulWidget {
  final MarketProvider market;
  final bool isMonthly;
  final List<ChartIndicator> activeIndicators;
  final ValueChanged<bool> onTimeframeChanged;
  final ValueChanged<IndicatorType> onIndicatorToggled;

  const _FullScreenChart({
    required this.market,
    required this.isMonthly,
    required this.activeIndicators,
    required this.onTimeframeChanged,
    required this.onIndicatorToggled,
  });

  @override
  State<_FullScreenChart> createState() => _FullScreenChartState();
}

class _FullScreenChartState extends State<_FullScreenChart> {
  late bool _isMonthly;
  late List<ChartIndicator> _indicators;

  @override
  void initState() {
    super.initState();
    _isMonthly = widget.isMonthly;
    _indicators = List.from(widget.activeIndicators);
  }

  void _toggle(IndicatorType type) {
    setState(() {
      final exists = _indicators.any((i) => i.type == type);
      if (exists) {
        _indicators.removeWhere((i) => i.type == type);
      } else {
        if (type == IndicatorType.sma) {
          _indicators.add(
            const ChartIndicator(
              type: IndicatorType.sma,
              period: 20,
              color: Colors.cyanAccent,
            ),
          );
        } else if (type == IndicatorType.ema) {
          _indicators.add(
            const ChartIndicator(
              type: IndicatorType.ema,
              period: 20,
              color: Colors.amberAccent,
            ),
          );
        } else if (type == IndicatorType.bollingerBands) {
          _indicators.add(
            const ChartIndicator(
              type: IndicatorType.bollingerBands,
              period: 20,
              color: Colors.purpleAccent,
              multiplier: 2.0,
            ),
          );
        }
      }
    });
    widget.onIndicatorToggled(type);
  }

  Widget _chip(String label, IndicatorType type, Color color) {
    final active = _indicators.any((i) => i.type == type);
    return GestureDetector(
      onTap: () => _toggle(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color: active
                ? color
                : AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _isMonthly
        ? widget.market.chartData
        : widget.market.intradayChartData;
    // final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.market.currentSymbol.split(':').last,
          style: TextStyle(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _timeBtn("1M", _isMonthly, () {
                  setState(() => _isMonthly = true);
                  widget.onTimeframeChanged(true);
                }),
                _timeBtn("1D", !_isMonthly, () {
                  setState(() => _isMonthly = false);
                  widget.onTimeframeChanged(false);
                }),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _chip("SMA 20", IndicatorType.sma, Colors.cyanAccent),
                  const SizedBox(width: 8),
                  _chip("EMA 20", IndicatorType.ema, Colors.amberAccent),
                  const SizedBox(width: 8),
                  _chip(
                    "Bollinger",
                    IndicatorType.bollingerBands,
                    Colors.purpleAccent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GlassCard(
                child: LayoutBuilder(
                  builder: (context, constraints) => CandleChart(
                    data: chartData,
                    height: constraints.maxHeight,
                    isIntraday: !_isMonthly,
                    activeIndicators: _indicators,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _timeBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : AppTheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
