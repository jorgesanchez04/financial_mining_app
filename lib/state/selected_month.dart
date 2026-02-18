import 'package:flutter/material.dart';

class SelectedMonth extends ChangeNotifier {
  int month;
  int year;

  SelectedMonth({
    required this.month,
    required this.year,
  });

  DateTime get start =>
      DateTime(year, month, 1);

  DateTime get end =>
      DateTime(year, month + 1, 0, 23, 59, 59);

  void update(int newMonth, int newYear) {
    month = newMonth;
    year = newYear;
    notifyListeners();
  }
}
