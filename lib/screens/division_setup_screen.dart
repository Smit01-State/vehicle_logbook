import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/config.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class DivisionSetupScreen extends StatefulWidget {
  final bool isEditing;
  const DivisionSetupScreen({super.key, this.isEditing = false});

  @override
  State<DivisionSetupScreen> createState() => _DivisionSetupScreenState();
}

class _DivisionSetupScreenState extends State<DivisionSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _divisionController = TextEditingController();
  final _hqController = TextEditingController();
  final _groupSSController = TextEditingController();

  String _selectedCityClass = '';
  String _selectedDesignation = '';
  bool _isGroupJE = false;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadExistingConfig();
  }

  Future<void> _loadExistingConfig() async {
    final config = await DatabaseHelper.instance.getConfig();
    if (config != null) {
      setState(() {
        _divisionController.text = config.divisionName;
        _hqController.text = config.headQuarter;
        _selectedCityClass = config.hqCityClass;
        _selectedDesignation = config.inchargeDesignation;
        _isGroupJE = config.groupJE;
        _groupSSController.text = config.groupSSName ?? '';
      });
    }
  }

  @override
  void dispose() {
    _divisionController.dispose();
    _hqController.dispose();
    _groupSSController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCityClass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Head Quarter City Class'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedDesignation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Designation of Incharge'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final config = Config(
      divisionName: _divisionController.text.trim(),
      headQuarter: _hqController.text.trim(),
      hqCityClass: _selectedCityClass,
      inchargeDesignation: _selectedDesignation,
      groupJE: _isGroupJE,
      groupSSName:
          _isGroupJE ? _groupSSController.text.trim() : null,
    );

    final existing = await DatabaseHelper.instance.getConfig();
    if (existing != null) {
      config.id = existing.id;
      await DatabaseHelper.instance.updateConfig(config);
    } else {
      await DatabaseHelper.instance.insertConfig(config);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configuration saved successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      if (widget.isEditing) {
        Navigator.pop(context, true);
      } else {
        // First-time setup: navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Configuration' : 'Division Setup'),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.business, size: 48, color: colorScheme.onPrimary),
                      const SizedBox(height: 8),
                      Text(
                        'Gujarat Energy Transmission\nCorporation Ltd.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Division Name
                Text('Division Name', style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _divisionController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Banaskantha',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter Division name' : null,
                ),
                const SizedBox(height: 20),

                // Head Quarter
                Text('Head Quarter', style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hqController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Deodar',
                    prefixIcon: Icon(Icons.place),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter Head Quarter name' : null,
                ),
                const SizedBox(height: 20),

                // City Class
                Text('Head Quarter City Class', style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.cityClasses.map((c) {
                    final selected = _selectedCityClass == c;
                    return ChoiceChip(
                      label: Text(c),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedCityClass = c),
                      selectedColor: colorScheme.primary,
                      labelStyle: TextStyle(
                        color: selected ? colorScheme.onPrimary : null,
                        fontWeight: selected ? FontWeight.bold : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Designation of Incharge
                Text('Designation of Incharge', style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDesignation.isEmpty ? null : _selectedDesignation,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge),
                    hintText: 'Select Designation',
                  ),
                  items: ['Executive Engineer', 'Deputy Engineer', 'Junior Engineer']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedDesignation = v ?? '';
                      if (v != 'Junior Engineer') {
                        _isGroupJE = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Group JE checkbox
                if (_selectedDesignation == 'Junior Engineer') ...[
                  CheckboxListTile(
                    value: _isGroupJE,
                    onChanged: (v) => setState(() => _isGroupJE = v ?? false),
                    title: const Text('Group JE'),
                    subtitle: const Text('Enable if this is a 66kV Group'),
                    controlAffinity: ListTileControlAffinity.leading,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  if (_isGroupJE) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _groupSSController,
                      decoration: const InputDecoration(
                        hintText: 'Enter 66kV Group name',
                        prefixIcon: Icon(Icons.group_work),
                      ),
                      validator: (v) {
                        if (_isGroupJE && (v == null || v.trim().isEmpty)) {
                          return 'Please enter 66kV Group name';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveConfig,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isLoading ? 'Saving...' : 'Save Configuration',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
