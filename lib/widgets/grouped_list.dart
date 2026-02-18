import 'package:flutter/material.dart';

class GroupedList<T> extends StatelessWidget {
  final Map<DateTime, List<T>> groups;
  final Widget Function(T item) itemBuilder;
  final double Function(T item)? amountSelector;
  final Color? totalColor;

  const GroupedList({
    super.key,
    required this.groups,
    required this.itemBuilder,
    this.amountSelector,
    this.totalColor,
  });

  @override
  Widget build(BuildContext context) {
    final dates = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView(
      children: dates.map((date) {
        final items = groups[date]!;

        double total = 0;
        if (amountSelector != null) {
          total = items.fold(
            0,
            (sum, item) => sum + amountSelector!(item),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (amountSelector != null)
                    Text(
                      total.toStringAsFixed(2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: totalColor ?? Colors.black,
                      ),
                    ),
                ],
              ),
            ),
            ...items.map(itemBuilder).toList(),
          ],
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
