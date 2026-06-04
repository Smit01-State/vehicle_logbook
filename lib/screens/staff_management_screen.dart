import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/staff.dart';
import '../models/vehicle.dart';
import '../utils/constants.dart';
import 'vehicle_management_screen.dart';
import 'division_setup_screen.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<Staff> _staffList = [];
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final staff = await DatabaseHelper.instance.getAllStaff();
    final vehicles = await DatabaseHelper.instance.getAllVehicles();
    setState(() {
      _staffList = staff;
      _vehicles = vehicles;
      _isLoading = false;
    });
  }

  void _showStaffForm({Staff? staff}) {
    final empNoCtrl = TextEditingController(text: staff?.empNo ?? '');
    final nameCtrl = TextEditingController(text: staff?.name ?? '');
    final ssCtrl = TextEditingController(text: staff?.subStation ?? '');
    final mobileCtrl = TextEditingController(text: staff?.mobile ?? '');
    final salaryCtrl = TextEditingController(
        text: staff != null ? staff.basicSalary.toStringAsFixed(0) : '');
    String designation = staff?.designation ?? '';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    staff != null ? 'Edit Staff' : 'Add Staff',
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: empNoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Employee Number',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name of Employee',
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: designation.isEmpty ? null : designation,
                    decoration: const InputDecoration(
                      labelText: 'Designation',
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: AppConstants.designations
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setModalState(() => designation = v ?? ''),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ssCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Place of Working (SubStation)',
                      prefixIcon: Icon(Icons.place),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: mobileCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: salaryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Basic Salary',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.trim().isEmpty == true) return 'Required';
                      if (double.tryParse(v!) == null) return 'Enter valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final s = Staff(
                          id: staff?.id,
                          empNo: empNoCtrl.text.trim(),
                          name: nameCtrl.text.trim(),
                          designation: designation,
                          subStation: ssCtrl.text.trim(),
                          mobile: mobileCtrl.text.trim(),
                          basicSalary: double.parse(salaryCtrl.text.trim()),
                          sortOrder: staff?.sortOrder ?? 0,
                        );
                        if (staff != null) {
                          await DatabaseHelper.instance.updateStaff(s);
                        } else {
                          await DatabaseHelper.instance.insertStaff(s);
                        }
                        Navigator.pop(ctx);
                        _loadData();
                      },
                      icon: Icon(staff != null ? Icons.save : Icons.add),
                      label: Text(staff != null ? 'Update' : 'Add Staff'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteStaff(Staff staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Remove ${staff.name} from staff list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteStaff(staff.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff & Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Division Setup',
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DivisionSetupScreen(isEditing: true)));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Vehicles section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Icon(Icons.directions_car, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Vehicles (${_vehicles.length}/${AppConstants.maxVehicles})',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const VehicleManagementScreen()));
                            _loadData();
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Manage'),
                        ),
                      ],
                    ),
                  ),
                  if (_vehicles.isEmpty)
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.info_outline, color: colorScheme.primary),
                        title: const Text('No vehicles added yet'),
                        subtitle: const Text('Tap Manage to add vehicles'),
                      ),
                    )
                  else
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _vehicles.length,
                        itemBuilder: (ctx, i) {
                          final v = _vehicles[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(v.vehicleNumber,
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(v.nickName, style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const Divider(height: 32),

                  // Staff section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Staff Members (${_staffList.length})',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        FilledButton.tonalIcon(
                          onPressed: () => _showStaffForm(),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                  if (_staffList.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.group_add, size: 48, color: colorScheme.primary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text('No staff members yet',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('Add staff members to start creating daily reports',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _staffList.length,
                      onReorder: (oldIndex, newIndex) async {
                        if (newIndex > oldIndex) newIndex--;
                        setState(() {
                          final item = _staffList.removeAt(oldIndex);
                          _staffList.insert(newIndex, item);
                        });
                        await DatabaseHelper.instance.reorderStaff(_staffList);
                      },
                      itemBuilder: (ctx, i) {
                        final s = _staffList[i];
                        return Card(
                          key: ValueKey(s.id),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                )),
                            ),
                            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${s.designation} • ₹${s.basicSalary.toStringAsFixed(0)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20, color: colorScheme.primary),
                                  onPressed: () => _showStaffForm(staff: s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _deleteStaff(s),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
