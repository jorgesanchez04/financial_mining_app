import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/selected_month.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key});

  Future<void> _showMonthPicker(BuildContext context) async {
  final selected = context.read<SelectedMonth>();

  int tempMonth = selected.month;
  int tempYear = selected.year;

  final currentYear = DateTime.now().year;

  // 🔹 rango personalizado
  final startYear = currentYear - 26; // muchos antiguos
  final endYear = currentYear + 2;    // pocos futuros

  final years = [
    for (int y = startYear; y <= endYear; y++) y
  ];

  await showModalBottomSheet(
    context: context,
    builder: (_) {
      return SizedBox(
        height: 300,
        child: Column(
          children: [
            const SizedBox(height: 10),

            const Text(
              "Select Month",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            Expanded(
              child: Row(
                children: [

                  /// YEAR PICKER
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.005,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: years.indexOf(selected.year),
                      ),
                      onSelectedItemChanged: (index) {
                        tempYear = years[index];
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: years.length,
                        builder: (_, index) {
                          return Center(
                            child: Text(
                              "${years[index]}",
                              style: const TextStyle(fontSize: 18),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  /// MONTH PICKER
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 40,
                      perspective: 0.005,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: selected.month - 1,
                      ),
                      onSelectedItemChanged: (index) {
                        tempMonth = index + 1;
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 12,
                        builder: (_, index) {
                          return Center(
                            child: Text(
                              _monthName(index + 1),
                              style:
                                  const TextStyle(fontSize: 18),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ElevatedButton(
              onPressed: () {
                selected.update(tempMonth, tempYear);
                Navigator.pop(context);
              },
              child: const Text("Confirm"),
            ),

            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final selected = context.watch<SelectedMonth>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final date = DateTime(selected.year, selected.month - 1);
              selected.update(date.month, date.year);
            },
          ),

          GestureDetector(
            onTap: () => _showMonthPicker(context),
            child: Text(
              '${_monthName(selected.month)} ${selected.year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final date = DateTime(selected.year, selected.month + 1);
              selected.update(date.month, date.year);
            },
          ),
        ],
      ),
    );
  }

  static String _monthName(int m) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return months[m - 1];
  }
}
