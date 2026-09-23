import 'package:cognifind/models/navigation/search_place.dart';

/// Approximate campus center; used as fallback when
/// user GPS location is unavailable.
const double campusCenterLat = 33.925902;
const double campusCenterLng = 75.018993;

/// Static catalog of searchable campus places.
/// Add new places here to appear in the search UI.
const List<SearchPlace> campusPlaces = [

  /// LIB
  SearchPlace(
    id: 'LIB',
    name: 'Rumi Library',
    subtitle: 'Main Campus Library',
    category: PlaceCategory.library,
    latitude: 33.9271258,
    longitude: 75.0189879,

  ),

  /// AB-I
  SearchPlace(
    id: 'AB-I',
    name: 'IMBA',
    subtitle: 'IMBA',
    category: PlaceCategory.academic,
    latitude: 33.9264335,
    longitude: 75.0191435,

  ),

  /// AB-II
  SearchPlace(
    id: 'AB-II',
    name: 'Civil Engineering',
    subtitle: 'Civil Department',
    category: PlaceCategory.academic,
    latitude: 33.9257505,
    longitude: 75.0188461,

  ),

  /// AB-III
  SearchPlace(
    id: 'AB-III',
    name: 'ECE / Electrical / Mechanical',
    subtitle: 'Electronics and Mechanical Departments',
    category: PlaceCategory.academic,
    latitude: 33.9251309,
    longitude: 75.0193087,

  ),

  /// AB-IV
  SearchPlace(
    id: 'AB-IV',
    name: 'CSE',
    subtitle: 'Computer Science Engineering',
    category: PlaceCategory.academic,
    latitude: 33.9252333,
    longitude: 75.0201628,

    /// Indoor destination so a search-selected CSE routes hybrid (outdoor →
    /// indoor), matching the CSE map marker in campus_buildings.
    destinationNodeId: 'N217',
  ),

  /// AB-V
  SearchPlace(
    id: 'AB-V',
    name: 'Arabic Department',
    subtitle: 'Arabic Studies',
    category: PlaceCategory.academic,
    latitude: 33.9247142,
    longitude: 75.0206382,

  ),

  /// AB-VI
  SearchPlace(
    id: 'AB-VI',
    name: 'Academic Block VI',
    subtitle: 'Academic Building',
    category: PlaceCategory.academic,
    latitude: 33.9255835,
    longitude: 75.0193744,

  ),

  /// AB-VII
  SearchPlace(
    id: 'AB-VII',
    name: 'FoodTech / Mathematics',
    subtitle: 'Food Technology and Mathematics',
    category: PlaceCategory.academic,
    latitude: 33.9257711,
    longitude: 75.0205175,

  ),

  /// AB-IX
  SearchPlace(
    id: 'AB-IX',
    name: 'Nursing Department',
    subtitle: 'School of Nursing',
    category: PlaceCategory.academic,
    latitude: 33.9262159,
    longitude: 75.0209405,

  ),

  /// AB-X
  SearchPlace(
    id: 'AB-X',
    name: 'English / Journalism',
    subtitle: 'English and Journalism Department',
    category: PlaceCategory.academic,
    latitude: 33.9245141,
    longitude: 75.0201382,

  ),

  /// AB-XI
  SearchPlace(
    id: 'AB-XI',
    name: 'Civil / Mechanical / Exam Hall',
    subtitle: 'Academic and Examination Block',
    category: PlaceCategory.academic,
    latitude: 33.9251681,
    longitude: 75.0186330,

  ),

  /// AB-XII
  SearchPlace(
    id: 'AB-XII',
    name: 'Architecture Department',
    subtitle: 'Architecture Building',
    category: PlaceCategory.academic,
    latitude: 33.9257057,
    longitude: 75.0183845,

  ),

  /// AD1
  SearchPlace(
    id: 'AD1',
    name: 'Administration Block',
    subtitle: 'University Administration Offices',
    category: PlaceCategory.administration,
    latitude: 33.9266072,
    longitude: 75.0186233,

  ),

  /// T-I
  SearchPlace(
    id: 'T-I',
    name: 'Transport Office',
    subtitle: 'Campus Transport Services',
    category: PlaceCategory.other,
    latitude: 33.9267694,
    longitude: 75.0188460,

  ),

  /// C-I
  SearchPlace(
    id: 'C-I',
    name: 'Light House',
    subtitle: 'Campus Facility Building',
    category: PlaceCategory.other,
    latitude: 33.9246871,
    longitude: 75.0194902,

  ),

  /// C-II
  SearchPlace(
    id: 'C-II',
    name: 'Nescafe',
    subtitle: 'Campus Cafe',
    category: PlaceCategory.other,
    latitude: 33.9268572,
    longitude: 75.0184013,

  ),

  /// M-I
  SearchPlace(
    id: 'M-I',
    name: 'Masjid',
    subtitle: 'Campus Mosque / Prayer Area',
    category: PlaceCategory.other,
    latitude: 33.9243623,
    longitude: 75.0190132,

  ),

  /// W-I
  SearchPlace(
    id: 'W-I',
    name: 'Washroom Building',
    subtitle: 'Public Washroom Facility',
    category: PlaceCategory.other,
    latitude: 33.9247065,
    longitude: 75.0191740,

  ),
];