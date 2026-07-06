import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CandleData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}

class OptionContract {
  final String contractSymbol;
  final double strike;
  final int expiration;
  final double lastPrice;
  final double bid;
  final double ask;
  final double change;
  final bool inTheMoney;
  // Greeks (Black-Scholes approximations)
  final double delta;
  final double gamma;
  final double theta;  // per day
  final double vega;   // per 1% IV move
  final double iv;     // implied volatility %

  OptionContract({
    required this.contractSymbol,
    required this.strike,
    required this.expiration,
    required this.lastPrice,
    required this.bid,
    required this.ask,
    required this.change,
    required this.inTheMoney,
    this.delta = 0.5,
    this.gamma = 0.01,
    this.theta = -1.0,
    this.vega = 5.0,
    this.iv = 20.0,
  });
}

class MarketProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  double underlyingPrice = 0;
  List<OptionContract> calls = [];
  List<OptionContract> puts = [];
  List<CandleData> chartData = [];
  List<CandleData> intradayChartData = [];
  bool isLoading = false;
  String currentSymbol = "NSE:NIFTY50";
  List<String> watchlist = [
    "NSE:RELIANCE",
    "NSE:TCS",
    "NSE:HDFCBANK",
    "NSE:INFY",
  ];

  Future<void> toggleFavorite(String symbol) async {
    if (watchlist.contains(symbol)) {
      watchlist = watchlist.where((s) => s != symbol).toList();
    } else {
      watchlist = [...watchlist, symbol];
    }
    notifyListeners();
    try {
      await _supabase.from('app_config').upsert({
        'key': 'global_favorites',
        'value': watchlist,
      });
    } catch (e) {
      debugPrint("STP ERROR: Failed to persist favorites: $e");
    }
  }

  MarketProvider() {
    // It's safer to check if Supabase is initialized before using it.
    // The actual initialization should be awaited in main.dart
    if (Supabase.instance.client.auth.currentUser != null) {
      _init();
    }
  }

  Future<void> _init() async {
    debugPrint("STP: MarketProvider initializing watchlist...");
    try {
      final res = await _supabase
          .from('app_config')
          .select('value')
          .eq('key', 'global_favorites')
          .maybeSingle();

      if (res != null && res['value'] != null) {
        final dynamic value = res['value'];
        debugPrint("STP: Global favorites raw value: $value");

        List<String> fetchedWatchlist = [];
        if (value is List) {
          fetchedWatchlist = value.map((e) => e.toString()).toList();
        } else if (value is String) {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            fetchedWatchlist = decoded.map((e) => e.toString()).toList();
          }
        }

        if (fetchedWatchlist.isNotEmpty) {
          watchlist = fetchedWatchlist;
          debugPrint("STP: Watchlist updated with ${watchlist.length} items.");
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("STP ERROR: Failed to load global favorites: $e");
    } finally {
      debugPrint("STP: Final watchlist: $watchlist");
    }
  }

  Future<void> fetchMarketData(String symbol) async {
    currentSymbol = symbol;
    isLoading = true;
    notifyListeners();

    try {
      final yfSymbol = _toYahooSymbol(symbol);

      // Fetch 1 month of daily data for candlesticks
      final monthlyUrl = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$yfSymbol?interval=1d&range=1mo',
      );
      final intradayUrl = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$yfSymbol?interval=5m&range=1d',
      );

      final responses = await Future.wait([
        http.get(monthlyUrl, headers: {"User-Agent": "Mozilla/5.0"}),
        http.get(intradayUrl, headers: {"User-Agent": "Mozilla/5.0"}),
      ]);

      if (responses[0].statusCode == 200) {
        final data = jsonDecode(responses[0].body);
        final result = data['chart']['result'];
        if (result != null && result.isNotEmpty) {
          final quote = result[0]['indicators']['quote'][0];
          final timestamps = result[0]['timestamp'] as List<dynamic>;
          underlyingPrice = (result[0]['meta']['regularMarketPrice'] ?? 0)
              .toDouble();

          chartData = _parseCandles(timestamps, quote);
        }
      }

      if (responses[1].statusCode == 200) {
        final data = jsonDecode(responses[1].body);
        final result = data['chart']['result'];
        if (result != null && result.isNotEmpty) {
          final quote = result[0]['indicators']['quote'][0];
          final timestamps = result[0]['timestamp'] as List<dynamic>;
          intradayChartData = _parseCandles(timestamps, quote);
        }
      }

      if (underlyingPrice > 0) {
        _generateOptionsChain(symbol);
      }
    } catch (e) {
      debugPrint("Error fetching market data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<CandleData> _parseCandles(List<dynamic> timestamps, dynamic quote) {
    List<CandleData> candles = [];
    for (int i = 0; i < timestamps.length; i++) {
      if (quote['open'][i] != null &&
          quote['high'][i] != null &&
          quote['low'][i] != null &&
          quote['close'][i] != null) {
        candles.add(
          CandleData(
            date: DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
            open: (quote['open'][i]).toDouble(),
            high: (quote['high'][i]).toDouble(),
            low: (quote['low'][i]).toDouble(),
            close: (quote['close'][i]).toDouble(),
          ),
        );
      }
    }
    return candles;
  }

  String _toYahooSymbol(String symbol) {
    if (symbol.startsWith("NSE:")) return "${symbol.substring(4)}.NS";
    if (symbol.startsWith("BSE:")) return "${symbol.substring(4)}.BO";
    return symbol;
  }

  void _generateOptionsChain(String symbol) {
    final nseSymbol = symbol.replaceAll("NSE:", "").replaceAll("BSE:", "");
    final step = underlyingPrice > 3000
        ? 50
        : underlyingPrice > 1000
        ? 20
        : underlyingPrice < 200
        ? 5
        : 10;
    final baseStrike = (underlyingPrice / step).round() * step;

    final today = DateTime.now();
    final nextThursday = today.add(
      Duration(days: (DateTime.thursday - today.weekday + 7) % 7),
    );
    final expiryStr = DateFormat('dd-MMM-yyyy').format(nextThursday).toUpperCase();
    final expTs = nextThursday.millisecondsSinceEpoch ~/ 1000;
    // Time to expiry in years
    final dte = nextThursday.difference(today).inDays.clamp(1, 365);
    final T = dte / 365.0;

    calls.clear();
    puts.clear();

    for (int i = -12; i <= 12; i++) {
      final strike = (baseStrike + i * step).toDouble();
      if (strike <= 0) continue;

      final callGreeks = _blackScholes(underlyingPrice, strike, T, true);
      final putGreeks  = _blackScholes(underlyingPrice, strike, T, false);

      calls.add(OptionContract(
        contractSymbol: "$nseSymbol-$expiryStr-$strike-CE",
        strike: strike,
        expiration: expTs,
        lastPrice: callGreeks['price']!,
        bid: callGreeks['price']! * 0.98,
        ask: callGreeks['price']! * 1.02,
        change: 0,
        inTheMoney: underlyingPrice > strike,
        delta: callGreeks['delta']!,
        gamma: callGreeks['gamma']!,
        theta: callGreeks['theta']!,
        vega:  callGreeks['vega']!,
        iv:    callGreeks['iv']!,
      ));

      puts.add(OptionContract(
        contractSymbol: "$nseSymbol-$expiryStr-$strike-PE",
        strike: strike,
        expiration: expTs,
        lastPrice: putGreeks['price']!,
        bid: putGreeks['price']! * 0.98,
        ask: putGreeks['price']! * 1.02,
        change: 0,
        inTheMoney: strike > underlyingPrice,
        delta: putGreeks['delta']!,
        gamma: putGreeks['gamma']!,
        theta: putGreeks['theta']!,
        vega:  putGreeks['vega']!,
        iv:    putGreeks['iv']!,
      ));
    }
  }

  /// Black-Scholes pricing + Greeks.
  /// r = 6.5% (Indian risk-free rate), IV derived from moneyness.
  Map<String, double> _blackScholes(double S, double K, double T, bool isCall) {
    const double r = 0.065;
    // Estimate IV from moneyness: ATM ~20%, scales up for OTM
    final moneyness = (S - K).abs() / S;
    final iv = (0.20 + moneyness * 0.8).clamp(0.10, 0.90);

    final sqrtT = sqrt(T);
    final d1 = (log(S / K) + (r + 0.5 * iv * iv) * T) / (iv * sqrtT);
    final d2 = d1 - iv * sqrtT;

    final nd1  = _normCdf(isCall ? d1 : -d1);
    final nd2  = _normCdf(isCall ? d2 : -d2);
    final nd1n = _normPdf(d1); // standard normal PDF at d1

    final price = isCall
        ? (S * _normCdf(d1) - K * exp(-r * T) * _normCdf(d2)).clamp(0.01, S)
        : (K * exp(-r * T) * _normCdf(-d2) - S * _normCdf(-d1)).clamp(0.01, K);

    final delta = isCall ? _normCdf(d1) : _normCdf(d1) - 1.0;
    final gamma = nd1n / (S * iv * sqrtT);
    // Theta per calendar day
    final theta = (-(S * nd1n * iv) / (2 * sqrtT) - r * K * exp(-r * T) * (isCall ? _normCdf(d2) : _normCdf(-d2))) / 365.0;
    // Vega per 1% move in IV (divide by 100 since IV is decimal)
    final vega = S * nd1n * sqrtT / 100.0;

    return {
      'price': double.parse(price.toStringAsFixed(2)),
      'delta': double.parse(delta.toStringAsFixed(4)),
      'gamma': double.parse(gamma.toStringAsFixed(5)),
      'theta': double.parse(theta.toStringAsFixed(3)),
      'vega':  double.parse(vega.toStringAsFixed(3)),
      'iv':    double.parse((iv * 100).toStringAsFixed(1)),
    };
  }

  // Standard normal CDF via Horner's method approximation
  double _normCdf(double x) {
    if (x < -8.0) return 0.0;
    if (x >  8.0) return 1.0;
    const a1 =  0.254829592, a2 = -0.284496736, a3 =  1.421413741;
    const a4 = -1.453152027, a5 =  1.061405429, p  =  0.3275911;
    final sign = x < 0 ? -1 : 1;
    final ax = x.abs() / sqrt(2);
    final t = 1.0 / (1.0 + p * ax);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-ax * ax);
    return 0.5 * (1.0 + sign * y);
  }

  // Standard normal PDF
  double _normPdf(double x) => exp(-0.5 * x * x) / sqrt(2 * pi);
}
