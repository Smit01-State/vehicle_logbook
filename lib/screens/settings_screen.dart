import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';
import '../models/config.dart';
import '../models/da_rate.dart';
import '../utils/constants.dart';
import 'division_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Config? _config;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await DatabaseHelper.instance.getConfig();
    setState(() => _config = config);
  }

  Future<void> _exportData() async {
    try {
      final jsonStr = await DatabaseHelper.instance.exportAllData();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/vehicle_logbook_backup.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Vehicle LogBook Backup',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importData() async {
    final textCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste the JSON backup content below:'),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: TextFormField(
                controller: textCtrl,
                decoration: InputDecoration(
                  hintText: '{"version":"1.3",...}',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) textCtrl.text = data!.text!;
                    },
                  ),
                ),
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
        ],
      ),
    );
    if (confirmed == true && textCtrl.text.isNotEmpty) {
      try {
        jsonDecode(textCtrl.text); // Validate
        await DatabaseHelper.instance.importAllData(textCtrl.text);
        _loadConfig();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Data imported successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will permanently delete ALL data including staff, vehicles, and daily reports. This cannot be undone!\n\nExport a backup first if needed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.resetAllData();
      setState(() => _config = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been reset.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDaRateEditor() async {
    final rates = await DatabaseHelper.instance.getAllDaRates();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('DA Rate Configuration',
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Basic Pay Range → A-1 / A / B-1 / Other',
                style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 16),
              ...rates.map((rate) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(
                    rate.basicPayRange == 'Other' ? 'Other' : '≥ ₹${rate.basicPayRange}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(rate.allRatesDisplay),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _editDaRate(rate);
                    },
                  ),
                ),
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _editDaRate(DaRate rate) {
    final a1Ctrl = TextEditingController(text: rate.a1Class.toStringAsFixed(0));
    final aCtrl = TextEditingController(text: rate.aClass.toStringAsFixed(0));
    final b1Ctrl = TextEditingController(text: rate.b1Class.toStringAsFixed(0));
    final oCtrl = TextEditingController(text: rate.other.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit DA Rate: ${rate.basicPayRange == "Other" ? "Other" : "≥ ₹${rate.basicPayRange}"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: a1Ctrl, decoration: const InputDecoration(labelText: 'A-1 Class'),
              keyboardType: TextInputType.number),
            TextFormField(controller: aCtrl, decoration: const InputDecoration(labelText: 'A Class'),
              keyboardType: TextInputType.number),
            TextFormField(controller: b1Ctrl, decoration: const InputDecoration(labelText: 'B-1 Class'),
              keyboardType: TextInputType.number),
            TextFormField(controller: oCtrl, decoration: const InputDecoration(labelText: 'Other'),
              keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              rate.a1Class = double.tryParse(a1Ctrl.text) ?? rate.a1Class;
              rate.aClass = double.tryParse(aCtrl.text) ?? rate.aClass;
              rate.b1Class = double.tryParse(b1Ctrl.text) ?? rate.b1Class;
              rate.other = double.tryParse(oCtrl.text) ?? rate.other;
              await DatabaseHelper.instance.updateDaRate(rate);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Config info card
          if (_config != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Division Configuration',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const DivisionSetupScreen(isEditing: true)));
                            _loadConfig();
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    _configRow('Division', _config!.divisionName),
                    _configRow('Head Quarter', _config!.headQuarter),
                    _configRow('City Class', _config!.hqCityClass),
                    _configRow('Incharge', _config!.inchargeDesignation),
                    if (_config!.groupJE)
                      _configRow('Group SS', _config!.groupSSName ?? '-'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),

          // DA Rates
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(Icons.currency_rupee, color: colorScheme.onSecondaryContainer),
              ),
              title: const Text('DA Rate Configuration'),
              subtitle: const Text('Edit Daily Allowance rates'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showDaRateEditor,
            ),
          ),
          const SizedBox(height: 16),

          // Data Management
          Text('Data Management', style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold, color: colorScheme.primary)),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                    child: const Icon(Icons.upload, color: Colors.green),
                  ),
                  title: const Text('Export Data'),
                  subtitle: const Text('Save backup as JSON file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportData,
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withValues(alpha: 0.15),
                    child: const Icon(Icons.download, color: Colors.blue),
                  ),
                  title: const Text('Import Data'),
                  subtitle: const Text('Restore from JSON backup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _importData,
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withValues(alpha: 0.15),
                    child: const Icon(Icons.delete_forever, color: Colors.red),
                  ),
                  title: const Text('Reset All Data'),
                  subtitle: const Text('Delete everything and start fresh'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _resetAllData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.directions_car_filled, size: 40, color: colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(AppConstants.appSubtitle, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(AppConstants.appVersion, style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(AppConstants.orgName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _configRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label,
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
