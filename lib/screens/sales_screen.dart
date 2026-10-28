import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'edit_sale_screen.dart';
import '../models/sale.dart';
import '../state/selected_month.dart';
import '../widgets/grouped_list.dart';
import 'add_sale_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Sale> sales = [];

  // ==========================================
  // CICLO DE VIDA: Detecta cambios de estado/mes
  // ==========================================
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchSales();
  }

  // Obtiene las ventas según el mes seleccionado globalmente
  Future<void> fetchSales() async {
    if (!mounted) return;
    setState(() => loading = true);

    final selected = context.read<SelectedMonth>();

    try {
      final data = await supabase
          .from('sales')
          .select()
          .gte('date', selected.start.toIso8601String())
          .lt('date', selected.end.toIso8601String())
          .order('date', ascending: false);

      if (!mounted) return;

      setState(() {
        sales = (data as List).map((e) => Sale.fromMap(e)).toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar ventas: $e')),
      );
    }
  }

  Future<void> deleteSale(String id) async {
    try {
      await supabase.from('sales').delete().eq('id', id);
      if (mounted) fetchSales();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la venta: $e')),
      );
    }
  }

  Future<bool> confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Eliminar venta'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta venta?',
            ),
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
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Map<DateTime, List<Sale>> _groupByDate() {
    final Map<DateTime, List<Sale>> grouped = {};

    for (final sale in sales) {
      final date = DateTime(
        sale.date.year,
        sale.date.month,
        sale.date.day,
      );

      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(sale);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchSales,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddSaleScreen(),
            ),
          );
          if (mounted) fetchSales(); // 👈 Se ejecuta siempre al regresar
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : sales.isEmpty
              ? const Center(child: Text('No se encontraron ventas'))
              : GroupedList<Sale>(
                  groups: _groupByDate(),
                  amountSelector: (s) => s.amount,
                  totalColor: Colors.green,
                  itemBuilder: (s) => Dismissible(
                    key: ValueKey(s.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (_) => confirmDelete(context),
                    onDismissed: (_) => deleteSale(s.id),
                    child: ListTile(
                      title: Text(s.category),
                      trailing: Text(
                        '\$${s.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditSaleScreen(sale: s),
                          ),
                        );
                        if (mounted) fetchSales(); // 👈 Se ejecuta siempre al regresar
                      },
                    ),
                  ),
                ),
    );
  }
}