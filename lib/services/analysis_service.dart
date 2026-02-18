import 'dart:math';

class MonthlyStats {
  final double totalSales;
  final double totalExpenses;
  final double balance;
  final double avgSale;
  final double stdDev;
  final double median;
  final double coefficientOfVariation;

  MonthlyStats({
    required this.totalSales,
    required this.totalExpenses,
    required this.balance,
    required this.avgSale,
    required this.stdDev,
    required this.median,
    required this.coefficientOfVariation,
  });
}

class StatisticsService {
  static MonthlyStats calculate({
    required List<double> sales,
    required List<double> expenses,
  }) {
    double totalSales =
        sales.fold(0.0, (a, b) => a + b);

    double totalExpenses =
        expenses.fold(0.0, (a, b) => a + b);

    double balance = totalSales - totalExpenses;

    double avgSale =
        sales.isEmpty ? 0 : totalSales / sales.length;

    double median = _median(sales);

    double stdDev = _stdDev(sales);

    double cv =
        avgSale == 0 ? 0 : stdDev / avgSale;

    return MonthlyStats(
      totalSales: totalSales,
      totalExpenses: totalExpenses,
      balance: balance,
      avgSale: avgSale,
      stdDev: stdDev,
      median: median,
      coefficientOfVariation: cv,
    );
  }

  static double _median(List<double> list) {
    if (list.isEmpty) return 0;
    List<double> sorted = List.from(list)..sort();
    int middle = sorted.length ~/ 2;

    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      return sorted[middle];
    }
  }

  static double _stdDev(List<double> list) {
    if (list.isEmpty) return 0;

    double mean =
        list.reduce((a, b) => a + b) / list.length;

    double variance = list
            .map((e) => pow(e - mean, 2))
            .reduce((a, b) => a + b) /
        list.length;

    return sqrt(variance);
  }
}
