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
    final startYear = currentYear - 10;
    final endYear = currentYear + 2;

    final years = [
      for (int y = startYear; y <= endYear; y++) y
    ];

    final initialYearIndex = years.indexOf(selected.year);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                "Seleccionar Mes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    /// PICKER DE AÑO
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 40,
                        perspective: 0.005,
                        physics: const FixedExtentScrollPhysics(),
                        controller: FixedExtentScrollController(
                          initialItem: initialYearIndex >= 0 ? initialYearIndex : 0,
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

                    /// PICKER DE MES
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
                                style: const TextStyle(fontSize: 18),
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
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text("Confirmar"),
              ),
              const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => selected.previousMonth(),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showMonthPicker(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                '${_monthName(selected.month)} ${selected.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => selected.nextMonth(),
          ),
        ],
      ),
    );
  }

  static String _monthName(int m) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[m - 1];
  }
}