import 'package:flutter/material.dart';

class GroupedByDateList<T> extends StatelessWidget {
  final Map<String, List<T>> groupedItems;
  final Widget Function(T item) itemBuilder;

  const GroupedByDateList({
    super.key,
    required this.groupedItems,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (groupedItems.isEmpty) {
      return const Center(child: Text('No records found'));
    }

    return ListView(
      children: groupedItems.entries.map((entry) {
        final date = entry.key;
        final items = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de fecha
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Text(
                date,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Items de ese día
            ...items.map(itemBuilder).toList(),
          ],
        );
      }).toList(),
    );
  }
}
