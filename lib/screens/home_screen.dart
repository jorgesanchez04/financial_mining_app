import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/excel_import_service.dart';
import '../services/excel_template_service.dart';
import '../state/selected_month.dart';
import '../widgets/month_selector.dart';
import 'expenses_screen.dart';
import 'mining_screen.dart';
import 'sales_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Clave o contador para forzar la recarga de datos
  int _refreshKey = 0;

  void _refreshData() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final selected = context.watch<SelectedMonth>();

    // --- MANEJO DE FECHAS EN UTC ---
    final startOfMonth = DateTime.utc(selected.start.year, selected.start.month, 1);
    final nextMonth = DateTime.utc(selected.start.year, selected.start.month + 1, 1);

    final importService = ExcelImportService();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png', // Ruta del logo cargado en pubspec.yaml
              height: 32,        // Tamaño adecuado para la AppBar
              width: 32,
              errorBuilder: (context, error, stackTrace) {
                // Muestra un icono de respaldo en caso de que la imagen aún no esté colocada
                return const Icon(Icons.show_chart, size: 28);
              },
            ),
            const SizedBox(width: 10),
            const Text('Prospera'),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Menú',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Ventas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesScreen()),
                ).then((_) => _refreshData()); // Recarga al volver
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Gastos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                ).then((_) => _refreshData()); // Recarga al volver
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Estadísticas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Asesor predictivo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MiningScreen(selectedMonth: selected),
                  ),
                );
              },
            ),

            const Divider(),

            // --- GESTIÓN DE DATOS EXCEL ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'GESTIÓN DE DATOS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.green),
              title: const Text('Descargar Plantilla de Ventas'),
              onTap: () => ExcelTemplateService.downloadSalesTemplate(context),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.green),
              title: const Text('Importar Ventas desde Excel'),
              onTap: () async {
                Navigator.pop(context);
                final result = await importService.importSalesFromExcel();
                _refreshData(); // Recarga tras la importación
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.red),
              title: const Text('Descargar Plantilla de Gastos'),
              onTap: () => ExcelTemplateService.downloadExpensesTemplate(context),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.red),
              title: const Text('Importar Gastos desde Excel'),
              onTap: () async {
                Navigator.pop(context);
                final result = await importService.importExpensesFromExcel();
                _refreshData(); // Recarga tras la importación
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? Colors.green : Colors.red,
                  ),
                );
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                await supabase.auth.signOut(scope: SignOutScope.global);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const MonthSelector(),
          Expanded(
            child: FutureBuilder(
              // Usamos _refreshKey en la clave para forzar la recreación del FutureBuilder
              key: ValueKey(_refreshKey),
              future: Future.wait([
                supabase
                    .from('sales')
                    .select('amount')
                    .gte('date', startOfMonth.toIso8601String())
                    .lt('date', nextMonth.toIso8601String()),
                supabase
                    .from('expenses')
                    .select('amount')
                    .gte('date', startOfMonth.toIso8601String())
                    .lt('date', nextMonth.toIso8601String()),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
                }

                final salesData = (snapshot.data?[0] as List?) ?? [];
                final expensesData = (snapshot.data?[1] as List?) ?? [];

                final totalSales = salesData.fold<double>(
                  0,
                  (sum, item) => sum + (item['amount'] as num).toDouble(),
                );

                final totalExpenses = expensesData.fold<double>(
                  0,
                  (sum, item) => sum + (item['amount'] as num).toDouble(),
                );

                final balance = totalSales - totalExpenses;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _card('Ventas totales', totalSales, Colors.green),
                      _card('Gastos totales', totalExpenses, Colors.red),
                      _card(
                        'Balance general',
                        balance,
                        balance >= 0 ? Colors.blue : Colors.orange,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _card(String title, double value, Color color) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: ListTile(
      leading: Icon(Icons.bar_chart, color: color),
      title: Text(title),
      trailing: Text(
        '\$${value.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 18,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}