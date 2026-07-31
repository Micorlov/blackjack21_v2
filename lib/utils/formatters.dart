/// Thousands-separated integer formatting, equivalent to JS `toLocaleString('en-US')`.
String formatChips(num n) {
  final rounded = n.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return (rounded < 0 ? '-' : '') + buffer.toString();
}

/// Signed chip delta, e.g. "+$250" or "-$40".
String formatSignedChips(num n) {
  final sign = n >= 0 ? '+' : '−';
  return '$sign\$${formatChips(n.abs())}';
}
