import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService extends ChangeNotifier {
  static const String _currencyKey = 'selected_currency';
  static const String _symbolKey = 'currency_symbol';
  
  String _currentCurrency = 'KES';
  String _currentSymbol = 'Ksh';

  static final Map<String, String> _currencySymbols = {
    'KES': 'Ksh',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'UGX': 'USh',
    'TZS': 'TSh',
    'RWF': 'RWF',
    'ETB': 'Br',
    'ZAR': 'R',
    'NGN': '₦',
    'GHS': '₵',
  };

  static final Map<String, String> _currencyNames = {
    'KES': 'Kenyan Shilling',
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'UGX': 'Ugandan Shilling',
    'TZS': 'Tanzanian Shilling',
    'RWF': 'Rwandan Franc',
    'ETB': 'Ethiopian Birr',
    'ZAR': 'South African Rand',
    'NGN': 'Nigerian Naira',
    'GHS': 'Ghanaian Cedi',
  };

  String get currentCurrency => _currentCurrency;
  String get currentSymbol => _currentSymbol;
  
  static Map<String, String> get availableCurrencies => _currencyNames;
  
  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCurrency = prefs.getString(_currencyKey) ?? 'KES';
    _currentSymbol = prefs.getString(_symbolKey) ?? 'Ksh';
    notifyListeners();
  }

  Future<void> setCurrency(String currencyCode) async {
    if (_currencySymbols.containsKey(currencyCode)) {
      _currentCurrency = currencyCode;
      _currentSymbol = _currencySymbols[currencyCode]!;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, _currentCurrency);
      await prefs.setString(_symbolKey, _currentSymbol);
      
      notifyListeners();
    }
  }

  String formatCurrency(double amount) {
    return '$_currentSymbol ${amount.toStringAsFixed(2)}';
  }

  static String formatCurrencyStatic(double amount, {String? currency}) {
    final symbol = currency != null ? _currencySymbols[currency] ?? 'Ksh' : 'Ksh';
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

  static String get defaultCurrency => 'KES';
  static String get defaultSymbol => 'Ksh';
}
