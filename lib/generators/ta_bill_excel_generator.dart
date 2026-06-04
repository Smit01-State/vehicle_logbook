import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';
import '../models/staff.dart';
import '../models/config.dart';
import '../utils/rupee_to_words.dart';
import '../utils/constants.dart';

class TABillExcelGenerator {
  static Future<void> generate(Staff staff, int month, int year) async {
    final reports = await DatabaseHelper.instance.getDailyReportsByEmployeeAndMonth(
        staff.name, month, year);
    final config = await DatabaseHelper.instance.getConfig();
    final monthName = DateFormat('MMMM').format(DateTime(year, month));

    if (reports.isEmpty) {
      throw Exception('No trips found for ${staff.name} in $monthName $year');
    }

    // Calculate DA
    final eligibleReports = reports.where((r) => r.isDaEligible).toList();
    final daAmount = await DatabaseHelper.instance.getDaRate(
        staff.basicSalary, config?.hqCityClass ?? 'Other', designation: staff.designation);
    final totalDaDays = eligibleReports.length;
    final totalDaAmount = daAmount * totalDaDays;
    double totalFare = 0;
    for (final r in reports) {
      totalFare += r.parsedFareTotal;
    }
    final netAmount = totalFare + totalDaAmount;

    final excel = Excel.createExcel();

    // ==================== BACK PAGE (Journey Details) ====================
    excel.rename(excel.getDefaultSheet()!, 'TA Bill Back');
    final back = excel['TA Bill Back'];

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 8,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#0057A7'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    final cellStyle = CellStyle(
      fontSize: 8,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 12,
      horizontalAlign: HorizontalAlign.Center,
    );

    final boldStyle = CellStyle(
      bold: true,
      fontSize: 9,
    );

    // Title
    back.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('O1'));
    final backTitle = back.cell(CellIndex.indexByString('A1'));
    backTitle.value = TextCellValue('Gujarat Energy Transmission Corporation LTD.');
    backTitle.cellStyle = titleStyle;

    // Employee info row
    back.cell(CellIndex.indexByString('A2'))
      ..value = TextCellValue('Name: ${staff.name}')
      ..cellStyle = boldStyle;
    back.cell(CellIndex.indexByString('F2'))
      ..value = TextCellValue('Designation: ${staff.designation}')
      ..cellStyle = boldStyle;
    back.cell(CellIndex.indexByString('K2'))
      ..value = TextCellValue('Month: $monthName-$year')
      ..cellStyle = boldStyle;

    back.cell(CellIndex.indexByString('A3'))
      ..value = TextCellValue('BACK')
      ..cellStyle = boldStyle;

    // Headers
    final backHeaders = [
      'Sr.', 'Departure\nStation', 'Dept.\nDate', 'Dept.\nTime', 'Arrival\nStation',
      'Arr.\nDate', 'Arr.\nTime', 'Kind of\nJourney', 'Fare\n(Rs.)', 'KMs',
      'DA\nDays', 'Actual\nExp.', 'Purpose', 'Total', 'Remarks',
    ];

    for (int c = 0; c < backHeaders.length; c++) {
      final cell = back.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3));
      cell.value = TextCellValue(backHeaders[c]);
      cell.cellStyle = headerStyle;
    }

    // Data
    int srNo = 0;
    for (final r in reports) {
      if (r.tripType == 'No Trip') continue;
      srNo++;
      final row = srNo + 3;
      final daEligible = r.isDaEligible;

      final values = [
        '$srNo',
        r.journey.split('-').first.trim(),
        DateFormat('dd-MM-yy').format(r.date),
        r.startTime ?? '',
        r.journey.split('-').last.trim(),
        DateFormat('dd-MM-yy').format(r.date),
        r.endTime ?? '',
        'Road',
        r.parsedFareTotal > 0 ? r.parsedFareTotal.toStringAsFixed(0) : '-',
        r.distance?.toStringAsFixed(0) ?? '0',
        daEligible ? '1' : '-',
        '-',
        r.purpose,
        (r.parsedFareTotal + (daEligible ? 1 : 0)).toStringAsFixed(0),
        '',
      ];

      for (int c = 0; c < values.length; c++) {
        final cell = back.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
        cell.value = TextCellValue(values[c]);
        cell.cellStyle = cellStyle;
      }
    }

    // Column widths for back page
    back.setColumnWidth(0, 5);
    back.setColumnWidth(1, 14);
    back.setColumnWidth(2, 10);
    back.setColumnWidth(3, 8);
    back.setColumnWidth(4, 14);
    back.setColumnWidth(5, 10);
    back.setColumnWidth(6, 8);
    back.setColumnWidth(7, 8);
    back.setColumnWidth(8, 8);
    back.setColumnWidth(9, 7);
    back.setColumnWidth(10, 6);
    back.setColumnWidth(11, 8);
    back.setColumnWidth(12, 22);
    back.setColumnWidth(13, 8);
    back.setColumnWidth(14, 10);

    // ==================== FRONT PAGE (Voucher) ====================
    final front = excel['TA Bill Front'];

    final frontTitleStyle = CellStyle(
      bold: true,
      fontSize: 13,
      horizontalAlign: HorizontalAlign.Center,
    );

    final frontSubStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
    );

    final labelStyle = CellStyle(
      bold: true,
      fontSize: 10,
    );

    final valueStyle = CellStyle(
      fontSize: 10,
    );

    final summaryLabelStyle = CellStyle(
      fontSize: 10,
    );

    final summaryValueStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Right,
    );

    final totalLabelStyle = CellStyle(
      bold: true,
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#E8F0FE'),
    );

    final totalValueStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Right,
      backgroundColorHex: ExcelColor.fromHexString('#E8F0FE'),
    );

    front.setColumnWidth(0, 18);
    front.setColumnWidth(1, 30);
    front.setColumnWidth(2, 20);
    front.setColumnWidth(3, 20);

    // Title
    front.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));
    front.cell(CellIndex.indexByString('A1'))
      ..value = TextCellValue('Gujarat Energy Transmission Corporation LTD.')
      ..cellStyle = frontTitleStyle;

    front.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('D2'));
    front.cell(CellIndex.indexByString('A2'))
      ..value = TextCellValue('TRAVELLING ALLOWANCE BILL - FRONT')
      ..cellStyle = frontSubStyle;

    // Employee details
    int row = 3;
    void addInfoRow(String label, String value) {
      front.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue(label)
        ..cellStyle = labelStyle;
      front.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        ..value = TextCellValue(value)
        ..cellStyle = valueStyle;
      row++;
    }

    addInfoRow('Name :', staff.name);
    addInfoRow('Designation :', staff.designation);
    addInfoRow('Emp. No. :', staff.empNo);
    addInfoRow('Mobile :', staff.mobile);
    addInfoRow('Section :', staff.subStation);
    addInfoRow('Month :', '$monthName - $year');
    addInfoRow('Basic Salary :', '₹ ${staff.basicSalary.toStringAsFixed(0)}');

    row++; // blank row

    // Certificates header
    front.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
    );
    front.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('Certificates:')
      ..cellStyle = labelStyle;
    row++;

    for (final cert in AppConstants.certificates) {
      front.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
      );
      front.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue(cert)
        ..cellStyle = CellStyle(fontSize: 8, textWrapping: TextWrapping.WrapText);
      row++;
    }

    row++; // blank row

    // Financial Summary header
    front.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
    );
    front.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('Summary:')
      ..cellStyle = labelStyle;
    row++;

    void addSummaryRow(String label, String amount, {bool isBold = false}) {
      front.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      );
      front.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue(label)
        ..cellStyle = isBold ? totalLabelStyle : summaryLabelStyle;
      front.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
        ..value = TextCellValue(amount)
        ..cellStyle = isBold ? totalValueStyle : summaryValueStyle;
      row++;
    }

    addSummaryRow('1. Leave Travel Concession', '-');
    addSummaryRow('2. Travelling Expenses', totalFare > 0 ? '₹ ${totalFare.toStringAsFixed(2)}' : '-');
    addSummaryRow('3. Travelling Allowances (DA) [$totalDaDays days × ₹${daAmount.toStringAsFixed(0)}]',
        '₹ ${totalDaAmount.toStringAsFixed(2)}');
    addSummaryRow('4. Leave Travelling Concession', '-');
    addSummaryRow('5. Less: Advance', '-');
    addSummaryRow('Net Amount Payable', '₹ ${netAmount.toStringAsFixed(2)}', isBold: true);

    row++;
    front.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
    );
    front.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('Amount in words: ${rupeeToWords(netAmount)}')
      ..cellStyle = CellStyle(bold: true, fontSize: 9);

    // --- Save & Share ---
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to encode Excel file');

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'TA_Bill_${staff.name}_${monthName}_$year.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'TA Bill - ${staff.name} - $monthName $year');
  }
}
