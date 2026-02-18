import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../state/selected_month.dart';
import '../services/analysis_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  MonthlyStats? stats;

  List<double> salesList = [];
  List<double> expensesList = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchStats();
  }

  Future<void> fetchStats() async {
    setState(() => loading = true);

    final selected = context.read<SelectedMonth>();

    final salesData = await supabase
        .from('sales')
        .select('amount')
        .gte('date', selected.start.toIso8601String())
        .lt('date', selected.end.toIso8601String());

    final expensesData = await supabase
        .from('expenses')
        .select('amount')
        .gte('date', selected.start.toIso8601String())
        .lt('date', selected.end.toIso8601String());

    salesList = (salesData as List)
        .map((e) => (e['amount'] as num).toDouble())
        .toList();

    expensesList = (expensesData as List)
        .map((e) => (e['amount'] as num).toDouble())
        .toList();

    stats = StatisticsService.calculate(
      sales: salesList,
      expenses: expensesList,
    );

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : stats == null
              ? const Center(child: Text("No data available"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// 📊 MONTHLY SUMMARY
                      const Text(
                        "📊 Monthly Summary",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      _statCard("Total Sales",
                          stats!.totalSales, Colors.green),

                      _statCard("Total Expenses",
                          stats!.totalExpenses, Colors.red),

                      _statCard(
                          "Net Balance",
                          stats!.balance,
                          stats!.balance >= 0
                              ? Colors.green
                              : Colors.red),

                      const SizedBox(height: 24),

                      /// 📐 STATISTICAL INDICATORS
                      const Text(
                        "📐 Statistical Indicators",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      _statCard("Average Sale",
                          stats!.avgSale, Colors.blue),

                      _statCard("Median",
                          stats!.median, Colors.purple),

                      _statCard("Standard Deviation",
                          stats!.stdDev, Colors.orange),

                      _statCard("Coefficient of Variation",
                          stats!.coefficientOfVariation,
                          Colors.teal),

                      const SizedBox(height: 30),

                      /// 📈 SALES TREND
                      const Text(
                        "📈 Sales Trend",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            borderData:
                                FlBorderData(show: false),
                            titlesData:
                                FlTitlesData(show: false),
                            gridData:
                                FlGridData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                spots: List.generate(
                                  salesList.length,
                                  (i) => FlSpot(
                                    i.toDouble(),
                                    salesList[i],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// 🥧 SALES VS EXPENSES
                      const Text(
                        "🥧 Sales vs Expenses",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: stats!.totalSales,
                                title: "Sales",
                              ),
                              PieChartSectionData(
                                value: stats!.totalExpenses,
                                title: "Expenses",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _statCard(
      String title, double value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
