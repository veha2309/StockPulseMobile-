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

  void _showTradeDialog(OptionContract contract, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TradeModal(
        symbol: contract.contractSymbol,
        price: contract.lastPrice,
        isBuy: true, // Default to buy in this view
        isOption: true,
        contract: contract,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Options Chain", style: Theme.of(context).textTheme.headlineMedium),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildUnderlyingSummary(context, market),
          const SizedBox(height: 16),
          _buildHeaderRow(context),
          Expanded(
            child: market.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: market.calls.length,
                  itemBuilder: (context, index) {
                    final call = market.calls[index];
                    final put = market.puts[index];
                    return _buildOptionRow(context, call, put);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderlyingSummary(BuildContext context, MarketProvider market) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(market.currentSymbol, style: Theme.of(context).textTheme.titleLarge),
                const Text("Underlying Price", style: TextStyle(color: AppTheme.onSurfaceVariant)),
              ],
            ),
            Text(
              "₹${market.underlyingPrice.toStringAsFixed(2)}",
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppTheme.surfaceContainer,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 3, child: Center(child: Text("CALLS", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)))),
          Expanded(flex: 2, child: Center(child: Text("STRIKE", style: TextStyle(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.bold)))),
          Expanded(flex: 3, child: Center(child: Text("PUTS", style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildOptionRow(BuildContext context, OptionContract call, OptionContract put) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.surfaceContainer, width: 1)),
      ),
      child: Row(
        children: [
          // Calls
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _showTradeDialog(call, "CE"),
              child: Container(
                color: call.inTheMoney ? AppTheme.primary.withValues(alpha: 0.05) : Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text(call.lastPrice.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary))),
              ),
            ),
          ),
          // Strike
          Expanded(
            flex: 2,
            child: Container(
              color: AppTheme.surfaceContainer.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text(call.strike.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface))),
            ),
          ),
          // Puts
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _showTradeDialog(put, "PE"),
              child: Container(
                color: put.inTheMoney ? AppTheme.secondary.withValues(alpha: 0.05) : Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text(put.lastPrice.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.secondary))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
