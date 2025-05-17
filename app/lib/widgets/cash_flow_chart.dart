import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/transaction.dart';

class CashFlowChart extends StatelessWidget {
  final List<Transaction> transactions;

  const CashFlowChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      series: <CartesianSeries>[
        LineSeries<Transaction, String>(
          dataSource: transactions,
          xValueMapper: (Transaction t, _) => t.date.toString(),
          yValueMapper: (Transaction t, _) => t.amount,
        ),
      ],
    );
  }
}