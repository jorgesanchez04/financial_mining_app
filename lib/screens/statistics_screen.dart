// lib/screens/statistics_screen.dart

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../services/pdf_export_service.dart';
import '../services/statistics_service.dart';
import '../state/selected_month.dart';
import '../widgets/additional_charts.dart';
import '../widgets/charts_widgets.dart';
import '../widgets/month_selector.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _statsService = StatisticsService();

  // 1. Claves para capturar las 4 gráficas
  final GlobalKey _categoryChartKey = GlobalKey();
  final GlobalKey _comparisonChartKey = GlobalKey();
  final GlobalKey _balanceChartKey = GlobalKey();
  final GlobalKey _dailyChartKey = GlobalKey();

  Map<String, double>? _categoryData;
  List<MonthlyComparison>? _comparisonData;
  List<BalanceTrend>? _balanceData;
  List<DailyExpense>? _dailyData;

  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final selectedMonth = context.watch<SelectedMonth>();

    setState(() => _isLoading = true);

    try {
      final categoryData = await _statsService.getExpensesByCategory(selectedMonth);
      // Se pasa selectedMonth para que cargue hasta el mes activo seleccionado
      final comparisonData = await _statsService.getRecentMonthsComparison(selected: selectedMonth);
      final balanceData = await _statsService.getBalanceTrend(selected: selectedMonth);
      final dailyData = await _statsService.getDailyExpenses(selectedMonth);

      if (mounted) {
        setState(() {
          _categoryData = categoryData;
          _comparisonData = comparisonData;
          _balanceData = balanceData;
          _dailyData = dailyData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Uint8List?> _captureWidgetImage(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _exportToPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    final selectedMonth = context.read<SelectedMonth>();

    // 2. Capturar las 4 imágenes
    final categoryBytes = await _captureWidgetImage(_categoryChartKey);
    final comparisonBytes = await _captureWidgetImage(_comparisonChartKey);
    final balanceBytes = await _captureWidgetImage(_balanceChartKey);
    final dailyBytes = await _captureWidgetImage(_dailyChartKey);

    final double totalExpense = _categoryData?.values.fold<double>(
          0.0,
          (sum, item) => sum + item,
        ) ??
        0.0;

    double totalIncome = 0.0;
    if (_comparisonData != null && _comparisonData!.isNotEmpty) {
      totalIncome = _comparisonData!.last.income;
    }

    final monthLabel = '${selectedMonth.month}/${selectedMonth.year}';

    // 3. Enviar las 4 capturas al servicio de PDF
    await PdfExportService.generateAndExportReport(
      monthYear: monthLabel,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      categoryChartBytes: categoryBytes,
      comparisonChartBytes: comparisonBytes,
      balanceChartBytes: balanceBytes,
      dailyChartBytes: dailyBytes,
    );

    if (mounted) {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Estadísticas"),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf),
            tooltip: "Exportar PDF",
            onPressed: _isLoading ? null : _exportToPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          const MonthSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Gráfica 1
                      if (_categoryData != null)
                        RepaintBoundary(
                          key: _categoryChartKey,
                          child: CategoryPieChart(categoryData: _categoryData!),
                        ),
                      const SizedBox(height: 16),

                      // Gráfica 2
                      if (_comparisonData != null)
                        RepaintBoundary(
                          key: _comparisonChartKey,
                          child: IncomeVsExpenseBarChart(data: _comparisonData!),
                        ),
                      const SizedBox(height: 16),

                      // Gráfica 3
                      if (_balanceData != null)
                        RepaintBoundary(
                          key: _balanceChartKey,
                          child: BalanceTrendLineChart(data: _balanceData!),
                        ),
                      const SizedBox(height: 16),

                      // Gráfica 4
                      if (_dailyData != null)
                        RepaintBoundary(
                          key: _dailyChartKey,
                          child: DailyExpenseBarChart(data: _dailyData!),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}