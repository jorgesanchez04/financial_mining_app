import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/selected_month.dart';

class StatisticsService {
  final supabase = Supabase.instance.client;

  /// Obtiene el total de gastos agrupado por categoría en el mes seleccionado
  Future<Map<String, double>> getExpensesByCategory(SelectedMonth selected) async {
    final start = selected.start.toIso8601String();
    final end = selected.end.toIso8601String();

    final response = await supabase
        .from('expenses')
        .select('amount, category')
        .gte('date', start)
        .lt('date', end);

    final Map<String, double> categoryMap = {};

    for (final row in (response as List)) {
      final category = (row['category'] as String?) ?? 'Sin categoría';
      final amount = (row['amount'] as num).toDouble();
      categoryMap[category] = (categoryMap[category] ?? 0.0) + amount;
    }

    return categoryMap;
  }

  /// Obtiene totales de ingresos vs gastos de los últimos N meses tomando como referencia el mes seleccionado
  Future<List<MonthlyComparison>> getRecentMonthsComparison({
    required SelectedMonth selected,
    int monthCount = 6,
  }) async {
    final List<MonthlyComparison> result = [];

    // Tomamos como punto final de la ventana el mes seleccionado por el usuario
    final referenceDate = DateTime.utc(selected.year, selected.month, 1);

    for (int i = monthCount - 1; i >= 0; i--) {
      // Retrocedemos mes a mes usando fechas en UTC neutro
      final date = DateTime.utc(referenceDate.year, referenceDate.month - i, 1);
      final nextMonth = DateTime.utc(date.year, date.month + 1, 1);

      final start = date.toIso8601String();
      final end = nextMonth.toIso8601String();

      final salesRaw = await supabase
          .from('sales')
          .select('amount')
          .gte('date', start)
          .lt('date', end);

      final expensesRaw = await supabase
          .from('expenses')
          .select('amount')
          .gte('date', start)
          .lt('date', end);

      double income = 0.0;
      double expense = 0.0;

      for (final s in (salesRaw as List)) {
        income += (s['amount'] as num).toDouble();
      }

      for (final e in (expensesRaw as List)) {
        expense += (e['amount'] as num).toDouble();
      }

      final monthLabel = _getMonthAbbreviation(date.month);
      result.add(MonthlyComparison(
        monthLabel: monthLabel,
        income: income,
        expense: expense,
      ));
    }

    return result;
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month - 1];
  }
}

class MonthlyComparison {
  final String monthLabel;
  final double income;
  final double expense;

  MonthlyComparison({
    required this.monthLabel,
    required this.income,
    required this.expense,
  });
}

extension MoreStatistics on StatisticsService {
  Future<List<DailyExpense>> getDailyExpenses(SelectedMonth selected) async {
    final start = selected.start.toIso8601String();
    final end = selected.end.toIso8601String();

    final response = await supabase
        .from('expenses')
        .select('amount, date')
        .gte('date', start)
        .lt('date', end);

    final Map<int, double> daysMap = {};
    final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;

    for (int i = 1; i <= daysInMonth; i++) {
      daysMap[i] = 0.0;
    }

    for (final row in (response as List)) {
      final date = DateTime.parse(row['date']);
      final amount = (row['amount'] as num).toDouble();
      daysMap[date.day] = (daysMap[date.day] ?? 0.0) + amount;
    }

    return daysMap.entries
        .map((e) => DailyExpense(day: e.key, amount: e.value))
        .toList();
  }

  Future<List<BalanceTrend>> getBalanceTrend({
    required SelectedMonth selected,
    int monthCount = 6,
  }) async {
    final comparisons = await getRecentMonthsComparison(
      selected: selected,
      monthCount: monthCount,
    );
    return comparisons
        .map((c) => BalanceTrend(
              monthLabel: c.monthLabel,
              balance: c.income - c.expense,
            ))
        .toList();
  }
}

class DailyExpense {
  final int day;
  final double amount;
  DailyExpense({required this.day, required this.amount});
}

class BalanceTrend {
  final String monthLabel;
  final double balance;
  BalanceTrend({required this.monthLabel, required this.balance});
}