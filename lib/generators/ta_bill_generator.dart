import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/staff.dart';
import '../models/daily_report.dart';
import '../models/config.dart';
import '../utils/rupee_to_words.dart';
import '../utils/constants.dart';

class TABillGenerator {
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

    // Calculate fare totals
    double totalFare = 0;
    for (final r in reports) {
      totalFare += r.parsedFareTotal;
    }

    final netAmount = totalFare + totalDaAmount;

    final pdf = pw.Document();

    // Back page - Journey details (landscape)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => _buildBackPage(reports, staff, config, monthName, year),
      ),
    );

    // Front page - Voucher (portrait)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => _buildFrontPage(
          staff, config, monthName, year,
          totalFare, totalDaAmount, totalDaDays, daAmount, netAmount,
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'TA_Bill_${staff.name}_$monthName$year',
    );
  }

  static pw.Widget _buildBackPage(
    List<DailyReport> reports, Staff staff, Config? config,
    String monthName, int year,
  ) {
    int srNo = 0;
    final rows = <List<String>>[];

    for (final r in reports) {
      if (r.tripType == 'No Trip') continue;
      srNo++;
      final daEligible = r.isDaEligible;
      rows.add([
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
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text('Gujarat Energy Transmission Corporation LTD.',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Name: ${staff.name}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text('Designation: ${staff.designation}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text('Month: $monthName-$year',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text('BACK', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 6),
          headerAlignment: pw.Alignment.center,
          cellAlignment: pw.Alignment.center,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellPadding: const pw.EdgeInsets.all(2),
          columnWidths: {
            0: const pw.FixedColumnWidth(20),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FixedColumnWidth(42),
            3: const pw.FixedColumnWidth(30),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FixedColumnWidth(42),
            6: const pw.FixedColumnWidth(30),
            7: const pw.FixedColumnWidth(30),
            8: const pw.FixedColumnWidth(30),
            9: const pw.FixedColumnWidth(30),
            10: const pw.FixedColumnWidth(25),
            11: const pw.FixedColumnWidth(30),
            12: const pw.FlexColumnWidth(2),
            13: const pw.FixedColumnWidth(30),
            14: const pw.FixedColumnWidth(35),
          },
          headers: [
            'Sr.',
            'Departure\nStation',
            'Dept.\nDate',
            'Dept.\nTime',
            'Arrival\nStation',
            'Arr.\nDate',
            'Arr.\nTime',
            'Kind of\nJourney',
            'Fare\n(Rs.)',
            'KMs',
            'DA\nDays',
            'Actual\nExp.',
            'Purpose',
            'Total',
            'Remarks',
          ],
          data: rows,
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 100,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(style: pw.BorderStyle.dotted)),
                  ),
                  height: 20,
                ),
                pw.Text('Signature of the Officer',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFrontPage(
    Staff staff, Config? config, String monthName, int year,
    double totalFare, double totalDaAmount, int daDays, double daRate, double netAmount,
  ) {
    final amountInWords = rupeeToWords(netAmount);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text('Gujarat Energy Transmission Corporation LTD.',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('TRAVELLING ALLOWANCE BILL',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('FRONT', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
        pw.SizedBox(height: 8),

        // Employee details
        _infoRow('Name :', staff.name),
        _infoRow('Designation :', staff.designation),
        _infoRow('Emp. No. :', staff.empNo),
        _infoRow('Mobile :', staff.mobile),
        _infoRow('Section :', staff.subStation),
        _infoRow('Month :', '$monthName - $year'),
        _infoRow('Basic Salary :', '₹ ${staff.basicSalary.toStringAsFixed(0)}'),
        pw.SizedBox(height: 8),
        pw.Divider(),

        // Certificates
        pw.Text('Certificates:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        ...AppConstants.certificates.map((c) =>
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(c, style: const pw.TextStyle(fontSize: 6.5)),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(),

        // Financial Summary
        pw.Text('Summary:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        _summaryRow('1. Leave Travel Concession', '-'),
        _summaryRow('2. Travelling Expenses', totalFare > 0 ? '₹ ${totalFare.toStringAsFixed(2)}' : '-'),
        _summaryRow('3. Travelling Allowances (DA) [$daDays days × ₹${daRate.toStringAsFixed(0)}]',
            '₹ ${totalDaAmount.toStringAsFixed(2)}'),
        _summaryRow('4. Leave Travelling Concession', '-'),
        _summaryRow('5. Less: Advance', '-'),
        pw.Divider(thickness: 2),
        _summaryRow('Net Amount Payable', '₹ ${netAmount.toStringAsFixed(2)}',
            isBold: true, fontSize: 10),
        pw.SizedBox(height: 4),
        pw.Text('Amount in words: $amountInWords',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic)),
        pw.SizedBox(height: 16),

        // Signature blocks
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _signatureBlock('Prepared By'),
            _signatureBlock('Checked By'),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _signatureBlock('Dy.Supdt.(A)'),
            _signatureBlock('Supdt. (A)'),
            _signatureBlock('Account Officer (PBG)'),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            _signatureBlock('Accounts Officer (Cash)'),
          ],
        ),
        pw.SizedBox(height: 12),

        // Payment section
        pw.Divider(),
        pw.Text('PAYMENT PARTICULARS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 7),
                headers: ['', 'CASH', 'CHEQUE'],
                data: [['Paid By', '1', '2']],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Bank Cheque No. : _____________', style: const pw.TextStyle(fontSize: 7)),
                  pw.Text('Cheque Date : _____________', style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _signatureBlock('Signature of Payee'),
            pw.Column(
              children: [
                pw.Text('Date :', style: const pw.TextStyle(fontSize: 7)),
              ],
            ),
            _signatureBlock('Cashier'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String amount, {bool isBold = false, double fontSize = 8}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(amount, style: pw.TextStyle(fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _signatureBlock(String title) {
    return pw.Column(
      children: [
        pw.Container(
          width: 80,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(style: pw.BorderStyle.dotted)),
          ),
          height: 20,
        ),
        pw.Text(title, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
