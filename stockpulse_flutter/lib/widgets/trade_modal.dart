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

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.isOption ? "1" : "1");
  }

  @override
  void dispose() {
    _amountController.dispose();
    _slController.dispose();
    _tpController.dispose();
    super.dispose();
  }

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
          type: widget.contract!.contractSymbol.split('-').last.substring(0, 2), // Rough extraction
          strike: widget.contract!.strike,
          expiration: widget.contract!.expiration,
          lots: amount.toInt(),
          premium: widget.price,
          action: widget.isBuy ? "buy" : "sell",
        );
      } else {
        if (widget.isBuy) {
          await portfolio.buyStock(widget.symbol, amount, widget.price);
          // Set TP/SL if provided (not yet implemented in buyStock, but user asked for these features)
          // For now, these are just UI props as per request
        } else {
          await portfolio.sellStock(widget.symbol, amount, widget.price);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${widget.isBuy ? 'Bought' : 'Sold'} ${widget.isOption ? 'Lots' : 'Units'} successfully!"),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.secondary),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double total = (double.tryParse(_amountController.text) ?? 0) * widget.price * (widget.isOption ? 50 : 1);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.isBuy ? 'BUY' : 'SELL'} ${widget.isOption ? 'OPTION' : 'STOCK'}",
                            style: TextStyle(color: widget.isBuy ? AppTheme.primary : AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2),
                          ),
                          Text(
                            widget.symbol, 
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPriceSection(),
                const SizedBox(height: 16),
                _buildInputFields(),
                const SizedBox(height: 24),
                if (!widget.isOption) ...[
                  const Text("Trade Features", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_tpController, "Take Profit", Icons.trending_up)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_slController, "Stop Loss", Icons.trending_down)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                _buildTotalSection(total),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isBuy ? AppTheme.primary : AppTheme.secondary,
                      foregroundColor: widget.isBuy ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _handleTrade,
                    child: Text(
                      "${widget.isBuy ? 'CONFIRM BUY' : 'CONFIRM SELL'}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.isOption ? "Premium per unit" : "Current Market Price",
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "₹${widget.price.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return _buildTextField(
      _amountController,
      widget.isOption ? "Number of Lots (1 Lot = 50 Units)" : "Number of Units",
      widget.isOption ? Icons.layers_outlined : Icons.inventory_2_outlined,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildTotalSection(double total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            "Estimated Total", 
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "₹${total.toStringAsFixed(2)}",
          style: TextStyle(color: widget.isBuy ? AppTheme.primary : AppTheme.secondary, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {Function(String)? onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
