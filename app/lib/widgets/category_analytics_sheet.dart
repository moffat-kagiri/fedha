import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../services/offline_data_service.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryAnalyticsSheet extends StatelessWidget {
  final List<Transaction> transactions;

  const CategoryAnalyticsSheet({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: FutureBuilder<Map<Category, List<Transaction>>>(
            future: _groupTransactionsByCategory(context),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final categoryData = snapshot.data!;
              final totalAmount = transactions
                  .map((t) => t.type == TransactionType.expense ? t.amount : 0.0)
                  .reduce((a, b) => a + b).toDouble();

              return Column(
                children: [
                  const Text(
                    'Category Analytics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: _buildPieChartSections(categoryData, totalAmount),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: categoryData.length,
                            itemBuilder: (context, index) {
                              final category = categoryData.keys.elementAt(index);
                              final transactions = categoryData[category]!;
                              final amount = transactions
                                  .map((t) => t.type == TransactionType.expense ? t.amount : 0)
                                  .reduce((a, b) => a + b);
                              final percentage = (amount / totalAmount * 100).toStringAsFixed(1);

                              return ListTile(
                                leading: Icon(
                                  IconData(int.parse(category.iconKey), fontFamily: 'MaterialIcons'),
                                  color: Color(int.parse(category.colorKey.replaceAll('#', '0xff'))),
                                ),
                                title: Text(category.name),
                                subtitle: Text('${amount.toStringAsFixed(2)} (${percentage}%)'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<Map<Category, List<Transaction>>> _groupTransactionsByCategory(BuildContext context) async {
    final dataService = Provider.of<OfflineDataService>(context, listen: false);
    final Map<Category, List<Transaction>> groupedTransactions = {};

    for (final transaction in transactions) {
      if (transaction.categoryId.isEmpty) continue;
      
      final category = await dataService.getCategoryById(transaction.categoryId);
      if (category == null) continue;

      if (!groupedTransactions.containsKey(category)) {
        groupedTransactions[category] = [];
      }
      groupedTransactions[category]!.add(transaction);
    }

    return groupedTransactions;
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<Category, List<Transaction>> categoryData,
    double totalAmount,
  ) {
    return categoryData.entries.map((entry) {
      final category = entry.key;
      final transactions = entry.value;
      final amount = transactions
          .map((t) => t.type == TransactionType.expense ? t.amount : 0)
          .reduce((a, b) => a + b);
      final percentage = amount / totalAmount;

      return PieChartSectionData(
        color: Color(int.parse(category.colorKey.replaceAll('#', '0xff'))),
        value: amount.toDouble(),
        title: '${(percentage * 100).toStringAsFixed(0)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
