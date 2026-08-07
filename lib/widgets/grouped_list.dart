import 'package:flutter/material.dart';

class GroupedList<T> extends StatelessWidget {
  final Map<DateTime, List<T>> groups;
  final Widget Function(T item) itemBuilder;
  final double Function(T item)? amountSelector;
  final Color? totalColor;
  final String emptyMessage;

  const GroupedList({
    super.key,
    required this.groups,
    required this.itemBuilder,
    this.amountSelector,
    this.totalColor,
    this.emptyMessage = 'No records found',
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            emptyMessage,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ),
      );
    }

    final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final items = groups[date] ?? [];

        double total = 0.0;
        if (amountSelector != null) {
          total = items.fold(
            0.0,
            (sum, item) => sum + amountSelector!(item),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (amountSelector != null)
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: totalColor ?? Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            ...items.map(itemBuilder),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }
}