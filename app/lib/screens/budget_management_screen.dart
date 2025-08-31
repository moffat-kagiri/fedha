import 'package:flutter/material.dart' hide Column;
import 'package:drift/drift.dart';
import 'package:provider/provider.dart';
import 'package:fedha/data/app_database.dart';

class BudgetManagementScreen extends StatefulWidget {
  @override
  _BudgetManagementScreenState createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  late AppDatabase _db;
  
  @override
  void initState() {
    super.initState();
    _db = Provider.of<AppDatabase>(context, listen: false);
  }

  Widget _buildBudgetCard(Budget budget) {
    return Card(
      child: ListTile(
        title: Text(budget.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Limit: ${budget.limitMinor / 100} ${budget.currency}'),
            LinearProgressIndicator(
              value: budget.spent / budget.limitMinor,
            ),
          ],
        ),
      ),
    );
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Budgets')),
      body: StreamBuilder<List<Budget>>(
        stream: _db.watchAllBudgets(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) => _buildBudgetCard(snapshot.data![index]),
          );
        }
      ),
    );
  }
}
