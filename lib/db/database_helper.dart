import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/config.dart';
import '../models/staff.dart';
import '../models/vehicle.dart';
import '../models/daily_report.dart';
import '../models/da_rate.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vehicle_logbook.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        divisionName TEXT NOT NULL,
        headQuarter TEXT NOT NULL,
        hqCityClass TEXT NOT NULL,
        inchargeDesignation TEXT NOT NULL,
        groupJE INTEGER DEFAULT 0,
        groupSSName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        empNo TEXT NOT NULL,
        name TEXT NOT NULL,
        designation TEXT NOT NULL,
        subStation TEXT NOT NULL,
        mobile TEXT NOT NULL,
        basicSalary REAL NOT NULL,
        sortOrder INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleNumber TEXT NOT NULL,
        nickName TEXT NOT NULL,
        sortOrder INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        vehicleId INTEGER,
        vehicleName TEXT DEFAULT '',
        staff TEXT DEFAULT '',
        journey TEXT DEFAULT '',
        purpose TEXT DEFAULT '',
        initialKm REAL,
        startTime TEXT,
        finalKm REAL,
        endTime TEXT,
        distance REAL,
        duration TEXT,
        signature TEXT,
        fare TEXT,
        cityClass TEXT DEFAULT 'Other',
        tripType TEXT DEFAULT 'Normal'
      )
    ''');

    await db.execute('''
      CREATE TABLE da_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        basicPayRange TEXT NOT NULL,
        a1Class REAL NOT NULL,
        aClass REAL NOT NULL,
        b1Class REAL NOT NULL,
        other REAL NOT NULL
      )
    ''');

    // Seed DA rates
    await _seedDaRates(db);
  }

  Future<void> _seedDaRates(Database db) async {
    final rates = [
      {'basicPayRange': '110100', 'a1Class': 590.0, 'aClass': 480.0, 'b1Class': 390.0, 'other': 300.0},
      {'basicPayRange': '55600', 'a1Class': 530.0, 'aClass': 420.0, 'b1Class': 350.0, 'other': 270.0},
      {'basicPayRange': '45400', 'a1Class': 450.0, 'aClass': 360.0, 'b1Class': 300.0, 'other': 240.0},
      {'basicPayRange': '26000', 'a1Class': 390.0, 'aClass': 300.0, 'b1Class': 260.0, 'other': 210.0},
      {'basicPayRange': 'Other', 'a1Class': 240.0, 'aClass': 200.0, 'b1Class': 170.0, 'other': 140.0},
    ];
    for (final rate in rates) {
      await db.insert('da_rates', rate);
    }
  }

  // ===== CONFIG =====
  Future<int> insertConfig(Config config) async {
    final db = await database;
    return db.insert('config', config.toMap());
  }

  Future<Config?> getConfig() async {
    final db = await database;
    final maps = await db.query('config', limit: 1);
    if (maps.isEmpty) return null;
    return Config.fromMap(maps.first);
  }

  Future<int> updateConfig(Config config) async {
    final db = await database;
    return db.update('config', config.toMap(), where: 'id = ?', whereArgs: [config.id]);
  }

  // ===== STAFF =====
  Future<int> insertStaff(Staff staff) async {
    final db = await database;
    final maxOrder = await db.rawQuery('SELECT MAX(sortOrder) as maxOrder FROM staff');
    staff.sortOrder = ((maxOrder.first['maxOrder'] as int?) ?? 0) + 1;
    return db.insert('staff', staff.toMap());
  }

  Future<List<Staff>> getAllStaff() async {
    final db = await database;
    final maps = await db.query('staff', orderBy: 'sortOrder ASC');
    return maps.map((m) => Staff.fromMap(m)).toList();
  }

  Future<Staff?> getStaffById(int id) async {
    final db = await database;
    final maps = await db.query('staff', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Staff.fromMap(maps.first);
  }

  Future<int> updateStaff(Staff staff) async {
    final db = await database;
    return db.update('staff', staff.toMap(), where: 'id = ?', whereArgs: [staff.id]);
  }

  Future<int> deleteStaff(int id) async {
    final db = await database;
    return db.delete('staff', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorderStaff(List<Staff> staffList) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < staffList.length; i++) {
      batch.update('staff', {'sortOrder': i}, where: 'id = ?', whereArgs: [staffList[i].id]);
    }
    await batch.commit();
  }

  // ===== VEHICLES =====
  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    final maxOrder = await db.rawQuery('SELECT MAX(sortOrder) as maxOrder FROM vehicles');
    vehicle.sortOrder = ((maxOrder.first['maxOrder'] as int?) ?? 0) + 1;
    return db.insert('vehicles', vehicle.toMap());
  }

  Future<List<Vehicle>> getAllVehicles() async {
    final db = await database;
    final maps = await db.query('vehicles', orderBy: 'sortOrder ASC');
    return maps.map((m) => Vehicle.fromMap(m)).toList();
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    return db.update('vehicles', vehicle.toMap(), where: 'id = ?', whereArgs: [vehicle.id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getVehicleCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM vehicles');
    return (result.first['count'] as int?) ?? 0;
  }

  // ===== DAILY REPORTS =====
  Future<int> insertDailyReport(DailyReport report) async {
    final db = await database;
    return db.insert('daily_reports', report.toMap());
  }

  Future<List<DailyReport>> getAllDailyReports() async {
    final db = await database;
    final maps = await db.query('daily_reports', orderBy: 'date ASC');
    return maps.map((m) => DailyReport.fromMap(m)).toList();
  }

  Future<List<DailyReport>> getDailyReportsByMonth(int month, int year) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    final maps = await db.query(
      'daily_reports',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => DailyReport.fromMap(m)).toList();
  }

  Future<List<DailyReport>> getDailyReportsByVehicleAndMonth(
      String vehicleName, int month, int year) async {
    final reports = await getDailyReportsByMonth(month, year);
    return reports.where((r) => r.vehicleName == vehicleName).toList();
  }

  Future<List<DailyReport>> getDailyReportsByEmployeeAndMonth(
      String employeeName, int month, int year) async {
    final reports = await getDailyReportsByMonth(month, year);
    return reports.where((r) => r.staff.contains(employeeName)).toList();
  }

  Future<List<Map<String, int>> > getAvailableMonths() async {
    final db = await database;
    final maps = await db.query('daily_reports', columns: ['date'], orderBy: 'date ASC');
    final months = <String, Map<String, int>>{};
    for (final m in maps) {
      final date = DateTime.parse(m['date'] as String);
      final key = '${date.month}-${date.year}';
      months[key] = {'month': date.month, 'year': date.year};
    }
    return months.values.toList();
  }

  Future<int> updateDailyReport(DailyReport report) async {
    final db = await database;
    return db.update('daily_reports', report.toMap(), where: 'id = ?', whereArgs: [report.id]);
  }

  Future<int> deleteDailyReport(int id) async {
    final db = await database;
    return db.delete('daily_reports', where: 'id = ?', whereArgs: [id]);
  }

  // ===== DA RATES =====
  Future<List<DaRate>> getAllDaRates() async {
    final db = await database;
    final maps = await db.query('da_rates');
    return maps.map((m) => DaRate.fromMap(m)).toList();
  }

  Future<double> getDaRate(double basicSalary, String cityClass, {String? designation}) async {
    String basicPayRange;
    if (basicSalary >= 110100) {
      basicPayRange = '110100';
    } else if (basicSalary >= 55600) {
      basicPayRange = '55600';
    } else if (basicSalary >= 45400 || designation == 'Junior Engineer') {
      basicPayRange = '45400';
    } else if (basicSalary >= 26000) {
      basicPayRange = '26000';
    } else {
      basicPayRange = 'Other';
    }

    final db = await database;
    final maps = await db.query('da_rates',
      where: 'basicPayRange = ?', whereArgs: [basicPayRange]);
    if (maps.isEmpty) return 0;
    final rate = DaRate.fromMap(maps.first);
    return rate.getRate(cityClass);
  }

  Future<int> updateDaRate(DaRate rate) async {
    final db = await database;
    return db.update('da_rates', rate.toMap(), where: 'id = ?', whereArgs: [rate.id]);
  }

  // ===== EXPORT / IMPORT =====
  Future<String> exportAllData() async {
    final config = await getConfig();
    final staffList = await getAllStaff();
    final vehicles = await getAllVehicles();
    final reports = await getAllDailyReports();
    final daRates = await getAllDaRates();

    final data = {
      'version': '1.3',
      'exportDate': DateTime.now().toIso8601String(),
      'config': config?.toMap(),
      'staff': staffList.map((s) => s.toMap()).toList(),
      'vehicles': vehicles.map((v) => v.toMap()).toList(),
      'dailyReports': reports.map((r) => r.toMap()).toList(),
      'daRates': daRates.map((d) => d.toMap()).toList(),
    };
    return jsonEncode(data);
  }

  Future<void> importAllData(String jsonData) async {
    final data = jsonDecode(jsonData) as Map<String, dynamic>;
    final db = await database;

    await db.delete('config');
    await db.delete('staff');
    await db.delete('vehicles');
    await db.delete('daily_reports');
    await db.delete('da_rates');

    if (data['config'] != null) {
      await db.insert('config', data['config'] as Map<String, dynamic>);
    }
    for (final s in (data['staff'] as List? ?? [])) {
      await db.insert('staff', Map<String, dynamic>.from(s));
    }
    for (final v in (data['vehicles'] as List? ?? [])) {
      await db.insert('vehicles', Map<String, dynamic>.from(v));
    }
    for (final r in (data['dailyReports'] as List? ?? [])) {
      await db.insert('daily_reports', Map<String, dynamic>.from(r));
    }
    for (final d in (data['daRates'] as List? ?? [])) {
      await db.insert('da_rates', Map<String, dynamic>.from(d));
    }
  }

  Future<void> resetAllData() async {
    final db = await database;
    await db.delete('config');
    await db.delete('staff');
    await db.delete('vehicles');
    await db.delete('daily_reports');
    await db.delete('da_rates');
    await _seedDaRates(db);
  }
}
