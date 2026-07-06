import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class TradeModal extends StatefulWidget {
  final String symbol;
  final double price;
  final bool isBuy;
  final bool isOption;
  final OptionContract? contract;

  const TradeModal({
    super.key,
    required this.symbol,
    required this.price,
    required this.isBuy,
    this.isOption = false,
    this.contract,
  });

  @override
  State<TradeModal> createState() => _TradeModalState();
}

class _TradeModalState extends State<TradeModal> {
  late final TextEditingController _amountController;
  final _slController = TextEditingController();
  final _tpController = TextEditingController();

  static const int _lotSize = 50;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _slController.dispose();
    _tpController.dispose();
    super.dispose();
  }

  int get _lots => int.tryParse(_amountController.text) ?? 1;
  double get _units => widget.isOption ? (_lots * _lotSize).toDouble() : (double.tryParse(_amountController.text) ?? 0);
  double get _total => _units * widget.price;

  void _handleTrade() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final portfolio = context.read<PortfolioProvider>();
    final market = context.read<MarketProvider>();

    try {
      if (widget.isOption && widget.contract != null) {
        await portfolio.tradeOption(
          contractSymbol: widget.contract!.contractSymbol,
          underlyingSymbol: market.currentSymbol,
          type: widget.contract!.contractSymbol.split('-').last.substring(0, 2),
          strike: widget.contract!.strike,
          expiration: widget.contract!.expiration,
          lots: amount.toInt(),
          premium: widget.price,
          action: widget.isBuy ? 'buy' : 'sell',
        );
      } else {
        if (widget.isBuy) {
          await portfolio.buyStock(widget.symbol, amount, widget.price);
        } else {
          await portfolio.sellStock(widget.symbol, amount, widget.price);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.isBuy ? 'Bought' : 'Sold'} ${widget.isOption ? 'Lots' : 'Units'} successfully!'),
          backgroundColor: AppTheme.primary,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.secondary,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = widget.isBuy ? AppTheme.primary : AppTheme.secondary;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          '${widget.isBuy ? 'BUY' : 'SELL'} ${widget.isOption ? 'OPTION' : 'STOCK'}',
                          style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2),
                        ),
                        Text(
                          widget.symbol.split(':').last,
                          style: TextStyle(color: AppTheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Price card ───────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                      widget.isOption ? 'Premium per unit' : 'Market Price',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                    ),
                    Text('₹${widget.price.toStringAsFixed(2)}',
                        style: TextStyle(color: AppTheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Quantity input ───────────────────────────────
                _buildTextField(
                  _amountController,
                  widget.isOption ? 'Number of Lots  (1 Lot = $_lotSize units)' : 'Number of Units',
                  widget.isOption ? Icons.layers_outlined : Icons.inventory_2_outlined,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),

                // ── SL / TP for stocks ───────────────────────────
                if (!widget.isOption) ...[
                  Row(children: [
                    Expanded(child: _buildTextField(_tpController, 'Take Profit', Icons.trending_up)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_slController, 'Stop Loss', Icons.trending_down)),
                  ]),
                  const SizedBox(height: 14),
                ],

                // ── Greeks impact panel (options only) ───────────
                if (widget.isOption && widget.contract != null) ...[
                  _buildGreeksImpact(),
                  const SizedBox(height: 14),
                ],

                // ── Total ────────────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Estimated Total', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
                  Text('₹${_total.toStringAsFixed(2)}',
                      style: TextStyle(color: typeColor, fontSize: 24, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 20),

                // ── Confirm button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: typeColor,
                      foregroundColor: widget.isBuy ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _handleTrade,
                    child: Text(
                      widget.isBuy ? 'CONFIRM BUY' : 'CONFIRM SELL',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeksImpact() {
    final c = widget.contract!;
    final isCall = c.contractSymbol.endsWith('CE');
    final lots = _lots.clamp(1, 999);
    final units = lots * _lotSize;
    final premium = c.lastPrice;

    // ── Key trade metrics ──────────────────────────────────
    // Break-even at expiry
    final breakEven = isCall ? c.strike + premium : c.strike - premium;
    // Max loss for buyer = total premium paid
    final maxLoss = premium * units;
    // Theoretical max profit (call: unlimited shown as 2x move; put: strike - 0)
    final maxProfit = isCall ? (c.strike * 0.1 - premium).clamp(0, double.infinity) * units
                             : (c.strike - premium).clamp(0, double.infinity) * units;

    // ── Greeks impact on this position ────────────────────
    // Delta: ₹ gain per ₹1 move in underlying
    final deltaImpact = c.delta.abs() * units;
    // Theta: ₹ lost per day
    final thetaImpact = c.theta * units; // negative
    // Vega: ₹ gained per 1% IV rise
    final vegaImpact = c.vega * units;
    // Gamma: delta change per ₹1 move
    final gammaImpact = c.gamma * units;

    // Days to expiry
    final expiry = DateTime.fromMillisecondsSinceEpoch(c.expiration * 1000);
    final dte = expiry.difference(DateTime.now()).inDays.clamp(0, 365);
    // Total theta decay until expiry
    final totalDecay = thetaImpact * dte;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.analytics_rounded, color: AppTheme.primary, size: 16),
          const SizedBox(width: 6),
          Text('Greeks Impact on Your Trade',
              style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 14),

        // Trade summary metrics
        _impactRow('Lots × Units', '$lots × $_lotSize = $units units', AppTheme.onSurface),
        _impactRow('Break-even at Expiry', '₹${breakEven.toStringAsFixed(2)}', Colors.amberAccent),
        _impactRow('Max Loss (premium paid)', '₹${maxLoss.toStringAsFixed(2)}', AppTheme.secondary),
        _impactRow('Days to Expiry', '$dte days', AppTheme.onSurfaceVariant),
        Divider(color: AppTheme.borderColor, height: 20),

        // Greeks
        Text('How each Greek affects this position:',
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
        const SizedBox(height: 10),

        _greekImpactTile(
          'Δ Delta  ${c.delta.toStringAsFixed(3)}',
          'For every ₹1 the stock moves ${isCall ? 'up' : 'down'}, your position gains ₹${deltaImpact.toStringAsFixed(2)}.',
          AppTheme.primary,
          Icons.trending_up,
        ),
        _greekImpactTile(
          'Γ Gamma  ${c.gamma.toStringAsFixed(5)}',
          'Your delta shifts by ${gammaImpact.toStringAsFixed(3)} units per ₹1 move. High gamma = accelerating gains near expiry.',
          Colors.cyanAccent,
          Icons.speed_rounded,
        ),
        _greekImpactTile(
          'Θ Theta  ₹${thetaImpact.toStringAsFixed(2)}/day',
          'You lose ₹${thetaImpact.abs().toStringAsFixed(2)} per day from time decay. Over $dte days = ₹${totalDecay.abs().toStringAsFixed(2)} total decay.',
          AppTheme.secondary,
          Icons.hourglass_bottom_rounded,
        ),
        _greekImpactTile(
          'V Vega  ₹${vegaImpact.toStringAsFixed(2)} per 1% IV',
          'If implied volatility rises 1%, your position gains ₹${vegaImpact.toStringAsFixed(2)}. IV crush after events can hurt buyers.',
          Colors.purpleAccent,
          Icons.bar_chart_rounded,
        ),

        Divider(color: AppTheme.borderColor, height: 20),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isCall
                ? '📌 You need the stock to close above ₹${breakEven.toStringAsFixed(2)} at expiry to profit. Theta works against you every day — act before time value erodes.'
                : '📌 You need the stock to close below ₹${breakEven.toStringAsFixed(2)} at expiry to profit. Theta works against you every day — act before time value erodes.',
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, height: 1.5),
          ),
        ),
      ]),
    );
  }

  Widget _impactRow(String label, String value, Color valueColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
      Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 12)),
    ]),
  );

  Widget _greekImpactTile(String title, String body, Color color, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 15),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 2),
        Text(body, style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, height: 1.4)),
      ])),
    ]),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: AppTheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
