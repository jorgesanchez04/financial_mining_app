import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/selected_month.dart';

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController customerController = TextEditingController();

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

  @override
  void dispose() {
    amountController.dispose();
    categoryController.dispose();
    customerController.dispose();
    super.dispose();
  }

  Future<void> saveSale() async {
    if (amountController.text.isEmpty || categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad y categoria son necesarías')),
      );
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad inválida')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await supabase.from('sales').insert({
        'amount': amount,
        'category': categoryController.text,
        'date': selectedDate.toIso8601String(),
        'customer': customerController.text.isEmpty
            ? null
            : customerController.text,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir venta')),
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

            TextField(
              controller: customerController,
              decoration:
                  const InputDecoration(labelText: 'Cliente (opcional)'),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Text(
                  'Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100), // Ampliado para permitir registrar fechas futuras si es necesario
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: const Text('Seleccionar fecha'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveSale,
                    child: const Text('Guardar venta'),
                  ),
          ],
        ),
      ),
    );
  }
}