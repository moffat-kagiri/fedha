import '../models/category.dart';

class ProfileTransactionUtils {
  static String getCategoryDisplayName(Category? category) {
    if (category == null) return 'Unknown';
    return category.name;
  }

  static String formatCurrency(double amount, {String currency = 'KES'}) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  static String getTransactionTypeDisplay(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return 'Income';
      case 'expense':
        return 'Expense';
      case 'transfer':
        return 'Transfer';
      default:
        return 'Unknown';
    }
  }
}
