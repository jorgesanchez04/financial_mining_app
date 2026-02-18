import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/selected_month.dart';

/// ================= MONTHLY MODEL =================

class MiningInsight {
  final double totalSales;
  final double totalExpenses;
  final double profitMargin;

  MiningInsight({
    required this.totalSales,
    required this.totalExpenses,
    required this.profitMargin,
  });
}

/// ================= HISTORICAL MODEL =================

class HistoricalMining {
  final double avgMonthlySales;
  final double avgMonthlyExpenses;
  final double expenseRatio;
  final double salesGrowthRate;
  final double momentum;
  final double salesVolatility;
  final int anomalyCount;
  final double bestMonthSales;
  final double worstMonthSales;
  final double regressionPrediction;

  HistoricalMining({
    required this.avgMonthlySales,
    required this.avgMonthlyExpenses,
    required this.expenseRatio,
    required this.salesGrowthRate,
    required this.momentum,
    required this.salesVolatility,
    required this.anomalyCount,
    required this.bestMonthSales,
    required this.worstMonthSales,
    required this.regressionPrediction,
  });
}

/// ================= SERVICE =================

class MiningService {
  final supabase = Supabase.instance.client;

  /// ============================================================
  /// MONTHLY ANALYSIS
  /// ============================================================

  Future<MiningInsight> analyze(SelectedMonth selected) async {
    final start = selected.start.toIso8601String();
    final end = selected.end.toIso8601String();

    final salesRaw = await supabase
        .from('sales')
        .select()
        .gte('date', start)
        .lt('date', end);

    final expensesRaw = await supabase
        .from('expenses')
        .select()
        .gte('date', start)
        .lt('date', end);

    double totalSales = 0;
    double totalExpenses = 0;

    for (final s in salesRaw) {
      totalSales += (s['amount'] as num).toDouble();
    }

    for (final e in expensesRaw) {
      totalExpenses += (e['amount'] as num).toDouble();
    }

    final profit = totalSales - totalExpenses;
    final double margin =
        totalSales == 0 ? 0 : ((profit / totalSales) * 100);

    return MiningInsight(
      totalSales: totalSales,
      totalExpenses: totalExpenses,
      profitMargin: margin,
    );
  }

  /// ============================================================
  /// HISTORICAL ANALYSIS + LINEAR REGRESSION
  /// ============================================================

  Future<HistoricalMining> analyzeHistory() async {
    final salesRaw = await supabase.from('sales').select();
    final expensesRaw = await supabase.from('expenses').select();

    final monthlySales = <String, double>{};
    final monthlyExpenses = <String, double>{};

    void accumulate(List data, Map<String, double> bucket) {
      for (final r in data) {
        final amount = (r['amount'] as num).toDouble();
        final date = DateTime.parse(r['date']);
        final month = date.month.toString().padLeft(2, '0');
        final key = "${date.year}-$month";
        bucket[key] = (bucket[key] ?? 0) + amount;
      }
    }

    accumulate(salesRaw, monthlySales);
    accumulate(expensesRaw, monthlyExpenses);

    final sortedEntries = monthlySales.entries.toList()
      ..sort((a, b) {
        final aDate = DateTime.parse("${a.key}-01");
        final bDate = DateTime.parse("${b.key}-01");
        return aDate.compareTo(bDate);
      });

    final salesValues =
        sortedEntries.map((e) => e.value).toList();

    final expenseValues = monthlyExpenses.values.toList();

    double avgSales = 0;
    double avgExpenses = 0;

    if (salesValues.isNotEmpty) {
      avgSales =
          salesValues.reduce((a, b) => a + b) /
              salesValues.length;
    }

    if (expenseValues.isNotEmpty) {
      avgExpenses =
          expenseValues.reduce((a, b) => a + b) /
              expenseValues.length;
    }

    final double ratio =
        avgSales == 0 ? 0 : avgExpenses / avgSales;

    /// ================= Growth Rate =================

    double growthRate = 0;
    int growthCount = 0;

    for (int i = 1; i < salesValues.length; i++) {
      final prev = salesValues[i - 1];
      final curr = salesValues[i];

      if (prev != 0) {
        growthRate += (curr - prev) / prev;
        growthCount++;
      }
    }

    if (growthCount > 0) {
      growthRate = (growthRate / growthCount) * 100;
    }

    /// ================= Momentum =================

    double momentum = 0;

    if (salesValues.length >= 3) {
      final last3 = salesValues
              .sublist(salesValues.length - 3)
              .reduce((a, b) => a + b) /
          3;

      momentum =
          avgSales == 0 ? 0 : ((last3 - avgSales) / avgSales) * 100;
    }

    /// ================= Volatility =================

    double variance = 0;
    for (var v in salesValues) {
      variance += pow(v - avgSales, 2);
    }

    final double volatility =
        salesValues.isEmpty
            ? 0
            : sqrt(variance / salesValues.length);

    /// ================= Anomalies =================

    int anomalies = 0;
    for (var v in salesValues) {
      if ((v - avgSales).abs() > volatility * 2) {
        anomalies++;
      }
    }

    final double bestMonth =
        salesValues.isEmpty ? 0.0 : salesValues.reduce(max);

    final double worstMonth =
        salesValues.isEmpty ? 0.0 : salesValues.reduce(min);

    /// ================= LINEAR REGRESSION =================

    double regressionPrediction = 0;

    if (salesValues.length >= 2) {
      final n = salesValues.length;

      double sumX = 0;
      double sumY = 0;
      double sumXY = 0;
      double sumX2 = 0;

      for (int i = 0; i < n; i++) {
        final x = i.toDouble();
        final y = salesValues[i];

        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
      }

      final b = (n * sumXY - sumX * sumY) /
          (n * sumX2 - sumX * sumX);

      final a = (sumY - b * sumX) / n;

      final nextX = n.toDouble();
      regressionPrediction = a + b * nextX;
    }

    return HistoricalMining(
      avgMonthlySales: avgSales,
      avgMonthlyExpenses: avgExpenses,
      expenseRatio: ratio,
      salesGrowthRate: growthRate,
      momentum: momentum,
      salesVolatility: volatility,
      anomalyCount: anomalies,
      bestMonthSales: bestMonth,
      worstMonthSales: worstMonth,
      regressionPrediction: regressionPrediction,
    );
  }

  /// ============================================================
  /// RECOMMENDATION ENGINE
  /// ============================================================

  String generateRecommendations(
      MiningInsight monthly,
      HistoricalMining history) {

    List<String> tips = [];

    if (monthly.profitMargin < 10) {
      tips.add(
          "Your profit margin is low. Consider adjusting prices or reducing costs.");
    }

    if (history.salesGrowthRate < 0) {
      tips.add(
          "Sales are declining. It may be a good time to launch promotions or strengthen marketing.");
    }

    if (history.expenseRatio > 0.7) {
      tips.add(
          "Expenses represent a large portion of revenue. Review fixed and variable costs.");
    }

    if (history.salesVolatility >
        history.avgMonthlySales * 0.5) {
      tips.add(
          "Sales are unstable. Try maintaining consistent promotions and improving customer retention.");
    }

    if (monthly.profitMargin > 25 &&
        history.salesGrowthRate > 5) {
      tips.add(
          "Your business shows strong growth and profitability. Maintain the current strategy.");
    }

    if (tips.isEmpty) {
      tips.add(
          "Your business is stable. Continue monitoring your metrics monthly.");
    }

    return tips.map((e) => "• $e").join("\n");
  }

  /// ============================================================
  /// FINANCIAL HEALTH INDEX + PROJECTION
  /// ============================================================

  Future<String> generateFinancialDataAnalysis(
      SelectedMonth selected) async {

    final monthly = await analyze(selected);
    final history = await analyzeHistory();

    double normalize(
        double value, double min, double max) {
      return ((value - min) / (max - min))
          .clamp(0.0, 1.0);
    }

    final normMargin =
        normalize(monthly.profitMargin, -20, 40);

    final normGrowth =
        normalize(history.salesGrowthRate, -30, 30);

    final normMomentum =
        normalize(history.momentum, -20, 20);

    final normExpenseControl =
        1 - normalize(history.expenseRatio, 0.3, 0.9);

    final stability =
        1 - normalize(
            history.salesVolatility,
            0,
            history.avgMonthlySales);

    double fhi =
        (normMargin * 0.30) +
        (normGrowth * 0.25) +
        (normMomentum * 0.15) +
        (normExpenseControl * 0.15) +
        (stability * 0.15);

    final score = (fhi * 100).clamp(0, 100);

    String category;
    if (score < 40) {
      category = "🔴 High Risk";
    } else if (score < 70) {
      category = "🟡 Stable";
    } else {
      category = "🟢 Healthy";
    }

    final growthProjection =
        monthly.totalSales *
            (1 + history.salesGrowthRate / 100);

    final regressionProjection =
        history.regressionPrediction;

    final combinedProjection =
        max(0,
            (growthProjection * 0.4) +
                (regressionProjection * 0.6));

    final recommendations =
        generateRecommendations(monthly, history);

    return """
📊 FINANCIAL HEALTH INDEX (FHI)

Score: ${score.toStringAsFixed(1)} / 100
Category: $category

--- Next Month Projection ---
Growth-based: ${growthProjection.toStringAsFixed(2)}
Regression-based: ${regressionProjection.toStringAsFixed(2)}
Combined Projection: ${combinedProjection.toStringAsFixed(2)}

--- Recommendations ---
$recommendations
""";
  }
}
