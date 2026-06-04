import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/daily_report.dart';
import '../models/staff.dart';
import '../models/vehicle.dart';
import '../utils/constants.dart';

class TripEntryScreen extends StatefulWidget {
  final DailyReport? report;
  const TripEntryScreen({super.key, this.report});

  @override
  State<TripEntryScreen> createState() => _TripEntryScreenState();
}

class _TripEntryScreenState extends State<TripEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _tripType = 'Normal';
  DateTime? _selectedDate;
  String? _selectedVehicle;

  List<Staff> _allStaff = [];
  List<Staff> _selectedStaff = [];
  List<Vehicle> _vehicles = [];

  final _journeyCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _initialKmCtrl = TextEditingController();
  final _finalKmCtrl = TextEditingController();
  final _fareCtrl = TextEditingController();
  final _vehicleTextCtrl = TextEditingController();
  final _empsManualCtrl = TextEditingController();
  final _distanceManualCtrl = TextEditingController();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _cityClass = 'Other';
  bool _isLoading = false;

  bool get _isEditing => widget.report != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final staff = await DatabaseHelper.instance.getAllStaff();
    final vehicles = await DatabaseHelper.instance.getAllVehicles();
    final config = await DatabaseHelper.instance.getConfig();

    setState(() {
      _allStaff = staff;
      _vehicles = vehicles;
      if (config != null) _cityClass = config.hqCityClass;
    });

    if (_isEditing) _populateForm();
  }

  void _populateForm() {
    final r = widget.report!;
    setState(() {
      _tripType = r.tripType;
      _selectedDate = r.date;
      _selectedVehicle = r.vehicleName.isNotEmpty ? r.vehicleName : null;
      _vehicleTextCtrl.text = r.vehicleName;
      _journeyCtrl.text = r.journey;
      _purposeCtrl.text = r.purpose;
      _initialKmCtrl.text = r.initialKm?.toStringAsFixed(0) ?? '';
      _finalKmCtrl.text = r.finalKm?.toStringAsFixed(0) ?? '';
      _fareCtrl.text = r.fare ?? '';
      _cityClass = r.cityClass;
      _distanceManualCtrl.text = r.distance?.toStringAsFixed(0) ?? '';

      if (r.startTime != null && r.startTime!.isNotEmpty) {
        final parts = r.startTime!.split(':');
        _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (r.endTime != null && r.endTime!.isNotEmpty) {
        final parts = r.endTime!.split(':');
        _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }

      // Restore selected staff
      if (r.staff.isNotEmpty) {
        final names = r.staff.split(',').map((s) => s.trim()).toList();
        _selectedStaff = _allStaff.where((s) => names.contains(s.name)).toList();
        if (r.tripType == 'Vehicle Allotted') {
          _empsManualCtrl.text = r.staff;
        }
      }
    });
  }

  double get _distance {
    final ini = double.tryParse(_initialKmCtrl.text) ?? 0;
    final fin = double.tryParse(_finalKmCtrl.text) ?? 0;
    return fin - ini;
  }

  String get _duration {
    if (_startTime == null || _endTime == null) return '';
    final startMin = _startTime!.hour * 60 + _startTime!.minute;
    final endMin = _endTime!.hour * 60 + _endTime!.minute;
    final diff = endMin - startMin;
    if (diff < 0) return '00:00';
    return '${(diff ~/ 60).toString().padLeft(2, '0')}:${(diff % 60).toString().padLeft(2, '0')}';
  }

  bool get _isDaEligible {
    if (_tripType == 'Employee Training') return true;
    final dist = _tripType == 'Employee Training'
        ? (double.tryParse(_distanceManualCtrl.text) ?? 0)
        : _distance;
    if (_startTime == null || _endTime == null) return false;
    final startMin = _startTime!.hour * 60 + _startTime!.minute;
    final endMin = _endTime!.hour * 60 + _endTime!.minute;
    return dist >= 8 && (endMin - startMin) >= 480;
  }

  String _formatTime(TimeOfDay? t) =>
      t != null ? '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}' : '';

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
    );
    if (time != null) setState(() => isStart ? _startTime = time : _endTime = time);
  }

  void _selectEmployees() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Select Employees',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          if (_selectedStaff.length == _allStaff.length) {
                            _selectedStaff.clear();
                          } else {
                            _selectedStaff = List.from(_allStaff);
                          }
                        });
                      },
                      child: Text(_selectedStaff.length == _allStaff.length ? 'Deselect All' : 'Select All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _allStaff.length,
                    itemBuilder: (ctx, i) {
                      final s = _allStaff[i];
                      final selected = _selectedStaff.any((ss) => ss.id == s.id);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (v) {
                          setModalState(() {
                            if (v == true) {
                              _selectedStaff.add(s);
                            } else {
                              _selectedStaff.removeWhere((ss) => ss.id == s.id);
                            }
                          });
                        },
                        title: Text(s.name),
                        subtitle: Text(s.designation),
                        dense: true,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: Text('Done (${_selectedStaff.length} selected)'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedDate == null) {
      _showError('Please select the Date of Journey');
      return;
    }

    // Validation based on trip type
    if (_tripType == 'No Trip') {
      if (_selectedVehicle == null) { _showError('Please select a Vehicle'); return; }
      if (_initialKmCtrl.text.isEmpty) { _showError('Please enter Initial KM'); return; }
      if (_finalKmCtrl.text.isEmpty) { _showError('Please enter Final KM'); return; }
    } else if (_tripType == 'Employee Training') {
      if (_startTime == null) { _showError('Please select Start Time'); return; }
      if (_endTime == null) { _showError('Please select End Time'); return; }
      if (_selectedStaff.isEmpty) { _showError('Please select Employees'); return; }
      if (_journeyCtrl.text.isEmpty) { _showError('Please enter Journey details'); return; }
      if (_purposeCtrl.text.isEmpty) { _showError('Please enter Purpose'); return; }
    } else {
      if (_tripType == 'Staff Allotted') {
        if (_vehicleTextCtrl.text.isEmpty) { _showError('Please enter Vehicle details'); return; }
      } else {
        if (_selectedVehicle == null) { _showError('Please select a Vehicle'); return; }
      }
      if (_initialKmCtrl.text.isEmpty) { _showError('Please enter Initial KM'); return; }
      if (_finalKmCtrl.text.isEmpty) { _showError('Please enter Final KM'); return; }
      if (_startTime == null) { _showError('Please select Start Time'); return; }
      if (_endTime == null) { _showError('Please select End Time'); return; }
      if (_tripType == 'Vehicle Allotted') {
        if (_empsManualCtrl.text.isEmpty) { _showError('Please enter Employee names'); return; }
      } else {
        if (_selectedStaff.isEmpty) { _showError('Please select Employees'); return; }
      }
      if (_journeyCtrl.text.isEmpty) { _showError('Please enter Journey details'); return; }
      if (_purposeCtrl.text.isEmpty) { _showError('Please enter Purpose'); return; }
    }

    setState(() => _isLoading = true);

    String staffStr = '';
    if (_tripType == 'Vehicle Allotted') {
      staffStr = _empsManualCtrl.text.trim();
    } else {
      staffStr = _selectedStaff.map((s) => s.name).join(', ');
    }

    String vehicleName = '';
    if (_tripType == 'Staff Allotted') {
      vehicleName = _vehicleTextCtrl.text.trim();
    } else if (_tripType == 'Employee Training') {
      vehicleName = _selectedVehicle ?? '';
    } else {
      vehicleName = _selectedVehicle ?? '';
    }

    final dist = _tripType == 'Employee Training'
        ? (double.tryParse(_distanceManualCtrl.text) ?? 0)
        : _distance;

    final report = DailyReport(
      id: widget.report?.id,
      date: _selectedDate!,
      vehicleName: vehicleName,
      staff: staffStr,
      journey: _journeyCtrl.text.trim(),
      purpose: _purposeCtrl.text.trim(),
      initialKm: double.tryParse(_initialKmCtrl.text),
      startTime: _formatTime(_startTime),
      finalKm: double.tryParse(_finalKmCtrl.text),
      endTime: _formatTime(_endTime),
      distance: dist,
      duration: _duration,
      fare: _fareCtrl.text.trim(),
      cityClass: _cityClass,
      tripType: _tripType,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateDailyReport(report);
    } else {
      await DatabaseHelper.instance.insertDailyReport(report);
    }

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context, true);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _journeyCtrl.dispose();
    _purposeCtrl.dispose();
    _initialKmCtrl.dispose();
    _finalKmCtrl.dispose();
    _fareCtrl.dispose();
    _vehicleTextCtrl.dispose();
    _empsManualCtrl.dispose();
    _distanceManualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showVehicleDropdown = _tripType != 'Staff Allotted' && _tripType != 'Employee Training';
    final showVehicleText = _tripType == 'Staff Allotted';
    final showKm = _tripType != 'Employee Training';
    final showTime = _tripType != 'No Trip';
    final showEmployeeSelect = _tripType != 'No Trip' && _tripType != 'Vehicle Allotted';
    final showManualEmps = _tripType == 'Vehicle Allotted';
    final showJourneyPurpose = _tripType != 'No Trip';
    final showFare = _tripType == 'Employee Training';
    final showManualDistance = _tripType == 'Employee Training';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'New Daily Report'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Trip Type selector
            Text('Trip Type', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppConstants.tripTypes.map((t) {
                  final selected = _tripType == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: selected,
                      onSelected: (_) => setState(() => _tripType = t),
                      selectedColor: colorScheme.primary,
                      labelStyle: TextStyle(
                        color: selected ? colorScheme.onPrimary : null,
                        fontWeight: selected ? FontWeight.bold : null,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Date
            Text('Date', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? DateFormat('dd-MM-yyyy (EEEE)').format(_selectedDate!)
                          : 'Select Date',
                      style: TextStyle(
                        color: _selectedDate != null ? null : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle dropdown
            if (showVehicleDropdown) ...[
              Text('Vehicle', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedVehicle,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.directions_car)),
                hint: const Text('Select Vehicle'),
                items: _vehicles.map((v) =>
                    DropdownMenuItem(value: v.displayName, child: Text(v.displayName))).toList(),
                onChanged: (v) => setState(() => _selectedVehicle = v),
              ),
              const SizedBox(height: 16),
            ],

            // Vehicle text input (for Staff Allotted)
            if (showVehicleText) ...[
              Text('Vehicle Details', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _vehicleTextCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.directions_car),
                  hintText: 'Enter vehicle number/name',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // KM readings
            if (showKm) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Initial KM', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _initialKmCtrl,
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.speed)),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Final KM', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _finalKmCtrl,
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.speed)),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_initialKmCtrl.text.isNotEmpty && _finalKmCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _distance >= 8 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Distance: ${_distance.toStringAsFixed(0)} km',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _distance >= 8 ? Colors.green : Colors.red,
                      )),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Manual distance (for Training)
            if (showManualDistance) ...[
              Text('Distance (km)', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _distanceManualCtrl,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.straighten)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            // Time pickers
            if (showTime) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Time', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _pickTime(true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 20, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(_startTime != null ? _formatTime(_startTime) : 'Select',
                                  style: TextStyle(color: _startTime != null ? null : colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('End Time', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _pickTime(false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 20, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(_endTime != null ? _formatTime(_endTime) : 'Select',
                                  style: TextStyle(color: _endTime != null ? null : colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_startTime != null && _endTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isDaEligible ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Duration: $_duration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isDaEligible ? Colors.green : Colors.red,
                      )),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Employee selection
            if (showEmployeeSelect) ...[
              Text('Employees', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectEmployees,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedStaff.isNotEmpty
                              ? _selectedStaff.map((s) => s.name).join(', ')
                              : 'Select Employees',
                          style: TextStyle(
                            color: _selectedStaff.isNotEmpty ? null : colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Manual employee input (Vehicle Allotted)
            if (showManualEmps) ...[
              Text('Employee Names', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _empsManualCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.people),
                  hintText: 'e.g., J R Bhavsar, T M Kakadia',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
            ],

            // Journey & Purpose
            if (showJourneyPurpose) ...[
              Text('Journey Details', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _journeyCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.route),
                  hintText: 'e.g., Deodar - Palanpur - Deodar Back',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Text('Purpose', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _purposeCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.info_outline),
                  hintText: 'Purpose of journey',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
            ],

            // Fare (Training only)
            if (showFare) ...[
              Text('Travel Fare', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fareCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.currency_rupee),
                  hintText: 'e.g., 40 + 50 + 60',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // City Class
            if (_tripType != 'No Trip') ...[
              Text('City Class', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.cityClasses.map((c) {
                  final selected = _cityClass == c;
                  return ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) => setState(() => _cityClass = c),
                    selectedColor: colorScheme.primary,
                    labelStyle: TextStyle(
                      color: selected ? colorScheme.onPrimary : null,
                      fontWeight: selected ? FontWeight.bold : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // DA Eligibility notice
            if (_tripType != 'No Trip')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDaEligible ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDaEligible ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isDaEligible ? Icons.check_circle : Icons.warning_amber,
                      color: _isDaEligible ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isDaEligible ? 'Eligible for Daily Allowance' : 'Not Eligible for Daily Allowance',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isDaEligible ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_isEditing ? Icons.save : Icons.add),
                label: Text(_isLoading ? 'Saving...' : (_isEditing ? 'Update Entry' : 'Add Entry'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
