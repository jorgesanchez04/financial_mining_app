import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expense.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final supabase = Supabase.instance.client;

  late TextEditingController amountCtrl;
  late TextEditingController categoryCtrl;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    amountCtrl =
        TextEditingController(text: widget.expense.amount.toString());
    categoryCtrl =
        TextEditingController(text: widget.expense.category);
  }

  Future<void> saveExpense() async {
    setState(() => loading = true);

    await supabase.from('expenses').update({
      'amount': double.parse(amountCtrl.text),
      'category': categoryCtrl.text,
    }).eq('id', widget.expense.id); // 👈 CLAVE

    setState(() => loading = false);

    Navigator.pop(context, true); // 👈 avisamos que hubo cambios
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 24),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveExpense,
                    child: const Text('Save'),
                  ),
          ],
        ),
      ),
    );
  }
}
