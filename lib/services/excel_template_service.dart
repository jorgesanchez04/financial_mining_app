import 'package:excel/excel.dart';
import 'package:flutter/material.dart';

class ExcelTemplateService {
  // --- Plantilla para Ventas ---
  static Future<bool> downloadSalesTemplate(BuildContext context) async {
    return _generateAndDownload(
      context: context,
      filename: 'Plantilla_Ventas_Prospera.xlsx',
      sheetTitle: 'Ventas',
      headers: ['Categoría', 'Cantidad', 'Cliente (Opcional)', 'Fecha (YYYY-MM-DD)'],
      sampleRow: ['Servicios', 1200.00, 'Cliente Ejemplo S.A.', '2026-08-01'],
    );
  }

  // --- Plantilla para Gastos ---
  static Future<bool> downloadExpensesTemplate(BuildContext context) async {
    return _generateAndDownload(
      context: context,
      filename: 'Plantilla_Gastos_Prospera.xlsx',
      sheetTitle: 'Gastos',
      headers: ['Categoría', 'Cantidad', 'Fecha (YYYY-MM-DD)'],
      sampleRow: ['Comida', 250.50, '2026-08-01'],
    );
  }

  // Función auxiliar para construir y descargar en Web
  static Future<bool> _generateAndDownload({
    required BuildContext context,
    required String filename,
    required String sheetTitle,
    required List<String> headers,
    required List<dynamic> sampleRow,
  }) async {
    try {
      final excel = Excel.createExcel();
      excel.rename('Sheet1', sheetTitle);
      final Sheet sheet = excel[sheetTitle];

      // Insertar Encabezados
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Insertar Fila de Ejemplo
      sheet.appendRow(sampleRow.map((val) {
        if (val is double) return DoubleCellValue(val);
        if (val is int) return IntCellValue(val);
        return TextCellValue(val.toString());
      }).toList());

      // Al pasar 'fileName' en Web, la librería activa automáticamente la descarga ÚNICA.
      excel.save(fileName: filename);

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar la plantilla: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }
}