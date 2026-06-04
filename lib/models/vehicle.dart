class Vehicle {
  int? id;
  String vehicleNumber;
  String nickName;
  int sortOrder;

  Vehicle({
    this.id,
    required this.vehicleNumber,
    required this.nickName,
    this.sortOrder = 0,
  });

  String get displayName => '$vehicleNumber {$nickName}';

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'vehicleNumber': vehicleNumber,
    'nickName': nickName,
    'sortOrder': sortOrder,
  };

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle(
    id: map['id'] as int?,
    vehicleNumber: map['vehicleNumber'] as String,
    nickName: map['nickName'] as String,
    sortOrder: (map['sortOrder'] as int?) ?? 0,
  );

  Vehicle copyWith({int? id, String? vehicleNumber, String? nickName, int? sortOrder}) =>
    Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      nickName: nickName ?? this.nickName,
      sortOrder: sortOrder ?? this.sortOrder,
    );
}
