import 'dart:math' as math;
import 'package:intl/intl.dart';

/// Enhanced SMS transaction extractor with platform detection and reference extraction
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

  /// Matches common transaction reference patterns
  static final RegExp referencePatterns = RegExp(
    r'\b(?:ref(?:erence)?|transaction|receipt|code|id)[:\s]*([A-Z0-9]{6,})\b',
    caseSensitive: false,
  );

  /// Financial platform keywords with their standardized names
  static const Map<String, String> platformKeywords = {
    // Mobile Money
    'mpesa': 'M-PESA',
    'm-pesa': 'M-PESA',
    'safaricom': 'M-PESA',
    'airtel money': 'Airtel Money',
    'airtel': 'Airtel Money',
    't-kash': 'T-Kash',
    'tkash': 'T-Kash',
    'equitel': 'Equitel',
    
    // Banks
    'kcb': 'KCB Bank',
    'equity': 'Equity Bank',
    'cooperative': 'Co-operative Bank',
    'co-op': 'Co-operative Bank',
    'coop': 'Co-operative Bank',
    'absa': 'Absa Bank',
    'dtb': 'Diamond Trust Bank',
    'family': 'Family Bank',
    'ncba': 'NCBA Bank',
    'diamond': 'Diamond Trust Bank',
    'chase': 'Chase Bank',
    'gulf': 'Gulf African Bank',
    'prime': 'Prime Bank',
    'citibank': 'Citibank',
    'barclays': 'Absa Bank', // Rebranded
    'standard': 'Standard Chartered',
    'stanchart': 'Standard Chartered',
    'i&m': 'I&M Bank',
    'crdb': 'CRDB Bank',
    'victoria': 'Victoria Bank',
    'sidian': 'Sidian Bank',
    'guaranty': 'Guaranty Trust Bank',
    'gtbank': 'Guaranty Trust Bank',
    
    // SACCOs
    'stima': 'Stima SACCO',
    'mwalimu': 'Mwalimu SACCO',
    'kenya police': 'Kenya Police SACCO',
    'ukulima': 'Ukulima SACCO',
    'harambee': 'Harambee SACCO',
    
    // MFIs
    'faulu': 'Faulu Microfinance',
    'kwft': 'Kenya Women Finance Trust',
    'smep': 'SMEP Microfinance',
  };

  /// Extracts the financial platform/service provider from the message
  String extractPlatform(String message, {String? sender}) {
    // First try the sender field if provided
    if (sender != null && sender.isNotEmpty) {
      final senderLower = sender.toLowerCase();
      for (final entry in platformKeywords.entries) {
        if (senderLower.contains(entry.key)) {
          return entry.value;
        }
      }
    }
    
    // Then try the message body
    final messageLower = message.toLowerCase();
    for (final entry in platformKeywords.entries) {
      if (messageLower.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // If no specific platform found, check for generic "bank" keyword
    if (messageLower.contains('bank') || (sender?.toLowerCase().contains('bank') ?? false)) {
      return 'Bank';
    }
    
    return 'Unknown'; // Default fallback
  }

  /// Extracts a transaction reference/code from the message
  String extractReference(String message) {
    // Try to find explicit reference pattern
    final match = referencePatterns.firstMatch(message);
    if (match != null && match.groupCount >= 1) {
      final ref = match.group(1);
      if (ref != null && ref.isNotEmpty) {
        return ref;
      }
    }
    
    // Look for M-PESA specific transaction codes (format: XXXXXXXXXX - 10 alphanumeric)
    final mpesaCodePattern = RegExp(r'\b([A-Z0-9]{10})\b');
    final mpesaMatch = mpesaCodePattern.firstMatch(message);
    if (mpesaMatch != null) {
      final code = mpesaMatch.group(1);
      if (code != null) {
        return code;
      }
    }
    
    // Fallback: Use first 100 characters of the message as reference
    return message.length > 100 
        ? message.substring(0, 100).trim() 
        : message.trim();
  }

  /// Extracts the first amount found in [message] and returns
  /// its minor-unit representation (e.g. cents for 2 fractionDigits).
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
