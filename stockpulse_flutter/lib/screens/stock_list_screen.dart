import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/market_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'stock_detail_screen.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredStocks = [];

  // Discovery list (Trending)
  final List<String> _trendingStocks = [
    "NSE:RELIANCE", "NSE:TCS", "NSE:HDFCBANK", "NSE:INFY", "NSE:ICICIBANK",
    "NSE:HINDUNILVR", "NSE:SBIN", "NSE:BHARTIARTL", "NSE:ITC", "NSE:KOTAKBANK",
    "NSE:LT", "NSE:AXISBANK", "NSE:ASIANPAINT", "NSE:MARUTI", "NSE:TITAN",
  ];

  @override
  void initState() {
    super.initState();
    _filteredStocks = _trendingStocks;
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStocks = _trendingStocks;
      } else {
        _filteredStocks = _trendingStocks
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background ambient decoration
          if (AppTheme.isDark)
            Positioned(
              top: -100,
              left: -50,
              child: _Orb(color: AppTheme.primary.withValues(alpha: 0.08), size: 300),
            ),
          
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildSearchField(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    children: [
                      if (market.watchlist.isNotEmpty && _searchController.text.isEmpty) ...[
                        _buildSectionLabel("FAVORITES", Icons.star_rounded),
                        const SizedBox(height: 16),
                        _buildFavoritesGrid(market),
                        const SizedBox(height: 32),
                      ],
                      _buildSectionLabel(
                        _searchController.text.isEmpty ? "TRENDING NOW" : "SEARCH RESULTS", 
                        Icons.trending_up_rounded
                      ),
                      const SizedBox(height: 16),
                      ..._filteredStocks.map((symbol) => _buildStockItem(market, symbol)),
                      
                      // Handle custom symbol search if not in trending
                      if (_searchController.text.isNotEmpty && 
                          !_filteredStocks.any((s) => s.contains(_searchController.text.toUpperCase())))
                        _buildStockItem(market, "NSE:${_searchController.text.toUpperCase()}"),
                        
                      const SizedBox(height: 140), // Space for Arc Dial
                    ],
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Text(
            "Market Hub", 
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: AppTheme.isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintText: "Search stocks (e.g. RELIANCE)",
            hintStyle: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesGrid(MarketProvider market) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: market.watchlist.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        final symbol = market.watchlist[index];
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          onTap: () {
            market.fetchMarketData(symbol);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StockDetailScreen()));
          },
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  symbol.split(':').last,
                  style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStockItem(MarketProvider market, String symbol) {
    final displaySymbol = symbol.split(':').last;
    final bool isFavorite = market.watchlist.contains(symbol);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        onTap: () {
          market.fetchMarketData(symbol);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StockDetailScreen()));
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  displaySymbol.substring(0, 1),
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displaySymbol, style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold)),
                  Text("NSE Equity", style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => market.toggleFavorite(symbol),
              child: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFavorite ? Colors.amber : AppTheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.onSurfaceVariant, size: 14),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
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
