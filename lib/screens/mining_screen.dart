import 'package:flutter/material.dart';
import '../services/mining_service.dart';
import '../state/selected_month.dart';

class MiningScreen extends StatefulWidget {
  final SelectedMonth selectedMonth;

  const MiningScreen({
    super.key,
    required this.selectedMonth,
  });

  @override
  State<MiningScreen> createState() =>
      _MiningScreenState();
}

class _MiningScreenState
    extends State<MiningScreen> {
  final service = MiningService();

  late Future<HistoricalMining> historyFuture;

  bool isAnalyzing = false;
  String? analysisResult;

  @override
  void initState() {
    super.initState();
    historyFuture = service.analyzeHistory();
  }

  Future<void> _analyzeBusiness() async {
    setState(() {
      isAnalyzing = true;
      analysisResult = null;
    });

    final result =
        await service.generateFinancialDataAnalysis(
            widget.selectedMonth);

    setState(() {
      isAnalyzing = false;
      analysisResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Financial Mining")),
      body: FutureBuilder<HistoricalMining>(
        future: historyFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final h = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                "Average Monthly Sales",
                h.avgMonthlySales
                    .toStringAsFixed(2),
                Colors.green,
              ),
              _card(
                "Average Monthly Expenses",
                h.avgMonthlyExpenses
                    .toStringAsFixed(2),
                Colors.red,
              ),
              _card(
                "Expense Ratio",
                h.expenseRatio
                    .toStringAsFixed(2),
                Colors.orange,
              ),
              _card(
                "Sales Growth Rate",
                "${h.salesGrowthRate.toStringAsFixed(1)}%",
                Colors.teal,
              ),
              _card(
                "Momentum",
                "${h.momentum.toStringAsFixed(1)}%",
                Colors.purple,
              ),
              _card(
                "Sales Volatility",
                h.salesVolatility
                    .toStringAsFixed(2),
                Colors.indigo,
              ),
              _card(
                "Detected Anomalies",
                h.anomalyCount.toString(),
                Colors.brown,
              ),

              const SizedBox(height: 30),

              /// 🔹 LOCAL BUSINESS ANALYSIS BUTTON
              ElevatedButton(
                onPressed: isAnalyzing
                    ? null
                    : _analyzeBusiness,
                child: isAnalyzing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Analyze Business Performance",
                      ),
              ),

              const SizedBox(height: 20),

              /// 🔹 ANALYSIS RESULT
              if (analysisResult != null)
                Card(
                  color: Colors.blueGrey
                      .withOpacity(0.08),
                  elevation: 3,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Text(
                      analysisResult!,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Widget _card(
    String title,
    String value,
    Color color) {
  return Card(
    margin: const EdgeInsets.symmetric(
        vertical: 6),
    child: ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ),
  );
}
