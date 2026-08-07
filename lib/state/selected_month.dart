import 'package:flutter/material.dart';

class SelectedMonth extends ChangeNotifier {
  int _month;
  int _year;

  SelectedMonth({
    required int month,
    required int year,
  })  : _month = month,
        _year = year;

  int get month => _month;
  int get year => _year;

  /// Inicio del mes seleccionado (ej: 2026-08-01 00:00:00.000)
  DateTime get start => DateTime(_year, _month, 1);

  /// Primer instante del mes Siguiente (ej: 2026-09-01 00:00:00.000)
  /// Usado con la condición `.lt('date', end)` en Supabase para cubrir hasta el último milisegundo del mes actual.
  DateTime get end => DateTime(_year, _month + 1, 1);

  /// Actualiza el mes y año solo si cambian los valores
  void update(int newMonth, int newYear) {
    if (_month == newMonth && _year == newYear) return;

    _month = newMonth;
    _year = newYear;
    notifyListeners();
  }

  /// Método de conveniencia para avanzar un mes
  void nextMonth() {
    if (_month == 12) {
      _month = 1;
      _year++;
    } else {
      _month++;
    }
    notifyListeners();
  }

  /// Método de conveniencia para retroceder un mes
  void previousMonth() {
    if (_month == 1) {
      _month = 12;
      _year--;
    } else {
      _month--;
    }
    notifyListeners();
  }
}