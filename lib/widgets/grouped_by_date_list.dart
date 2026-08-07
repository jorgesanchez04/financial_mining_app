import 'package:flutter/material.dart';

class GroupedByDateList<T> extends StatelessWidget {
  final Map<String, List<T>> groupedItems;
  final Widget Function(T item) itemBuilder;
  final String emptyMessage;

  const GroupedByDateList({
    super.key,
    required this.groupedItems,
    required this.itemBuilder,
    this.emptyMessage = 'No records found',
  });

  @override
  Widget build(BuildContext context) {
    if (groupedItems.isEmpty) {
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

    final entries = groupedItems.entries.toList();

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final date = entry.key;
        final items = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                date,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...items.map(itemBuilder),
          ],
        );
      },
    );
  }
}