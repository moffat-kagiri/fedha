class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedType = 'IN'; // IN=Income, EX=Expense
  String _selectedCategory = 'OTHER';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'IN', child: Text('Income')),
                DropdownMenuItem(value: 'EX', child: Text('Expense')),
              ],
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            ElevatedButton(
              onPressed: _saveTransaction,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: double.parse(_amountController.text),
        type: _selectedType,
        category: _selectedCategory,
        date: DateTime.now(),
      );
      
      // Save to Hive
      Hive.box<Transaction>('transactions').add(transaction);
      Navigator.pop(context);
    }
  }
}