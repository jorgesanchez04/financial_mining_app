import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExcelImportService {
  final _supabase = Supabase.instance.client;

  // -------------------------------------------------------------
  // 1. IMPORTAR VENTAS (category, amount, customer, date)
  // -------------------------------------------------------------
  Future<ImportResult> importSalesFromExcel() async {
    try {
      final fileBytes = await _pickExcelFileBytes();
      if (fileBytes == null) {
        return ImportResult(success: false, message: "No se seleccionó o leyó ningún archivo");
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        return ImportResult(success: false, message: "Usuario no autenticado");
      }

      final excel = Excel.decodeBytes(fileBytes);
      final sheetName = excel.tables.keys.first;
      final table = excel.tables[sheetName];

      if (table == null || table.maxRows <= 1) {
        return ImportResult(success: false, message: "El archivo está vacío o sin registros");
      }

      final List<Map<String, dynamic>> salesToInsert = [];

      for (int rowIndex = 1; rowIndex < table.maxRows; rowIndex++) {
        final row = table.rows[rowIndex];
        if (row.isEmpty) continue;

        // Estructura esperada de la plantilla de Ventas:
        // Columna 0: Categoría
        // Columna 1: Monto
        // Columna 2: Cliente (Opcional)
        // Columna 3: Fecha (YYYY-MM-DD)
        final categoryRaw = row.length > 0 ? row[0]?.value?.toString().trim() : null;
        final category = (categoryRaw != null && categoryRaw.isNotEmpty) ? categoryRaw : 'General';

        final amountRaw = row.length > 1 ? row[1]?.value?.toString() : null;
        final customerRaw = row.length > 2 ? row[2]?.value?.toString().trim() : null;
        final dateRaw = row.length > 3 ? row[3]?.value?.toString() : null;

        if (amountRaw == null || dateRaw == null) continue;

        final amount = double.tryParse(amountRaw);
        final date = DateTime.tryParse(dateRaw);

        if (amount != null && date != null) {
          salesToInsert.add({
            'user_id': user.id,
            'category': category,
            'amount': amount,
            'customer': (customerRaw != null && customerRaw.isNotEmpty) ? customerRaw : null,
            'date': date.toIso8601String(),
          });
        }
      }

      if (salesToInsert.isEmpty) {
        return ImportResult(success: false, message: "No se encontraron filas de ventas válidas");
      }

      await _supabase.from('sales').insert(salesToInsert);

      return ImportResult(
        success: true,
        message: "¡Éxito! Se importaron ${salesToInsert.length} ventas.",
        count: salesToInsert.length,
      );
    } catch (e) {
      return ImportResult(success: false, message: "Error al importar ventas: $e");
    }
  }

  // -------------------------------------------------------------
  // 2. IMPORTAR GASTOS (category, amount, date)
  // -------------------------------------------------------------
  Future<ImportResult> importExpensesFromExcel() async {
    try {
      final fileBytes = await _pickExcelFileBytes();
      if (fileBytes == null) {
        return ImportResult(success: false, message: "No se seleccionó o leyó ningún archivo");
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        return ImportResult(success: false, message: "Usuario no autenticado");
      }

      final excel = Excel.decodeBytes(fileBytes);
      final sheetName = excel.tables.keys.first;
      final table = excel.tables[sheetName];

      if (table == null || table.maxRows <= 1) {
        return ImportResult(success: false, message: "El archivo está vacío o sin registros");
      }

      final List<Map<String, dynamic>> expensesToInsert = [];

      for (int rowIndex = 1; rowIndex < table.maxRows; rowIndex++) {
        final row = table.rows[rowIndex];
        if (row.isEmpty) continue;

        // Estructura esperada de la plantilla de Gastos:
        // Columna 0: Categoría
        // Columna 1: Monto
        // Columna 2: Fecha (YYYY-MM-DD)
        final categoryRaw = row.length > 0 ? row[0]?.value?.toString().trim() : null;
        final category = (categoryRaw != null && categoryRaw.isNotEmpty) ? categoryRaw : 'General';

        final amountRaw = row.length > 1 ? row[1]?.value?.toString() : null;
        final dateRaw = row.length > 2 ? row[2]?.value?.toString() : null;

        if (amountRaw == null || dateRaw == null) continue;

        final amount = double.tryParse(amountRaw);
        final date = DateTime.tryParse(dateRaw);

        if (amount != null && date != null) {
          expensesToInsert.add({
            'user_id': user.id,
            'category': category,
            'amount': amount,
            'date': date.toIso8601String(),
          });
        }
      }

      if (expensesToInsert.isEmpty) {
        return ImportResult(success: false, message: "No se encontraron filas de gastos válidas");
      }

      await _supabase.from('expenses').insert(expensesToInsert);

      return ImportResult(
        success: true,
        message: "¡Éxito! Se importaron ${expensesToInsert.length} gastos.",
        count: expensesToInsert.length,
      );
    } catch (e) {
      return ImportResult(success: false, message: "Error al importar gastos: $e");
    }
  }

  // Selección de archivo en bytes (compatible con Web y GitHub Pages)
  Future<List<int>?> _pickExcelFileBytes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;
    return result.files.single.bytes;
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int count;

  ImportResult({
    required this.success,
    required this.message,
    this.count = 0,
  });
}