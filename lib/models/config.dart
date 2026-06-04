class Config {
  int? id;
  String divisionName;
  String headQuarter;
  String hqCityClass;
  String inchargeDesignation;
  bool groupJE;
  String? groupSSName;

  Config({
    this.id,
    required this.divisionName,
    required this.headQuarter,
    required this.hqCityClass,
    required this.inchargeDesignation,
    this.groupJE = false,
    this.groupSSName,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'divisionName': divisionName,
    'headQuarter': headQuarter,
    'hqCityClass': hqCityClass,
    'inchargeDesignation': inchargeDesignation,
    'groupJE': groupJE ? 1 : 0,
    'groupSSName': groupSSName,
  };

  factory Config.fromMap(Map<String, dynamic> map) => Config(
    id: map['id'] as int?,
    divisionName: map['divisionName'] as String,
    headQuarter: map['headQuarter'] as String,
    hqCityClass: map['hqCityClass'] as String,
    inchargeDesignation: map['inchargeDesignation'] as String,
    groupJE: (map['groupJE'] as int?) == 1,
    groupSSName: map['groupSSName'] as String?,
  );

  Config copyWith({
    int? id,
    String? divisionName,
    String? headQuarter,
    String? hqCityClass,
    String? inchargeDesignation,
    bool? groupJE,
    String? groupSSName,
  }) => Config(
    id: id ?? this.id,
    divisionName: divisionName ?? this.divisionName,
    headQuarter: headQuarter ?? this.headQuarter,
    hqCityClass: hqCityClass ?? this.hqCityClass,
    inchargeDesignation: inchargeDesignation ?? this.inchargeDesignation,
    groupJE: groupJE ?? this.groupJE,
    groupSSName: groupSSName ?? this.groupSSName,
  );
}
