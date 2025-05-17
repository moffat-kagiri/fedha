import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/transaction.dart';
// app/lib/widgets/cash_flow_chart.dart

class CashFlowChart extends StatelessWidget {
  final List<Transaction> transactions;

  const CashFlowChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(),
      series: <CartesianSeries>[
        LineSeries<Transaction, DateTime>(
          dataSource: transactions,
          xValueMapper: (Transaction t, _) => t.date,
          yValueMapper: (Transaction t, _) => t.amount,
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}
