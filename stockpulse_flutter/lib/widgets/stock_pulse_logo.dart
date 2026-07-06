import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StockPulseLogo extends StatelessWidget {
  final double size;
  final Color? color;
  
  const StockPulseLogo({
    super.key,
    this.size = 100,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: LogoPainter(color: color ?? AppTheme.primary),
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  final Color color;

  LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final bullPaint = Paint()..color = color..style = PaintingStyle.fill;
    final wickPaint = Paint()..color = color..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final bearPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    // Scale everything relative to a 96x96 design
    final s = size.width / 96.0;

    final candles = [
      (cx - 18.0 * s, cy + 8.0 * s,  cy - 4.0 * s,  cy + 14.0 * s, cy - 10.0 * s, true),
      (cx,            cy - 6.0 * s,  cy + 10.0 * s, cy - 14.0 * s, cy + 16.0 * s, false),
      (cx + 18.0 * s, cy + 4.0 * s,  cy - 12.0 * s, cy + 10.0 * s, cy - 18.0 * s, true),
    ];

    for (final (x, bodyTop, bodyBot, wickTop, wickBot, isBull) in candles) {
      canvas.drawLine(Offset(x, wickTop), Offset(x, wickBot), wickPaint);
      final body = Rect.fromLTRB(x - 5 * s, bodyTop, x + 5 * s, bodyBot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(body, Radius.circular(1.5 * s)),
        isBull ? bullPaint : bearPaint,
      );
    }

    final path = Path();
    final y0 = cy + 20.0 * s;
    path.moveTo(cx - 30 * s, y0);
    path.lineTo(cx - 18 * s, y0);
    path.lineTo(cx - 12 * s, y0 - 8 * s);
    path.lineTo(cx - 6 * s,  y0 + 6 * s);
    path.lineTo(cx,              y0 - 14 * s);
    path.lineTo(cx + 6 * s,  y0 + 4 * s);
    path.lineTo(cx + 12 * s, y0);
    path.lineTo(cx + 30 * s, y0);
    canvas.drawPath(path, linePaint);

    canvas.drawCircle(Offset(cx, y0 - 14 * s), 2.5 * s, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
