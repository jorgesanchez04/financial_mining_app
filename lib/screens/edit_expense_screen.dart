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
  late DateTime selectedDate;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    amountCtrl =
        TextEditingController(text: widget.expense.amount.toString());
    categoryCtrl =
        TextEditingController(text: widget.expense.category);
    selectedDate = widget.expense.date;
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> saveExpense() async {
    setState(() => loading = true);

    await supabase.from('expenses').update({
      'amount': double.parse(amountCtrl.text),
      'category': categoryCtrl.text,
      'date': selectedDate.toIso8601String(),
    }).eq('id', widget.expense.id); 

    setState(() => loading = false);

    if (mounted) Navigator.pop(context, true); // avisamos que hubo cambios
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar gasto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                'Fecha: ${selectedDate.toLocal().toString().split(' ')[0]}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: pickDate,
            ),
            const SizedBox(height: 24),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveExpense,
                    child: const Text('Guardar'),
                  ),
          ],
        ),
      ),
    );
  }
}