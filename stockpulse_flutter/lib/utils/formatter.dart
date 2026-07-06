String formatINR(double value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  return '$sign₹${_formatWithCommas(abs.toStringAsFixed(2))}';
}

String formatINRSigned(double value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '+';
  return '$sign₹${_formatWithCommas(abs.toStringAsFixed(2))}';
}

/// Formats a number string with Indian comma grouping (e.g. 1,00,000.00)
String _formatWithCommas(String numStr) {
  final parts = numStr.split('.');
  final integerPart = parts[0];
  final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

  if (integerPart.length <= 3) return '$integerPart$decimalPart';

  // Last 3 digits, then groups of 2 (Indian numbering)
  final buf = StringBuffer();
  final last3 = integerPart.substring(integerPart.length - 3);
  final rest = integerPart.substring(0, integerPart.length - 3);

  // Insert commas every 2 digits from the right of 'rest'
  for (int i = 0; i < rest.length; i++) {
    buf.write(rest[i]);
    final remaining = rest.length - 1 - i;
    if (remaining > 0 && remaining % 2 == 0) {
      buf.write(',');
    }
  }
  buf.write(',');
  buf.write(last3);
  buf.write(decimalPart);
  return buf.toString();
}
