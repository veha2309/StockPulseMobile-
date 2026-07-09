import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../providers/market_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatter.dart';
import '../widgets/glass_card.dart';
import 'stock_detail_screen.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  // Discovery list (Trending)
  final List<String> _trendingStocks = [
    // Banking (12 stocks)
    "NSE:HDFCBANK", "NSE:ICICIBANK", "NSE:SBIN", "NSE:KOTAKBANK", "NSE:AXISBANK",
    "NSE:INDUSINDBK", "NSE:PNB", "NSE:BANKBARODA", "NSE:FEDERALBNK", "NSE:IDFCFIRSTB",
    "NSE:CANBK", "NSE:BANDHANBNK",
    // Info Tech (10 stocks)
    "NSE:TCS", "NSE:INFY", "NSE:WIPRO", "NSE:HCLTECH", "NSE:TECHM", "NSE:LTIM",
    "NSE:COFORGE", "NSE:MPHASIS", "NSE:PERSISTENT", "NSE:KPITTECH",
    // Pharma (8 stocks)
    "NSE:SUNPHARMA", "NSE:CIPLA", "NSE:DRREDDY", "NSE:APOLLOHOSP", "NSE:DIVISLAB",
    "NSE:LUPIN", "NSE:AUROPHARMA", "NSE:BIOCON",
    // Auto (9 stocks)
    "NSE:TATAMOTORS", "NSE:MARUTI", "NSE:M&M", "NSE:BAJAJ-AUTO", "NSE:EICHERMOT",
    "NSE:HEROMOTOCO", "NSE:TVSMOTOR", "NSE:BALKRISIND", "NSE:TIINDIA",
    // FMCG (7 stocks)
    "NSE:HINDUNILVR", "NSE:ITC", "NSE:NESTLEIND", "NSE:BRITANNIA", "NSE:TATACONSUM",
    "NSE:COLPAL", "NSE:GODREJCP",
    // Energy (6 stocks)
    "NSE:RELIANCE", "NSE:ONGC", "NSE:NTPC", "NSE:POWERGRID", "NSE:COALINDIA", "NSE:BPCL",
    // Infra (5 stocks)
    "NSE:LT", "NSE:ADANIENT", "NSE:ADANIPORTS", "NSE:ULTRACEMCO", "NSE:GRASIM",
    // Telecom (4 stocks)
    "NSE:BHARTIARTL", "NSE:IDEA", "NSE:TATACOMM", "NSE:TEJASNET"
  ];

  final Map<String, String> _stockSectors = {
    // Banking
    "NSE:HDFCBANK": "Banking",
    "NSE:ICICIBANK": "Banking",
    "NSE:SBIN": "Banking",
    "NSE:KOTAKBANK": "Banking",
    "NSE:AXISBANK": "Banking",
    "NSE:INDUSINDBK": "Banking",
    "NSE:PNB": "Banking",
    "NSE:BANKBARODA": "Banking",
    "NSE:FEDERALBNK": "Banking",
    "NSE:IDFCFIRSTB": "Banking",
    "NSE:CANBK": "Banking",
    "NSE:BANDHANBNK": "Banking",
    // Info Tech
    "NSE:TCS": "Info Tech",
    "NSE:INFY": "Info Tech",
    "NSE:WIPRO": "Info Tech",
    "NSE:HCLTECH": "Info Tech",
    "NSE:TECHM": "Info Tech",
    "NSE:LTIM": "Info Tech",
    "NSE:COFORGE": "Info Tech",
    "NSE:MPHASIS": "Info Tech",
    "NSE:PERSISTENT": "Info Tech",
    "NSE:KPITTECH": "Info Tech",
    // Pharma
    "NSE:SUNPHARMA": "Pharma",
    "NSE:CIPLA": "Pharma",
    "NSE:DRREDDY": "Pharma",
    "NSE:APOLLOHOSP": "Pharma",
    "NSE:DIVISLAB": "Pharma",
    "NSE:LUPIN": "Pharma",
    "NSE:AUROPHARMA": "Pharma",
    "NSE:BIOCON": "Pharma",
    // Auto
    "NSE:TATAMOTORS": "Auto",
    "NSE:MARUTI": "Auto",
    "NSE:M&M": "Auto",
    "NSE:BAJAJ-AUTO": "Auto",
    "NSE:EICHERMOT": "Auto",
    "NSE:HEROMOTOCO": "Auto",
    "NSE:TVSMOTOR": "Auto",
    "NSE:BALKRISIND": "Auto",
    "NSE:TIINDIA": "Auto",
    // FMCG
    "NSE:HINDUNILVR": "FMCG",
    "NSE:ITC": "FMCG",
    "NSE:NESTLEIND": "FMCG",
    "NSE:BRITANNIA": "FMCG",
    "NSE:TATACONSUM": "FMCG",
    "NSE:COLPAL": "FMCG",
    "NSE:GODREJCP": "FMCG",
    // Energy
    "NSE:RELIANCE": "Energy",
    "NSE:ONGC": "Energy",
    "NSE:NTPC": "Energy",
    "NSE:POWERGRID": "Energy",
    "NSE:COALINDIA": "Energy",
    "NSE:BPCL": "Energy",
    // Infra
    "NSE:LT": "Infra",
    "NSE:ADANIENT": "Infra",
    "NSE:ADANIPORTS": "Infra",
    "NSE:ULTRACEMCO": "Infra",
    "NSE:GRASIM": "Infra",
    // Telecom
    "NSE:BHARTIARTL": "Telecom",
    "NSE:IDEA": "Telecom",
    "NSE:TATACOMM": "Telecom",
    "NSE:TEJASNET": "Telecom",
  };

  // Local storage for dynamically searched stock sectors
  final Map<String, String> _searchedStockSectors = {};

  void _onSearchChanged(String query, String baseUrl) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final url = Uri.parse('$baseUrl/api/stocks/search?q=${Uri.encodeComponent(query.trim())}');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> results = data['results'] ?? [];
          final list = results.cast<Map<String, dynamic>>();

          if (!mounted) return;

          setState(() {
            _searchResults = list;
            _isSearching = false;
          });

          // Register sector mappings dynamically and fetch quotes
          final market = context.read<MarketProvider>();
          for (var item in list) {
            final sym = item['symbol'] as String;
            final sec = item['sector'] as String;
            _searchedStockSectors[sym] = sec;
            market.fetchSingleQuote(sym);
          }
        } else {
          _fallbackLocalSearch(query);
        }
      } catch (e) {
        debugPrint("STP ERROR: Server search failed, falling back to local: $e");
        _fallbackLocalSearch(query);
      }
    });
  }

  void _fallbackLocalSearch(String query) {
    if (!mounted) return;
    final List<Map<String, dynamic>> localResults = [];
    final queryLower = query.toLowerCase().trim();

    for (var sym in _trendingStocks) {
      final displaySymbol = sym.replaceFirst("NSE:", "");
      final sector = _stockSectors[sym] ?? "";
      if (displaySymbol.toLowerCase().contains(queryLower) ||
          sector.toLowerCase().contains(queryLower)) {
        localResults.add({
          'symbol': sym,
          'sector': sector,
          'name': displaySymbol,
        });
      }
    }

    setState(() {
      _searchResults = localResults;
      _isSearching = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().initializeWatchlist();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();
    final auth = context.watch<AuthProvider>();

    // ── Apply Sector & Search Filters ──
    List<String> displayedList = [];

    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      displayedList = _searchResults.map((e) => e['symbol'] as String).toList();
    } else if (market.selectedSector.isNotEmpty) {
      displayedList = _trendingStocks.where((symbol) {
        final sector = _stockSectors[symbol] ?? "";
        return sector.toLowerCase() == market.selectedSector.toLowerCase();
      }).toList();
    } else {
      displayedList = _trendingStocks;
    }
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background ambient orbs with multi-color depth
          if (AppTheme.isDark) ...[
            Positioned(
              top: -120,
              left: -60,
              child: _Orb(color: AppTheme.primary.withValues(alpha: 0.10), size: 320),
            ),
            Positioned(
              top: 200,
              right: -80,
              child: _Orb(color: AppTheme.violet.withValues(alpha: 0.08), size: 280),
            ),
            Positioned(
              bottom: 200,
              left: -60,
              child: _Orb(color: AppTheme.blue.withValues(alpha: 0.07), size: 240),
            ),
          ],
          
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildSearchField(auth.baseUrl),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      // Active Sector Filter Chip
                      if (market.selectedSector.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.violet.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.violet.withValues(alpha: 0.35), width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.category_rounded, color: AppTheme.violet, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Sector: ${market.selectedSector}",
                                    style: TextStyle(color: AppTheme.onSurface, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      market.setSectorFilter("");
                                      _searchController.clear();
                                    },
                                    child: const Icon(Icons.close_rounded, color: AppTheme.secondary, size: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (market.watchlist.isNotEmpty && _searchController.text.isEmpty && market.selectedSector.isEmpty) ...[
                        _buildSectionLabel("FAVORITES", Icons.star_rounded),
                        const SizedBox(height: 16),
                        _buildFavoritesGrid(market, auth),
                        const SizedBox(height: 32),
                      ],

                      _buildSectionLabel(
                        _searchController.text.isEmpty && market.selectedSector.isEmpty
                            ? "TRENDING NOW"
                            : market.selectedSector.isNotEmpty && _searchController.text.isEmpty
                                ? "SECTOR ASSETS"
                                : "SEARCH RESULTS", 
                        Icons.trending_up_rounded
                      ),
                      const SizedBox(height: 16),

                      if (_isSearching) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          ),
                        ),
                      ] else if (displayedList.isEmpty) ...[
                        if (!(_searchController.text.isNotEmpty && market.selectedSector.isEmpty && !_isSearching))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                "No stocks found",
                                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                              ),
                            ),
                          ),
                      ] else ...[
                        ...displayedList.map((symbol) => _buildStockItem(market, auth, symbol)),
                      ],
                      
                      // Handle custom symbol search if not in filtered list
                      if (_searchController.text.isNotEmpty && 
                          !displayedList.any((s) => s.toLowerCase().contains(_searchController.text.toLowerCase().trim())) &&
                          market.selectedSector.isEmpty && !_isSearching)
                        _buildStockItem(market, auth, "NSE:${_searchController.text.toUpperCase().trim()}"),
                        
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          // Gradient accent bar on the left
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              "Market Hub",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          // Live pulse indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.6), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 5),
                const Text("LIVE", style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(String baseUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.violet.withValues(alpha: 0.20), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.violet.withValues(alpha: AppTheme.isDark ? 0.08 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: AppTheme.isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => _onSearchChanged(val, baseUrl),
          style: TextStyle(color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintText: "Search stocks (e.g. RELIANCE)",
            hintStyle: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
            prefixIcon: ShaderMask(
              shaderCallback: (bounds) => AppTheme.violetGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: const Icon(Icons.search_rounded),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    final isSearch = label == "SEARCH RESULTS";
    final isFavorites = label == "FAVORITES";
    final labelColor = isFavorites
        ? AppTheme.amber
        : isSearch
            ? AppTheme.violet
            : AppTheme.primary;
    return Row(
      children: [
        Icon(icon, color: labelColor, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesGrid(MarketProvider market, AuthProvider auth) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: market.watchlist.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.1,
      ),
      itemBuilder: (context, index) {
        final symbol = market.watchlist[index];
        final sectorColorFav = AppTheme.sectorColor(index);
        final price = market.stockPrices[symbol] ?? 0.0;
        final change = market.stockChanges[symbol] ?? 0.0;

        final holdings = (auth.user?.portfolio ?? [])
            .where((p) => p.symbol == symbol)
            .toList();
        final bool hasHolding = holdings.isNotEmpty;

        double pnl = 0;
        if (hasHolding) {
          for (var item in holdings) {
            final currentPrice = price > 0 ? price : item.avgBuyPrice;
            pnl += (currentPrice - item.avgBuyPrice) * item.amount;
          }
        }

        return GestureDetector(
          onTap: () {
            market.fetchMarketData(symbol);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StockDetailScreen()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  sectorColorFav.withValues(alpha: AppTheme.isDark ? 0.16 : 0.08),
                  AppTheme.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: sectorColorFav.withValues(alpha: 0.25), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: sectorColorFav.withValues(alpha: AppTheme.isDark ? 0.12 : 0.05),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        symbol.split(':').last,
                        style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasHolding)
                      Text(
                        pnl == 0 ? '₹0.00' : formatINRSigned(pnl),
                        style: TextStyle(
                          color: pnl >= 0 ? AppTheme.primary : AppTheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Icon(Icons.star_rounded, color: sectorColorFav, size: 14),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price > 0 ? "₹${price.toStringAsFixed(1)}" : "₹---",
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: price > 0
                            ? (change >= 0 ? AppTheme.primary : AppTheme.secondary).withValues(alpha: 0.15)
                            : AppTheme.onSurfaceVariant.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        price > 0 ? "${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%" : "--%",
                        style: TextStyle(
                          color: price > 0
                              ? (change >= 0 ? AppTheme.primary : AppTheme.secondary)
                              : AppTheme.onSurfaceVariant,
                          fontSize: 9,
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

  Widget _buildStockItem(MarketProvider market, AuthProvider auth, String symbol) {
    final displaySymbol = symbol.split(':').last;
    final bool isFavorite = market.watchlist.contains(symbol);
    final symbolIndex = (_trendingStocks.indexOf(symbol) + market.watchlist.indexOf(symbol) + 2).abs();
    final sectorColor = AppTheme.sectorColor(symbolIndex);

    final holdings = (auth.user?.portfolio ?? [])
        .where((p) => p.symbol == symbol)
        .toList();
    final bool hasHolding = holdings.isNotEmpty;

    // Use cached prices and changes if available
    final price = market.stockPrices[symbol] ?? 0.0;
    final change = market.stockChanges[symbol] ?? 0.0;

    double pnl = 0;
    if (hasHolding) {
      for (var item in holdings) {
        final currentPrice = price > 0 ? price : item.avgBuyPrice;
        pnl += (currentPrice - item.avgBuyPrice) * item.amount;
      }
    }

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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: sectorColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sectorColor.withValues(alpha: 0.30), width: 1.5),
                boxShadow: [
                  BoxShadow(color: sectorColor.withValues(alpha: AppTheme.isDark ? 0.18 : 0.08), blurRadius: 10, spreadRadius: -2),
                ],
              ),
              child: Center(
                child: Text(
                  displaySymbol.substring(0, 1),
                  style: TextStyle(color: sectorColor, fontWeight: FontWeight.bold, fontSize: 16),
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
                      Text(displaySymbol, style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold)),
                      if (price > 0) ...[
                        const SizedBox(width: 6),
                        Icon(
                          change >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: change >= 0 ? AppTheme.primary : AppTheme.secondary,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text("NSE Equity", style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
                      Text("  ·  ", style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
                      Text(
                        price > 0
                            ? "₹${price.toStringAsFixed(2)} (${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%)"
                            : "₹--- (-.-%)",
                        style: TextStyle(
                          color: price > 0
                              ? (change >= 0 ? AppTheme.primary : AppTheme.secondary)
                              : AppTheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: price > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (hasHolding)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pnl >= 0
                      ? AppTheme.primary.withValues(alpha: 0.12)
                      : AppTheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: pnl >= 0
                        ? AppTheme.primary.withValues(alpha: 0.25)
                        : AppTheme.secondary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  pnl == 0 ? '₹0.00' : formatINRSigned(pnl),
                  style: TextStyle(
                    color: pnl >= 0 ? AppTheme.primary : AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
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
