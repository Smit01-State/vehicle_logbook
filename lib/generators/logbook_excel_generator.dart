import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';
import '../models/vehicle.dart';
import '../models/config.dart';

class LogBookExcelGenerator {
  static Future<void> generate(Vehicle vehicle, int month, int year) async {
    final reports = await DatabaseHelper.instance
        .getDailyReportsByVehicleAndMonth(vehicle.displayName, month, year);
    final config = await DatabaseHelper.instance.getConfig();
    final monthName = DateFormat('MMMM').format(DateTime(year, month));

    if (reports.isEmpty) {
      throw Exception(
        'No trips found for ${vehicle.vehicleNumber} in $monthName $year',
      );
    }

    final excel = Excel.createExcel();
    final sheetName = 'LogBook';
    excel.rename(excel.getDefaultSheet()!, sheetName);
    final sheet = excel[sheetName];

    // --- Styling ---
    final headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#0057A7'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
    );

    final subTitleStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
    );

    final cellStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    final cellStyleLeft = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    final totalStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#E8F0FE'),
    );

    // --- Title rows ---
    // Row 0: GETCO title
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('L1'));
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue(
      'Gujarat Energy Transmission Corporation Ltd.',
    );
    titleCell.cellStyle = titleStyle;

    // Row 1: Division + Vehicle info
    sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('D2'));
    final divCell = sheet.cell(CellIndex.indexByString('A2'));
    divCell.value = TextCellValue('Division: ${config?.divisionName ?? ""}');
    divCell.cellStyle = subTitleStyle;

    sheet.merge(CellIndex.indexByString('E2'), CellIndex.indexByString('I2'));
    final vehCell = sheet.cell(CellIndex.indexByString('E2'));
    vehCell.value = TextCellValue(
      'Log Book for Vehicle No. ${vehicle.vehicleNumber}',
    );
    vehCell.cellStyle = subTitleStyle;

    // Row 2: Month
    sheet.merge(CellIndex.indexByString('A3'), CellIndex.indexByString('L3'));
    final monthCell = sheet.cell(CellIndex.indexByString('A3'));
    monthCell.value = TextCellValue(
      'Entries for the Month of $monthName-$year',
    );
    monthCell.cellStyle = subTitleStyle;

    // --- Headers (Row 3) ---
    final headers = [
      'Sr.\nNo.',
      'Date',
      'Name & Designation\nof Officers',
      'Places\nVisited',
      'Purpose of\nJourney',
      'Initial\nKM',
      'Start\nTime',
      'Final\nKM',
      'End\nTime',
      'Distance\n(km)',
      'Duration\n(hrs)',
      'Signature',
    ];

    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3),
      );
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }

    // --- Data rows ---
    double totalKm = 0;
    for (int i = 0; i < reports.length; i++) {
      final r = reports[i];
      final row = i + 4; // Data starts at row 4

      final isNoTrip = r.tripType == 'No Trip';
      totalKm += r.distance ?? 0;

      final values = [
        '${i + 1}',
        DateFormat('dd-MM-yyyy').format(r.date),
        isNoTrip ? '' : r.staff,
        isNoTrip ? '::::: No Trip :::::' : r.journey,
        isNoTrip ? '' : r.purpose,
        r.initialKm?.toStringAsFixed(0) ?? '',
        r.startTime ?? '',
        r.finalKm?.toStringAsFixed(0) ?? '',
        r.endTime ?? '',
        r.distance?.toStringAsFixed(0) ?? '0',
        r.duration ?? '',
        isNoTrip
            ? ''
            : (r.staff.isNotEmpty ? r.staff.split(',').first.trim() : ''),
      ];

      for (int c = 0; c < values.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
        );
        cell.value = TextCellValue(values[c]);
        cell.cellStyle = (c == 2 || c == 3 || c == 4 || c == 11)
            ? cellStyleLeft
            : cellStyle;
      }
    }

    // --- Total row ---
    final totalRow = reports.length + 4;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: totalRow),
    );
    final totalLabelCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
    );
    totalLabelCell.value = TextCellValue('Total KMs Travelled');
    totalLabelCell.cellStyle = totalStyle;

    final totalValueCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: totalRow),
    );
    totalValueCell.value = TextCellValue(totalKm.toStringAsFixed(0));
    totalValueCell.cellStyle = totalStyle;

    // --- Signature row ---
    final sigRow = totalRow + 2;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: sigRow),
      CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: sigRow),
    );
    final sigCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: sigRow),
    );
    sigCell.value = TextCellValue(
      '${config?.inchargeDesignation ?? ""}\nGETCO',
    );
    sigCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
    );

    // --- Column widths ---
    sheet.setColumnWidth(0, 6); // Sr No
    sheet.setColumnWidth(1, 12); // Date
    sheet.setColumnWidth(2, 28); // Names
    sheet.setColumnWidth(3, 22); // Places
    sheet.setColumnWidth(4, 22); // Purpose
    sheet.setColumnWidth(5, 10); // Ini KM
    sheet.setColumnWidth(6, 9); // Start
    sheet.setColumnWidth(7, 10); // Final KM
    sheet.setColumnWidth(8, 9); // End
    sheet.setColumnWidth(9, 10); // Distance
    sheet.setColumnWidth(10, 10); // Duration
    sheet.setColumnWidth(11, 14); // Signature

    // --- Save & Share ---
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to encode Excel file');

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'LogBook_${vehicle.vehicleNumber}_${monthName}_$year.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Vehicle LogBook - $monthName $year');
  }
}
