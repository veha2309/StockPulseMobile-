import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/market_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/trade_modal.dart';

class OptionsChainScreen extends StatefulWidget {
  const OptionsChainScreen({super.key});

  @override
  State<OptionsChainScreen> createState() => _OptionsChainScreenState();
}

class _OptionsChainScreenState extends State<OptionsChainScreen> {
  bool _eduExpanded = false;

  // Greeks now come directly from the contract (Black-Scholes computed in MarketProvider)
  Map<String, double> _greeks(OptionContract c) => {
    'delta': c.delta,
    'gamma': c.gamma,
    'theta': c.theta,
    'vega':  c.vega,
    'iv':    c.iv,
  };

  String _strikeLabel(double strike, double spot) {
    final diff = (strike - spot).abs();
    final step = spot * 0.005;
    if (diff <= step) return 'ATM';
    return strike < spot ? 'ITM' : 'OTM';
  }

  Color _strikeLabelColor(String label) {
    if (label == 'ATM') return Colors.amberAccent;
    if (label == 'ITM') return AppTheme.primary;
    return AppTheme.onSurfaceVariant;
  }

  String _strategyTip(OptionContract c, double spot, bool isCall) {
    final label = _strikeLabel(c.strike, spot);
    if (isCall) {
      if (label == 'ITM') return '💡 Deep ITM calls behave like stock — high delta, expensive but safer directional bet.';
      if (label == 'ATM') return '💡 ATM calls have the highest gamma & theta. Best for short-term bullish bets but decay fast.';
      return '💡 OTM calls are cheap lottery tickets — low probability but high reward if the stock surges.';
    } else {
      if (label == 'ITM') return '💡 Deep ITM puts act like short stock — use for strong bearish conviction or hedging.';
      if (label == 'ATM') return '💡 ATM puts are the most popular hedge. Theta eats value daily — time your entry carefully.';
      return '💡 OTM puts are cheap insurance. Ideal for protecting a long portfolio against a crash.';
    }
  }

  void _showContractDetail(OptionContract c, double spot, bool isCall) {
    final greeks = _greeks(c);
    final label = _strikeLabel(c.strike, spot);
    final spread = c.ask - c.bid;
    final spreadPct = c.lastPrice > 0 ? (spread / c.lastPrice * 100) : 0.0;
    final tip = _strategyTip(c, spot, isCall);
    final typeColor = isCall ? AppTheme.primary : AppTheme.secondary;
    final typeName = isCall ? 'CALL (CE)' : 'PUT (PE)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // title
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(typeName, style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _strikeLabelColor(label).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(label, style: TextStyle(color: _strikeLabelColor(label), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const Spacer(),
                Text('Strike ₹${c.strike.toStringAsFixed(0)}',
                    style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              const SizedBox(height: 20),

              // Price row
              _detailSection('Price Info', [
                _detailRow('Last Price', '₹${c.lastPrice.toStringAsFixed(2)}', typeColor),
                _detailRow('Bid', '₹${c.bid.toStringAsFixed(2)}', AppTheme.onSurface),
                _detailRow('Ask', '₹${c.ask.toStringAsFixed(2)}', AppTheme.onSurface),
                _detailRow('Spread', '₹${spread.toStringAsFixed(2)} (${spreadPct.toStringAsFixed(1)}%)',
                    spreadPct > 5 ? Colors.orangeAccent : AppTheme.primary),
                _detailRow('Impl. Volatility', '${greeks['iv']!.toStringAsFixed(1)}%', Colors.purpleAccent),
              ]),
              const SizedBox(height: 16),

              // Greeks
              _detailSection('Greeks', [
                _detailRow('Δ Delta', greeks['delta']!.toStringAsFixed(3), typeColor),
                _detailRow('Γ Gamma', greeks['gamma']!.toStringAsFixed(4), Colors.cyanAccent),
                _detailRow('Θ Theta (per day)', '₹${greeks['theta']!.toStringAsFixed(2)}', Colors.redAccent),
                _detailRow('V Vega (per 1% IV)', '₹${greeks['vega']!.toStringAsFixed(2)}', Colors.purpleAccent),
              ]),
              const SizedBox(height: 16),

              // Greeks explainer
              _eduBox('What do Greeks mean?', [
                ('Δ Delta', 'How much the option price moves per ₹1 move in the stock. A delta of 0.6 means the option gains ₹0.60 for every ₹1 the stock rises.'),
                ('Γ Gamma', 'Rate of change of delta. High gamma near expiry means delta can shift rapidly — risky but rewarding.'),
                ('Θ Theta', 'Daily time decay. Every day that passes, the option loses this much value even if the stock doesn\'t move.'),
                ('V Vega', 'Sensitivity to volatility. If IV rises by 1%, the option gains this much value.'),
              ]),
              const SizedBox(height: 16),

              // Spread explainer
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bid-Ask Spread', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    spreadPct > 5
                        ? '⚠️ Wide spread (${spreadPct.toStringAsFixed(1)}%) — you pay a high entry cost. Use limit orders near the mid-price (₹${((c.bid + c.ask) / 2).toStringAsFixed(2)}) to avoid overpaying.'
                        : '✅ Tight spread (${spreadPct.toStringAsFixed(1)}%) — liquid contract. Market orders are reasonably safe here.',
                    style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, height: 1.5),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Strategy tip
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Text(tip, style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, height: 1.6)),
              ),
              const SizedBox(height: 20),

              // Trade button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: typeColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => TradeModal(
                        symbol: c.contractSymbol,
                        price: c.lastPrice,
                        isBuy: true,
                        isOption: true,
                        contract: c,
                      ),
                    );
                  },
                  child: Text('Paper Trade this ${isCall ? 'Call' : 'Put'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> rows) => GlassCard(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 10),
      ...rows,
    ]),
  );

  Widget _detailRow(String label, String value, Color valueColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
      Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 12)),
    ]),
  );

  Widget _eduBox(String title, List<(String, String)> items) => GlassCard(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 10),
      ...items.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(text: TextSpan(children: [
          TextSpan(text: '${e.$1}  ', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          TextSpan(text: e.$2, style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, height: 1.5)),
        ])),
      )),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Options Chain',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildUnderlyingSummary(context, market),
          const SizedBox(height: 8),
          _buildEduPanel(),
          const SizedBox(height: 8),
          _buildHeaderRow(),
          Expanded(
            child: market.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : ListView.builder(
                    itemCount: market.calls.length,
                    itemBuilder: (context, index) {
                      final call = market.calls[index];
                      final put = market.puts[index];
                      return _buildOptionRow(context, call, put, market.underlyingPrice);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderlyingSummary(BuildContext context, MarketProvider market) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                market.currentSymbol.split(':').last,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.onSurface, fontWeight: FontWeight.bold),
              ),
              Text('Underlying Spot Price',
                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '₹${market.underlyingPrice.toStringAsFixed(2)}',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              Text('Tap any row to learn more',
                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildEduPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _eduExpanded = !_eduExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(Icons.school_rounded, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text('Options 101 — Tap to ${_eduExpanded ? 'hide' : 'learn'}',
                    style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Icon(_eduExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.onSurfaceVariant),
              ]),
            ),
          ),
          if (_eduExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Divider(color: AppTheme.borderColor),
                const SizedBox(height: 8),
                ..._eduItems.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.$1, style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.$2, style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(e.$3, style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, height: 1.5)),
                    ])),
                  ]),
                )),
                Divider(color: AppTheme.borderColor),
                const SizedBox(height: 8),
                Text('Reading this chain:', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                _chainLegendRow(AppTheme.primary.withValues(alpha: 0.15), 'Highlighted CALL rows = In The Money (ITM). Stock is already above this strike.'),
                const SizedBox(height: 4),
                _chainLegendRow(AppTheme.secondary.withValues(alpha: 0.15), 'Highlighted PUT rows = In The Money (ITM). Stock is already below this strike.'),
                const SizedBox(height: 4),
                _chainLegendRow(Colors.amberAccent.withValues(alpha: 0.15), 'ATM = At The Money. Closest strike to current spot price.'),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _chainLegendRow(Color bg, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, height: 1.4)),
  );

  static const List<(String, String, String)> _eduItems = [
    ('📞', 'Call Option (CE)', 'Gives you the RIGHT to BUY a stock at the strike price before expiry. You profit when the stock goes UP. Max loss = premium paid.'),
    ('📉', 'Put Option (PE)', 'Gives you the RIGHT to SELL a stock at the strike price before expiry. You profit when the stock goes DOWN. Max loss = premium paid.'),
    ('💰', 'Premium', 'The price you pay to buy an option. It has two parts: Intrinsic Value (real profit if exercised now) + Time Value (hope premium).'),
    ('⏳', 'Time Decay (Theta)', 'Options lose value every day as expiry approaches. Buyers lose from decay; sellers profit from it. ATM options decay fastest.'),
    ('📊', 'Implied Volatility (IV)', 'Market\'s expectation of future price swings. High IV = expensive options. Buy options when IV is low, sell when IV is high.'),
    ('🎯', 'Strike Price', 'The fixed price at which you can buy (call) or sell (put) the stock. ITM strikes cost more but have higher probability of profit.'),
  ];

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: AppTheme.surfaceContainer,
      child: Row(children: [
        _headerCell('LTP', flex: 2, color: AppTheme.primary),
        _headerCell('Bid/Ask', flex: 2, color: AppTheme.primary),
        _headerCell('STRIKE', flex: 3, color: AppTheme.onSurfaceVariant, center: true),
        _headerCell('Bid/Ask', flex: 2, color: AppTheme.secondary, right: true),
        _headerCell('LTP', flex: 2, color: AppTheme.secondary, right: true),
      ]),
    );
  }

  Widget _headerCell(String text, {int flex = 1, Color? color, bool center = false, bool right = false}) =>
      Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: center ? TextAlign.center : right ? TextAlign.right : TextAlign.left,
          style: TextStyle(color: color ?? AppTheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 10),
        ),
      );

  Widget _buildOptionRow(BuildContext context, OptionContract call, OptionContract put, double spot) {
    final label = _strikeLabel(call.strike, spot);
    final labelColor = _strikeLabelColor(label);
    final isAtm = label == 'ATM';

    return InkWell(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5)),
          color: isAtm ? Colors.amberAccent.withValues(alpha: 0.04) : Colors.transparent,
        ),
        child: Row(children: [
          // ── CALL side ──────────────────────────────────
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () => _showContractDetail(call, spot, true),
              child: Container(
                color: call.inTheMoney ? AppTheme.primary.withValues(alpha: 0.07) : Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(call.lastPrice.toStringAsFixed(2),
                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${call.bid.toStringAsFixed(1)} / ${call.ask.toStringAsFixed(1)}',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 9)),
                ]),
              ),
            ),
          ),
          // ── STRIKE ─────────────────────────────────────
          Expanded(
            flex: 3,
            child: Container(
              color: AppTheme.isDark
                  ? AppTheme.surfaceContainer.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.02),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(children: [
                Text(call.strike.toStringAsFixed(0),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 13)),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: labelColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(label,
                      style: TextStyle(color: labelColor, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          ),
          // ── PUT side ───────────────────────────────────
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () => _showContractDetail(put, spot, false),
              child: Container(
                color: put.inTheMoney ? AppTheme.secondary.withValues(alpha: 0.07) : Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(put.lastPrice.toStringAsFixed(2),
                      style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${put.bid.toStringAsFixed(1)} / ${put.ask.toStringAsFixed(1)}',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 9)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
