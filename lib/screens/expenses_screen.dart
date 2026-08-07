import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../state/selected_month.dart';
import '../widgets/grouped_list.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Expense> expenses = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchExpenses();
  }

  //  Obtener gastos según mes seleccionado
  Future<void> fetchExpenses() async {
    setState(() => loading = true);

    final selected = context.read<SelectedMonth>();

    final data = await supabase
        .from('expenses')
        .select()
        .gte('date', selected.start.toIso8601String())
        .lt('date', selected.end.toIso8601String())
        .order('date', ascending: false);

    expenses = (data as List)
        .map((e) => Expense.fromMap(e))
        .toList();

    setState(() => loading = false);
  }

  //  Eliminar gasto
  Future<void> deleteExpense(String id) async {
    await supabase.from('expenses').delete().eq('id', id);
    fetchExpenses();
  }

  //  Confirmación de borrado
  Future<bool> confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Borrar gasto'),
            content:
                const Text('Estás seguro que quieres borrar este gasto?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Borrar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  //  Agrupar por fecha
  Map<DateTime, List<Expense>> _groupByDate() {
    final Map<DateTime, List<Expense>> grouped = {};

    for (final expense in expenses) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(expense);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          fetchExpenses();
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
              ? const Center(child: Text('Sin gastos encontrados'))
              : GroupedList<Expense>(
                  groups: _groupByDate(),
                  amountSelector: (e) => e.amount,
                  totalColor: Colors.red,
                  itemBuilder: (e) => Dismissible(
                    key: ValueKey(e.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (_) => confirmDelete(context),
                    onDismissed: (_) => deleteExpense(e.id),
                    child: ListTile(
                      title: Text(e.category),
                      trailing: Text(
                        '-\$${e.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // EDITAR GASTO
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditExpenseScreen(expense: e),
                          ),
                        );

                        if (updated == true) {
                          fetchExpenses(); // solo si hubo cambios
                        }
                      },
                    ),
                  ),
                ),
    );
  }
}
