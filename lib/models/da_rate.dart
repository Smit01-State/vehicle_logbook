class DaRate {
  int? id;
  String basicPayRange;
  double a1Class;
  double aClass;
  double b1Class;
  double other;

  DaRate({
    this.id,
    required this.basicPayRange,
    required this.a1Class,
    required this.aClass,
    required this.b1Class,
    required this.other,
  });

  double getRate(String cityClass) {
    switch (cityClass) {
      case 'A-1 Class': return a1Class;
      case 'A Class': return aClass;
      case 'B-1 Class': return b1Class;
      default: return other;
    }
  }

  String get allRatesDisplay =>
    '${a1Class.toInt()} / ${aClass.toInt()} / ${b1Class.toInt()} / ${other.toInt()}';

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'basicPayRange': basicPayRange,
    'a1Class': a1Class,
    'aClass': aClass,
    'b1Class': b1Class,
    'other': other,
  };

  factory DaRate.fromMap(Map<String, dynamic> map) => DaRate(
    id: map['id'] as int?,
    basicPayRange: map['basicPayRange'] as String,
    a1Class: (map['a1Class'] as num).toDouble(),
    aClass: (map['aClass'] as num).toDouble(),
    b1Class: (map['b1Class'] as num).toDouble(),
    other: (map['other'] as num).toDouble(),
  );
}
