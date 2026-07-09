import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stockpulse_flutter/screens/stock_list_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stock_pulse_logo.dart';
import 'profile_screen.dart';
import 'trade_history_screen.dart';
import 'portfolio_screen.dart';
import 'stock_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  DateTime? _lastPressedAt;

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_selectedIndex != 0) {
          // Switch to home page if not on home page
          setState(() => _selectedIndex = 0);
          return;
        }

        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Press back again to exit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppTheme.violet,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }

        // Exit app programmatically
        await SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SizedBox.expand(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardHome(onNavigate: _onNavTap),
              const PortfolioScreen(),
              const StockListScreen(),
              const TradeHistoryScreen(),
              const ProfileScreen(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        boxShadow: [
          BoxShadow(
            color: AppTheme.isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.grid_view_rounded, 'Home', AppTheme.primary),
            _navItem(1, Icons.pie_chart_rounded, 'Portfolio', AppTheme.blue),
            _navItem(
              2,
              Icons.candlestick_chart_rounded,
              'Stocks',
              AppTheme.violet,
            ),
            _navItem(3, Icons.history_rounded, 'History', AppTheme.amber),
            _navItem(4, Icons.person_rounded, 'Profile', AppTheme.cyan),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, Color accentColor) {
    final bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withValues(alpha: 0.13)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isActive
              ? Border.all(color: accentColor.withValues(alpha: 0.22), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? accentColor : AppTheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? accentColor : AppTheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class DashboardHome extends StatefulWidget {
  final Function(int)? onNavigate;
  const DashboardHome({super.key, this.onNavigate});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome>
    with SingleTickerProviderStateMixin {
  late TabController _moversTab;
  bool _showGainers = true;

  // ── Static market data (simulated live) ──────────────────────────────────
  static const List<Map<String, dynamic>> _indices = [
    {
      'name': 'NIFTY 50',
      'value': '24,850',
      'change': '+1.2%',
      'positive': true,
      'color': 0xFF00D09C,
    },
    {
      'name': 'SENSEX',
      'value': '81,420',
      'change': '+0.8%',
      'positive': true,
      'color': 0xFF3B82F6,
    },
    {
      'name': 'BANK NIFTY',
      'value': '52,180',
      'change': '-0.3%',
      'positive': false,
      'color': 0xFFFF4D6D,
    },
    {
      'name': 'NIFTY IT',
      'value': '38,650',
      'change': '+2.1%',
      'positive': true,
      'color': 0xFF7C3AED,
    },
    {
      'name': 'MIDCAP 150',
      'value': '17,320',
      'change': '+0.5%',
      'positive': true,
      'color': 0xFFF59E0B,
    },
  ];

  static const List<Map<String, dynamic>> _sectors = [
    {
      'name': 'Banking',
      'icon': Icons.account_balance_rounded,
      'count': '12 stocks',
      'top': 'HDFCBANK',
      'change': '+2.8%',
      'color': 0xFF7C3AED,
    },
    {
      'name': 'Info Tech',
      'icon': Icons.computer_rounded,
      'count': '10 stocks',
      'top': 'INFY',
      'change': '+3.1%',
      'color': 0xFF3B82F6,
    },
    {
      'name': 'Pharma',
      'icon': Icons.local_hospital_rounded,
      'count': '8 stocks',
      'top': 'SUNPHARMA',
      'change': '+1.4%',
      'color': 0xFF00D09C,
    },
    {
      'name': 'Auto',
      'icon': Icons.directions_car_rounded,
      'count': '9 stocks',
      'top': 'TATAMOTORS',
      'change': '+4.2%',
      'color': 0xFFF59E0B,
    },
    {
      'name': 'FMCG',
      'icon': Icons.shopping_basket_rounded,
      'count': '7 stocks',
      'top': 'HINDUNILVR',
      'change': '+0.9%',
      'color': 0xFFF97316,
    },
    {
      'name': 'Energy',
      'icon': Icons.bolt_rounded,
      'count': '6 stocks',
      'top': 'RELIANCE',
      'change': '+1.7%',
      'color': 0xFFEAB308,
    },
    {
      'name': 'Infra',
      'icon': Icons.business_rounded,
      'count': '5 stocks',
      'top': 'L&T',
      'change': '+2.3%',
      'color': 0xFF4F46E5,
    },
    {
      'name': 'Telecom',
      'icon': Icons.signal_cellular_alt_rounded,
      'count': '4 stocks',
      'top': 'BHARTIARTL',
      'change': '+1.5%',
      'color': 0xFF06B6D4,
    },
  ];

  static const List<Map<String, dynamic>> _learningCards = [
    {
      'title': 'What is Options Trading?',
      'desc':
          'Options give you the right (not obligation) to buy/sell a stock at a fixed price before expiry.',
      'tag': 'DERIVATIVES',
      'icon': Icons.auto_graph_rounded,
      'color': 0xFF7C3AED,
    },
    {
      'title': 'Understanding P/E Ratio',
      'desc':
          'Price-to-Earnings ratio tells you how much investors pay for every ₹1 of company earnings.',
      'tag': 'FUNDAMENTALS',
      'icon': Icons.bar_chart_rounded,
      'color': 0xFF3B82F6,
    },
    {
      'title': 'F&O vs Equity Trading',
      'desc':
          'Equity means owning shares. F&O are contracts derived from underlying stocks — higher risk, higher leverage.',
      'tag': 'F&O',
      'icon': Icons.timeline_rounded,
      'color': 0xFF00D09C,
    },
    {
      'title': 'Reading Candlestick Charts',
      'desc':
          'Each candle shows open, high, low & close prices. Green = bullish day, Red = bearish day.',
      'tag': 'TECHNICAL',
      'icon': Icons.candlestick_chart_rounded,
      'color': 0xFFF59E0B,
    },
  ];

  static const List<Map<String, dynamic>> _gainers = [
    {
      'symbol': 'TATAMOTORS',
      'name': 'Tata Motors',
      'price': '₹924.50',
      'change': '+4.2%',
      'color': 0xFF00D09C,
    },
    {
      'symbol': 'INFY',
      'name': 'Infosys Ltd',
      'price': '₹1,842.30',
      'change': '+3.1%',
      'color': 0xFF00D09C,
    },
    {
      'symbol': 'HDFCBANK',
      'name': 'HDFC Bank',
      'price': '₹1,612.75',
      'change': '+2.8%',
      'color': 0xFF00D09C,
    },
    {
      'symbol': 'BHARTIARTL',
      'name': 'Bharti Airtel',
      'price': '₹1,290.00',
      'change': '+2.3%',
      'color': 0xFF00D09C,
    },
  ];

  static const List<Map<String, dynamic>> _losers = [
    {
      'symbol': 'WIPRO',
      'name': 'Wipro Ltd',
      'price': '₹432.10',
      'change': '-2.1%',
      'color': 0xFFFF4D6D,
    },
    {
      'symbol': 'COALINDIA',
      'name': 'Coal India',
      'price': '₹461.85',
      'change': '-1.8%',
      'color': 0xFFFF4D6D,
    },
    {
      'symbol': 'ITC',
      'name': 'ITC Limited',
      'price': '₹451.20',
      'change': '-1.3%',
      'color': 0xFFFF4D6D,
    },
    {
      'symbol': 'AXISBANK',
      'name': 'Axis Bank',
      'price': '₹1,058.40',
      'change': '-0.9%',
      'color': 0xFFFF4D6D,
    },
  ];

  @override
  void initState() {
    super.initState();
    _moversTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _moversTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<MarketProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          // ── Ambient orbs ─────────────────────────────────────────────────
          if (AppTheme.isDark) ...[
            Positioned(
              top: -80,
              left: -60,
              child: _Orb(
                color: AppTheme.primary.withValues(alpha: 0.07),
                size: 300,
              ),
            ),
            Positioned(
              top: 300,
              right: -80,
              child: _Orb(
                color: AppTheme.violet.withValues(alpha: 0.06),
                size: 260,
              ),
            ),
            Positioned(
              bottom: 200,
              left: -40,
              child: _Orb(
                color: AppTheme.blue.withValues(alpha: 0.05),
                size: 200,
              ),
            ),
          ],
          // ── Main content ──────────────────────────────────────────────────
          SizedBox(
            height: constraints.maxHeight,
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<PortfolioProvider>().refresh();
                },
                color: AppTheme.primary,
                backgroundColor: AppTheme.card,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _buildHeader(context, user),
                      ),
                      const SizedBox(height: 24),

                      // ── Market Pulse ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _sectionTitle(
                          'Market Pulse',
                          Icons.show_chart_rounded,
                          AppTheme.primary,
                          trailing: _liveIndicator(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildIndicesRow(),
                      const SizedBox(height: 28),

                      // ── Explore by Category ───────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _sectionTitle(
                          'Explore by Sector',
                          Icons.grid_view_rounded,
                          AppTheme.violet,
                          trailing: GestureDetector(
                            onTap: () {
                              context.read<MarketProvider>().setSectorFilter(
                                "",
                              );
                              widget.onNavigate?.call(2);
                            },
                            child: Text(
                              'All Stocks →',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSectorGrid(),
                      const SizedBox(height: 28),

                      // ── Today's Learning ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _sectionTitle(
                          "Today's Learning",
                          Icons.school_rounded,
                          AppTheme.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLearningCards(),
                      const SizedBox(height: 28),

                      // ── Top Movers ────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _sectionTitle(
                          'Top Movers Today',
                          Icons.trending_up_rounded,
                          AppTheme.amber,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTopMovers(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header with Logo ──────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, dynamic user) {
    return Row(
      children: [
        // Logo area
        Row(
          children: [
            StockPulseLogo(size: 38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    'StockPulse',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  'Learn. Trade. Grow.',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        // Profile avatar
        GestureDetector(
          onTap: () => widget.onNavigate?.call(4),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.violetGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.violet.withValues(
                    alpha: AppTheme.isDark ? 0.35 : 0.15,
                  ),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Section title helper ──────────────────────────────────────────────────
  Widget _sectionTitle(
    String title,
    IconData icon,
    Color accent, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accent, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  // ── Live dot indicator ────────────────────────────────────────────────────
  Widget _liveIndicator() {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'LIVE',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // ── Market Indices Row ────────────────────────────────────────────────────
  Widget _buildIndicesRow() {
    final market = context.watch<MarketProvider>();

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: _indices.length,
        itemBuilder: (_, i) {
          final idx = _indices[i];
          final symbol = idx['name'] == 'NIFTY 50'
              ? 'NSE:NIFTY50'
              : idx['name'] == 'SENSEX'
              ? 'BSE:SENSEX'
              : idx['name'] == 'BANK NIFTY'
              ? 'NSE:NIFTY_BANK'
              : idx['name'] == 'NIFTY IT'
              ? 'NSE:NIFTY_IT'
              : 'NSE:NIFTY_MIDCAP_50';

          final livePrice = market.stockPrices[symbol];
          final liveChange = market.stockChanges[symbol];

          final displayPrice = livePrice != null && livePrice > 0
              ? livePrice.toStringAsFixed(1)
              : idx['value'] as String;
          final displayChange = liveChange != null
              ? "${liveChange >= 0 ? '+' : ''}${liveChange.toStringAsFixed(1)}%"
              : idx['change'] as String;
          final isPos = liveChange != null ? liveChange >= 0 : idx['positive'] as bool;
          final color = isPos ? Color(idx['color'] as int) : AppTheme.secondary;

          return GestureDetector(
            onTap: () {
              market.fetchMarketData(symbol);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockDetailScreen()),
              );
            },
            child: Container(
              width: 130,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(
                      alpha: AppTheme.isDark ? 0.08 : 0.04,
                    ),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: AppTheme.isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    idx['name'] as String,
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    displayPrice,
                    style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isPos
                            ? Icons.arrow_drop_up_rounded
                            : Icons.arrow_drop_down_rounded,
                        color: isPos ? AppTheme.primary : AppTheme.secondary,
                        size: 16,
                      ),
                      Text(
                        displayChange,
                        style: TextStyle(
                          color: isPos ? AppTheme.primary : AppTheme.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Sector Grid ───────────────────────────────────────────────────────────
  Widget _buildSectorGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemCount: _sectors.length,
      itemBuilder: (_, i) {
        final s = _sectors[i];
        final color = Color(s['color'] as int);
        return GestureDetector(
          onTap: () {
            context.read<MarketProvider>().setSectorFilter(s['name'] as String);
            widget.onNavigate?.call(2);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.22),
                width: 1,
              ),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: AppTheme.isDark ? 0.12 : 0.06),
                  AppTheme.card.withValues(alpha: 0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(s['icon'] as IconData, color: color, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s['name'] as String,
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s['count'] as String,
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Learning Cards ────────────────────────────────────────────────────────
  Widget _buildLearningCards() {
    final market = context.watch<MarketProvider>();
    final activeCards = market.learningCards.isNotEmpty ? market.learningCards : _learningCards;

    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: activeCards.length,
        itemBuilder: (_, i) {
          final card = activeCards[i];

          // Helper to resolve icon data dynamically (from string name or IconData)
          IconData resolveIcon(dynamic iconVal) {
            if (iconVal is IconData) return iconVal;
            if (iconVal == null) return Icons.auto_graph_rounded;
            final str = iconVal.toString();
            if (str == 'bar_chart') return Icons.bar_chart_rounded;
            if (str == 'timeline') return Icons.timeline_rounded;
            if (str == 'candlestick_chart') return Icons.candlestick_chart_rounded;
            if (str == 'school') return Icons.school_rounded;
            if (str == 'insights') return Icons.insights_rounded;
            return Icons.auto_graph_rounded;
          }

          // Helper to resolve colors dynamically (from hex string or int)
          Color resolveColor(dynamic colVal) {
            if (colVal is int) return Color(colVal);
            if (colVal == null) return AppTheme.primary;
            final str = colVal.toString();
            if (str.startsWith('#')) {
              try {
                return Color(int.parse(str.replaceFirst('#', '0xFF')));
              } catch (_) {
                return AppTheme.primary;
              }
            }
            return AppTheme.primary;
          }

          final color = resolveColor(card['colorHex'] ?? card['color']);
          final icon = resolveIcon(card['iconName'] ?? card['icon']);

          // Safe fields extraction
          final String title = card['title']?.toString() ?? 'Learning Card';
          final String desc = card['desc']?.toString() ?? 'Tap to read more about this financial concept.';
          final String tag = card['tag']?.toString() ?? 'LEARN';

          return GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(color: AppTheme.borderColor, width: 1),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.onSurfaceVariant.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tag,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        desc,
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(
                      alpha: AppTheme.isDark ? 0.08 : 0.04,
                    ),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: AppTheme.isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3.5,
                    height: 100,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                color: color,
                                size: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                desc,
                                style: TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
          );
        },
      ),
    );
  }

  // ── Top Movers ────────────────────────────────────────────────────────────
  Widget _buildTopMovers() {
    final market = context.watch<MarketProvider>();

    // 1. Get all active symbols that have quotes loaded (filtering out indices)
    final allSymbols = market.stockPrices.keys
        .where((sym) => sym.startsWith("NSE:") && !sym.contains("NIFTY") && !sym.contains("SENSEX"))
        .toList();

    // 2. Build dynamic gainers list
    final List<Map<String, dynamic>> dynamicGainers = [];
    if (allSymbols.isNotEmpty) {
      final sortedGainers = List<String>.from(allSymbols)
        ..sort((a, b) => (market.stockChanges[b] ?? 0.0).compareTo(market.stockChanges[a] ?? 0.0));
      for (var sym in sortedGainers.take(5)) {
        final price = market.stockPrices[sym] ?? 0.0;
        final change = market.stockChanges[sym] ?? 0.0;
        final name = sym.substring(4);
        dynamicGainers.add({
          'symbol': sym,
          'name': name,
          'price': '₹${price.toStringAsFixed(2)}',
          'change': '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
          'color': change >= 0 ? 0xFF00D09C : 0xFFFF4D6D,
          'isPos': change >= 0,
        });
      }
    }

    // 3. Build dynamic losers list
    final List<Map<String, dynamic>> dynamicLosers = [];
    if (allSymbols.isNotEmpty) {
      final sortedLosers = List<String>.from(allSymbols)
        ..sort((a, b) => (market.stockChanges[a] ?? 0.0).compareTo(market.stockChanges[b] ?? 0.0));
      for (var sym in sortedLosers.take(5)) {
        final price = market.stockPrices[sym] ?? 0.0;
        final change = market.stockChanges[sym] ?? 0.0;
        final name = sym.substring(4);
        dynamicLosers.add({
          'symbol': sym,
          'name': name,
          'price': '₹${price.toStringAsFixed(2)}',
          'change': '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
          'color': change >= 0 ? 0xFF00D09C : 0xFFFF4D6D,
          'isPos': change >= 0,
        });
      }
    }

    // Fallback if provider data is not yet loaded
    final List<Map<String, dynamic>> staticFallbacks = _showGainers ? _gainers : _losers;
    final List<Map<String, dynamic>> activeList = _showGainers
        ? (dynamicGainers.isNotEmpty ? dynamicGainers : staticFallbacks)
        : (dynamicLosers.isNotEmpty ? dynamicLosers : staticFallbacks);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Tab row
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                _moverTab(0, 'Top Gainers', AppTheme.primary),
                _moverTab(1, 'Top Losers', AppTheme.secondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // List
          ...activeList.map((stock) {
            final color = Color(stock['color'] as int);
            final symbol = stock['symbol'] as String;
            final displaySymbolName = symbol.startsWith("NSE:") ? symbol.substring(4) : symbol;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  final String lookupSymbol = symbol.startsWith("NSE:") ? symbol : "NSE:$symbol";
                  market.fetchMarketData(lookupSymbol);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StockDetailScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: color.withValues(alpha: 0.28),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            displaySymbolName.length >= 2
                                ? displaySymbolName.substring(0, 2)
                                : displaySymbolName,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
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
                              displaySymbolName,
                              style: TextStyle(
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              stock['name'] as String,
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            stock['price'] as String,
                            style: TextStyle(
                              color: AppTheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              stock['change'] as String,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _moverTab(int index, String label, Color accent) {
    final isActive = _showGainers == (index == 0);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showGainers = index == 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive
                ? accent.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: isActive
                ? Border.all(color: accent.withValues(alpha: 0.30), width: 1)
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  index == 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: isActive ? accent : AppTheme.onSurfaceVariant,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? accent : AppTheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ambient Orb ───────────────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    if (!AppTheme.isDark) return const SizedBox.shrink();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
