import 'package:drift/drift.dart';
import '../data/app_database.dart';
import '../models/category.dart' as dom_cat;

class CategorySeeder {
  static const _defaultCategories = [
    // Income Categories
    {
      'name': 'Salary',
      'iconKey': '0xe8f3', // AttachMoney
      'colorKey': '#4CAF50',
      'isExpense': false,
      'sortOrder': 0,
    },
    {
      'name': 'Business',
      'iconKey': '0xe0af', // Business
      'colorKey': '#2196F3',
      'isExpense': false,
      'sortOrder': 1,
    },
    {
      'name': 'Investments',
      'iconKey': '0xe8e1', // TrendingUp
      'colorKey': '#9C27B0',
      'isExpense': false,
      'sortOrder': 2,
    },
    {
      'name': 'Freelance',
      'iconKey': '0xe8f9', // Computer
      'colorKey': '#FF9800',
      'isExpense': false,
      'sortOrder': 3,
    },
    {
      'name': 'Other Income',
      'iconKey': '0xe5c8', // Done
      'colorKey': '#607D8B',
      'isExpense': false,
      'sortOrder': 4,
    },

    // Expense Categories
    {
      'name': 'Food & Dining',
      'iconKey': '0xe556', // Restaurant
      'colorKey': '#F44336',
      'isExpense': true,
      'sortOrder': 0,
    },
    {
      'name': 'Transportation',
      'iconKey': '0xe531', // DirectionsCar
      'colorKey': '#3F51B5',
      'isExpense': true,
      'sortOrder': 1,
    },
    {
      'name': 'Housing & Utilities',
      'iconKey': '0xe88a', // Home
      'colorKey': '#009688',
      'isExpense': true,
      'sortOrder': 2,
    },
    {
      'name': 'Healthcare',
      'iconKey': '0xe548', // LocalHospital
      'colorKey': '#E91E63',
      'isExpense': true,
      'sortOrder': 3,
    },
    {
      'name': 'Education',
      'iconKey': '0xe80c', // School
      'colorKey': '#FF5722',
      'isExpense': true,
      'sortOrder': 4,
    },
    {
      'name': 'Shopping',
      'iconKey': '0xe8cc', // ShoppingCart
      'colorKey': '#795548',
      'isExpense': true,
      'sortOrder': 5,
    },
    {
      'name': 'Entertainment',
      'iconKey': '0xe87f', // MovieCreation
      'colorKey': '#673AB7',
      'isExpense': true,
      'sortOrder': 6,
    },
    {
      'name': 'Bills & Utilities',
      'iconKey': '0xe870', // Receipt
      'colorKey': '#00BCD4',
      'isExpense': true,
      'sortOrder': 7,
    },
    {
      'name': 'Personal Care',
      'iconKey': '0xe7fd', // Person
      'colorKey': '#8BC34A',
      'isExpense': true,
      'sortOrder': 8,
    },
    {
      'name': 'Other Expenses',
      'iconKey': '0xe5c9', // MoreHoriz
      'colorKey': '#9E9E9E',
      'isExpense': true,
      'sortOrder': 9,
    },
  ];

  final AppDatabase _db;

  CategorySeeder(this._db);

  /// Seed default categories for a profile if none exist
  Future<void> seedDefaultCategories(int profileId) async {
    // Check if profile has any categories
    final existing = await _db.getCategories(profileId);
    if (existing.isNotEmpty) return; // Don't seed if categories exist

    // Create default categories
    for (final cat in _defaultCategories) {
      final companion = CategoriesCompanion.insert(
        name: cat['name'] as String,
        iconKey: Value(cat['iconKey'] as String),
        colorKey: Value(cat['colorKey'] as String),
        isExpense: Value(cat['isExpense'] as bool),
        sortOrder: Value(cat['sortOrder'] as int),
        profileId: profileId,
      );
      await _db.insertCategory(companion);
    }
  }

  /// Create a single category
  Future<dom_cat.Category> createCategory({
    required String name,
    required String iconKey,
    required String colorKey,
    required bool isExpense,
    required int sortOrder,
    required int profileId,
  }) async {
    final companion = CategoriesCompanion.insert(
      name: name,
      iconKey: Value(iconKey),
      colorKey: Value(colorKey),
      isExpense: Value(isExpense),
      sortOrder: Value(sortOrder),
      profileId: profileId,
    );
    
    final id = await _db.insertCategory(companion);
    return dom_cat.Category(
      id: id.toString(),
      name: name,
      iconKey: iconKey,
      colorKey: colorKey,
      isExpense: isExpense,
      sortOrder: sortOrder,
      profileId: profileId.toString(),
    );
  }
}
