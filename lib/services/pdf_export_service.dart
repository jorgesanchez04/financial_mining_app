import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  static Future<void> generateAndExportReport({
    required String monthYear,
    required double totalIncome,
    required double totalExpense,
    required Uint8List? categoryChartBytes,
    required Uint8List? comparisonChartBytes,
    required Uint8List? balanceChartBytes,
    required Uint8List? dailyChartBytes,
  }) async {
    final pdf = pw.Document();
    final netSavings = totalIncome - totalExpense;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Reporte Financiero',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Período: $monthYear',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Prospera',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 12),

              // Tarjetas de Resumen
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryBox('Ingresos Totales', '\$${totalIncome.toStringAsFixed(2)}', PdfColors.green700),
                  _buildSummaryBox('Gastos Totales', '\$${totalExpense.toStringAsFixed(2)}', PdfColors.red700),
                  _buildSummaryBox('Ahorro Neto', '\$${netSavings.toStringAsFixed(2)}', netSavings >= 0 ? PdfColors.blue700 : PdfColors.orange700),
                ],
              ),

              pw.SizedBox(height: 16),

              // Fila 1 de Gráficas (Gráfica 1 y 2)
              pw.Row(
                children: [
                  if (categoryChartBytes != null)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text('Gastos por Categoría', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Image(pw.MemoryImage(categoryChartBytes), height: 160),
                        ],
                      ),
                    ),
                  if (categoryChartBytes != null && comparisonChartBytes != null)
                    pw.SizedBox(width: 12),
                  if (comparisonChartBytes != null)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text('Comparativa Mensual', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Image(pw.MemoryImage(comparisonChartBytes), height: 160),
                        ],
                      ),
                    ),
                ],
              ),

              pw.SizedBox(height: 12),

              // Fila 2 de Gráficas (Gráfica 3 y 4)
              pw.Row(
                children: [
                  if (balanceChartBytes != null)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text('Evolución del Ahorro', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Image(pw.MemoryImage(balanceChartBytes), height: 160),
                        ],
                      ),
                    ),
                  if (balanceChartBytes != null && dailyChartBytes != null)
                    pw.SizedBox(width: 12),
                  if (dailyChartBytes != null)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text('Gastos Diarios', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Image(pw.MemoryImage(dailyChartBytes), height: 160),
                        ],
                      ),
                    ),
                ],
              ),

              pw.Spacer(),

              // Pie de página
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generado automáticamente por la aplicación.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Página 1 de 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Financiero_$monthYear.pdf',
    );
  }

  static pw.Widget _buildSummaryBox(String title, String value, PdfColor valueColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}