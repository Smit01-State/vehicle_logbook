class Staff {
  int? id;
  String empNo;
  String name;
  String designation;
  String subStation;
  String mobile;
  double basicSalary;
  int sortOrder;

  Staff({
    this.id,
    required this.empNo,
    required this.name,
    required this.designation,
    required this.subStation,
    required this.mobile,
    required this.basicSalary,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'empNo': empNo,
    'name': name,
    'designation': designation,
    'subStation': subStation,
    'mobile': mobile,
    'basicSalary': basicSalary,
    'sortOrder': sortOrder,
  };

  factory Staff.fromMap(Map<String, dynamic> map) => Staff(
    id: map['id'] as int?,
    empNo: map['empNo'] as String,
    name: map['name'] as String,
    designation: map['designation'] as String,
    subStation: map['subStation'] as String,
    mobile: map['mobile'] as String,
    basicSalary: (map['basicSalary'] as num).toDouble(),
    sortOrder: (map['sortOrder'] as int?) ?? 0,
  );

  Staff copyWith({
    int? id, String? empNo, String? name, String? designation,
    String? subStation, String? mobile, double? basicSalary, int? sortOrder,
  }) => Staff(
    id: id ?? this.id,
    empNo: empNo ?? this.empNo,
    name: name ?? this.name,
    designation: designation ?? this.designation,
    subStation: subStation ?? this.subStation,
    mobile: mobile ?? this.mobile,
    basicSalary: basicSalary ?? this.basicSalary,
    sortOrder: sortOrder ?? this.sortOrder,
  );
}
