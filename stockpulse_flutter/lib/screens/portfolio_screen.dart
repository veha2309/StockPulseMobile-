import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatter.dart';
import '../widgets/glass_card.dart';
import '../widgets/trade_modal.dart';
import 'stock_detail_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final market = context.watch<MarketProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    double totalInvested = 0;
    double totalCurrentValue = 0;
    for (var item in user.portfolio) {
      totalInvested += item.amount * item.avgBuyPrice;
      totalCurrentValue +=
          item.amount *
          (market.currentSymbol == item.symbol
              ? market.underlyingPrice
              : item.avgBuyPrice);
    }
    final double totalPnL = totalCurrentValue - totalInvested;
    final bool isPnLPositive = totalPnL >= 0;
    final double netWorth = user.eTokens + totalCurrentValue;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Ambient orb (Dark mode only) ──
          if (AppTheme.isDark) ...[
            Positioned(
              top: -80,
              right: -60,
              child: _Orb(
                color: AppTheme.primary.withValues(alpha: 0.08),
                size: 280,
              ),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: _Orb(
                color: AppTheme.primary.withValues(alpha: 0.05),
                size: 220,
              ),
            ),
          ],
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildTabBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => portfolio.refresh(),
                    color: AppTheme.primary,
                    backgroundColor: AppTheme.card,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: Column(
                              children: [
                                _buildNetWorthCard(
                                  netWorth,
                                  totalCurrentValue,
                                  totalPnL,
                                  isPnLPositive,
                                ),
                                const SizedBox(height: 16),
                                _buildStatRow(
                                  user,
                                  totalInvested,
                                  totalCurrentValue,
                                  totalPnL,
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        SliverFillRemaining(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _EquityList(
                                portfolio: user.portfolio,
                                market: market,
                              ),
                              _OptionsList(options: user.options),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(
            'Portfolio',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          // live dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: AppTheme.isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
          tabs: const [
            Tab(text: 'EQUITY'),
            Tab(text: 'OPTIONS'),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthCard(
    double netWorth,
    double holdingsValue,
    double pnl,
    bool isPos,
  ) {
    return GlassCard(
      glow: true,
      animate: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppTheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'TOTAL NET WORTH',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPos
                      ? AppTheme.primary.withValues(alpha: 0.12)
                      : AppTheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPos ? '▲ PROFIT' : '▼ LOSS',
                  style: TextStyle(
                    color: isPos ? AppTheme.primary : AppTheme.secondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatINR(netWorth),
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Cash ${formatINR(netWorth - holdingsValue)}  ·  Holdings ${formatINR(holdingsValue)}',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Overall P&L',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                pnl == 0 ? '₹0.00' : formatINRSigned(pnl),
                style: TextStyle(
                  color: pnl == 0
                      ? AppTheme.onSurface
                      : (isPos ? AppTheme.primary : AppTheme.secondary),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    dynamic user,
    double invested,
    double current,
    double pnl,
  ) {
    final pnlPct = invested > 0 ? (pnl / invested * 100) : 0.0;
    return Row(
      children: [
        Expanded(
          child: AnimatedStatCard(
            label: 'Cash Balance',
            value: formatINR(user.eTokens),
            icon: Icons.currency_rupee_rounded,
            delay: 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedStatCard(
            label: 'Invested',
            value: formatINR(invested),
            icon: Icons.trending_up_rounded,
            delay: 80,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedStatCard(
            label: 'Return %',
            value: '${pnlPct >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(1)}%',
            icon: Icons.percent_rounded,
            valueColor: pnlPct >= 0 ? AppTheme.primary : AppTheme.secondary,
            delay: 160,
          ),
        ),
      ],
    );
  }
}

// ── Equity list ──
class _EquityList extends StatelessWidget {
  final List<dynamic> portfolio;
  final MarketProvider market;

  const _EquityList({required this.portfolio, required this.market});

  @override
  Widget build(BuildContext context) {
    if (portfolio.isEmpty) {
      return Center(
        child: Text(
          'No equity holdings',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: portfolio.length,
      itemBuilder: (context, index) {
        final item = portfolio[index];
        final currentPrice = market.currentSymbol == item.symbol
            ? market.underlyingPrice
            : item.avgBuyPrice;
        final pnl = (currentPrice - item.avgBuyPrice) * item.amount;
        final isPos = pnl >= 0;

        return _SlideItem(
          delay: index * 60,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            onTap: () => _showHoldingOptions(context, item, currentPrice),
            child: Row(
              children: [
                // Symbol badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.symbol.split(':').last.substring(0, 2),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.symbol.split(':').last,
                            style: TextStyle(
                              color: AppTheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (item.sl != null || item.tp != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SL/TP',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.amount.toInt()} qty  ·  avg ${formatINR(item.avgBuyPrice)}',
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
                      formatINR(item.amount * currentPrice),
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isPos
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : AppTheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pnl == 0 ? '₹0.00' : formatINRSigned(pnl),
                        style: TextStyle(
                          color: isPos ? AppTheme.primary : AppTheme.secondary,
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
        );
      },
    );
  }

  void _showHoldingOptions(
    BuildContext context,
    dynamic item,
    double currentPrice,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.symbol.split(':').last,
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionBtn(
              context,
              "View Stock Details",
              Icons.visibility,
              () {
                Navigator.pop(context);
                market.fetchMarketData(item.symbol);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockDetailScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildOptionBtn(
              context,
              "Trade / Sell",
              Icons.shopping_cart_checkout,
              () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => TradeModal(
                    symbol: item.symbol,
                    price: currentPrice,
                    isBuy: false,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildOptionBtn(
              context,
              "Set Target / Stop Loss",
              Icons.track_changes,
              () {
                Navigator.pop(context);
                _showTargetModal(context, item);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showTargetModal(BuildContext context, dynamic item) {
    final slController = TextEditingController(text: item.sl?.toString() ?? '');
    final tpController = TextEditingController(text: item.tp?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Set Targets for ${item.symbol.split(':').last}",
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: tpController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(color: AppTheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Take Profit Price",
                  labelStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                  filled: true,
                  fillColor: AppTheme.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: slController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(color: AppTheme.onSurface),
                decoration: InputDecoration(
                  labelText: "Stop Loss Price",
                  labelStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                  filled: true,
                  fillColor: AppTheme.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final tp = double.tryParse(tpController.text);
                    final sl = double.tryParse(slController.text);
                    try {
                      await context.read<PortfolioProvider>().updateTargets(
                        item.id,
                        sl,
                        tp,
                      );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.secondary));
                      }
                    }
                  },
                  child: const Text(
                    "Save Targets",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionBtn(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Options list ──
class _OptionsList extends StatelessWidget {
  final List<dynamic> options;
  const _OptionsList({required this.options});

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Center(
        child: Text(
          'No open option positions',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final pos = options[index];
        final isCall = pos.type == 'call';
        final invested = pos.lots * 75 * pos.premium;

        return _SlideItem(
          delay: index * 60,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            onTap: () => _showContractOptions(context, pos),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCall
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : AppTheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCall
                              ? AppTheme.primary.withValues(alpha: 0.3)
                              : AppTheme.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        pos.type.toUpperCase(),
                        style: TextStyle(
                          color: isCall ? AppTheme.primary : AppTheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${pos.underlyingSymbol}  ·  ₹${pos.strike.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${pos.lots} lots',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: AppTheme.borderColor,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _optStat('Premium', '₹${pos.premium.toStringAsFixed(2)}'),
                    _optStat('Invested', formatINR(invested)),
                    _optStat('Side', pos.side.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _optStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _showContractOptions(BuildContext context, dynamic pos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${pos.underlyingSymbol} ${pos.strike} ${pos.type.toUpperCase()}",
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionBtn(
              context,
              "View in Options Chain",
              Icons.layers_outlined,
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "To view this contract, please open the Options Chain for this symbol.",
                    ),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildOptionBtn(
              context,
              "Square Off / Sell",
              Icons.shopping_cart_checkout,
              () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => TradeModal(
                    symbol: pos.underlyingSymbol,
                    price: pos.premium,
                    isBuy: false,
                    isOption: true,
                    contract: OptionContract(
                      contractSymbol: pos.contractSymbol,
                      strike: (pos.strike is int)
                          ? (pos.strike as int).toDouble()
                          : pos.strike,
                      expiration: pos.expiration,
                      lastPrice: pos.premium,
                      bid: pos.premium,
                      ask: pos.premium,
                      change: 0,
                      inTheMoney: false,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionBtn(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide-up entrance wrapper ──
class _SlideItem extends StatefulWidget {
  final Widget child;
  final int delay;
  const _SlideItem({required this.child, this.delay = 0});

  @override
  State<_SlideItem> createState() => _SlideItemState();
}

class _SlideItemState extends State<_SlideItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
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
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Ambient orb ──
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
