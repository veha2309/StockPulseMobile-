import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/market_provider.dart';
import '../theme/app_theme.dart';

enum IndicatorType { sma, ema, bollingerBands }

class ChartIndicator {
  final IndicatorType type;
  final int period;
  final Color color;
  final double multiplier;

  const ChartIndicator({
    required this.type,
    this.period = 20,
    this.color = Colors.cyanAccent,
    this.multiplier = 2.0,
  });
}

class ComputedIndicator {
  final ChartIndicator config;
  final List<double?> mainLine;
  final List<double?> upperLine;
  final List<double?> lowerLine;

  ComputedIndicator({
    required this.config,
    required this.mainLine,
    this.upperLine = const [],
    this.lowerLine = const [],
  });
}

class CandleChart extends StatefulWidget {
  final List<CandleData> data;
  final double height;
  final bool isIntraday;
  final List<ChartIndicator> activeIndicators;

  const CandleChart({
    super.key,
    required this.data,
    this.height = 350,
    this.isIntraday = false,
    this.activeIndicators = const [],
  });

  @override
  State<CandleChart> createState() => _CandleChartState();
}

class _CandleChartState extends State<CandleChart> {
  static const double _yAxisWidth = 58.0;
  static const double _xAxisHeight = 22.0;
  static const double _topPad = 12.0;

  // X zoom: number of candles visible
  double _visibleCandles = 0;
  // Pan: leftmost visible candle index (fractional)
  double _panOffset = 0.0;
  // Y zoom: >1 = tighter price range
  double _yZoom = 1.0;

  // 1-finger pan tracking
  double _panStartOffset = 0.0;
  double _panStartX = 0.0;

  // Axis-drag zoom tracking
  double _axisDragStartX = 0.0;
  double _axisDragStartY = 0.0;
  double _axisDragStartVisible = 0.0;
  double _axisDragStartYZoom = 1.0;

  // Crosshair
  int? _hoverIndex;
  double? _hoverPrice;
  bool _crosshairActive = false;

  List<ComputedIndicator> _computeIndicators() {
    final results = <ComputedIndicator>[];
    for (var ind in widget.activeIndicators) {
      if (widget.data.length < ind.period) continue;
      final mainVals = List<double?>.filled(widget.data.length, null);

      if (ind.type == IndicatorType.sma) {
        for (int i = ind.period - 1; i < widget.data.length; i++) {
          double sum = 0;
          for (int j = 0; j < ind.period; j++) sum += widget.data[i - j].close;
          mainVals[i] = sum / ind.period;
        }
        results.add(ComputedIndicator(config: ind, mainLine: mainVals));
      } else if (ind.type == IndicatorType.ema) {
        final k = 2 / (ind.period + 1);
        double sum = 0;
        for (int j = 0; j < ind.period; j++) sum += widget.data[ind.period - 1 - j].close;
        mainVals[ind.period - 1] = sum / ind.period;
        for (int i = ind.period; i < widget.data.length; i++) {
          mainVals[i] = (widget.data[i].close - mainVals[i - 1]!) * k + mainVals[i - 1]!;
        }
        results.add(ComputedIndicator(config: ind, mainLine: mainVals));
      } else if (ind.type == IndicatorType.bollingerBands) {
        final upper = List<double?>.filled(widget.data.length, null);
        final lower = List<double?>.filled(widget.data.length, null);
        for (int i = ind.period - 1; i < widget.data.length; i++) {
          double sum = 0;
          for (int j = 0; j < ind.period; j++) sum += widget.data[i - j].close;
          final sma = sum / ind.period;
          mainVals[i] = sma;
          double vSum = 0;
          for (int j = 0; j < ind.period; j++) vSum += pow(widget.data[i - j].close - sma, 2);
          final sd = sqrt(vSum / ind.period);
          upper[i] = sma + sd * ind.multiplier;
          lower[i] = sma - sd * ind.multiplier;
        }
        results.add(ComputedIndicator(config: ind, mainLine: mainVals, upperLine: upper, lowerLine: lower));
      }
    }
    return results;
  }

  ({double hi, double lo}) _baseRange(List<ComputedIndicator> computed) {
    double hi = widget.data.map((e) => e.high).reduce(max);
    double lo = widget.data.map((e) => e.low).reduce(min);
    for (var ind in computed) {
      for (var v in ind.mainLine) { if (v != null) { hi = max(hi, v); lo = min(lo, v); } }
      for (var v in ind.upperLine) { if (v != null) hi = max(hi, v); }
      for (var v in ind.lowerLine) { if (v != null) lo = min(lo, v); }
    }
    final pad = (hi - lo) * 0.12;
    return (hi: hi + pad, lo: lo - pad);
  }

  double _clampPan(double pan, double visibleCandles) =>
      pan.clamp(0.0, max(0.0, widget.data.length - visibleCandles));

  // ── 1-finger pan on plot area ──────────────────────────
  void _onPanStart(DragStartDetails d) {
    _panStartOffset = _panOffset;
    _panStartX = d.localPosition.dx;
  }

  void _onPanUpdate(DragUpdateDetails d, double plotW) {
    if (_crosshairActive) return;
    final step = plotW / _visibleCandles;
    final dx = _panStartX - d.localPosition.dx;
    setState(() => _panOffset = _clampPan(_panStartOffset + dx / step, _visibleCandles));
  }

  // ── X-axis drag: left = zoom in (fewer candles), right = zoom out ──
  void _onXAxisDragStart(DragStartDetails d) {
    _axisDragStartX = d.localPosition.dx;
    _axisDragStartVisible = _visibleCandles;
  }

  void _onXAxisDragUpdate(DragUpdateDetails d) {
    final dx = d.localPosition.dx - _axisDragStartX;
    // Each 4px = 1 candle change; drag right = more candles (zoom out)
    final delta = dx / 4;
    setState(() {
      _visibleCandles = (_axisDragStartVisible + delta)
          .clamp(5.0, widget.data.length.toDouble());
      _panOffset = _clampPan(_panOffset, _visibleCandles);
    });
  }

  // ── Y-axis drag: drag up = zoom in (tighter range), drag down = zoom out ──
  void _onYAxisDragStart(DragStartDetails d) {
    _axisDragStartY = d.localPosition.dy;
    _axisDragStartYZoom = _yZoom;
  }

  void _onYAxisDragUpdate(DragUpdateDetails d) {
    final dy = _axisDragStartY - d.localPosition.dy;
    setState(() {
      _yZoom = (_axisDragStartYZoom + dy / 60).clamp(0.5, 8.0);
    });
  }

  void _activateCrosshair(Offset local, double plotW, double plotH,
      double minP, double maxP, double step) {
    final idx = (_panOffset + local.dx / step).floor().clamp(0, widget.data.length - 1);
    final c = widget.data[idx];

    final prices = [c.open, c.high, c.low, c.close];
    double snapped = prices[0];
    double minDist = double.infinity;
    for (final p in prices) {
      final py = _topPad + plotH - ((p - minP) / (maxP - minP) * plotH);
      final dist = (local.dy - py).abs();
      if (dist < minDist) { minDist = dist; snapped = p; }
    }

    if (idx != _hoverIndex) HapticFeedback.selectionClick();
    setState(() {
      _crosshairActive = true;
      _hoverIndex = idx;
      _hoverPrice = snapped;
    });
  }

  void _clearCrosshair() => setState(() {
    _crosshairActive = false;
    _hoverIndex = null;
    _hoverPrice = null;
  });

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(child: Text('No data', style: TextStyle(color: AppTheme.onSurfaceVariant))),
      );
    }

    final isDark = AppTheme.isDark;
    final gridColor = isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.06);
    final labelColor = isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.45);
    final tooltipBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final tooltipBorder = isDark ? AppTheme.borderColor : Colors.black.withValues(alpha: 0.12);

    return LayoutBuilder(builder: (context, constraints) {
      final canvasW = constraints.maxWidth;
      final canvasH = (constraints.maxHeight.isFinite && constraints.maxHeight > 0)
          ? constraints.maxHeight
          : widget.height;
      final plotW = canvasW - _yAxisWidth;
      final plotH = canvasH - _xAxisHeight - _topPad;

      if (_visibleCandles == 0) {
        _visibleCandles = widget.data.length.toDouble();
        _panOffset = max(0.0, widget.data.length - _visibleCandles);
      }

      final step = plotW / _visibleCandles;
      final computed = _computeIndicators();
      final base = _baseRange(computed);

      final mid = (base.hi + base.lo) / 2;
      final halfRange = (base.hi - base.lo) / 2 / _yZoom;
      final minP = mid - halfRange;
      final maxP = mid + halfRange;

      return SizedBox(
        width: canvasW,
        height: canvasH,
        child: Stack(
          children: [
            // ── Full chart painter ───────────────────────────
            CustomPaint(
              size: Size(canvasW, canvasH),
              painter: _ChartPainter(
                data: widget.data,
                computed: computed,
                isIntraday: widget.isIntraday,
                plotW: plotW,
                plotH: plotH,
                topPad: _topPad,
                yAxisWidth: _yAxisWidth,
                xAxisHeight: _xAxisHeight,
                minPrice: minP,
                maxPrice: maxP,
                panOffset: _panOffset,
                visibleCandles: _visibleCandles,
                hoverIndex: _hoverIndex,
                hoverPrice: _hoverPrice,
                gridColor: gridColor,
                labelColor: labelColor,
              ),
              child: (_crosshairActive && _hoverIndex != null && _hoverPrice != null)
                  ? _buildTooltip(plotW, plotH, minP, maxP, step, tooltipBg, tooltipBorder)
                  : null,
            ),
            // ── Plot area: pan + long-press crosshair ────────
            Positioned(
              left: 0, top: 0,
              width: plotW, height: plotH + _topPad,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _onPanStart,
                onHorizontalDragUpdate: (d) => _onPanUpdate(d, plotW),
                onLongPressStart: (d) => _activateCrosshair(d.localPosition, plotW, plotH, minP, maxP, step),
                onLongPressMoveUpdate: (d) => _activateCrosshair(d.localPosition, plotW, plotH, minP, maxP, step),
                onLongPressEnd: (_) => _clearCrosshair(),
                onLongPressCancel: _clearCrosshair,
              ),
            ),
            // ── X-axis strip: horizontal drag to zoom X ──────
            Positioned(
              left: 0, top: plotH + _topPad,
              width: plotW, height: _xAxisHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _onXAxisDragStart,
                onHorizontalDragUpdate: _onXAxisDragUpdate,
              ),
            ),
            // ── Y-axis strip: vertical drag to zoom Y ────────
            Positioned(
              left: plotW, top: 0,
              width: _yAxisWidth, height: plotH + _topPad,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: _onYAxisDragStart,
                onVerticalDragUpdate: _onYAxisDragUpdate,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTooltip(double plotW, double plotH, double minP, double maxP,
      double step, Color bg, Color border) {
    final idx = _hoverIndex!;
    final candle = widget.data[idx];
    const tooltipW = 92.0;
    const tooltipH = 82.0;

    final cx = (idx - _panOffset) * step + step / 2;
    double left = cx + 12;
    if (left + tooltipW > plotW) left = cx - tooltipW - 12;
    left = left.clamp(0.0, plotW - tooltipW);

    final snappedY = _topPad + plotH - ((_hoverPrice! - minP) / (maxP - minP) * plotH);
    double top = snappedY - tooltipH / 2;
    top = top.clamp(_topPad, _topPad + plotH - tooltipH);

    final dateStr = widget.isIntraday
        ? '${candle.date.hour.toString().padLeft(2, '0')}:${candle.date.minute.toString().padLeft(2, '0')}'
        : '${candle.date.day}/${candle.date.month}/${candle.date.year.toString().substring(2)}';

    return Stack(children: [
      Positioned(
        left: left, top: top,
        child: Container(
          width: tooltipW,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dateStr, style: TextStyle(color: AppTheme.primary, fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _tRow('O', candle.open),
              _tRow('H', candle.high),
              _tRow('L', candle.low),
              _tRow('C', candle.close),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _tRow(String l, double v) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('$l ', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 9)),
      Text('₹${v.toStringAsFixed(1)}', style: TextStyle(color: AppTheme.onSurface, fontSize: 9, fontWeight: FontWeight.bold)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _ChartPainter extends CustomPainter {
  final List<CandleData> data;
  final List<ComputedIndicator> computed;
  final bool isIntraday;
  final double plotW, plotH, topPad, yAxisWidth, xAxisHeight;
  final double minPrice, maxPrice;
  final double panOffset, visibleCandles;
  final int? hoverIndex;
  final double? hoverPrice;
  final Color gridColor, labelColor;

  _ChartPainter({
    required this.data,
    required this.computed,
    required this.isIntraday,
    required this.plotW, required this.plotH,
    required this.topPad, required this.yAxisWidth, required this.xAxisHeight,
    required this.minPrice, required this.maxPrice,
    required this.panOffset, required this.visibleCandles,
    required this.hoverIndex, required this.hoverPrice,
    required this.gridColor, required this.labelColor,
  });

  double get _range => maxPrice - minPrice;
  double get _step => plotW / visibleCandles;

  double _px(int i) => (i - panOffset) * _step + _step / 2;
  double _py(double price) => topPad + plotH - ((price - minPrice) / _range * plotH);

  @override
  void paint(Canvas canvas, Size size) {
    if (_range == 0 || data.isEmpty) return;

    final gridPaint = Paint()..color = gridColor..strokeWidth = 0.5;
    final labelStyle = TextStyle(color: labelColor, fontSize: 9);

    // ── Horizontal grid + Y labels ────────────────────────
    const gridLines = 6;
    for (int i = 0; i <= gridLines; i++) {
      final y = topPad + plotH * i / gridLines;
      canvas.drawLine(Offset(0, y), Offset(plotW, y), gridPaint);
      final price = maxPrice - (_range * i / gridLines);
      _drawText(canvas, '₹${price.toStringAsFixed(0)}', Offset(plotW + 4, y - 6), labelStyle);
    }

    // ── Vertical grid + X labels ──────────────────────────
    final firstVisible = panOffset.floor();
    final lastVisible = min(data.length - 1, (panOffset + visibleCandles).ceil());
    final labelInterval = max(1, ((lastVisible - firstVisible) / 5).ceil());

    for (int i = firstVisible; i <= lastVisible; i += labelInterval) {
      final x = _px(i);
      if (x < 0 || x > plotW) continue;
      canvas.drawLine(Offset(x, topPad), Offset(x, topPad + plotH), gridPaint);
      final label = isIntraday
          ? '${data[i].date.hour.toString().padLeft(2, '0')}:${data[i].date.minute.toString().padLeft(2, '0')}'
          : '${data[i].date.day}/${data[i].date.month}';
      _drawText(canvas, label, Offset(x - 12, topPad + plotH + 5), labelStyle);
    }

    // ── Clip plot area ────────────────────────────────────
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, topPad, plotW, plotH));

    // ── Candles ───────────────────────────────────────────
    final candleW = _step * 0.6;
    for (int i = firstVisible; i <= lastVisible; i++) {
      final cx = _px(i);
      if (cx + candleW < 0 || cx - candleW > plotW) continue;

      final c = data[i];
      final isBull = c.close >= c.open;
      final color = isBull ? AppTheme.primary : AppTheme.secondary;

      canvas.drawLine(
        Offset(cx, _py(c.high)),
        Offset(cx, _py(c.low)),
        Paint()..color = color.withValues(alpha: 0.7)..strokeWidth = 1.2,
      );

      final bodyTop = min(_py(c.open), _py(c.close));
      final bodyBot = max(_py(c.open), _py(c.close));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - candleW / 2, bodyTop, cx + candleW / 2, max(bodyBot, bodyTop + 1.5)),
          const Radius.circular(1.5),
        ),
        Paint()..color = color..style = PaintingStyle.fill,
      );
    }

    // ── Indicators ────────────────────────────────────────
    for (var ind in computed) {
      if (ind.config.type == IndicatorType.bollingerBands) {
        _drawLine(canvas, ind.upperLine, ind.config.color.withValues(alpha: 0.35), 1.2);
        _drawLine(canvas, ind.lowerLine, ind.config.color.withValues(alpha: 0.35), 1.2);
      }
      _drawLine(canvas, ind.mainLine, ind.config.color, 1.8);
    }

    canvas.restore();

    // ── Crosshair ─────────────────────────────────────────
    if (hoverIndex != null && hoverPrice != null) {
      final cx = _px(hoverIndex!);
      final cy = _py(hoverPrice!).clamp(topPad, topPad + plotH);
      final crossPaint = Paint()
        ..color = AppTheme.primary.withValues(alpha: 0.55)
        ..strokeWidth = 0.8;

      if (cx >= 0 && cx <= plotW) {
        canvas.drawLine(Offset(cx, topPad), Offset(cx, topPad + plotH), crossPaint);
      }
      canvas.drawLine(Offset(0, cy), Offset(plotW, cy), crossPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '₹${hoverPrice!.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final badgeRect = Rect.fromLTWH(plotW + 2, cy - 9, tp.width + 10, 18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
        Paint()..color = AppTheme.primary,
      );
      tp.paint(canvas, Offset(badgeRect.left + 5, badgeRect.top + (18 - tp.height) / 2));
    }
  }

  void _drawLine(Canvas canvas, List<double?> values, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final path = Path();
    bool started = false;
    for (int i = 0; i < values.length; i++) {
      if (values[i] == null) { started = false; continue; }
      final x = _px(i);
      final y = _py(values[i]!);
      if (!started) { path.moveTo(x, y); started = true; }
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.hoverIndex != hoverIndex ||
      old.hoverPrice != hoverPrice ||
      old.panOffset != panOffset ||
      old.visibleCandles != visibleCandles ||
      old.minPrice != minPrice ||
      old.maxPrice != maxPrice ||
      old.plotH != plotH ||
      old.data != data;
}
