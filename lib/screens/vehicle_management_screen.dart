import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/vehicle.dart';
import '../utils/constants.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    final vehicles = await DatabaseHelper.instance.getAllVehicles();
    setState(() { _vehicles = vehicles; _isLoading = false; });
  }

  void _showVehicleForm({Vehicle? vehicle}) {
    final numberCtrl = TextEditingController(text: vehicle?.vehicleNumber ?? '');
    final nickCtrl = TextEditingController(text: vehicle?.nickName ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(vehicle != null ? 'Edit Vehicle' : 'Add Vehicle',
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: numberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                  prefixIcon: Icon(Icons.directions_car),
                  hintText: 'e.g., GJ-1-GG-1234',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nickCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nick Name',
                  prefixIcon: Icon(Icons.label),
                  hintText: 'e.g., Bolero',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final v = Vehicle(
                      id: vehicle?.id,
                      vehicleNumber: numberCtrl.text.trim(),
                      nickName: nickCtrl.text.trim(),
                      sortOrder: vehicle?.sortOrder ?? 0,
                    );
                    if (vehicle != null) {
                      await DatabaseHelper.instance.updateVehicle(v);
                    } else {
                      await DatabaseHelper.instance.insertVehicle(v);
                    }
                    Navigator.pop(ctx);
                    _loadVehicles();
                  },
                  icon: Icon(vehicle != null ? Icons.save : Icons.add),
                  label: Text(vehicle != null ? 'Update' : 'Add Vehicle'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteVehicle(Vehicle v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Remove ${v.vehicleNumber} (${v.nickName})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteVehicle(v.id!);
      _loadVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Vehicles')),
      floatingActionButton: _vehicles.length < AppConstants.maxVehicles
          ? FloatingActionButton.extended(
              onPressed: () => _showVehicleForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 64,
                        color: colorScheme.primary.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('No vehicles added', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Add up to ${AppConstants.maxVehicles} vehicles',
                        style: theme.textTheme.bodySmall),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _vehicles.length,
                  itemBuilder: (ctx, i) {
                    final v = _vehicles[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Icon(Icons.directions_car, color: colorScheme.onSecondaryContainer),
                        ),
                        title: Text(v.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(v.nickName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: Icon(Icons.edit, color: colorScheme.primary, size: 20),
                              onPressed: () => _showVehicleForm(vehicle: v)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _deleteVehicle(v)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
