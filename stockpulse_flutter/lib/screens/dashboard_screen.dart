import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stockpulse_flutter/screens/stock_list_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatter.dart';
import '../widgets/glass_card.dart';
import 'stock_detail_screen.dart';
import 'profile_screen.dart';
import 'trade_history_screen.dart';
import 'portfolio_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    // Watch ThemeProvider to ensure rebuild on theme change
    context.watch<ThemeProvider>();

    return Scaffold(
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
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        boxShadow: [
          BoxShadow(
            color: AppTheme.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
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
            _navItem(0, Icons.grid_view_rounded, 'Home'),
            _navItem(1, Icons.pie_chart_rounded, 'Portfolio'),
            _navItem(2, Icons.attach_money_outlined, 'Stocks'),
            _navItem(3, Icons.history_rounded, 'History'),
            _navItem(4, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
class DashboardHome extends StatefulWidget {
  final Function(int)? onNavigate;
  const DashboardHome({super.key, this.onNavigate});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  int _dialIndex = 0;
  bool _isDialActive = false;

  late Future<List<Map<String, dynamic>>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _fetchNews();
  }

  Future<List<Map<String, dynamic>>> _fetchNews() async {
    debugPrint("STP: Fetching news from Supabase...");
    try {
      final response = await Supabase.instance.client
          .from('market_news')
          .select()
          .order('pubDate', ascending: false)
          .limit(10);

      // Supabase returns a List<dynamic>, which is a List<Map<String, dynamic>>
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('STP Error: Failed to fetch news from Supabase: $e');
      // Return sample data as a fallback on error
      return _getSampleNews();
    }
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri) && url.isNotEmpty) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch ThemeProvider here as well to ensure the Orbs and other theme-dependent elements update
    context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final market = context.watch<MarketProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final user = auth.user;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
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

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          // ── Ambient orbs ──
          Positioned(
            top: -100,
            left: -60,
            child: _Orb(
              color: AppTheme.primary.withValues(
                alpha: AppTheme.isDark ? 0.08 : 0.0,
              ),
              size: 320,
            ),
          ),
          Positioned(
            top: 200,
            right: -80,
            child: _Orb(
              color: AppTheme.primary.withValues(
                alpha: AppTheme.isDark ? 0.05 : 0.0,
              ),
              size: 240,
            ),
          ),
          SizedBox(
            height: constraints.maxHeight,
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  await portfolio.refresh();
                  if (market.currentSymbol.isNotEmpty) {
                    await market.fetchMarketData(market.currentSymbol);
                  }
                },
                color: AppTheme.primary,
                backgroundColor: AppTheme.card,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, user),
                      const SizedBox(height: 28),
                      _buildBalanceCard(
                        context,
                        user,
                        totalCurrentValue,
                        totalPnL,
                      ),
                      const SizedBox(height: 28),
                      _buildPortfolioPreview(context, market, user),
                      const SizedBox(height: 28),
                      // _buildMarketNews(context),
                      // const SizedBox(height: 28),
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

  // ── Dial state handlers ──────────────────────────────────────
  void _onDialIndexChanged(int idx) {
    final market = context.read<MarketProvider>();
    setState(() => _dialIndex = idx);
    if (idx < market.watchlist.length) {
      market.fetchMarketData(market.watchlist[idx]);
    }
  }

  void _onDialScrollStateChanged(bool active) {
    setState(() => _isDialActive = active);
  }

  void _onCardTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StockDetailScreen()),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            widget.onNavigate?.call(4); // Switch to Profile Screen
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.1),
              border: Border.all(color: AppTheme.primary, width: 1.5),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    dynamic user,
    double currentVal,
    double pnl,
  ) {
    final bool isPositive = pnl >= 0;
    return GestureDetector(
      onTap: () => widget.onNavigate?.call(1),
      child: GlassCard(
        glow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'WALLET BALANCE',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                // live dot
              ],
            ),
            const SizedBox(height: 10),
            Text(
              formatINR(user.eTokens),
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -1.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: AppTheme.borderColor),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStat(
                  'Holdings',
                  formatINR(currentVal),
                  Icons.account_balance_wallet_rounded,
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Overall P&L',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pnl == 0 ? '₹0.00' : formatINRSigned(pnl),
                      style: TextStyle(
                        color: pnl == 0
                            ? AppTheme.onSurface
                            : (isPositive
                                  ? AppTheme.primary
                                  : AppTheme.secondary),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioPreview(
    BuildContext context,
    MarketProvider market,
    dynamic user,
  ) {
    if (user.portfolio.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Holdings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () => widget.onNavigate?.call(1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...user.portfolio.take(3).map<Widget>((item) {
          final currentPrice = market.currentSymbol == item.symbol
              ? market.underlyingPrice
              : item.avgBuyPrice;
          final pnl = (currentPrice - item.avgBuyPrice) * item.amount;
          final isPos = pnl >= 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              onTap: () {
                market.fetchMarketData(item.symbol);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockDetailScreen()),
                );
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
                        item.symbol.split(':').last.substring(0, 2),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
                          item.symbol.split(':').last,
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${item.amount.toInt()} shares',
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
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        pnl == 0 ? '₹0.00' : formatINRSigned(pnl),
                        style: TextStyle(
                          color: pnl == 0
                              ? AppTheme.onSurface
                              : (isPos ? AppTheme.primary : AppTheme.secondary),
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
        }),
      ],
    );
  }

  List<Map<String, dynamic>> _getSampleNews() {
    return [
      {
        'title': 'NIFTY 50 hits all-time high amid strong FII inflows.',
        'pubDate': DateTime.now()
            .subtract(const Duration(minutes: 15))
            .toIso8601String(),
        'image_url':
            'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=400',
        'link': 'https://flutter.dev',
        'source_name': 'Reuters',
      },
    ];
  }

  // Widget _buildMarketNews(BuildContext context) {
  //   String timeAgo(String? dateString) {
  //     // This function remains the same and will work with the new 'pubDate'
  //     if (dateString == null) return '';
  //     final date = DateTime.tryParse(dateString);
  //     if (date == null) return '';

  //     final difference = DateTime.now().difference(date);
  //     if (difference.inMinutes < 60) {
  //       return '${difference.inMinutes}m ago';
  //     } else if (difference.inHours < 24) {
  //       return '${difference.inHours}h ago';
  //     } else {
  //       return '${difference.inDays}d ago';
  //     }
  //   }

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Market News',
  //         style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //               color: AppTheme.onSurface,
  //               fontWeight: FontWeight.bold,
  //             ),
  //       ),
  //       const SizedBox(height: 14),
  //       FutureBuilder<List<Map<String, dynamic>>>(
  //         future: _newsFuture,
  //         builder: (context, snapshot) {
  //           if (snapshot.connectionState == ConnectionState.waiting) {
  //             return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
  //           }
  //           if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
  //             return const Text('Could not load news at this time.');
  //           }

  //           final articles = snapshot.data!;

  //           return Column(
  //             children: articles.map((news) {
  //               // Use new field names: 'image_url' and 'link'
  //               final imageUrl = news['image_url'];
  //               final articleUrl = news['link'];

  //               return Padding(
  //                 padding: const EdgeInsets.only(bottom: 12),
  //                 child: GlassCard(
  //                   padding: const EdgeInsets.all(12),
  //                   onTap: articleUrl != null ? () => _launchURL(articleUrl) : null,
  //                   child: Row(
  //                     children: [
  //                       if (imageUrl != null && imageUrl.toString().startsWith('http'))
  //                         ClipRRect(
  //                           borderRadius: BorderRadius.circular(10),
  //                           child: Image.network(
  //                             imageUrl,
  //                             width: 70,
  //                             height: 70,
  //                             fit: BoxFit.cover,
  //                             errorBuilder: (_, __, ___) => const SizedBox(width: 70, height: 70),
  //                           ),
  //                         )
  //                       else
  //                         Container(
  //                           width: 70,
  //                           height: 70,
  //                           decoration: BoxDecoration(
  //                             color: AppTheme.surface,
  //                             borderRadius: BorderRadius.circular(10),
  //                           ),
  //                           child: Icon(Icons.image_not_supported_outlined, color: AppTheme.onSurfaceVariant),
  //                         ),
  //                       const SizedBox(width: 14),
  //                       Expanded(
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Text(
  //                               news['title'] ?? 'No Title',
  //                               style: TextStyle(
  //                                 color: AppTheme.onSurface,
  //                                 fontWeight: FontWeight.bold,
  //                                 fontSize: 13,
  //                                 height: 1.4,
  //                               ),
  //                               maxLines: 2,
  //                               overflow: TextOverflow.ellipsis,
  //                             ),
  //                             const SizedBox(height: 6),
  //                             Text(
  //                               // Use new field names: 'source_name' and 'pubDate'
  //                               '${news['source_name'] ?? 'Unknown Source'} · ${timeAgo(news['pubDate'])}',
  //                               style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               );
  //             }).toList(),
  //           );
  //         },
  //       ),
  //     ],
  //   );
  // }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    if (!AppTheme.isDark)
      return const SizedBox.shrink(); // Fades out completely in light mode

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
