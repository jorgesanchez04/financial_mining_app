import 'dart:math';
import 'package:flutter/foundation.dart';

@immutable
class MonthlyStats {
  final double totalSales;
  final double totalExpenses;
  final double balance;
  final double avgSale;
  final double stdDev;
  final double median;
  final double coefficientOfVariation;

  const MonthlyStats({
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
    final double totalSales = sales.fold(0.0, (a, b) => a + b);
    final double totalExpenses = expenses.fold(0.0, (a, b) => a + b);
    final double balance = totalSales - totalExpenses;

    final double avgSale = sales.isEmpty ? 0.0 : totalSales / sales.length;
    final double median = _median(sales);
    final double stdDev = _stdDev(sales, avgSale);
    final double cv = avgSale == 0.0 ? 0.0 : stdDev / avgSale;

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
    if (list.isEmpty) return 0.0;

    final List<double> sorted = List<double>.from(list)..sort();
    final int middle = sorted.length ~/ 2;

    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    } else {
      return sorted[middle];
    }
  }

  static double _stdDev(List<double> list, double mean) {
    if (list.length <= 1) return 0.0;

    final double sumSquaredDiffs = list.fold(
      0.0,
      (sum, item) => sum + pow(item - mean, 2),
    );

    final double variance = sumSquaredDiffs / (list.length - 1);

    return sqrt(variance);
  }
}