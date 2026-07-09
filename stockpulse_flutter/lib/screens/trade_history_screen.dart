import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatter.dart';
import '../widgets/glass_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TradeHistoryScreen extends StatefulWidget {
  const TradeHistoryScreen({super.key});

  @override
  State<TradeHistoryScreen> createState() => _TradeHistoryScreenState();
}

class _TradeHistoryScreenState extends State<TradeHistoryScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _trades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrades();
  }

  Future<void> _fetchTrades() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('trades')
          .select()
          .eq('email', auth.user!.email)
          .order('timestamp', ascending: false);
      if (mounted) setState(() { _trades = res; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          if (AppTheme.isDark) ...[
            Positioned(
              top: -60,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.violet.withValues(alpha: 0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.blue.withValues(alpha: 0.06),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ],
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchTrades,
                    color: AppTheme.primary,
                    backgroundColor: AppTheme.card,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary))
                        : _trades.isEmpty
                            ? _buildEmpty()
                            : _buildList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: AppTheme.amberGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HISTORY',
                    style: TextStyle(
                      color: AppTheme.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              ShaderMask(
                shaderCallback: (bounds) => AppTheme.amberGradient.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'Trade History',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.blue.withValues(alpha: 0.25)),
            ),
            child: Text(
              '${_trades.length} trades',
              style: TextStyle(
                color: AppTheme.blue,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.history_rounded,
                  color: AppTheme.primary, size: 48),
              SizedBox(height: 12),
              Text('No trades yet',
                  style: TextStyle(
                      color: AppTheme.tertiary, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _trades.length,
      itemBuilder: (context, index) {
        final trade = _trades[index];
        final isBuy = trade['action'] == 'buy';
        DateTime? date;
        try {
          date = DateTime.parse(trade['timestamp']).toLocal();
        } catch (_) {}

        return _SlideItem(
          delay: index * 40,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isBuy
                        ? AppTheme.emerald.withValues(alpha: 0.12)
                        : AppTheme.rose.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isBuy
                          ? AppTheme.emerald.withValues(alpha: 0.28)
                          : AppTheme.rose.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isBuy ? AppTheme.emerald : AppTheme.rose).withValues(alpha: AppTheme.isDark ? 0.14 : 0.06),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isBuy ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: isBuy ? AppTheme.emerald : AppTheme.rose,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (trade['symbol'] as String? ?? '').split(':').last,
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        date != null
                            ? '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                            : '',
                        style: TextStyle(
                            color: AppTheme.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isBuy
                            ? AppTheme.emerald.withValues(alpha: 0.13)
                            : AppTheme.rose.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isBuy ? AppTheme.emerald.withValues(alpha: 0.25) : AppTheme.rose.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        isBuy ? 'BUY' : 'SELL',
                        style: TextStyle(
                            color: isBuy ? AppTheme.emerald : AppTheme.rose,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatINR((trade['total'] as num?)?.toDouble() ?? 0),
                      style: TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    Text(
                      '${trade['amount']} units @ ${formatINR((trade['price'] as num?)?.toDouble() ?? 0)}',
                      style: TextStyle(
                          color: AppTheme.onSurfaceVariant, fontSize: 10),
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
}

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
        vsync: this, duration: const Duration(milliseconds: 420));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(
        Duration(milliseconds: widget.delay), () { if (mounted) _ctrl.forward(); });
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
