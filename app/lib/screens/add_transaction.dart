// lib/screens/add_transaction.dart
import 'package:flutter/material.dart';
import '../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  TransactionCategory _selectedCategory = TransactionCategory.other;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Type selector
              DropdownButtonFormField<TransactionType>(
                value: _selectedType,
                items:
                    TransactionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),

              // Category selector
              DropdownButtonFormField<TransactionCategory>(
                value: _selectedCategory,
                items:
                    TransactionCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.toString().split('.').last),
                      );
                    }).toList(),
                onChanged:
                    (value) => setState(() => _selectedCategory = value!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),

              // Amount input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),

              // Date picker
              ListTile(
                title: const Text('Date'),
                subtitle: Text(_selectedDate.toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),

              // Save button
              ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        amount: double.parse(_amountController.text),
        type: _selectedType,
        category: _selectedCategory,
        date: _selectedDate,
        profileId:
            '1', // Replace with the actual profile ID from your authentication or state management
      );

      Navigator.pop(context, transaction);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
