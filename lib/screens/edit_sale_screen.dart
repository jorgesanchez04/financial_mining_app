import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale.dart';

class EditSaleScreen extends StatefulWidget {
  final Sale sale;

  const EditSaleScreen({super.key, required this.sale});

  @override
  State<EditSaleScreen> createState() => _EditSaleScreenState();
}

class _EditSaleScreenState extends State<EditSaleScreen> {
  final supabase = Supabase.instance.client;

  late TextEditingController amountController;
  late TextEditingController categoryController;
  late DateTime selectedDate;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    amountController =
        TextEditingController(text: widget.sale.amount.toString());
    categoryController =
        TextEditingController(text: widget.sale.category);
    selectedDate = widget.sale.date;
  }

  Future<void> saveChanges() async {
    setState(() => loading = true);

    await supabase.from('sales').update({
      'amount': double.parse(amountController.text),
      'category': categoryController.text,
      'date': selectedDate.toIso8601String(),
    }).eq('id', widget.sale.id);

    setState(() => loading = false);
    Navigator.pop(context, true); // 🔹 indica que hubo cambios
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Sale')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  selectedDate.toLocal().toString().split(' ')[0],
                ),
                const Spacer(),
                TextButton(
                  onPressed: pickDate,
                  child: const Text('Change date'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveChanges,
                    child: const Text('Save changes'),
                  ),
          ],
        ),
      ),
    );
  }
}
