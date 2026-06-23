class AppConstants {
  static const String companyName = 'GETCO';
  static const String appName = 'Vehicle LogBook & TA Bill Generator';
  static const String appSubtitle = 'General Purpose';
  static const String appVersion = 'V - 1.3';
  static const String orgName = '';

  static const List<String> designations = [
    'Executive Engineer',
    'Deputy Engineer',
    'Junior Engineer',
    'PO-1',
    'Line Inspector',
    'Line Man',
    'AO',
    'Assistant Line Man',
    'Electrician',
    'SBO',
    'Electrical Assistant',
  ];

  static const List<String> inchargeDesignations = [
    'Executive Engineer',
    'Deputy Engineer',
    'Junior Engineer',
  ];

  static const List<String> cityClasses = [
    'A-1 Class',
    'A Class',
    'B-1 Class',
    'Other',
  ];

  static const List<String> tripTypes = [
    'Normal',
    'No Trip',
    'Vehicle Allotted',
    'Staff Allotted',
    'Employee Training',
  ];

  static const int maxVehicles = 12;

  static const List<String> certificates = [
    'Certified that the claims representing payment of railway or steamer are of the class of accommodation actually used.',
    '1. Certified that distance travelled by road are correct so far as I have been able to ascertain.',
    '2. Certified that the actual cost claimed in the bill for which vouchers could not be obtained is correct to the best of my knowledge.',
    '3. Certified that in respect of journey for which road mileages is claimed.',
    'I have travelled by : Motor-car / Motor-cycle Owned / hired / borrowed by me and that vouchers for actual expenses have furnished in respect of journey performed in hired / borrowed conveyance.',
    'Name or the conveyance to be written here.',
    '4. Certified that journeys for which claims have been prepare were performed in the interest of public service and the actual expenses were not less than those claimed in the bill.',
  ];
}
