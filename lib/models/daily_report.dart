class DailyReport {
  int? id;
  DateTime date;
  int? vehicleId;
  String vehicleName;
  String staff;
  String journey;
  String purpose;
  double? initialKm;
  String? startTime;
  double? finalKm;
  String? endTime;
  double? distance;
  String? duration;
  String? signature;
  String? fare;
  String cityClass;
  String tripType;

  DailyReport({
    this.id,
    required this.date,
    this.vehicleId,
    this.vehicleName = '',
    this.staff = '',
    this.journey = '',
    this.purpose = '',
    this.initialKm,
    this.startTime,
    this.finalKm,
    this.endTime,
    this.distance,
    this.duration,
    this.signature,
    this.fare,
    this.cityClass = 'Other',
    this.tripType = 'Normal',
  });

  bool get isDaEligible {
    if (tripType == 'Employee Training') return true;
    final dist = distance ?? 0;
    final dur = _durationToMinutes(duration);
    return dist >= 8 && dur >= 480; // 8 hours = 480 minutes
  }

  static int _durationToMinutes(String? dur) {
    if (dur == null || dur.isEmpty) return 0;
    final parts = dur.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  double get parsedFareTotal {
    if (fare == null || fare!.isEmpty) return 0;
    try {
      final parts = fare!.split('+');
      double total = 0;
      for (final p in parts) {
        total += double.tryParse(p.trim()) ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'date': date.toIso8601String(),
    'vehicleId': vehicleId,
    'vehicleName': vehicleName,
    'staff': staff,
    'journey': journey,
    'purpose': purpose,
    'initialKm': initialKm,
    'startTime': startTime,
    'finalKm': finalKm,
    'endTime': endTime,
    'distance': distance,
    'duration': duration,
    'signature': signature,
    'fare': fare,
    'cityClass': cityClass,
    'tripType': tripType,
  };

  factory DailyReport.fromMap(Map<String, dynamic> map) => DailyReport(
    id: map['id'] as int?,
    date: DateTime.parse(map['date'] as String),
    vehicleId: map['vehicleId'] as int?,
    vehicleName: (map['vehicleName'] as String?) ?? '',
    staff: (map['staff'] as String?) ?? '',
    journey: (map['journey'] as String?) ?? '',
    purpose: (map['purpose'] as String?) ?? '',
    initialKm: (map['initialKm'] as num?)?.toDouble(),
    startTime: map['startTime'] as String?,
    finalKm: (map['finalKm'] as num?)?.toDouble(),
    endTime: map['endTime'] as String?,
    distance: (map['distance'] as num?)?.toDouble(),
    duration: map['duration'] as String?,
    signature: map['signature'] as String?,
    fare: map['fare'] as String?,
    cityClass: (map['cityClass'] as String?) ?? 'Other',
    tripType: (map['tripType'] as String?) ?? 'Normal',
  );

  DailyReport copyWith({
    int? id, DateTime? date, int? vehicleId, String? vehicleName,
    String? staff, String? journey, String? purpose,
    double? initialKm, String? startTime, double? finalKm, String? endTime,
    double? distance, String? duration, String? signature, String? fare,
    String? cityClass, String? tripType,
  }) => DailyReport(
    id: id ?? this.id,
    date: date ?? this.date,
    vehicleId: vehicleId ?? this.vehicleId,
    vehicleName: vehicleName ?? this.vehicleName,
    staff: staff ?? this.staff,
    journey: journey ?? this.journey,
    purpose: purpose ?? this.purpose,
    initialKm: initialKm ?? this.initialKm,
    startTime: startTime ?? this.startTime,
    finalKm: finalKm ?? this.finalKm,
    endTime: endTime ?? this.endTime,
    distance: distance ?? this.distance,
    duration: duration ?? this.duration,
    signature: signature ?? this.signature,
    fare: fare ?? this.fare,
    cityClass: cityClass ?? this.cityClass,
    tripType: tripType ?? this.tripType,
  );
}
