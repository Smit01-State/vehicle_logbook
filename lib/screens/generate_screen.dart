import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/vehicle.dart';
import '../models/staff.dart';
import '../generators/logbook_generator.dart';
import '../generators/ta_bill_generator.dart';
import '../generators/logbook_excel_generator.dart';
import '../generators/ta_bill_excel_generator.dart';

enum OutputFormat { pdf, excel }

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  List<Vehicle> _vehicles = [];
  List<Staff> _staffList = [];
  List<Map<String, int>> _availableMonths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final vehicles = await DatabaseHelper.instance.getAllVehicles();
    final staff = await DatabaseHelper.instance.getAllStaff();
    final months = await DatabaseHelper.instance.getAvailableMonths();
    setState(() {
      _vehicles = vehicles;
      _staffList = staff;
      _availableMonths = months;
      _isLoading = false;
    });
  }

  String _monthYearLabel(Map<String, int> m) {
    final date = DateTime(m['year']!, m['month']!);
    return DateFormat('MMMM yyyy').format(date);
  }

  void _showLogBookDialog() {
    Vehicle? selectedVehicle;
    Map<String, int>? selectedMonth;
    OutputFormat selectedFormat = OutputFormat.pdf;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Generate Vehicle Log Book'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Vehicle>(
                decoration: const InputDecoration(labelText: 'Select Vehicle'),
                items: _vehicles.map((v) =>
                    DropdownMenuItem(value: v, child: Text(v.displayName))).toList(),
                onChanged: (v) => setDialogState(() => selectedVehicle = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Map<String, int>>(
                decoration: const InputDecoration(labelText: 'Select Month'),
                items: _availableMonths.map((m) =>
                    DropdownMenuItem(value: m, child: Text(_monthYearLabel(m)))).toList(),
                onChanged: (v) => setDialogState(() => selectedMonth = v),
              ),
              const SizedBox(height: 16),
              // Format Selection
              Row(
                children: [
                  Text('Format:',
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<OutputFormat>(
                      segments: const [
                        ButtonSegment(
                          value: OutputFormat.pdf,
                          label: Text('PDF'),
                          icon: Icon(Icons.picture_as_pdf, size: 18),
                        ),
                        ButtonSegment(
                          value: OutputFormat.excel,
                          label: Text('Excel'),
                          icon: Icon(Icons.table_chart, size: 18),
                        ),
                      ],
                      selected: {selectedFormat},
                      onSelectionChanged: (v) => setDialogState(() => selectedFormat = v.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: Theme.of(ctx).colorScheme.primaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: selectedVehicle != null && selectedMonth != null
                  ? () async {
                      Navigator.pop(ctx);
                      await _generateLogBook(selectedVehicle!, selectedMonth!, selectedFormat);
                    }
                  : null,
              icon: Icon(selectedFormat == OutputFormat.pdf ? Icons.picture_as_pdf : Icons.table_chart, size: 18),
              label: Text('Generate ${selectedFormat == OutputFormat.pdf ? 'PDF' : 'Excel'}'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTABillDialog() {
    Staff? selectedStaff;
    Map<String, int>? selectedMonth;
    OutputFormat selectedFormat = OutputFormat.pdf;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Generate TA Bill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Staff>(
                decoration: const InputDecoration(labelText: 'Select Employee'),
                items: _staffList.map((s) =>
                    DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (v) => setDialogState(() => selectedStaff = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Map<String, int>>(
                decoration: const InputDecoration(labelText: 'Select Month'),
                items: _availableMonths.map((m) =>
                    DropdownMenuItem(value: m, child: Text(_monthYearLabel(m)))).toList(),
                onChanged: (v) => setDialogState(() => selectedMonth = v),
              ),
              const SizedBox(height: 16),
              // Format Selection
              Row(
                children: [
                  Text('Format:',
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<OutputFormat>(
                      segments: const [
                        ButtonSegment(
                          value: OutputFormat.pdf,
                          label: Text('PDF'),
                          icon: Icon(Icons.picture_as_pdf, size: 18),
                        ),
                        ButtonSegment(
                          value: OutputFormat.excel,
                          label: Text('Excel'),
                          icon: Icon(Icons.table_chart, size: 18),
                        ),
                      ],
                      selected: {selectedFormat},
                      onSelectionChanged: (v) => setDialogState(() => selectedFormat = v.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: Theme.of(ctx).colorScheme.primaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: selectedStaff != null && selectedMonth != null
                  ? () async {
                      Navigator.pop(ctx);
                      await _generateTABill(selectedStaff!, selectedMonth!, selectedFormat);
                    }
                  : null,
              icon: Icon(selectedFormat == OutputFormat.pdf ? Icons.picture_as_pdf : Icons.table_chart, size: 18),
              label: Text('Generate ${selectedFormat == OutputFormat.pdf ? 'PDF' : 'Excel'}'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateLogBook(Vehicle vehicle, Map<String, int> month, OutputFormat format) async {
    final scaffold = ScaffoldMessenger.of(context);
    final formatLabel = format == OutputFormat.pdf ? 'PDF' : 'Excel';
    try {
      scaffold.showSnackBar(SnackBar(content: Text('Generating Log Book ($formatLabel)...')));
      if (format == OutputFormat.pdf) {
        await LogBookGenerator.generate(vehicle, month['month']!, month['year']!);
      } else {
        await LogBookExcelGenerator.generate(vehicle, month['month']!, month['year']!);
      }
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(SnackBar(
        content: Text('Log Book $formatLabel generated successfully!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ));
    } catch (e) {
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _generateTABill(Staff staff, Map<String, int> month, OutputFormat format) async {
    final scaffold = ScaffoldMessenger.of(context);
    final formatLabel = format == OutputFormat.pdf ? 'PDF' : 'Excel';
    try {
      scaffold.showSnackBar(SnackBar(content: Text('Generating TA Bill ($formatLabel)...')));
      if (format == OutputFormat.pdf) {
        await TABillGenerator.generate(staff, month['month']!, month['year']!);
      } else {
        await TABillExcelGenerator.generate(staff, month['month']!, month['year']!);
      }
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(SnackBar(
        content: Text('TA Bill $formatLabel generated successfully!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ));
    } catch (e) {
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Documents')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // LogBook card
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _vehicles.isEmpty || _availableMonths.isEmpty ? null : _showLogBookDialog,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.menu_book, size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text('Vehicle Log Book',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Generate monthly vehicle log book with all trip details',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf, size: 16, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text('PDF', style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                              const SizedBox(width: 8),
                              Text('•', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              const SizedBox(width: 8),
                              Icon(Icons.table_chart, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              const Text('Excel', style: TextStyle(fontSize: 12, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _vehicles.isEmpty || _availableMonths.isEmpty ? null : _showLogBookDialog,
                            icon: const Icon(Icons.description),
                            label: const Text('Generate'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // TA Bill card
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _staffList.isEmpty || _availableMonths.isEmpty ? null : _showTABillDialog,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [const Color(0xFFF2704E), const Color(0xFFF2704E).withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.receipt_long, size: 48, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text('TA Bill',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Generate Travelling Allowance bill with Front & Back pages',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf, size: 16, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text('PDF', style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                              const SizedBox(width: 8),
                              Text('•', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              const SizedBox(width: 8),
                              Icon(Icons.table_chart, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              const Text('Excel', style: TextStyle(fontSize: 12, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _staffList.isEmpty || _availableMonths.isEmpty ? null : _showTABillDialog,
                            icon: const Icon(Icons.description),
                            label: const Text('Generate'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF2704E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_availableMonths.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Add daily report entries first to generate documents.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
    );
  }
}
