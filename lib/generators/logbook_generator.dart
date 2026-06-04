import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/vehicle.dart';

import '../models/config.dart';

class LogBookGenerator {
  static Future<void> generate(Vehicle vehicle, int month, int year) async {
    final reports = await DatabaseHelper.instance.getDailyReportsByVehicleAndMonth(
        vehicle.displayName, month, year);
    final config = await DatabaseHelper.instance.getConfig();

    if (reports.isEmpty) {
      throw Exception('No trips found for ${vehicle.vehicleNumber} in ${DateFormat('MMMM yyyy').format(DateTime(year, month))}');
    }

    final pdf = pw.Document();
    final monthName = DateFormat('MMMM').format(DateTime(year, month));
    double totalKm = 0;
    for (final r in reports) {
      totalKm += r.distance ?? 0;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildHeader(config, vehicle, monthName, year),
        footer: (context) => _buildFooter(config, totalKm),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.all(4),
            columnWidths: {
              0: const pw.FixedColumnWidth(25),   // Sr.No
              1: const pw.FixedColumnWidth(55),   // Date
              2: const pw.FlexColumnWidth(2.5),   // Names
              3: const pw.FlexColumnWidth(2),     // Places
              4: const pw.FlexColumnWidth(2),     // Purpose
              5: const pw.FixedColumnWidth(40),   // Ini KM
              6: const pw.FixedColumnWidth(35),   // Start
              7: const pw.FixedColumnWidth(40),   // Final KM
              8: const pw.FixedColumnWidth(35),   // End
              9: const pw.FixedColumnWidth(40),   // Distance
              10: const pw.FixedColumnWidth(40),  // Duration
              11: const pw.FixedColumnWidth(50),  // Signature
            },
            headers: [
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
            ],
            data: List.generate(reports.length, (i) {
              final r = reports[i];
              if (r.tripType == 'No Trip') {
                return [
                  '${i + 1}',
                  DateFormat('dd-MM-yyyy').format(r.date),
                  '',
                  '::::: No Trip :::::',
                  '',
                  r.initialKm?.toStringAsFixed(0) ?? '',
                  r.startTime ?? '',
                  r.finalKm?.toStringAsFixed(0) ?? '',
                  r.endTime ?? '',
                  r.distance?.toStringAsFixed(0) ?? '0',
                  r.duration ?? '',
                  '',
                ];
              }
              return [
                '${i + 1}',
                DateFormat('dd-MM-yyyy').format(r.date),
                r.staff,
                r.journey,
                r.purpose,
                r.initialKm?.toStringAsFixed(0) ?? '',
                r.startTime ?? '',
                r.finalKm?.toStringAsFixed(0) ?? '',
                r.endTime ?? '',
                r.distance?.toStringAsFixed(0) ?? '0',
                r.duration ?? '',
                r.staff.isNotEmpty ? r.staff.split(',').first.trim() : '',
              ];
            }),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'LogBook_${vehicle.vehicleNumber}_$monthName$year',
    );
  }

  static pw.Widget _buildHeader(Config? config, Vehicle vehicle, String monthName, int year) {
    return pw.Column(
      children: [
        pw.Text('Gujarat Energy Transmission Corporation Ltd.',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Division: ${config?.divisionName ?? ""}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text('Log Book for Vehicle No. ${vehicle.vehicleNumber}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text('Prepared By 220kV Deodar SS',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Text('Entries for the Month of $monthName-$year',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildFooter(Config? config, double totalKm) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('Total KMs Travelled: ',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Text(totalKm.toStringAsFixed(0),
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              children: [
                pw.Text(config?.inchargeDesignation ?? '',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('GETCO',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
