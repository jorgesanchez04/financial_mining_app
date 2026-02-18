import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'statistics_screen.dart';
import 'sales_screen.dart';
import 'expenses_screen.dart';
import 'mining_screen.dart';
import '../state/selected_month.dart';
import '../widgets/month_selector.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    // 🔹 estado global (Provider)
    final selected = context.watch<SelectedMonth>();

    final startOfMonth = selected.start;
    final endOfMonth = selected.end;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Financiero'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menú',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Sales'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SalesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Expenses'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExpensesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistics'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StatisticsScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Data Mining'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MiningScreen(
                      selectedMonth: selected,
                    ),
                  ),
                );
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await supabase.auth.signOut(
                  scope: SignOutScope.global,
                );
              },
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          const MonthSelector(), // 🔹 selector global
          Expanded(
            child: FutureBuilder(
              future: Future.wait([
                supabase
                    .from('sales')
                    .select('amount')
                    .gte('date', startOfMonth.toIso8601String())
                    .lte('date', endOfMonth.toIso8601String()),
                supabase
                    .from('expenses')
                    .select('amount')
                    .gte('date', startOfMonth.toIso8601String())
                    .lte('date', endOfMonth.toIso8601String()),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final salesData = snapshot.data![0] as List;
                final expensesData = snapshot.data![1] as List;

                final totalSales = salesData.fold<double>(
                  0,
                  (sum, item) =>
                      sum + (item['amount'] as num).toDouble(),
                );

                final totalExpenses = expensesData.fold<double>(
                  0,
                  (sum, item) =>
                      sum + (item['amount'] as num).toDouble(),
                );

                final balance = totalSales - totalExpenses;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _card(
                        'Total Sales',
                        totalSales,
                        Colors.green,
                      ),
                      _card(
                        'Total Expenses',
                        totalExpenses,
                        Colors.red,
                      ),
                      _card(
                        'Balance',
                        balance,
                        balance >= 0
                            ? Colors.blue
                            : Colors.orange,
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
        value.toStringAsFixed(2),
        style: TextStyle(
          fontSize: 18,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
