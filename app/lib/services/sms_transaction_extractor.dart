import 'dart:math' as math;
import 'package:intl/intl.dart';

/// A simple SMS transaction extractor that identifies amounts and dates.
class SmsTransactionExtractor {
  /// Matches currency amounts like "123.45", "123.4", "1,234.56", etc.
  static final RegExp amountPattern = RegExp(
    r"\b\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?\b",
  );
  
  /// Matches currency identifiers for Kenyan Shillings (KES or Ksh), case-insensitive
  static final RegExp currencyPattern = RegExp(r"\b(?:KES|Ksh)\b", caseSensitive: false);
  
  /// Matches recipient patterns like "sent to X", "received from Y", "paid to Z"
  static final RegExp recipientPattern = RegExp(
    r"\b(?:sent to|received from|paid to)\s+([A-Za-z ]+?)(?=[,\.\s]|$)",
    caseSensitive: false,
  );

  /// Matches dates in formats DD/MM/YYYY, MM-DD-YYYY, or YYYY-MM-DD.
  static final RegExp datePattern = RegExp(
    r'\b(?:\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}|\d{4}-\d{2}-\d{2})\b',
  );

  /// Extracts the first amount found in [message] and returns
  /// its minor‐unit representation (e.g. cents for 2 fractionDigits).
  int extractAmountMinor(String message, {int fractionDigits = 2}) {
  // Only extract if currency code present
  if (!currencyPattern.hasMatch(message)) return 0;
  // Find first amount occurrence
  final m = amountPattern.firstMatch(message);
    if (m == null) return 0;
    // Remove thousands separators then parse
    final raw = m.group(0)!.replaceAll(',', '');
    final value = double.tryParse(raw) ?? 0.0;
    return (value * math.pow(10, fractionDigits)).round();
  }

  /// Extracts the first date found in [message].
  /// Returns null if no date parseable.
  DateTime? extractDate(String message) {
    final m = datePattern.firstMatch(message);
    if (m == null) return null;
    final s = m.group(0)!;
    try {
      if (s.contains('/')) {
        // Try dd/MM/yyyy first
        return DateFormat('dd/MM/yyyy').parseLoose(s);
      } else if (s.contains('-')) {
        // ISO first (YYYY-MM-DD), then MM-dd-yyyy
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
          return DateTime.parse(s);
        }
        return DateFormat('MM-dd-yyyy').parseLoose(s);
      }
    } catch (_) {
      // ignore parse errors
    }
    return null;
  }
  
  /// Extracts the recipient or payee name from [message], if any
  String? extractRecipient(String message) {
    final m = recipientPattern.firstMatch(message);
    return m?.group(1)?.trim();
  }
}