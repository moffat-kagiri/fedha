import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../services/offline_data_service.dart';
import '../services/auth_service.dart';
import '../data/app_database.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = int.tryParse(authService.currentProfile?.id ?? '0') ?? 0;
      
      final categories = await dataService.getCategories(profileId);
      if (mounted) {
        setState(() {
          _categories = categories;
          _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addCategory(),
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ReorderableListView.builder(
            itemCount: _categories.length,
            onReorder: _reorderCategories,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return ListTile(
                key: Key(category.id),
                leading: Icon(
                  IconData(int.parse(category.iconKey), fontFamily: 'MaterialIcons'),
                  color: Color(int.parse(category.colorKey.replaceAll('#', '0xff'))),
                ),
                title: Text(category.name),
                subtitle: Text(category.isExpense ? 'Expense' : 'Income'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editCategory(category),
                ),
              );
            },
          ),
    );
  }

  Future<void> _addCategory() async {
    await _showCategoryDialog();
  }

  Future<void> _editCategory(Category category) async {
    await _showCategoryDialog(category);
  }

  Future<void> _showCategoryDialog([Category? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final iconController = TextEditingController(text: existing?.iconKey ?? 'default_icon');
    final colorController = TextEditingController(text: existing?.colorKey ?? '#2196F3');
    bool isExpense = existing?.isExpense ?? true;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Category' : 'Edit Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(labelText: 'Icon Key'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: 'Color (hex)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Type:'),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('Expense'),
                    selected: isExpense,
                    onSelected: (selected) {
                      isExpense = selected;
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Income'),
                    selected: !isExpense,
                    onSelected: (selected) {
                      isExpense = !selected;
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop({
                'name': nameController.text,
                'iconKey': iconController.text,
                'colorKey': colorController.text,
                'isExpense': isExpense,
              });
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (result != null) {
      final dataService = Provider.of<OfflineDataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileId = int.tryParse(authService.currentProfile?.id ?? '0') ?? 0;

      if (existing == null) {
        // Add new category
        final category = Category(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: result['name'],
          iconKey: result['iconKey'],
          colorKey: result['colorKey'],
          isExpense: result['isExpense'],
          sortOrder: _categories.length,
          profileId: profileId.toString(),
        );
        await dataService.saveCategory(category);
      } else {
        // Update existing category
        final updated = Category(
          id: existing.id,
          name: result['name'],
          iconKey: result['iconKey'],
          colorKey: result['colorKey'],
          isExpense: result['isExpense'],
          sortOrder: existing.sortOrder,
          profileId: existing.profileId,
        );
        await dataService.updateCategory(updated);
      }

      _loadCategories(); // Refresh list
    }
  }

  Future<void> _reorderCategories(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
      
      // Update sort orders
      for (var i = 0; i < _categories.length; i++) {
        _categories[i] = Category(
          id: _categories[i].id,
          name: _categories[i].name,
          iconKey: _categories[i].iconKey,
          colorKey: _categories[i].colorKey,
          isExpense: _categories[i].isExpense,
          sortOrder: i,
          profileId: _categories[i].profileId,
        );
      }
    });

    // Persist the new order
    final dataService = Provider.of<OfflineDataService>(context, listen: false);
    for (var category in _categories) {
      await dataService.updateCategory(category);
    }
  }
}
