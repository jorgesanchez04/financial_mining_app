import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/selected_month.dart';

class MiningScreen extends StatelessWidget {
  final SelectedMonth selectedMonth;

  const MiningScreen({super.key, required this.selectedMonth});

  // ==========================================
  // 1. ALGORITMOS DE MINERÍA DE DATOS
  // ==========================================
  Map<String, double> _calculateLinearRegression(List<double> values) {
    if (values.length < 2) {
      return {
        'slope': 0.0,
        'intercept': values.isNotEmpty ? values.last : 0.0,
        'next': values.isNotEmpty ? values.last : 0.0,
      };
    }
    int n = values.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      double x = i.toDouble();
      double y = values[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;
    double nextPrediction = slope * n + intercept;
    return {
      'slope': slope,
      'intercept': intercept,
      'next': nextPrediction < 0 ? 0.0 : nextPrediction,
    };
  }

  Map<String, List<double>> _calculateKMeans(List<double> data, int k) {
    if (data.isEmpty) return {};
    if (data.length <= k) return {'Bajo': data, 'Medio': [], 'Alto': []};

    List<double> sorted = List.from(data)..sort();
    List<double> centroids = [
      sorted.first,
      sorted[(sorted.length / 2).floor()],
      sorted.last,
    ];
    List<List<double>> clusters = [[], [], []];
    bool converged = false;
    int iter = 0;

    while (!converged && iter < 50) {
      iter++;
      clusters = [[], [], []];
      for (double val in sorted) {
        int closest = 0;
        double minDistance = (val - centroids[0]).abs();
        for (int i = 1; i < k; i++) {
          double dist = (val - centroids[i]).abs();
          if (dist < minDistance) {
            minDistance = dist;
            closest = i;
          }
        }
        clusters[closest].add(val);
      }
      bool moved = false;
      for (int i = 0; i < k; i++) {
        if (clusters[i].isNotEmpty) {
          double newCentroid =
              clusters[i].reduce((a, b) => a + b) / clusters[i].length;
          if ((newCentroid - centroids[i]).abs() > 0.001) {
            centroids[i] = newCentroid;
            moved = true;
          }
        }
      }
      if (!moved) converged = true;
    }
    return {'Bajo': clusters[0], 'Medio': clusters[1], 'Alto': clusters[2]};
  }

  List<Map<String, dynamic>> _detectAnomalies(List<Map<String, dynamic>> records) {
    if (records.length < 3) return [];
    List<double> amounts =
        records.map((e) => (e['amount'] as num).toDouble()).toList();
    double mean = amounts.reduce((a, b) => a + b) / amounts.length;
    double variance =
        amounts.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            amounts.length;
    double stdDev = sqrt(variance);
    if (stdDev == 0) return [];

    List<Map<String, dynamic>> anomalies = [];
    for (var record in records) {
      double amt = (record['amount'] as num).toDouble();
      double zScore = (amt - mean) / stdDev;
      if (zScore > 1.8) {
        anomalies.add({...record, 'zScore': zScore, 'mean': mean});
      }
    }
    return anomalies;
  }

  Map<String, dynamic> _analyzeSalesPatterns(List<Map<String, dynamic>> sales) {
    if (sales.isEmpty) return {'bestDay': 'N/A', 'average': 0.0};
    Map<int, double> dayTotals = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    Map<int, int> dayCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

    for (var sale in sales) {
      if (sale['date'] != null) {
        DateTime date = DateTime.parse(sale['date']);
        int weekday = date.weekday;
        double amount = (sale['amount'] as num).toDouble();
        dayTotals[weekday] = (dayTotals[weekday] ?? 0) + amount;
        dayCounts[weekday] = (dayCounts[weekday] ?? 0) + 1;
      }
    }
    int bestDay = 1;
    double maxAvg = 0;
    List<String> days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    dayTotals.forEach((day, total) {
      int count = dayCounts[day] ?? 0;
      double avg = count > 0 ? total / count : 0;
      if (avg > maxAvg) {
        maxAvg = avg;
        bestDay = day;
      }
    });
    return {'bestDay': days[bestDay - 1], 'average': maxAvg};
  }

  // ==========================================
  // 2. EXPORTACIÓN A PDF
  // ==========================================
  Future<void> _exportToPdf({
    required BuildContext context,
    required double prediction,
    required double slope,
    required Map<String, dynamic> bestDay,
    required Map<String, List<double>> clusters,
    required List<Map<String, dynamic>> anomalies,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Reporte de Mineria de Datos - Prospera',
                      style: pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Generado automaticamente por el Asesor Inteligente.'),
                pw.Divider(),
                pw.SizedBox(height: 15),

                // Sección 1: Pronóstico
                pw.Text('1. Pronostico de Ventas (Regresion Lineal)',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text(
                    'Ventas Estimadas para proximo periodo: \$${prediction.toStringAsFixed(2)}'),
                pw.Text(
                    'Tendencia: ${slope > 0 ? 'Creciente' : (slope < 0 ? 'Decreciente' : 'Estable')} (m = ${slope.toStringAsFixed(2)})'),
                pw.SizedBox(height: 15),

                // Sección 2: Patrón de Actividad
                pw.Text('2. Patron de Actividad (Frecuencia)',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text(
                    'Dia con mayores ventas: ${bestDay['bestDay']} (Promedio: \$${(bestDay['average'] as double).toStringAsFixed(2)})'),
                pw.SizedBox(height: 15),

                // Sección 3: Clustering
                pw.Text('3. Niveles de Gastos (Clustering K-Means)',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                ...clusters.entries.map((entry) {
                  final count = entry.value.length;
                  final total =
                      entry.value.fold<double>(0, (a, b) => a + b);
                  final avg = count > 0 ? total / count : 0.0;
                  return pw.Text(
                      '- Nivel ${entry.key}: $count registros (Promedio \$${avg.toStringAsFixed(2)})');
                }),
                pw.SizedBox(height: 15),

                // Sección 4: Anomalías
                pw.Text('4. Deteccion de Anomalias (Z-Score)',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                if (anomalies.isEmpty)
                  pw.Text('No se detectaron gastos atipicos.')
                else
                  ...anomalies.map((a) => pw.Text(
                      '- Gasto Alto: ${a['category'] ?? 'Gasto'} (\$${(a['amount'] as num).toDouble().toStringAsFixed(2)})')),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Mineria_Prospera.pdf',
    );
  }

  // ==========================================
  // 3. INTERFAZ GRÁFICA (BUILD)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return FutureBuilder(
      future: Future.wait([
        supabase
            .from('sales')
            .select('amount, date, category')
            .order('date', ascending: true),
        supabase
            .from('expenses')
            .select('amount, date, category')
            .order('date', ascending: true),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Asesor Inteligente')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Asesor Inteligente')),
            body: Center(
                child: Text('Error en minería de datos: ${snapshot.error}')),
          );
        }

        final rawSales = List<Map<String, dynamic>>.from(
            (snapshot.data?[0] as List?) ?? []);
        final rawExpenses = List<Map<String, dynamic>>.from(
            (snapshot.data?[1] as List?) ?? []);

        final List<double> salesAmounts = rawSales
            .map<double>((e) => (e['amount'] as num).toDouble())
            .toList();
        final List<double> expensesAmounts = rawExpenses
            .map<double>((e) => (e['amount'] as num).toDouble())
            .toList();

        final regression = _calculateLinearRegression(salesAmounts);
        final clusters = _calculateKMeans(expensesAmounts, 3);
        final anomalies = _detectAnomalies(rawExpenses);
        final bestDayPattern = _analyzeSalesPatterns(rawSales);

        final slope = regression['slope'] ?? 0;
        final prediction = regression['next'] ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Asesor Inteligente'),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Exportar a PDF',
                onPressed: () => _exportToPdf(
                  context: context,
                  prediction: prediction,
                  slope: slope,
                  bestDay: bestDayPattern,
                  clusters: clusters,
                  anomalies: anomalies,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. REGRESIÓN LINEAL
                const Text('1. Pronóstico de Ventas (Regresión Lineal)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              slope > 0
                                  ? Icons.trending_up
                                  : (slope < 0
                                      ? Icons.trending_down
                                      : Icons.trending_flat),
                              color: slope > 0
                                  ? Colors.green
                                  : (slope < 0 ? Colors.red : Colors.orange),
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ventas Estimadas Próximo Período'),
                                  Text('\$${prediction.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          slope > 0
                              ? '• Tendencia al alza: Tus ventas van creciendo (m = ${slope.toStringAsFixed(2)}).'
                              : (slope < 0
                                  ? '• Tendencia a la baja: Tus ventas han disminuido (m = ${slope.toStringAsFixed(2)}).'
                                  : '• Comportamiento estable: Sin variaciones registradas en el tiempo (m = 0.00).'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. PATRÓN DE VENTAS
                const Text('2. Patrón de Actividad (Frecuencia)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.greenAccent,
                      child: Icon(Icons.calendar_today, color: Colors.black87),
                    ),
                    title: Text('Día clave: ${bestDayPattern['bestDay']}'),
                    subtitle: Text(
                        'Promedio: \$${(bestDayPattern['average'] as double).toStringAsFixed(2)}'),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. CLUSTERING K-MEANS
                const Text('3. Niveles de Gastos (Clustering K-Means)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...clusters.entries.map((entry) {
                          final count = entry.value.length;
                          final total =
                              entry.value.fold<double>(0, (a, b) => a + b);
                          final avg = count > 0 ? total / count : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('• Nivel ${entry.key}:'),
                                Text(
                                  '$count reg. (Prom: \$${avg.toStringAsFixed(2)})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. DETECCIÓN DE ANOMALÍAS
                const Text('4. Alerta de Gastos Atípicos (Z-Score)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (anomalies.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Text('No se detectaron gastos atípicos.'),
                        ],
                      ),
                    ),
                  )
                else
                  ...anomalies.map((a) {
                    final cat = a['category'] ?? 'Gasto';
                    final amt = (a['amount'] as num).toDouble();
                    return Card(
                      color: Colors.orange.shade50,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading:
                            const Icon(Icons.warning, color: Colors.orange),
                        title: Text('Gasto Atípico: $cat (\$$amt)'),
                        subtitle: Text(
                            'Superior al promedio (\$${(a['mean'] as double).toStringAsFixed(2)}).'),
                      ),
                    );
                  }),
              ],
            ),
            )
          );
        },
      );
  }
}