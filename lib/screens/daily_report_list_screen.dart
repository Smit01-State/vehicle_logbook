import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/daily_report.dart';
import 'trip_entry_screen.dart';

class DailyReportListScreen extends StatefulWidget {
  const DailyReportListScreen({super.key});

  @override
  State<DailyReportListScreen> createState() => _DailyReportListScreenState();
}

class _DailyReportListScreenState extends State<DailyReportListScreen> {
  List<DailyReport> _reports = [];
  List<DailyReport> _filteredReports = [];
  bool _isLoading = true;
  String? _selectedMonth;
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final reports = await DatabaseHelper.instance.getAllDailyReports();
    final months = <String>{};
    for (final r in reports) {
      months.add(DateFormat('MMMM-yyyy').format(r.date));
    }
    setState(() {
      _reports = reports;
      _availableMonths = months.toList()..sort((a, b) {
        final da = DateFormat('MMMM-yyyy').parse(a);
        final db = DateFormat('MMMM-yyyy').parse(b);
        return da.compareTo(db);
      });
      _filterReports();
      _isLoading = false;
    });
  }

  void _filterReports() {
    if (_selectedMonth == null || _selectedMonth == 'All') {
      _filteredReports = List.from(_reports);
    } else {
      _filteredReports = _reports.where((r) {
        return DateFormat('MMMM-yyyy').format(r.date) == _selectedMonth;
      }).toList();
    }
  }

  Color _getTripTypeColor(String tripType) {
    switch (tripType) {
      case 'No Trip': return Colors.grey;
      case 'Vehicle Allotted': return Colors.blue;
      case 'Staff Allotted': return Colors.orange;
      case 'Employee Training': return Colors.purple;
      default: return Colors.green;
    }
  }

  IconData _getTripTypeIcon(String tripType) {
    switch (tripType) {
      case 'No Trip': return Icons.block;
      case 'Vehicle Allotted': return Icons.directions_car;
      case 'Staff Allotted': return Icons.people;
      case 'Employee Training': return Icons.school;
      default: return Icons.route;
    }
  }

  Future<void> _deleteReport(DailyReport report) async {
    final confirmed = await _confirmDelete(report);
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteDailyReport(report.id!);
      _loadReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Entry for ${DateFormat('dd-MM-yyyy').format(report.date)} deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _confirmDelete(DailyReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 36),
        title: const Text('Delete Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to delete this entry?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(DateFormat('dd MMMM yyyy (EEEE)').format(report.date),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (report.journey.isNotEmpty)
                    Text(report.journey, style: const TextStyle(fontSize: 13)),
                  if (report.vehicleName.isNotEmpty)
                    Text(report.vehicleName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _showEntryMenu(DailyReport report) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${DateFormat('dd MMM yyyy').format(report.date)} — ${report.tripType}',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (report.journey.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(report.journey, style: Theme.of(ctx).textTheme.bodySmall),
                ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(ctx).colorScheme.primaryContainer,
                  child: Icon(Icons.edit, color: Theme.of(ctx).colorScheme.primary),
                ),
                title: const Text('Edit Entry'),
                subtitle: const Text('Modify this daily report'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => TripEntryScreen(report: report)));
                  if (result == true) _loadReports();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x20F44336),
                  child: Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text('Delete Entry', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Permanently remove this entry'),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteReport(report);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reports'),
        actions: [
          if (_availableMonths.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter by month',
              onSelected: (v) => setState(() { _selectedMonth = v; _filterReports(); }),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'All', child: Text('All Months')),
                ..._availableMonths.map((m) =>
                    PopupMenuItem(value: m, child: Text(m))),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TripEntryScreen()));
          if (result == true) _loadReports();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredReports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64,
                        color: colorScheme.primary.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('No daily reports yet', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first daily report',
                        style: theme.textTheme.bodySmall),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100, top: 8),
                    itemCount: _filteredReports.length,
                    itemBuilder: (ctx, i) {
                      final r = _filteredReports[i];
                      final tripColor = _getTripTypeColor(r.tripType);
                      return Dismissible(
                        key: ValueKey(r.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.delete, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        confirmDismiss: (_) => _confirmDelete(r),
                        onDismissed: (_) {
                          DatabaseHelper.instance.deleteDailyReport(r.id!);
                          setState(() {
                            _reports.removeWhere((rep) => rep.id == r.id);
                            _filteredReports.removeAt(i);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Entry for ${DateFormat('dd-MM-yyyy').format(r.date)} deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  await DatabaseHelper.instance.insertDailyReport(r);
                                  _loadReports();
                                },
                              ),
                            ),
                          );
                        },
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final result = await Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => TripEntryScreen(report: r)));
                              if (result == true) _loadReports();
                            },
                            onLongPress: () => _showEntryMenu(r),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Date box
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(DateFormat('dd').format(r.date),
                                          style: TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.bold,
                                            color: colorScheme.onPrimaryContainer)),
                                        Text(DateFormat('MMM').format(r.date),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: colorScheme.onPrimaryContainer)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: tripColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(_getTripTypeIcon(r.tripType),
                                                    size: 12, color: tripColor),
                                                  const SizedBox(width: 4),
                                                  Text(r.tripType,
                                                    style: TextStyle(fontSize: 11,
                                                      color: tripColor, fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            if (r.isDaEligible)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('DA ✓',
                                                  style: TextStyle(fontSize: 10,
                                                    color: Colors.green, fontWeight: FontWeight.bold)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (r.journey.isNotEmpty)
                                          Text(r.journey, maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w500)),
                                        if (r.vehicleName.isNotEmpty)
                                          Text(r.vehicleName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall),
                                        Row(
                                          children: [
                                            if (r.distance != null) ...[
                                              Icon(Icons.straighten, size: 12, color: colorScheme.onSurfaceVariant),
                                              const SizedBox(width: 2),
                                              Text('${r.distance?.toStringAsFixed(0)} km',
                                                style: theme.textTheme.bodySmall),
                                              const SizedBox(width: 12),
                                            ],
                                            if (r.duration != null && r.duration!.isNotEmpty) ...[
                                              Icon(Icons.schedule, size: 12, color: colorScheme.onSurfaceVariant),
                                              const SizedBox(width: 2),
                                              Text(r.duration!, style: theme.textTheme.bodySmall),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Delete & navigate icons
                                  Column(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => _deleteReport(r),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(Icons.delete_outline, size: 20,
                                            color: Colors.red.withValues(alpha: 0.7)),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Icon(Icons.chevron_right, size: 18,
                                        color: colorScheme.onSurfaceVariant),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
