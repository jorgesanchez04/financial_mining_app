import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/selected_month.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final supabase = Supabase.instance.client;

  final amountController = TextEditingController();
  final categoryController = TextEditingController();

  late DateTime selectedDate;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    // Preseleccionamos el día 1 del mes activo en el estado global
    final selectedMonth = context.read<SelectedMonth>();
    final now = DateTime.now();

    // Si coincide con el mes/año actual, usaremos el día de hoy
    if (selectedMonth.year == now.year && selectedMonth.month == now.month) {
      selectedDate = now;
    } else {
      selectedDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
    }
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
    if (amountController.text.isEmpty || categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son requeridos')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await supabase.from('expenses').insert({
        'amount': double.parse(amountController.text),
        'category': categoryController.text,
        'date': selectedDate.toIso8601String(),
        'user_id': supabase.auth.currentUser!.id,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  void dispose() {
    amountController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir gasto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
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